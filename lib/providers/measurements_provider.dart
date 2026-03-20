import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/measurement.dart';

class MeasurementsProvider extends ChangeNotifier {
  final _db = DatabaseHelper();

  final Map<MeasurementType, List<Measurement>> _byType = {};
  bool _loading = false;
  int? _profileId;

  bool get loading => _loading;

  List<Measurement> getForType(MeasurementType type) =>
      List.unmodifiable(_byType[type] ?? []);

  Future<void> loadForType(MeasurementType type, {int? profileId}) async {
    _profileId = profileId ?? _profileId;
    debugPrint('[MeasurementsProvider] DEBUG: loadForType entry type=${type.name} profileId=$_profileId');
    _loading = true;
    notifyListeners();
    try {
      _byType[type] = await _db.getMeasurementsByType(type.name, profileId: _profileId);
      debugPrint('[MeasurementsProvider] DEBUG: loadForType exit count=${_byType[type]?.length}');
    } catch (_) {
      // leave existing data intact
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> reloadAllForProfile(int? profileId) async {
    _profileId = profileId;
    debugPrint('[MeasurementsProvider] DEBUG: reloadAllForProfile profileId=$profileId types=${_byType.keys.map((t) => t.name).join(",")}');
    final types = List<MeasurementType>.from(_byType.keys);
    for (final type in types) {
      await loadForType(type, profileId: _profileId);
    }
  }

  Future<void> addMeasurement(Measurement m) async {
    final withProfile = m.copyWith(profileId: _profileId);
    debugPrint('[MeasurementsProvider] DEBUG: addMeasurement type=${m.type.name} profileId=$_profileId');
    try {
      final id = await _db.insertMeasurement(withProfile);
      final saved = withProfile.copyWith(id: id);
      _byType[m.type] = [saved, ...(_byType[m.type] ?? [])];
      notifyListeners();
    } catch (_) {
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateMeasurement(Measurement m) async {
    final withProfile = m.copyWith(profileId: _profileId);
    debugPrint('[MeasurementsProvider] DEBUG: updateMeasurement id=${m.id} type=${m.type.name}');
    try {
      await _db.updateMeasurement(withProfile);
      final list = _byType[m.type] ?? [];
      final idx = list.indexWhere((x) => x.id == m.id);
      if (idx != -1) list[idx] = withProfile;
      notifyListeners();
    } catch (_) {
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteMeasurement(Measurement m) async {
    if (m.id == null) return;
    debugPrint('[MeasurementsProvider] DEBUG: deleteMeasurement id=${m.id} type=${m.type.name}');
    try {
      await _db.deleteMeasurement(m.id!);
      _byType[m.type]?.removeWhere((x) => x.id == m.id);
      notifyListeners();
    } catch (_) {
      notifyListeners();
      rethrow;
    }
  }
}
