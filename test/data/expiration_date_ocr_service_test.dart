import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freshtrack/data/ocr/expiration_date_image_preprocessor.dart';
import 'package:freshtrack/data/ocr/expiration_date_ocr_service.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:mocktail/mocktail.dart';

class _Recognizer extends Mock implements TextRecognizer {}

class _Preprocessor extends ExpirationDateImagePreprocessor {
  const _Preprocessor(this.output);
  final String output;
  @override
  Future<String> cropDateBand(String imagePath) async => output;
}

void main() {
  setUpAll(() {
    registerFallbackValue(InputImage.fromFilePath('unused.jpg'));
  });
  for (final fails in [false, true]) {
    test('elimina il ritaglio OCR anche con errore=$fails', () async {
      final root = await Directory.systemTemp.createTemp('freshtrack_ocr_');
      addTearDown(() => root.delete(recursive: true));
      final original = File('${root.path}/source.jpg');
      final cropped = File('${root.path}/source.jpg_dateband.jpg');
      await original.writeAsBytes([1]);
      await cropped.writeAsBytes([2]);
      final recognizer = _Recognizer();
      when(() => recognizer.processImage(any())).thenAnswer((_) async {
        if (fails) throw StateError('OCR failure');
        return RecognizedText(text: '25/10/2026', blocks: []);
      });
      final service = ExpirationDateOcrService(
        recognizer: recognizer,
        preprocessor: _Preprocessor(cropped.path),
      );
      if (fails) {
        await expectLater(service.recognize(original.path), throwsStateError);
      } else {
        expect(await service.recognize(original.path), hasLength(1));
      }
      expect(await cropped.exists(), isFalse);
      expect(await original.exists(), isTrue);
    });
  }
}
