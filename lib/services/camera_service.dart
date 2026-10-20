import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class CaptureException implements Exception {
  CaptureException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Captures a report image from the native camera or the gallery.
/// Returns null if the user cancels.
class CameraService {
  CameraService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<File?> captureFromCamera() => _pick(ImageSource.camera);

  Future<File?> pickFromGallery() => _pick(ImageSource.gallery);

  Future<File?> _pick(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 90, // keeps text sharp, limits file size
        maxWidth: 2600,
        maxHeight: 2600,
      );
      if (picked == null) return null;
      return File(picked.path);
    } on PlatformException catch (e) {
      final denied = e.code.contains('denied') || e.code.contains('access');
      throw CaptureException(
        denied
            ? 'Camera or photo permission was denied. Please allow it in Settings.'
            : 'Could not open the camera/gallery (${e.code}).',
      );
    }
  }
}
