class AppConfig {
  /// flutter run --dart-define=WORKER_URL=https://report-analyzer.&lt;you&gt;.workers.dev/analyze
  static const workerUrl = String.fromEnvironment(
    'WORKER_URL',
    defaultValue:
        'https://tibbicare-worker.syedhasnatali785.workers.dev/analyze',
  );

  /// Optional shared key (MVP-only guard; replace with real auth later).
  static const appKey = String.fromEnvironment('APP_KEY', defaultValue: '');

  /// Keep a copy of the scanned image in the app's private storage.
  /// Off by default: reports are sensitive, the analysis text is enough for history.
  static const saveImages = bool.fromEnvironment(
    'SAVE_IMAGES',
    defaultValue: false,
  );

  /// Shows live sharpness/brightness numbers on the scan screen (for tuning).
  static const scanDebug = bool.fromEnvironment(
    'SCAN_DEBUG',
    defaultValue: false,
  );
}
