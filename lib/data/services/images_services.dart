import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();

  // Pick image from gallery or camera — compressed inline
  Future<File?> pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 35,
      maxWidth: 200,
      maxHeight: 200,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  // Convert file to base64 string
  Future<String?> convertToBase64(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    if (bytes.length > 100000) return null; // reject if still too large
    return base64Encode(bytes);
  }

  // Convert base64 string back to image bytes for display
  static bool isBase64(String url) {
    return !url.startsWith('http');
  }
}