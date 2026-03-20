import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  static SettingsService get instance => _instance;

  static const _keyAutoBackupEnabled = 'auto_backup_enabled';
  static const _keyAutoBackupFrequency = 'auto_backup_frequency';
  static const _keyLastAutoBackupAt = 'last_auto_backup_at';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    debugPrint('[SettingsService] DEBUG: init complete');
  }

  SharedPreferences get _p {
    if (_prefs == null) throw StateError('SettingsService not initialized — call init() first');
    return _prefs!;
  }

  bool get autoBackupEnabled => _p.getBool(_keyAutoBackupEnabled) ?? false;
  set autoBackupEnabled(bool value) {
    debugPrint('[SettingsService] DEBUG: set autoBackupEnabled=$value');
    _p.setBool(_keyAutoBackupEnabled, value);
  }

  /// 'daily' or 'weekly'
  String get autoBackupFrequency => _p.getString(_keyAutoBackupFrequency) ?? 'weekly';
  set autoBackupFrequency(String value) {
    debugPrint('[SettingsService] DEBUG: set autoBackupFrequency=$value');
    _p.setString(_keyAutoBackupFrequency, value);
  }

  DateTime? get lastAutoBackupAt {
    final ms = _p.getInt(_keyLastAutoBackupAt);
    return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  set lastAutoBackupAt(DateTime? value) {
    debugPrint('[SettingsService] DEBUG: set lastAutoBackupAt=$value');
    if (value == null) {
      _p.remove(_keyLastAutoBackupAt);
    } else {
      _p.setInt(_keyLastAutoBackupAt, value.millisecondsSinceEpoch);
    }
  }

  bool shouldRunAutoBackup() {
    if (!autoBackupEnabled) {
      debugPrint('[SettingsService] DEBUG: auto-backup skipped — disabled');
      return false;
    }
    final last = lastAutoBackupAt;
    if (last == null) return true;
    final now = DateTime.now();
    final diff = now.difference(last);
    final threshold = autoBackupFrequency == 'daily'
        ? const Duration(hours: 23)
        : const Duration(days: 6, hours: 23);
    if (diff < threshold) {
      debugPrint('[SettingsService] DEBUG: auto-backup skipped — too soon (last=$last diff=${diff.inHours}h threshold=${threshold.inHours}h)');
      return false;
    }
    return true;
  }
}
