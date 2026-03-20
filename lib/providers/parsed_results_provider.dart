import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/parsed_result.dart';
import '../models/record.dart';
import '../services/pdf_text_service.dart';
import '../services/ocr_service.dart';
import '../services/lab_parser_service.dart';

class ParsedResultsProvider extends ChangeNotifier {
  final _db = DatabaseHelper();

  List<ParsedResult> _recordResults = [];
  bool _loading = false;
  String? _error;

  List<ParsedResult> _allResults = [];
  bool _allLoaded = false;

  List<ParsedResult> get recordResults => _recordResults;
  bool get loading => _loading;
  String? get error => _error;
  List<ParsedResult> get allResults => _allResults;
  bool get allLoaded => _allLoaded;

  /// Results grouped by normalized test name, sorted by date, newest-first key order
  Map<String, List<ParsedResult>> get resultsByTestName {
    final map = <String, List<ParsedResult>>{};
    for (final r in _allResults) {
      map.putIfAbsent(r.testNameNormalized, () => []).add(r);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.testDate.compareTo(b.testDate));
    }
    final sorted = Map.fromEntries(
      map.entries.toList()
        ..sort((a, b) {
          final aDate = a.value.isNotEmpty ? a.value.last.testDate : '';
          final bDate = b.value.isNotEmpty ? b.value.last.testDate : '';
          return bDate.compareTo(aDate);
        }),
    );
    return sorted;
  }

  Future<void> loadForRecord(int recordId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _recordResults = await _db.getParsedResultsForRecord(recordId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadAll() async {
    _allResults = await _db.getAllParsedResults();
    _allLoaded = true;
    notifyListeners();
  }

  Future<void> updateResult(ParsedResult result) async {
    try {
      await _db.updateParsedResult(result);
      final idx = _recordResults.indexWhere((r) => r.id == result.id);
      if (idx != -1) _recordResults[idx] = result;
      final allIdx = _allResults.indexWhere((r) => r.id == result.id);
      if (allIdx != -1) _allResults[allIdx] = result;
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> parseRecord(MedicalRecord record) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final text = StringBuffer();

      for (final path in record.attachments) {
        final lower = path.toLowerCase();
        if (lower.endsWith('.pdf')) {
          final t = await PdfTextService.extractText(path);
          text.write(t);
          text.write('\n');
        } else if (lower.endsWith('.jpg') ||
            lower.endsWith('.jpeg') ||
            lower.endsWith('.png')) {
          final t = await OcrService.extractText(path);
          text.write(t);
          text.write('\n');
        }
      }

      final testDate = record.date.toIso8601String().substring(0, 10);
      final parsed = LabParserService.parse(text.toString(), record.id!, testDate);

      await _db.deleteParsedResultsForRecord(record.id!);
      for (final r in parsed) {
        await _db.insertParsedResult(r);
      }

      _recordResults = await _db.getParsedResultsForRecord(record.id!);
      _allLoaded = false;
      return parsed.isNotEmpty;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
