import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:pdfx/pdfx.dart' as pdfxpkg;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Extracts text from a PDF file.
///
/// First tries direct text extraction via Syncfusion Flutter PDF (fast, works
/// for digital/text-based PDFs). If the result is too short, falls back to
/// rendering each page as a PNG with pdfx and running ML Kit OCR on it —
/// which handles scanned/image-based PDFs.
class PdfTextService {
  /// Minimum characters of extracted text before we consider the PDF
  /// text-based (and skip OCR).
  static const int _minTextLength = 150;

  static Future<String> extractText(String filePath) async {
    final direct = await _extractDirect(filePath);
    if (direct.trim().length >= _minTextLength) return direct;
    final ocr = await _extractOcr(filePath);
    return ocr.isNotEmpty ? ocr : direct;
  }

  // ── Direct text extraction (digital PDFs) ────────────────────────────────

  static Future<String> _extractDirect(String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final document = PdfDocument(inputBytes: bytes);
      final extractor = PdfTextExtractor(document);
      final text = extractor.extractText();
      document.dispose();
      return text;
    } catch (_) {
      return '';
    }
  }

  // ── OCR fallback (scanned PDFs) ──────────────────────────────────────────

  static Future<String> _extractOcr(String filePath) async {
    final buffer = StringBuffer();
    pdfxpkg.PdfDocument? document;
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      document = await pdfxpkg.PdfDocument.openFile(filePath);
      final tempDir = await getTemporaryDirectory();

      for (int i = 1; i <= document.pagesCount && i <= 5; i++) {
        File? tempFile;
        try {
          final page = await document.getPage(i);
          final image = await page.render(
            width: page.width * 2,
            height: page.height * 2,
            format: pdfxpkg.PdfPageImageFormat.png,
            backgroundColor: '#FFFFFF',
          );
          await page.close();

          if (image?.bytes != null) {
            tempFile = File('${tempDir.path}/pdf_ocr_page_$i.png');
            await tempFile.writeAsBytes(image!.bytes);
            final input = InputImage.fromFilePath(tempFile.path);
            final result = await recognizer.processImage(input);
            buffer.writeln(result.text);
          }
        } catch (_) {
          // Skip pages that cannot be rendered or OCR'd
        } finally {
          try {
            await tempFile?.delete();
          } catch (_) {}
        }
      }
    } catch (_) {
      // OCR pipeline unavailable on this platform/device
    } finally {
      await recognizer.close();
      try {
        await document?.close();
      } catch (_) {}
    }

    return buffer.toString();
  }
}
