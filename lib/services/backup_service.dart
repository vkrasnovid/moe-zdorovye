import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  static BackupService get instance => _instance;

  static const _dbFileName = 'moe_zdorovye.db';
  static const _attachmentsDirName = 'attachments';

  /// Exports DB + attachments into a timestamped zip file and returns it.
  Future<File> exportBackup() async {
    debugPrint('[BackupService] INFO: exportBackup start');
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dbDir = await getDatabasesPath();
      final dbFile = File(p.join(dbDir, _dbFileName));

      // Flush WAL
      try {
        final db = await DatabaseHelper().database;
        await db.execute('PRAGMA wal_checkpoint(FULL)');
        debugPrint('[BackupService] DEBUG: WAL checkpoint complete');
      } catch (e) {
        debugPrint('[BackupService] WARN: WAL checkpoint failed: $e — proceeding anyway');
      }

      final archive = Archive();

      // Add DB file
      if (await dbFile.exists()) {
        final dbBytes = await dbFile.readAsBytes();
        archive.addFile(ArchiveFile(_dbFileName, dbBytes.length, dbBytes));
        debugPrint('[BackupService] DEBUG: added DB file name=$_dbFileName size=${dbBytes.length}');
      }

      // Add attachments recursively
      final attachDir = Directory(p.join(appDir.path, _attachmentsDirName));
      int fileCount = 0;
      if (await attachDir.exists()) {
        await for (final entity in attachDir.list(recursive: true)) {
          if (entity is File) {
            final rel = p.relative(entity.path, from: appDir.path);
            final bytes = await entity.readAsBytes();
            archive.addFile(ArchiveFile(rel, bytes.length, bytes));
            debugPrint('[BackupService] DEBUG: added attachment name=$rel size=${bytes.length}');
            fileCount++;
          }
        }
      }

      // Encode zip
      final encoder = ZipEncoder();
      final zipBytes = encoder.encode(archive);
      if (zipBytes == null) throw Exception('Failed to encode archive');

      // Write to backup dir
      final backupDir = await _getBackupDir();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').substring(0, 19);
      final outFile = File(p.join(backupDir.path, 'backup_$timestamp.zip'));
      await outFile.writeAsBytes(zipBytes);

      debugPrint('[BackupService] INFO: exportBackup complete files=${fileCount + 1} size=${zipBytes.length} path=${outFile.path}');
      return outFile;
    } catch (e, st) {
      debugPrint('[BackupService] ERROR: exportBackup failed: $e\n$st');
      rethrow;
    }
  }

  /// Restores DB and attachments from a zip file.
  /// Caller must show confirmation dialog and reload providers after this returns.
  Future<void> importBackup(File zipFile) async {
    debugPrint('[BackupService] INFO: importBackup start path=${zipFile.path}');
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dbDir = await getDatabasesPath();

      final zipBytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(zipBytes);

      final hasDb = archive.files.any((f) => f.name == _dbFileName);
      debugPrint('[BackupService] INFO: importBackup archive files=${archive.files.length} hasDb=$hasDb');

      // Close DB connection
      await DatabaseHelper().close();
      debugPrint('[BackupService] DEBUG: DB connection closed');

      int restored = 0;
      for (final file in archive) {
        if (!file.isFile) continue;
        final bytes = file.content as List<int>;
        File outFile;
        if (file.name == _dbFileName) {
          outFile = File(p.join(dbDir, _dbFileName));
        } else {
          outFile = File(p.join(appDir.path, file.name));
        }
        await outFile.parent.create(recursive: true);
        await outFile.writeAsBytes(bytes);
        debugPrint('[BackupService] DEBUG: restored file name=${file.name} size=${bytes.length}');
        restored++;
      }

      // Re-open DB (triggers singleton re-init)
      await DatabaseHelper().database;
      debugPrint('[BackupService] INFO: importBackup complete restored=$restored files');
    } catch (e, st) {
      debugPrint('[BackupService] ERROR: importBackup failed: $e\n$st');
      rethrow;
    }
  }

  Future<Directory> _getBackupDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'МоёЗдоровье', 'backups'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }
}
