import 'dart:async';
import 'dart:io';

import 'package:aimedicalreportanalyzer/models/report_analysis_m.dart';
import 'package:aimedicalreportanalyzer/repositories/analysis_api.dart';
import 'package:aimedicalreportanalyzer/repositories/db_repo.dart';
import 'package:aimedicalreportanalyzer/services/camera_service.dart';
import 'package:aimedicalreportanalyzer/services/ocr_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum Stage { idle, capturing, ocr, analyzing, done, error }

class AnalysisState {
  const AnalysisState({
    this.stage = Stage.idle,
    this.ocrText,
    this.result,
    this.error,
  });

  final Stage stage;
  final String? ocrText;
  final ReportAnalysis? result;
  final String? error;

  bool get isBusy =>
      stage == Stage.capturing ||
      stage == Stage.ocr ||
      stage == Stage.analyzing;

  AnalysisState copyWith({
    Stage? stage,
    String? ocrText,
    ReportAnalysis? result,
    String? error,
  }) => AnalysisState(
    stage: stage ?? this.stage,
    ocrText: ocrText ?? this.ocrText,
    result: result ?? this.result,
    error: error ?? this.error,
  );
}

// ---- Providers ----

/// Used for gallery picking. Live camera capture is handled by LiveScanScreen.
final cameraServiceProvider = Provider<CameraService>((ref) => CameraService());

final ocrServiceProvider = Provider<OcrService>((ref) {
  final service = OcrService();
  ref.onDispose(service.dispose);
  return service;
});

final analysisApiProvider = Provider<AnalysisApi>((ref) => AnalysisApi());

final reportRepositoryProvider = Provider<ReportRepository>(
  (ref) => ReportRepository(),
);

final analysisControllerProvider =
    NotifierProvider<AnalysisController, AnalysisState>(AnalysisController.new);

// ---- Controller: image file -> OCR -> Worker -> save to sqflite -> result ----

class AnalysisController extends Notifier<AnalysisState> {
  @override
  AnalysisState build() => const AnalysisState();

  /// Gallery flow.
  Future<void> pickFromGallery() => _run(() async {
    state = const AnalysisState(stage: Stage.capturing);
    final file = await ref.read(cameraServiceProvider).pickFromGallery();
    if (file == null) {
      state = const AnalysisState(); // cancelled
      return;
    }
    await _process(file);
  });

  /// Live camera flow: the scan screen hands over the captured photo.
  Future<void> analyzeFile(File file) => _run(() => _process(file));

  Future<void> _process(File file) async {
    try {
      state = const AnalysisState(stage: Stage.ocr);
      final ocr = await ref.read(ocrServiceProvider).extractText(file);

      state = state.copyWith(stage: Stage.analyzing, ocrText: ocr.text);
      final result = await ref.read(analysisApiProvider).analyze(ocr.text);

      // Saving history must never block showing the result.
      try {
        await ref
            .read(reportRepositoryProvider)
            .save(result, ocrText: ocr.text, image: file);
      } catch (_) {}

      state = state.copyWith(stage: Stage.done, result: result);
    } finally {
      // Remove the temporary camera/gallery copy (a private copy is kept
      // only if AppConfig.saveImages is true).
      try {
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
  }

  Future<void> _run(Future<void> Function() body) async {
    if (state.isBusy) return;
    try {
      await body();
    } on CaptureException catch (e) {
      _fail(e.message);
    } on OcrException catch (e) {
      _fail(e.message);
    } on ApiException catch (e) {
      _fail(e.message);
    } on TimeoutException {
      _fail('The request took too long. Check your connection and try again.');
    } on SocketException {
      _fail('No internet connection.');
    } catch (_) {
      _fail('Something went wrong. Please try again.');
    }
  }

  void reset() => state = const AnalysisState();

  void _fail(String message) =>
      state = state.copyWith(stage: Stage.error, error: message);
}
