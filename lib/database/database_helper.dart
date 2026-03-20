import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/record.dart';
import '../models/measurement.dart';
import '../models/parsed_result.dart';
import '../models/profile.dart';
import '../models/reminder.dart';
import 'tables.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<void> close() async {
    if (_db != null) {
      debugPrint('[DatabaseHelper] DEBUG: closing database connection');
      await _db!.close();
      _db = null;
    }
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'moe_zdorovye.db');
    return openDatabase(
      path,
      version: 4,
      onCreate: (db, version) async {
        debugPrint('[DatabaseHelper] DEBUG: onCreate version=$version');
        await db.execute(Tables.createRecords);
        await db.execute(Tables.createMeasurements);
        await db.execute(Tables.createParsedResults);
        await db.execute(Tables.createProfiles);
        await db.execute(Tables.createReminders);
        // Insert default profile
        await _insertDefaultProfile(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        debugPrint('[DatabaseHelper] DEBUG: onUpgrade oldVersion=$oldVersion newVersion=$newVersion');
        try {
          if (oldVersion < 2) {
            debugPrint('[DatabaseHelper] DEBUG: Migrating DB from v1 to v2: creating parsed_results table');
            await db.execute(Tables.createParsedResults);
          }
          if (oldVersion < 3) {
            debugPrint('[DatabaseHelper] DEBUG: Migrating DB from v2 to v3: creating profiles table');
            await db.execute(Tables.createProfiles);
            debugPrint('[DatabaseHelper] DEBUG: Migrating DB from v2 to v3: adding profile_id to records');
            await db.execute('ALTER TABLE ${Tables.records} ADD COLUMN profile_id INTEGER');
            debugPrint('[DatabaseHelper] DEBUG: Migrating DB from v2 to v3: adding profile_id to measurements');
            await db.execute('ALTER TABLE ${Tables.measurements} ADD COLUMN profile_id INTEGER');
            // Insert default profile and back-fill existing data
            final defaultId = await _insertDefaultProfile(db);
            final recordsUpdated = await db.rawUpdate(
              'UPDATE ${Tables.records} SET profile_id = ? WHERE profile_id IS NULL',
              [defaultId],
            );
            final measurementsUpdated = await db.rawUpdate(
              'UPDATE ${Tables.measurements} SET profile_id = ? WHERE profile_id IS NULL',
              [defaultId],
            );
            debugPrint('[DatabaseHelper] DEBUG: Back-filled $recordsUpdated records, $measurementsUpdated measurements with default profile id=$defaultId');
          }
          if (oldVersion < 4) {
            debugPrint('[DatabaseHelper] DEBUG: Migrating DB from v3 to v4: creating reminders table');
            await db.execute(Tables.createReminders);
          }
        } catch (e, st) {
          debugPrint('[DatabaseHelper] ERROR: migration failed: $e\n$st');
          rethrow;
        }
      },
    );
  }

  Future<int> _insertDefaultProfile(Database db) async {
    final id = await db.insert(Tables.profiles, {
      'name': 'Я',
      'avatar_color': 0xFF1976D2, // blue
      'is_default': 1,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
    debugPrint('[DatabaseHelper] DEBUG: inserted default profile id=$id');
    return id;
  }

  // Profiles
  Future<int> insertProfile(Profile p) async {
    debugPrint('[DatabaseHelper] DEBUG: insertProfile entry name=${p.name} avatarColor=${p.avatarColor}');
    final db = await database;
    final id = await db.insert(Tables.profiles, p.toMap());
    debugPrint('[DatabaseHelper] DEBUG: insertProfile exit id=$id');
    return id;
  }

  Future<List<Profile>> getProfiles() async {
    debugPrint('[DatabaseHelper] DEBUG: getProfiles entry');
    final db = await database;
    final maps = await db.query(Tables.profiles, orderBy: 'created_at ASC');
    final profiles = maps.map(Profile.fromMap).toList();
    debugPrint('[DatabaseHelper] DEBUG: getProfiles exit count=${profiles.length}');
    return profiles;
  }

  Future<Profile?> getProfile(int id) async {
    debugPrint('[DatabaseHelper] DEBUG: getProfile entry id=$id');
    final db = await database;
    final maps = await db.query(Tables.profiles, where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) {
      debugPrint('[DatabaseHelper] DEBUG: getProfile exit — not found');
      return null;
    }
    final profile = Profile.fromMap(maps.first);
    debugPrint('[DatabaseHelper] DEBUG: getProfile exit name=${profile.name}');
    return profile;
  }

  Future<int> updateProfile(Profile p) async {
    debugPrint('[DatabaseHelper] DEBUG: updateProfile entry id=${p.id} name=${p.name}');
    final db = await database;
    final count = await db.update(
      Tables.profiles,
      p.toMap(),
      where: 'id = ?',
      whereArgs: [p.id],
    );
    debugPrint('[DatabaseHelper] DEBUG: updateProfile exit rowsAffected=$count');
    return count;
  }

  Future<int> deleteProfile(int id) async {
    debugPrint('[DatabaseHelper] DEBUG: deleteProfile entry id=$id');
    final db = await database;
    final profiles = await getProfiles();
    if (profiles.length <= 1) {
      debugPrint('[DatabaseHelper] WARN: deleteProfile blocked — cannot delete last profile');
      return 0;
    }
    final count = await db.delete(Tables.profiles, where: 'id = ?', whereArgs: [id]);
    debugPrint('[DatabaseHelper] DEBUG: deleteProfile exit rowsAffected=$count');
    return count;
  }

  // Records
  Future<int> insertRecord(MedicalRecord record) async {
    final db = await database;
    return db.insert(Tables.records, record.toMap());
  }

  Future<int> updateRecord(MedicalRecord record) async {
    final db = await database;
    return db.update(
      Tables.records,
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<int> deleteRecord(int id) async {
    final db = await database;
    return db.delete(Tables.records, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<MedicalRecord>> getAllRecords({int? profileId}) async {
    debugPrint('[DatabaseHelper] DEBUG: getAllRecords entry profileId=$profileId');
    final db = await database;
    final maps = profileId != null
        ? await db.query(Tables.records, where: 'profile_id = ?', whereArgs: [profileId], orderBy: 'date DESC')
        : await db.query(Tables.records, orderBy: 'date DESC');
    final records = maps.map(MedicalRecord.fromMap).toList();
    debugPrint('[DatabaseHelper] DEBUG: getAllRecords exit count=${records.length}');
    return records;
  }

  Future<List<MedicalRecord>> getRecordsByCategory(String category, {int? profileId}) async {
    debugPrint('[DatabaseHelper] DEBUG: getRecordsByCategory entry category=$category profileId=$profileId');
    final db = await database;
    final List<Map<String, dynamic>> maps;
    if (profileId != null) {
      maps = await db.query(
        Tables.records,
        where: 'category = ? AND profile_id = ?',
        whereArgs: [category, profileId],
        orderBy: 'date DESC',
      );
    } else {
      maps = await db.query(
        Tables.records,
        where: 'category = ?',
        whereArgs: [category],
        orderBy: 'date DESC',
      );
    }
    final records = maps.map(MedicalRecord.fromMap).toList();
    debugPrint('[DatabaseHelper] DEBUG: getRecordsByCategory exit count=${records.length}');
    return records;
  }

  Future<List<MedicalRecord>> searchRecords(String query) async {
    final db = await database;
    final maps = await db.query(
      Tables.records,
      where: 'title LIKE ? OR notes LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'date DESC',
    );
    return maps.map(MedicalRecord.fromMap).toList();
  }

  Future<Map<String, int>> getCategoryCounts({int? profileId}) async {
    debugPrint('[DatabaseHelper] DEBUG: getCategoryCounts entry profileId=$profileId');
    final db = await database;
    final result = profileId != null
        ? await db.rawQuery(
            'SELECT category, COUNT(*) as count FROM ${Tables.records} WHERE profile_id = ? GROUP BY category',
            [profileId],
          )
        : await db.rawQuery(
            'SELECT category, COUNT(*) as count FROM ${Tables.records} GROUP BY category',
          );
    final counts = {for (final row in result) row['category'] as String: row['count'] as int};
    debugPrint('[DatabaseHelper] DEBUG: getCategoryCounts exit categories=${counts.length}');
    return counts;
  }

  // Measurements
  Future<int> insertMeasurement(Measurement m) async {
    final db = await database;
    return db.insert(Tables.measurements, m.toMap());
  }

  Future<int> updateMeasurement(Measurement m) async {
    final db = await database;
    return db.update(
      Tables.measurements,
      m.toMap(),
      where: 'id = ?',
      whereArgs: [m.id],
    );
  }

  Future<int> deleteMeasurement(int id) async {
    final db = await database;
    return db.delete(Tables.measurements, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Measurement>> getMeasurementsByType(String type, {int? profileId}) async {
    debugPrint('[DatabaseHelper] DEBUG: getMeasurementsByType entry type=$type profileId=$profileId');
    final db = await database;
    final List<Map<String, dynamic>> maps;
    if (profileId != null) {
      maps = await db.query(
        Tables.measurements,
        where: 'type = ? AND profile_id = ?',
        whereArgs: [type, profileId],
        orderBy: 'date_time DESC',
      );
    } else {
      maps = await db.query(
        Tables.measurements,
        where: 'type = ?',
        whereArgs: [type],
        orderBy: 'date_time DESC',
      );
    }
    final measurements = maps.map(Measurement.fromMap).toList();
    debugPrint('[DatabaseHelper] DEBUG: getMeasurementsByType exit count=${measurements.length}');
    return measurements;
  }

  Future<int> getMeasurementsCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM ${Tables.measurements}');
    return result.first['count'] as int;
  }

  // ParsedResults
  Future<int> insertParsedResult(ParsedResult result) async {
    final db = await database;
    return db.insert(Tables.parsedResults, result.toMap());
  }

  Future<List<ParsedResult>> getParsedResultsForRecord(int recordId) async {
    final db = await database;
    final maps = await db.query(
      Tables.parsedResults,
      where: 'record_id = ?',
      whereArgs: [recordId],
      orderBy: 'test_name_normalized ASC',
    );
    return maps.map(ParsedResult.fromMap).toList();
  }

  Future<List<ParsedResult>> getAllParsedResults() async {
    final db = await database;
    final maps = await db.query(Tables.parsedResults, orderBy: 'test_date ASC');
    return maps.map(ParsedResult.fromMap).toList();
  }

  Future<int> updateParsedResult(ParsedResult r) async {
    final db = await database;
    return db.update(
      Tables.parsedResults,
      r.toMap(),
      where: 'id = ?',
      whereArgs: [r.id],
    );
  }

  Future<int> deleteParsedResult(int id) async {
    final db = await database;
    return db.delete(Tables.parsedResults, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteParsedResultsForRecord(int recordId) async {
    final db = await database;
    await db.delete(Tables.parsedResults, where: 'record_id = ?', whereArgs: [recordId]);
  }

  Future<List<ParsedResult>> getParsedResultsByNormalized(String normalized) async {
    final db = await database;
    final maps = await db.query(
      Tables.parsedResults,
      where: 'test_name_normalized = ?',
      whereArgs: [normalized],
      orderBy: 'test_date ASC',
    );
    return maps.map(ParsedResult.fromMap).toList();
  }

  Future<List<String>> getDistinctNormalizedTestNames() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT DISTINCT test_name_normalized FROM ${Tables.parsedResults} ORDER BY test_name_normalized ASC',
    );
    return result.map((r) => r['test_name_normalized'] as String).toList();
  }

  // Reminders
  Future<int> insertReminder(Reminder r) async {
    debugPrint('[DatabaseHelper] DEBUG: insertReminder entry title=${r.title} profileId=${r.profileId}');
    final db = await database;
    final id = await db.insert(Tables.reminders, r.toMap());
    debugPrint('[DatabaseHelper] DEBUG: insertReminder exit id=$id');
    return id;
  }

  Future<List<Reminder>> getReminders({int? profileId, bool activeOnly = false}) async {
    debugPrint('[DatabaseHelper] DEBUG: getReminders entry profileId=$profileId activeOnly=$activeOnly');
    final db = await database;
    String? where;
    List<dynamic>? whereArgs;
    if (profileId != null && activeOnly) {
      where = 'profile_id = ? AND is_active = 1';
      whereArgs = [profileId];
    } else if (profileId != null) {
      where = 'profile_id = ?';
      whereArgs = [profileId];
    } else if (activeOnly) {
      where = 'is_active = 1';
    }
    final maps = await db.query(
      Tables.reminders,
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at ASC',
    );
    final reminders = maps.map(Reminder.fromMap).toList();
    debugPrint('[DatabaseHelper] DEBUG: getReminders exit count=${reminders.length}');
    return reminders;
  }

  Future<int> updateReminder(Reminder r) async {
    debugPrint('[DatabaseHelper] DEBUG: updateReminder entry id=${r.id} title=${r.title}');
    final db = await database;
    final count = await db.update(
      Tables.reminders,
      r.toMap(),
      where: 'id = ?',
      whereArgs: [r.id],
    );
    debugPrint('[DatabaseHelper] DEBUG: updateReminder exit rowsAffected=$count');
    return count;
  }

  Future<int> deleteReminder(int id) async {
    debugPrint('[DatabaseHelper] DEBUG: deleteReminder entry id=$id');
    final db = await database;
    final count = await db.delete(Tables.reminders, where: 'id = ?', whereArgs: [id]);
    debugPrint('[DatabaseHelper] DEBUG: deleteReminder exit rowsAffected=$count');
    return count;
  }
}
