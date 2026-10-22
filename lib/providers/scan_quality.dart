import 'package:aimedicalreportanalyzer/models/frame_analyser_m.dart';
import 'package:flutter/material.dart';

/// All thresholds in one place. They depend on the phone camera and lighting,
/// so tune them on real devices with --dart-define=SCAN_DEBUG=true.
class ScanTuning {
  static const double sharpnessMin = 70;
  static const double brightnessMin = 55;
  static const double brightnessMax = 215;
  static const int minLines = 4;
  static const int minChars = 60;
  static const double minTextAreaFraction = 0.22; // of the frame
  static const double edgeMargin = 0.012; // text must not touch the frame edge
  static const double maxCenterShift = 0.04; // between consecutive frames
  static const int goodFramesRequired = 4; // consecutive steady, clear frames
  static const Duration frameInterval = Duration(milliseconds: 300);
}

enum ScanHint {
  starting,
  noText,
  tooDark,
  tooBright,
  tooFar,
  partial,
  blurry,
  holdSteady,
  capturing,
}

extension ScanHintX on ScanHint {
  String get message => switch (this) {
    ScanHint.starting => 'Starting camera...',
    ScanHint.noText => 'Point the camera at your report',
    ScanHint.tooDark => 'Too dark. Add light or turn on the torch',
    ScanHint.tooBright => 'Too much glare. Tilt the page slightly',
    ScanHint.tooFar => 'Move closer so the report fills the frame',
    ScanHint.partial => 'Fit the whole report inside the frame',
    ScanHint.blurry => 'Not sharp yet. Hold steady and let it focus',
    ScanHint.holdSteady => 'Looks clear. Hold steady...',
    ScanHint.capturing => 'Capturing...',
  };

  IconData get icon => switch (this) {
    ScanHint.starting => Icons.hourglass_empty,
    ScanHint.noText => Icons.document_scanner_outlined,
    ScanHint.tooDark => Icons.dark_mode_outlined,
    ScanHint.tooBright => Icons.light_mode_outlined,
    ScanHint.tooFar => Icons.zoom_in,
    ScanHint.partial => Icons.crop_free,
    ScanHint.blurry => Icons.blur_on,
    ScanHint.holdSteady => Icons.check_circle_outline,
    ScanHint.capturing => Icons.camera,
  };

  bool get isGood => this == ScanHint.holdSteady || this == ScanHint.capturing;
}

/// Returns the first problem found, or null when every check passes.
/// [bounds] is the union of detected text boxes, normalized to 0..1.
ScanHint? evaluateFrame({
  required int lineCount,
  required int charCount,
  required Rect? bounds,
  required FrameStats? stats,
}) {
  if (stats != null) {
    if (stats.brightness < ScanTuning.brightnessMin) return ScanHint.tooDark;
    if (stats.brightness > ScanTuning.brightnessMax) return ScanHint.tooBright;
  }
  if (bounds == null ||
      lineCount < ScanTuning.minLines ||
      charCount < ScanTuning.minChars) {
    return ScanHint.noText;
  }
  if (bounds.width * bounds.height < ScanTuning.minTextAreaFraction) {
    return ScanHint.tooFar;
  }
  const m = ScanTuning.edgeMargin;
  if (bounds.left < m ||
      bounds.top < m ||
      bounds.right > 1 - m ||
      bounds.bottom > 1 - m) {
    return ScanHint.partial;
  }
  if (stats != null && stats.sharpness < ScanTuning.sharpnessMin) {
    return ScanHint.blurry;
  }
  return null;
}

class ScanUiState {
  const ScanUiState({
    this.hint = ScanHint.starting,
    this.progress = 0,
    this.boxes = const [],
    this.sharpness = 0,
    this.brightness = 0,
    this.torchOn = false,
    this.autoCapture = true,
    this.cameraReady = false,
    this.error,
  });

  final ScanHint hint;
  final double progress; // 0..1 toward auto-capture
  final List<Rect> boxes; // normalized text line boxes
  final double sharpness;
  final double brightness;
  final bool torchOn;
  final bool autoCapture;
  final bool cameraReady;
  final String? error;

  ScanUiState copyWith({
    ScanHint? hint,
    double? progress,
    List<Rect>? boxes,
    double? sharpness,
    double? brightness,
    bool? torchOn,
    bool? autoCapture,
    bool? cameraReady,
    String? error,
  }) => ScanUiState(
    hint: hint ?? this.hint,
    progress: progress ?? this.progress,
    boxes: boxes ?? this.boxes,
    sharpness: sharpness ?? this.sharpness,
    brightness: brightness ?? this.brightness,
    torchOn: torchOn ?? this.torchOn,
    autoCapture: autoCapture ?? this.autoCapture,
    cameraReady: cameraReady ?? this.cameraReady,
    error: error ?? this.error,
  );
}
