import 'dart:math' as math;

import 'package:camera/camera.dart';

class FrameStats {
  const FrameStats({required this.sharpness, required this.brightness});

  /// Edge strength of the strongest edges in the frame. Sharp text has strong
  /// stroke edges; blur flattens them. Roughly 0-400+, tune in ScanTuning.
  final double sharpness;

  /// Mean luminance, 0-255.
  final double brightness;
}

/// Cheap per-frame quality metrics computed straight from the camera buffer
/// (Y plane on Android NV21, BGRA on iOS). Samples a sparse grid of the
/// central region, so it costs a few milliseconds.
FrameStats? computeFrameStats(CameraImage image, {int samplesAcross = 170}) {
  if (image.planes.isEmpty) return null;

  final plane = image.planes.first;
  final bytes = plane.bytes;
  final stride = plane.bytesPerRow;
  final w = image.width;
  final h = image.height;
  final isBgra = image.format.group == ImageFormatGroup.bgra8888;
  final bpp = isBgra ? 4 : 1;

  if (w < 16 || h < 16) return null;

  int lum(int x, int y) {
    final i = y * stride + x * bpp;
    if (isBgra) {
      return (bytes[i] * 29 + bytes[i + 1] * 150 + bytes[i + 2] * 77) >> 8;
    }
    return bytes[i];
  }

  final x0 = math.max(2, (w * 0.15).round());
  final x1 = math.min(w - 3, (w * 0.85).round());
  final y0 = math.max(2, (h * 0.15).round());
  final y1 = math.min(h - 3, (h * 0.85).round());
  final step = math.max(1, ((x1 - x0) / samplesAcross).floor());

  // Histogram of |laplacian| (max 4*255 = 1020).
  final hist = List<int>.filled(1021, 0);
  var n = 0;
  var sumL = 0;

  for (var y = y0; y < y1; y += step) {
    for (var x = x0; x < x1; x += step) {
      final c = lum(x, y);
      final lap =
          (4 * c - lum(x - 1, y) - lum(x + 1, y) - lum(x, y - 1) - lum(x, y + 1))
              .abs();
      hist[lap > 1020 ? 1020 : lap]++;
      sumL += c;
      n++;
    }
  }
  if (n == 0) return null;

  // Mean of the strongest 5% of edge responses: independent of how much of
  // the frame is blank paper.
  final topCount = math.max(1, (n * 0.05).round());
  var taken = 0;
  var topSum = 0;
  for (var v = 1020; v >= 0 && taken < topCount; v--) {
    final take = math.min(hist[v], topCount - taken);
    topSum += take * v;
    taken += take;
  }

  return FrameStats(
    sharpness: topSum / taken,
    brightness: sumL / n,
  );
}