import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:freshtrack/data/ocr/expiration_date_image_preprocessor.dart';
import 'package:freshtrack/domain/products/expiration_date_parser.dart';

class ExpirationDateOcrService {
  ExpirationDateOcrService({
    TextRecognizer? recognizer,
    ExpirationDateImagePreprocessor? preprocessor,
  }) : _recognizer =
           recognizer ?? TextRecognizer(script: TextRecognitionScript.latin),
       _preprocessor = preprocessor ?? const ExpirationDateImagePreprocessor();

  final TextRecognizer _recognizer;
  final ExpirationDateImagePreprocessor _preprocessor;

  Future<List<ExpirationDateCandidate>> recognize(String imagePath) async {
    final croppedPath = await _preprocessor.cropDateBand(imagePath);
    try {
      final cropped = await _recognizePath(croppedPath);
      if (cropped.isNotEmpty) return cropped;
      if (croppedPath == imagePath) return const [];
      return await _recognizePath(imagePath);
    } finally {
      if (croppedPath != imagePath) {
        try {
          await File(croppedPath).delete();
        } on FileSystemException {
          // Cleanup must not hide recognition errors or a successful result.
        }
      }
    }
  }

  Future<List<ExpirationDateCandidate>> _recognizePath(String path) async {
    final input = InputImage.fromFilePath(path);
    final recognized = await _recognizer.processImage(input);
    return ExpirationDateParser.parse(recognized.text);
  }

  Future<void> close() => _recognizer.close();
}
