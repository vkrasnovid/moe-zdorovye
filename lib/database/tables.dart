class Tables {
  static const String records = 'records';
  static const String measurements = 'measurements';
  static const String parsedResults = 'parsed_results';

  static const String createRecords = '''
    CREATE TABLE $records (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      category TEXT NOT NULL,
      title TEXT NOT NULL,
      date INTEGER NOT NULL,
      notes TEXT,
      attachments TEXT NOT NULL DEFAULT '[]',
      extra_data TEXT NOT NULL DEFAULT '{}',
      created_at INTEGER NOT NULL
    )
  ''';

  static const String createMeasurements = '''
    CREATE TABLE $measurements (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      type TEXT NOT NULL,
      value REAL NOT NULL,
      value2 REAL,
      date_time INTEGER NOT NULL,
      notes TEXT
    )
  ''';

  static const String createParsedResults = '''
    CREATE TABLE $parsedResults (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      record_id INTEGER NOT NULL,
      test_name TEXT NOT NULL,
      test_name_normalized TEXT NOT NULL,
      value REAL NOT NULL,
      unit TEXT NOT NULL,
      ref_min REAL,
      ref_max REAL,
      flag TEXT NOT NULL,
      test_date TEXT NOT NULL,
      parsed_at INTEGER NOT NULL
    )
  ''';
}
