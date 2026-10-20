import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrException implements Exception {
  OcrException(this.message);
  final String message;
  @override
  String toString() => message;
}

class OcrResult {
  const OcrResult({required this.text, required this.lineCount});
  final String text;
  final int lineCount;
}

/// On-device OCR (Google ML Kit). The image never leaves the phone;
/// only the extracted text is sent onward.
class OcrService {
  OcrService()
    : _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  final TextRecognizer _recognizer;

  Future<OcrResult> extractText(File image) async {
    final input = InputImage.fromFilePath(image.path);
    final recognized = await _recognizer.processImage(input);

    final lines = <TextLine>[
      for (final block in recognized.blocks) ...block.lines,
    ];
    if (lines.isEmpty) {
      throw OcrException(
        'No text was found. Try again with better light and the report filling the frame.',
      );
    }

    final text = _rebuildRows(lines);
    if (text.trim().length < 20) {
      throw OcrException(
        'Too little text was detected. Please retake the photo.',
      );
    }
    return OcrResult(text: text, lineCount: lines.length);
  }

  /// Lab reports are tables. ML Kit returns text in blocks, which can split
  /// a row ("Hemoglobin  10.2  g/dL  12-15.5") into separate pieces.
  /// This groups lines that sit on the same visual row and joins them with " | ".
  String _rebuildRows(List<TextLine> lines) {
    final sorted = [...lines]
      ..sort(
        (a, b) => a.boundingBox.center.dy.compareTo(b.boundingBox.center.dy),
      );

    final rows = <List<TextLine>>[];
    for (final line in sorted) {
      if (rows.isNotEmpty) {
        final last = rows.last;
        final avgCenterY =
            last.map((l) => l.boundingBox.center.dy).reduce((a, b) => a + b) /
            last.length;
        final avgHeight =
            last.map((l) => l.boundingBox.height).reduce((a, b) => a + b) /
            last.length;
        if ((line.boundingBox.center.dy - avgCenterY).abs() < avgHeight * 0.6) {
          last.add(line);
          continue;
        }
      }
      rows.add([line]);
    }

    return rows
        .map((row) {
          row.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
          return row.map((l) => l.text.trim()).join('  |  ');
        })
        .join('\n');
  }

  Future<void> dispose() => _recognizer.close();
}
