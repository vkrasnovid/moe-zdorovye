import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  static Future<String> extractText(String filePath) async {
    try {
      final inputImage = InputImage.fromFilePath(filePath);
      final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final result = await recognizer.processImage(inputImage);
      await recognizer.close();
      return result.text;
    } catch (e) {
      return '';
    }
  }
}
