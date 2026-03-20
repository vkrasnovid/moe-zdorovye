import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'services/notification_service.dart';
import 'services/settings_service.dart';
import 'services/backup_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.initialize();
  await SettingsService.instance.init();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const App());
  // Request permissions and run auto-backup after first frame
  WidgetsBinding.instance.addPostFrameCallback((_) {
    NotificationService.instance.requestPermissions();
    _maybeAutoBackup();
  });
}

void _maybeAutoBackup() {
  final settings = SettingsService.instance;
  if (!settings.shouldRunAutoBackup()) return;
  debugPrint('[main] INFO: auto-backup triggered');
  unawaited(BackupService.instance.exportBackup().then((file) {
    settings.lastAutoBackupAt = DateTime.now();
    debugPrint('[main] INFO: auto-backup complete path=${file.path}');
  }).catchError((e) {
    debugPrint('[main] ERROR: auto-backup failed: $e');
  }));
}

void unawaited(Future<void> future) {}
