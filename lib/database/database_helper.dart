import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/record.dart';
import '../models/measurement.dart';
import '../models/parsed_result.dart';
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

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'moe_zdorovye.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute(Tables.createRecords);
        await db.execute(Tables.createMeasurements);
        await db.execute(Tables.createParsedResults);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(Tables.createParsedResults);
        }
      },
    );
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

  Future<List<MedicalRecord>> getAllRecords() async {
    final db = await database;
    final maps = await db.query(Tables.records, orderBy: 'date DESC');
    return maps.map(MedicalRecord.fromMap).toList();
  }

  Future<List<MedicalRecord>> getRecordsByCategory(String category) async {
    final db = await database;
    final maps = await db.query(
      Tables.records,
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'date DESC',
    );
    return maps.map(MedicalRecord.fromMap).toList();
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

  Future<Map<String, int>> getCategoryCounts() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT category, COUNT(*) as count FROM ${Tables.records} GROUP BY category',
    );
    return {for (final row in result) row['category'] as String: row['count'] as int};
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

  Future<List<Measurement>> getMeasurementsByType(String type) async {
    final db = await database;
    final maps = await db.query(
      Tables.measurements,
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'date_time DESC',
    );
    return maps.map(Measurement.fromMap).toList();
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
}
