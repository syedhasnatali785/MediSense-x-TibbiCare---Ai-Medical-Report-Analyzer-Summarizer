import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show Rect, Size, Offset;

import 'package:aimedicalreportanalyzer/models/frame_analyser_m.dart';
import 'package:aimedicalreportanalyzer/providers/scan_quality.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Owns the CameraController, the frame stream, real-time text detection,
/// the clarity checks and the auto-capture decision.
/// The UI listens to [ui]; when a photo is taken, [onCaptured] is called.
class LiveScanner {
  LiveScanner({required this.onCaptured});

  final void Function(File file) onCaptured;
  final ValueNotifier<ScanUiState> ui = ValueNotifier(const ScanUiState());

  CameraController? controller;
  CameraDescription? _camera;
  final TextRecognizer _recognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  bool _busy = false;
  bool _captured = false;
  bool _disposed = false;
  bool _streaming = false;
  DateTime _lastRun = DateTime.fromMillisecondsSinceEpoch(0);
  int _streak = 0;
  Rect? _prevBounds;

  static const _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  void _set(ScanUiState s) {
    if (!_disposed) ui.value = s;
  }

  Future<void> init() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _set(ui.value.copyWith(error: 'No camera found on this device.'));
        return;
      }
      _camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final c = CameraController(
        _camera!,
        ResolutionPreset.veryHigh, // sharper text; lower to "high" if slow
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );
      controller = c;
      await c.initialize();
      if (_disposed) {
        await c.dispose();
        return;
      }

      await _safe(() => c.setFocusMode(FocusMode.auto));
      await _safe(() => c.setExposureMode(ExposureMode.auto));
      await c.startImageStream(_onFrame);
      _streaming = true;

      _set(ui.value.copyWith(cameraReady: true, hint: ScanHint.noText));
    } on CameraException catch (e) {
      final denied = e.code.startsWith('CameraAccess');
      _set(
        ui.value.copyWith(
          error: denied
              ? 'Camera permission is needed to scan your report. Please allow it in Settings.'
              : 'Could not start the camera (${e.description ?? e.code}).',
        ),
      );
    } catch (_) {
      _set(ui.value.copyWith(error: 'Could not start the camera.'));
    }
  }

  Future<void> _safe(Future<void> Function() f) async {
    try {
      await f();
    } catch (_) {
      /* not supported on this device */
    }
  }

  // ---------------------------------------------------------------- frames

  Future<void> _onFrame(CameraImage image) async {
    if (_busy || _captured || _disposed) return;
    final now = DateTime.now();
    if (now.difference(_lastRun) < ScanTuning.frameInterval) return;
    _busy = true;
    _lastRun = now;

    try {
      final input = _toInputImage(image);
      if (input == null) return;

      final stats = computeFrameStats(image);
      final text = await _recognizer.processImage(input);
      if (_disposed || _captured) return;

      // The app is locked to portrait, so the upright frame is portrait.
      final up = Size(
        math.min(image.width, image.height).toDouble(),
        math.max(image.width, image.height).toDouble(),
      );

      final boxes = <Rect>[];
      Rect? union;
      var chars = 0;
      for (final block in text.blocks) {
        for (final line in block.lines) {
          final r = line.boundingBox;
          final n = Rect.fromLTRB(
            r.left / up.width,
            r.top / up.height,
            r.right / up.width,
            r.bottom / up.height,
          );
          boxes.add(n);
          union = union == null ? n : union.expandToInclude(n);
          chars += line.text.trim().length;
        }
      }

      var hint = evaluateFrame(
        lineCount: boxes.length,
        charCount: chars,
        bounds: union,
        stats: stats,
      );

      if (hint == null) {
        // All checks pass: require several steady frames in a row.
        final stable =
            _prevBounds != null &&
            (union!.center - _prevBounds!.center).distance <
                ScanTuning.maxCenterShift;
        _streak = stable ? _streak + 1 : 1;
        hint = ScanHint.holdSteady;
      } else {
        _streak = 0;
      }
      _prevBounds = union;

      final progress = (_streak / ScanTuning.goodFramesRequired).clamp(
        0.0,
        1.0,
      );

      _set(
        ui.value.copyWith(
          hint: hint,
          progress: progress,
          boxes: boxes,
          sharpness: stats?.sharpness ?? 0,
          brightness: stats?.brightness ?? 0,
        ),
      );

      if (_streak >= ScanTuning.goodFramesRequired && ui.value.autoCapture) {
        await capture();
      }
    } catch (_) {
      // Skip a bad frame; the next one will retry.
    } finally {
      _busy = false;
    }
  }

  InputImage? _toInputImage(CameraImage image) {
    final camera = _camera;
    final c = controller;
    if (camera == null || c == null) return null;

    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var compensation = _orientations[c.value.deviceOrientation];
      if (compensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        compensation = (sensorOrientation + compensation) % 360;
      } else {
        compensation = (sensorOrientation - compensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(compensation);
    }
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) {
      return null;
    }
    if (image.planes.length != 1) return null;
    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  // --------------------------------------------------------------- capture

  /// Called automatically when the frame is clear, or by the shutter button.
  Future<void> capture() async {
    final c = controller;
    if (c == null ||
        !c.value.isInitialized ||
        _captured ||
        c.value.isTakingPicture) {
      return;
    }
    _captured = true;
    _set(ui.value.copyWith(hint: ScanHint.capturing, progress: 1));

    try {
      if (_streaming) {
        await c.stopImageStream();
        _streaming = false;
      }
      final shot = await c.takePicture();
      await HapticFeedback.mediumImpact();
      if (!_disposed) onCaptured(File(shot.path));
    } on CameraException {
      // Resume live detection so the user can try again.
      _captured = false;
      _streak = 0;
      _set(ui.value.copyWith(hint: ScanHint.noText, progress: 0));
      await _safe(() async {
        await c.startImageStream(_onFrame);
        _streaming = true;
      });
    }
  }

  // ---------------------------------------------------------- user actions

  Future<void> toggleTorch() async {
    final c = controller;
    if (c == null || !c.value.isInitialized) return;
    final on = !ui.value.torchOn;
    await _safe(() async {
      await c.setFlashMode(on ? FlashMode.torch : FlashMode.off);
      _set(ui.value.copyWith(torchOn: on));
    });
  }

  void setAutoCapture(bool value) {
    _streak = 0;
    _set(ui.value.copyWith(autoCapture: value, progress: 0));
  }

  Future<void> focusAt(Offset normalized) async {
    final c = controller;
    if (c == null || !c.value.isInitialized) return;
    await _safe(() => c.setFocusPoint(normalized));
    await _safe(() => c.setExposurePoint(normalized));
  }

  Future<void> dispose() async {
    if (_disposed) return;
    // Let the UI stop drawing the preview before the controller goes away.
    _set(ui.value.copyWith(cameraReady: false));
    _disposed = true;
    await WidgetsBinding.instance.endOfFrame;

    final c = controller;
    controller = null;
    try {
      if (_streaming) await c?.stopImageStream();
    } catch (_) {}
    _streaming = false;
    await c?.dispose();
    await _recognizer.close();
  }
}
