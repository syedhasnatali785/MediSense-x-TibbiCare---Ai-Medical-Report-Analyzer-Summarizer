import 'dart:io';

import 'package:aimedicalreportanalyzer/constants/app_config.dart';
import 'package:aimedicalreportanalyzer/providers/scan_quality.dart';
import 'package:aimedicalreportanalyzer/services/live_scanner_service.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Full-screen live camera. Pops with the captured [File], or null if closed.
class LiveScanScreen extends StatefulWidget {
  const LiveScanScreen({super.key});

  @override
  State<LiveScanScreen> createState() => _LiveScanScreenState();
}

class _LiveScanScreenState extends State<LiveScanScreen>
    with WidgetsBindingObserver {
  late LiveScanner _scanner;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _startScanner();
  }

  void _startScanner() {
    _scanner = LiveScanner(onCaptured: _onCaptured)..init();
  }

  void _onCaptured(File file) {
    if (mounted) Navigator.of(context).pop(file);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _scanner.dispose();
    } else if (state == AppLifecycleState.resumed) {
      setState(_startScanner);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _scanner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: ValueListenableBuilder<ScanUiState>(
        valueListenable: _scanner.ui,
        builder: (context, s, _) {
          if (s.error != null) return _ErrorView(message: s.error!);

          final c = _scanner.controller;
          final showPreview =
              s.cameraReady && c != null && c.value.isInitialized;
          final good = s.hint.isGood;
          final color = good ? Colors.greenAccent : Colors.amberAccent;

          return Stack(
            fit: StackFit.expand,
            children: [
              if (showPreview)
                _Preview(
                  controller: c,
                  scanner: _scanner,
                  boxes: s.boxes,
                  color: color,
                )
              else
                const Center(child: CircularProgressIndicator()),
              IgnorePointer(child: CustomPaint(painter: _CornerGuide(color))),
              _TopBar(state: s, scanner: _scanner),
              _BottomPanel(state: s, scanner: _scanner, color: color),
            ],
          );
        },
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({
    required this.controller,
    required this.scanner,
    required this.boxes,
    required this.color,
  });

  final CameraController controller;
  final LiveScanner scanner;
  final List<Rect> boxes;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // previewSize is reported in landscape; the screen is portrait.
    final ps = controller.value.previewSize!;
    return LayoutBuilder(
      builder: (context, cons) => GestureDetector(
        onTapUp: (d) => scanner.focusAt(
          Offset(
            d.localPosition.dx / cons.maxWidth,
            d.localPosition.dy / cons.maxHeight,
          ),
        ),
        child: ClipRect(
          child: SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: ps.height,
                height: ps.width,
                child: Stack(
                  children: [
                    CameraPreview(controller),
                    Positioned.fill(
                      child: CustomPaint(painter: _BoxesPainter(boxes, color)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Draws the live text-detection boxes (coordinates are normalized 0..1).
class _BoxesPainter extends CustomPainter {
  _BoxesPainter(this.boxes, this.color);
  final List<Rect> boxes;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.004
      ..color = color.withAlpha(200);
    for (final b in boxes) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(
            b.left * size.width,
            b.top * size.height,
            b.right * size.width,
            b.bottom * size.height,
          ),
          Radius.circular(size.width * 0.006),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BoxesPainter old) =>
      old.boxes != boxes || old.color != color;
}

class _CornerGuide extends CustomPainter {
  _CornerGuide(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = color;
    final r = Rect.fromLTRB(
      size.width * 0.06,
      size.height * 0.14,
      size.width * 0.94,
      size.height * 0.76,
    );
    const len = 34.0;
    void corner(Offset o, double dx, double dy) {
      canvas.drawLine(o, o + Offset(dx * len, 0), p);
      canvas.drawLine(o, o + Offset(0, dy * len), p);
    }

    corner(r.topLeft, 1, 1);
    corner(r.topRight, -1, 1);
    corner(r.bottomLeft, 1, -1);
    corner(r.bottomRight, -1, -1);
  }

  @override
  bool shouldRepaint(_CornerGuide old) => old.color != color;
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.state, required this.scanner});
  final ScanUiState state;
  final LiveScanner scanner;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                color: Colors.white,
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const Spacer(),
              IconButton(
                color: Colors.white,
                tooltip: 'Torch',
                icon: Icon(state.torchOn ? Icons.flash_on : Icons.flash_off),
                onPressed: scanner.toggleTorch,
              ),
              const SizedBox(width: 4),
              FilterChip(
                label: const Text('Auto'),
                avatar: const Icon(Icons.auto_awesome, size: 16),
                selected: state.autoCapture,
                onSelected: scanner.setAutoCapture,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomPanel extends StatelessWidget {
  const _BottomPanel({
    required this.state,
    required this.scanner,
    required this.color,
  });

  final ScanUiState state;
  final LiveScanner scanner;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (AppConfig.scanDebug)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'sharp ${state.sharpness.toStringAsFixed(0)}   '
                    'light ${state.brightness.toStringAsFixed(0)}   '
                    'lines ${state.boxes.length}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(170),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(state.hint.icon, color: color, size: 20),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            state.hint.message,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    if (state.autoCapture && state.progress > 0) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: state.progress,
                          minHeight: 6,
                          color: color,
                          backgroundColor: Colors.white24,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Manual shutter, always available as a fallback.
              GestureDetector(
                onTap: state.cameraReady ? scanner.capture : null,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  padding: const EdgeInsets.all(6),
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.no_photography_outlined,
                size: 64,
                color: Colors.white70,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
