import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:freshtrack/domain/products/expiration_date_parser.dart';

class ExpirationDateOcrService {
  ExpirationDateOcrService({TextRecognizer? recognizer})
    : _recognizer =
          recognizer ?? TextRecognizer(script: TextRecognitionScript.latin);

  final TextRecognizer _recognizer;

  Future<List<ExpirationDateCandidate>> recognize(String imagePath) async {
    final input = InputImage.fromFilePath(imagePath);
    final recognized = await _recognizer.processImage(input);
    return ExpirationDateParser.parse(recognized.text);
  }

  Future<void> close() => _recognizer.close();
}
