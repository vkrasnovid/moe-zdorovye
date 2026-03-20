import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/reminder.dart';
import '../services/notification_service.dart';

class RemindersProvider extends ChangeNotifier {
  final _db = DatabaseHelper();

  List<Reminder> _reminders = [];
  bool _loading = false;
  String? _error;

  List<Reminder> get reminders => List.unmodifiable(_reminders);
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadReminders(int profileId) async {
    debugPrint('[RemindersProvider] DEBUG: loadReminders entry profileId=$profileId');
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _reminders = await _db.getReminders(profileId: profileId);
      debugPrint('[RemindersProvider] DEBUG: loadReminders exit count=${_reminders.length}');
    } catch (e, st) {
      _error = e.toString();
      debugPrint('[RemindersProvider] ERROR: loadReminders failed: $e\n$st');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> addReminder(Reminder r) async {
    debugPrint('[RemindersProvider] INFO: addReminder title=${r.title} type=${r.type.name}');
    try {
      final id = await _db.insertReminder(r);
      final saved = r.copyWith(id: id);
      try {
        await NotificationService.instance.scheduleReminder(saved);
      } catch (e) {
        debugPrint('[RemindersProvider] WARN: scheduleReminder failed for id=$id: $e — reminder saved but notification may not fire');
      }
      _reminders = await _db.getReminders(profileId: r.profileId);
      notifyListeners();
    } catch (e, st) {
      debugPrint('[RemindersProvider] ERROR: addReminder failed: $e\n$st');
      rethrow;
    }
  }

  Future<void> updateReminder(Reminder r) async {
    debugPrint('[RemindersProvider] DEBUG: updateReminder id=${r.id} title=${r.title}');
    try {
      await _db.updateReminder(r);
      if (r.id != null) {
        await NotificationService.instance.cancelReminder(r.id!);
        if (r.isActive) {
          try {
            await NotificationService.instance.scheduleReminder(r);
          } catch (e) {
            debugPrint('[RemindersProvider] WARN: reschedule failed for id=${r.id}: $e');
          }
        }
      }
      _reminders = await _db.getReminders(profileId: r.profileId);
      notifyListeners();
    } catch (e, st) {
      debugPrint('[RemindersProvider] ERROR: updateReminder failed: $e\n$st');
      rethrow;
    }
  }

  Future<void> toggleActive(int id) async {
    debugPrint('[RemindersProvider] DEBUG: toggleActive id=$id');
    final reminder = _reminders.firstWhere((r) => r.id == id);
    final updated = reminder.copyWith(isActive: !reminder.isActive);
    await updateReminder(updated);
  }

  Future<void> deleteReminder(int id) async {
    debugPrint('[RemindersProvider] INFO: deleteReminder id=$id');
    final reminder = _reminders.firstWhere((r) => r.id == id);
    try {
      await _db.deleteReminder(id);
      await NotificationService.instance.cancelReminder(id);
      _reminders = await _db.getReminders(profileId: reminder.profileId);
      notifyListeners();
    } catch (e, st) {
      debugPrint('[RemindersProvider] ERROR: deleteReminder failed: $e\n$st');
      rethrow;
    }
  }

  Future<void> rescheduleAll(int profileId) async {
    debugPrint('[RemindersProvider] DEBUG: rescheduleAll profileId=$profileId');
    final activeReminders = await _db.getReminders(profileId: profileId, activeOnly: true);
    for (final r in activeReminders) {
      try {
        await NotificationService.instance.scheduleReminder(r);
      } catch (e) {
        debugPrint('[RemindersProvider] WARN: rescheduleAll — failed for id=${r.id}: $e');
      }
    }
    debugPrint('[RemindersProvider] DEBUG: rescheduleAll completed count=${activeReminders.length}');
  }
}
