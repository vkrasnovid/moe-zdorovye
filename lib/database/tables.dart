class Tables {
  static const String records = 'records';
  static const String measurements = 'measurements';

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
}
