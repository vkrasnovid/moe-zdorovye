import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/record.dart';

class RecordsProvider extends ChangeNotifier {
  final _db = DatabaseHelper();

  List<MedicalRecord> _records = [];
  Map<String, int> _categoryCounts = {};
  bool _loading = false;
  String _searchQuery = '';
  RecordCategory? _filterCategory;

  List<MedicalRecord> get records => _filteredRecords;
  Map<String, int> get categoryCounts => _categoryCounts;
  bool get loading => _loading;
  String get searchQuery => _searchQuery;
  RecordCategory? get filterCategory => _filterCategory;

  List<MedicalRecord> get _filteredRecords {
    var result = List<MedicalRecord>.from(_records);
    if (_filterCategory != null) {
      result = result.where((r) => r.category == _filterCategory).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((r) {
        return r.title.toLowerCase().contains(q) ||
            (r.notes?.toLowerCase().contains(q) ?? false);
      }).toList();
    }
    return result;
  }

  List<MedicalRecord> get recentRecords => _records.take(5).toList();

  int countForCategory(RecordCategory cat) =>
      _categoryCounts[cat.name] ?? 0;

  Future<void> loadRecords() async {
    _loading = true;
    notifyListeners();
    _records = await _db.getAllRecords();
    _categoryCounts = await _db.getCategoryCounts();
    _loading = false;
    notifyListeners();
  }

  Future<void> addRecord(MedicalRecord record) async {
    final id = await _db.insertRecord(record);
    final saved = record.copyWith(id: id);
    _records.insert(0, saved);
    _categoryCounts[record.category.name] =
        (_categoryCounts[record.category.name] ?? 0) + 1;
    notifyListeners();
  }

  Future<void> updateRecord(MedicalRecord record) async {
    await _db.updateRecord(record);
    final idx = _records.indexWhere((r) => r.id == record.id);
    if (idx != -1) _records[idx] = record;
    notifyListeners();
  }

  Future<void> deleteRecord(MedicalRecord record) async {
    await _db.deleteRecord(record.id!);
    _records.removeWhere((r) => r.id == record.id);
    final count = _categoryCounts[record.category.name] ?? 1;
    _categoryCounts[record.category.name] = (count - 1).clamp(0, 999);
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilterCategory(RecordCategory? cat) {
    _filterCategory = cat;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _filterCategory = null;
    notifyListeners();
  }
}
