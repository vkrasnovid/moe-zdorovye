---
name: flutter-sqflite
description: >-
  sqflite database patterns for Flutter apps. Covers singleton DatabaseHelper
  setup, versioned migrations with onUpgrade, typed CRUD methods, rawQuery
  aggregates, JSON column serialization (DateTime as ms, enums as strings,
  List/Map as JSON), and in-memory testing with sqflite_common_ffi. Use when
  adding tables, writing migrations, implementing repository methods, or testing
  database logic in this project.
---

# Flutter sqflite Patterns

## Core Pattern: Singleton DatabaseHelper

This project uses a single `DatabaseHelper` singleton that lazily opens the DB.
Never instantiate `DatabaseHelper` directly — always use `DatabaseHelper()`.

```dart
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }
}
```

**Rules:**
- Keep one `Database?` field; use `??=` to open lazily.
- Never expose `_db` directly — always go through `get database`.
- Do not open the database in constructors or `initState`.

---

## Schema Conventions

All tables are defined as `static const String` DDL in `lib/database/tables.dart`.

| Convention | Rule |
|---|---|
| Primary key | `id INTEGER PRIMARY KEY AUTOINCREMENT` |
| DateTime | Store as `INTEGER` milliseconds (`date.millisecondsSinceEpoch`) |
| Enum | Store as `TEXT` using `.name` / `fromName()` |
| `List<String>` | Store as `TEXT` using `jsonEncode` / `jsonDecode` |
| `Map<String, dynamic>` | Store as `TEXT` using `jsonEncode` / `jsonDecode` |
| Nullable column | Use `TEXT` or `REAL` without `NOT NULL` |

### Current Tables

```
records         — MedicalRecord: category(TEXT), title(TEXT), date(INT), notes(TEXT?),
                  attachments(TEXT JSON), extra_data(TEXT JSON), created_at(INT)

measurements    — Measurement: type(TEXT), value(REAL), value2(REAL?),
                  date_time(INT), notes(TEXT?)

parsed_results  — ParsedResult: record_id(INT FK), test_name(TEXT),
                  test_name_normalized(TEXT), value(REAL), unit(TEXT),
                  ref_min(REAL?), ref_max(REAL?), flag(TEXT), test_date(TEXT),
                  parsed_at(INT)
```

---

## Model Serialization

Every model must implement `toMap()` and a `fromMap()` factory.

**toMap() rules:**
- Skip `id` when null: `if (id != null) 'id': id`
- DateTime -> `millisecondsSinceEpoch`
- Enum -> `.name`
- `List` / `Map` -> `jsonEncode(...)`

**fromMap() rules:**
- Cast every field explicitly: `map['field'] as int`
- DateTime -> `DateTime.fromMillisecondsSinceEpoch(map['date'] as int)`
- Enum -> call your extension `fromName(map['category'] as String)`
- JSON columns -> `jsonDecode(map['col'] as String? ?? '[]')`

---

## CRUD Workflow

### Insert
```dart
Future<int> insertRecord(MedicalRecord record) async {
  final db = await database;
  return db.insert(Tables.records, record.toMap());
}
```

### Update
```dart
Future<int> updateRecord(MedicalRecord record) async {
  final db = await database;
  return db.update(
    Tables.records,
    record.toMap(),
    where: 'id = ?',
    whereArgs: [record.id],
  );
}
```

### Delete
```dart
Future<int> deleteRecord(int id) async {
  final db = await database;
  return db.delete(Tables.records, where: 'id = ?', whereArgs: [id]);
}
```

### Query with ordering
```dart
Future<List<MedicalRecord>> getAllRecords() async {
  final db = await database;
  final maps = await db.query(Tables.records, orderBy: 'date DESC');
  return maps.map(MedicalRecord.fromMap).toList();
}
```

### Filtered query
```dart
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
```

### LIKE search (always use placeholders, never string interpolation)
```dart
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
```

### rawQuery aggregates
```dart
Future<Map<String, int>> getCategoryCounts() async {
  final db = await database;
  final result = await db.rawQuery(
    'SELECT category, COUNT(*) as count FROM ${Tables.records}'
    ' GROUP BY category',
  );
  return {
    for (final row in result)
      row['category'] as String: row['count'] as int,
  };
}
```

---

## Versioned Migrations

- Increment `version:` in `openDatabase`.
- Add DDL to `onCreate` (for fresh installs).
- Add guarded migration block to `onUpgrade`.

```dart
return openDatabase(
  path,
  version: 3,
  onCreate: (db, version) async {
    await db.execute(Tables.createRecords);
    await db.execute(Tables.createMeasurements);
    await db.execute(Tables.createParsedResults);
    await db.execute(Tables.createNewTable);
  },
  onUpgrade: (db, oldVersion, newVersion) async {
    if (oldVersion < 2) {
      await db.execute(Tables.createParsedResults);
    }
    if (oldVersion < 3) {
      await db.execute(Tables.createNewTable);
      await db.execute(
        'ALTER TABLE ${Tables.records} ADD COLUMN new_col TEXT',
      );
    }
  },
);
```

**Rules:**
- Never drop/recreate a table in `onUpgrade` — users lose data.
- `ALTER TABLE` supports only `ADD COLUMN` in SQLite.
- Guard every migration with `if (oldVersion < N)`.

---

## Testing with sqflite_common_ffi

Add to `dev_dependencies` if not present:
```yaml
sqflite_common_ffi: ^2.3.0
```

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    await DatabaseHelper().resetForTesting();
  });

  test('insertRecord returns a valid id', () async {
    final helper = DatabaseHelper();
    final record = MedicalRecord(
      category: RecordCategory.lab,
      title: 'CBC',
      date: DateTime(2025, 1, 1),
    );
    final id = await helper.insertRecord(record);
    expect(id, greaterThan(0));
  });
}
```

Add a test-only helper to `DatabaseHelper`:
```dart
Future<void> resetForTesting() async {
  await _db?.close();
  _db = null;
}
```

---

## Common Mistakes

| Mistake | Fix |
|---|---|
| String interpolation in WHERE: `where: 'id = $id'` | Use placeholders: `where: 'id = ?', whereArgs: [id]` |
| Storing DateTime as string | Store as `millisecondsSinceEpoch` (INTEGER) for sort correctness |
| Opening DB eagerly in `main()` | Let `get database` open lazily on first use |
| Missing `NOT NULL` on required columns | Match Dart non-nullable types to `NOT NULL` SQL columns |
| Missing `if (oldVersion < N)` guard | Always guard migrations |
