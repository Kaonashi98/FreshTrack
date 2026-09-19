import 'dart:io';

import 'package:image/image.dart' as img;

class ExpirationDateImagePreprocessor {
  const ExpirationDateImagePreprocessor();

  /// Crops a horizontal band where printed dates usually sit, then falls back
  /// to the original path if decoding or writing fails.
  Future<String> cropDateBand(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null || decoded.width < 32 || decoded.height < 32) {
        return imagePath;
      }
      final left = (decoded.width * 0.08).round();
      final top = (decoded.height * 0.28).round();
      final width = (decoded.width * 0.84).round().clamp(
        1,
        decoded.width - left,
      );
      final height = (decoded.height * 0.44).round().clamp(
        1,
        decoded.height - top,
      );
      final cropped = img.copyCrop(
        decoded,
        x: left,
        y: top,
        width: width,
        height: height,
      );
      final output = File('${imagePath}_dateband.jpg');
      await output.writeAsBytes(img.encodeJpg(cropped, quality: 92));
      return output.path;
    } catch (_) {
      return imagePath;
    }
  }
}
