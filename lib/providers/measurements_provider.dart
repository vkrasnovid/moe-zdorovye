import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/measurement.dart';

class MeasurementsProvider extends ChangeNotifier {
  final _db = DatabaseHelper();

  final Map<MeasurementType, List<Measurement>> _byType = {};
  bool _loading = false;

  bool get loading => _loading;

  List<Measurement> getForType(MeasurementType type) =>
      List.unmodifiable(_byType[type] ?? []);

  Future<void> loadForType(MeasurementType type) async {
    _loading = true;
    notifyListeners();
    _byType[type] = await _db.getMeasurementsByType(type.name);
    _loading = false;
    notifyListeners();
  }

  Future<void> addMeasurement(Measurement m) async {
    final id = await _db.insertMeasurement(m);
    final saved = m.copyWith(id: id);
    _byType[m.type] = [saved, ...(_byType[m.type] ?? [])];
    notifyListeners();
  }

  Future<void> updateMeasurement(Measurement m) async {
    await _db.updateMeasurement(m);
    final list = _byType[m.type] ?? [];
    final idx = list.indexWhere((x) => x.id == m.id);
    if (idx != -1) list[idx] = m;
    notifyListeners();
  }

  Future<void> deleteMeasurement(Measurement m) async {
    await _db.deleteMeasurement(m.id!);
    _byType[m.type]?.removeWhere((x) => x.id == m.id);
    notifyListeners();
  }
}
