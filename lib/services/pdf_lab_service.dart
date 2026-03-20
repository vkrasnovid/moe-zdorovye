import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sfpdf;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:pdfx/pdfx.dart' as pdfxpkg;
import '../models/parsed_result.dart';
import 'lab_normalizer.dart';
import 'lab_text_parser.dart';

/// Orchestrates PDF text extraction (via Syncfusion) with an OCR fallback
/// (via google_mlkit_text_recognition + pdfx for page rendering), then
/// delegates parsing to [LabTextParser].
class PdfLabService {
  /// Minimum extracted-text length before we consider it "text-based".
  static const int _minTextLength = 150;

  /// Parse a PDF file and return structured lab results linked to [recordId].
  static Future<List<ParsedResult>> parseLabPdf({
    required String pdfPath,
    required int recordId,
    required DateTime recordDate,
  }) async {
    final text = await _extractText(pdfPath);
    final labResults = LabTextParser.parseText(text);
    final dateStr = recordDate.toIso8601String().substring(0, 10);
    final now = DateTime.now();

    return labResults.map((r) {
      final normalized = LabNormalizer.normalize(r.testName);
      return ParsedResult(
        recordId: recordId,
        testName: r.testName,
        testNameNormalized: normalized,
        value: r.value,
        unit: r.unit,
        refMin: r.refMin,
        refMax: r.refMax,
        flag: r.flag,
        testDate: dateStr,
        parsedAt: now,
      );
    }).toList();
  }

  // ── Text extraction pipeline ──────────────────────────────────────────────

  static Future<String> _extractText(String pdfPath) async {
    final direct = await _extractTextDirect(pdfPath);
    if (direct.trim().length >= _minTextLength) return direct;
    // Scanned PDF — fall back to OCR
    final ocr = await _extractTextOcr(pdfPath);
    return ocr.isNotEmpty ? ocr : direct;
  }

  /// Extract text using Syncfusion Flutter PDF (works for digital/text PDFs).
  static Future<String> _extractTextDirect(String pdfPath) async {
    try {
      final bytes = await File(pdfPath).readAsBytes();
      final document = sfpdf.PdfDocument(inputBytes: bytes);
      final extractor = sfpdf.PdfTextExtractor(document);
      final buffer = StringBuffer();
      for (int i = 0; i < document.pages.count; i++) {
        final pageText =
            extractor.extractText(startPageIndex: i, endPageIndex: i);
        buffer.writeln(pageText);
      }
      document.dispose();
      return buffer.toString();
    } catch (_) {
      return '';
    }
  }

  /// Render each PDF page to a PNG image using pdfx, then OCR with ML Kit.
  static Future<String> _extractTextOcr(String pdfPath) async {
    final buffer = StringBuffer();
    pdfxpkg.PdfDocument? document;
    final textRecognizer =
        TextRecognizer(script: TextRecognitionScript.latin);

    try {
      document = await pdfxpkg.PdfDocument.openFile(pdfPath);
      final pageCount = document.pagesCount;
      final tempDir = await getTemporaryDirectory();

      // Process at most 5 pages to keep performance acceptable
      for (int i = 1; i <= pageCount && i <= 5; i++) {
        File? tempFile;
        try {
          final page = await document.getPage(i);
          final pageImage = await page.render(
            width: page.width * 2,
            height: page.height * 2,
            format: pdfxpkg.PdfPageImageFormat.png,
            backgroundColor: '#FFFFFF',
          );
          await page.close();

          if (pageImage?.bytes != null) {
            tempFile =
                File('${tempDir.path}/lab_ocr_page_$i.png');
            await tempFile.writeAsBytes(pageImage!.bytes);

            final inputImage =
                InputImage.fromFilePath(tempFile.path);
            final recognized =
                await textRecognizer.processImage(inputImage);
            buffer.writeln(recognized.text);
          }
        } catch (_) {
          // Skip pages that fail to render or OCR
        } finally {
          try {
            await tempFile?.delete();
          } catch (_) {}
        }
      }
    } catch (_) {
      // OCR pipeline unavailable on this platform/device
    } finally {
      await textRecognizer.close();
      try {
        await document?.close();
      } catch (_) {}
    }

    return buffer.toString();
  }
}
