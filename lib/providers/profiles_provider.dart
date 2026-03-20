import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/profile.dart';

class ProfilesProvider extends ChangeNotifier {
  final _db = DatabaseHelper();

  List<Profile> _profiles = [];
  Profile? _activeProfile;

  List<Profile> get profiles => List.unmodifiable(_profiles);
  Profile? get activeProfile => _activeProfile;
  int? get activeProfileId => _activeProfile?.id;

  Future<void> loadProfiles() async {
    debugPrint('[ProfilesProvider] DEBUG: loadProfiles entry');
    try {
      _profiles = await _db.getProfiles();
      debugPrint('[ProfilesProvider] DEBUG: loaded ${_profiles.length} profiles');
      if (_activeProfile == null) {
        _activeProfile = _profiles.firstWhere(
          (p) => p.isDefault,
          orElse: () => _profiles.first,
        );
        debugPrint('[ProfilesProvider] INFO: initial active profile set: id=${_activeProfile?.id} name=${_activeProfile?.name}');
      } else {
        // Refresh active profile from loaded list
        final refreshed = _profiles.where((p) => p.id == _activeProfile!.id);
        if (refreshed.isNotEmpty) {
          _activeProfile = refreshed.first;
        }
      }
      notifyListeners();
    } catch (e, st) {
      debugPrint('[ProfilesProvider] ERROR: loadProfiles failed: $e\n$st');
      rethrow;
    }
  }

  void setActiveProfile(int id) {
    debugPrint('[ProfilesProvider] INFO: setActiveProfile id=$id');
    final profile = _profiles.firstWhere((p) => p.id == id, orElse: () => _profiles.first);
    _activeProfile = profile;
    debugPrint('[ProfilesProvider] DEBUG: active profile switched to id=${profile.id} name=${profile.name}');
    notifyListeners();
  }

  Future<void> createProfile(String name, Color color) async {
    debugPrint('[ProfilesProvider] DEBUG: createProfile entry name=$name color=${color.value}');
    try {
      final profile = Profile(
        name: name,
        avatarColor: color.value,
        isDefault: false,
      );
      await _db.insertProfile(profile);
      debugPrint('[ProfilesProvider] DEBUG: createProfile inserted, reloading');
      await loadProfiles();
    } catch (e, st) {
      debugPrint('[ProfilesProvider] ERROR: createProfile failed: $e\n$st');
      rethrow;
    }
  }

  Future<void> updateProfile(Profile p) async {
    debugPrint('[ProfilesProvider] DEBUG: updateProfile entry id=${p.id} name=${p.name}');
    try {
      await _db.updateProfile(p);
      debugPrint('[ProfilesProvider] DEBUG: updateProfile updated, reloading');
      await loadProfiles();
    } catch (e, st) {
      debugPrint('[ProfilesProvider] ERROR: updateProfile failed: $e\n$st');
      rethrow;
    }
  }

  Future<bool> deleteProfile(int id) async {
    debugPrint('[ProfilesProvider] DEBUG: deleteProfile entry id=$id');
    if (_profiles.length <= 1) {
      debugPrint('[ProfilesProvider] WARN: deleteProfile blocked — cannot delete last profile');
      return false;
    }
    try {
      final result = await _db.deleteProfile(id);
      if (result == 0) {
        debugPrint('[ProfilesProvider] WARN: deleteProfile returned 0 rows — blocked by DB guard');
        return false;
      }
      // If active profile was deleted, switch to first remaining
      if (_activeProfile?.id == id) {
        final remaining = _profiles.where((p) => p.id != id).toList();
        if (remaining.isNotEmpty) {
          _activeProfile = remaining.first;
          debugPrint('[ProfilesProvider] INFO: active profile auto-switched to id=${_activeProfile?.id} name=${_activeProfile?.name}');
        }
      }
      await loadProfiles();
      debugPrint('[ProfilesProvider] DEBUG: deleteProfile exit success');
      return true;
    } catch (e, st) {
      debugPrint('[ProfilesProvider] ERROR: deleteProfile failed: $e\n$st');
      rethrow;
    }
  }
}
