---
name: flutter-medical-records
description: >-
  Domain model and provider patterns for the MoeZdorovye Flutter medical
  records app. Covers RecordCategory and MeasurementType enums, MedicalRecord /
  Measurement / ParsedResult models, Provider-based ViewModels (RecordsProvider,
  MeasurementsProvider, ParsedResultsProvider), flag logic for lab results, and
  the parse-record workflow (PDF + OCR -> LabParserService -> DB). Use when
  adding features, new record types, lab parsing logic, or dynamics charts.
---

# MoeZdorovye Domain Model & Provider Patterns

## Domain Overview

МоеЗдоровье stores three types of health data:

| Entity | Provider | Table |
|---|---|---|
| `MedicalRecord` | `RecordsProvider` | `records` |
| `Measurement` | `MeasurementsProvider` | `measurements` |
| `ParsedResult` | `ParsedResultsProvider` | `parsed_results` |

All providers extend `ChangeNotifier` and are injected via the `provider`
package. Read state with `context.watch<T>()`, call mutations with
`context.read<T>()`.

---

## RecordCategory Enum

File: `lib/models/category.dart`

```
tests          — Анализы крови/мочи
imaging        — Медицинские снимки
prescriptions  — Рецепты и назначения
vaccinations   — Вакцинации
conditions     — Хронические заболевания и аллергии
```

Each value exposes:
- `.name` (String, stored in DB)
- `.displayName` / `.displayNameFull` (Russian UI labels)
- `.icon` (IconData)
- `.color` (Color) and `.gradientColors` (List<Color>)
- `RecordCategoryExtension.fromName(String)` for DB deserialization

**Adding a new category:** Add to enum + all switch cases in the extension,
then add a migration to bump DB version only if schema changes.

---

## MedicalRecord Model

File: `lib/models/record.dart`

```dart
MedicalRecord({
  int? id,
  required RecordCategory category,
  required String title,
  required DateTime date,
  String? notes,
  List<String>? attachments,   // file paths, stored as JSON
  Map<String, dynamic>? extraData, // flexible KV storage, stored as JSON
  DateTime? createdAt,
})
```

Key rules:
- `id` is null before first insert; assign returned id via `copyWith(id: id)`.
- `attachments` holds absolute file paths on device storage.
- `extraData` is a schema-free JSON blob for category-specific fields.
- `date` is the record date; `createdAt` is the insertion timestamp.

---

## Measurement Model

File: `lib/models/measurement.dart`

```dart
Measurement({
  int? id,
  required MeasurementType type,
  required double value,
  double? value2,       // only used for bloodPressure (diastolic)
  required DateTime dateTime,
  String? notes,
})
```

MeasurementType values: `bloodPressure`, `weight`, `temperature`,
`bloodSugar`, `heartRate`.

- `hasTwoValues` is true only for `bloodPressure`; use `value2` for diastolic.
- `displayValue` formats the value with unit in Russian for UI display.
- Store with `MeasurementTypeExtension.fromName(string)` for roundtrip safety.

---

## ParsedResult Model

File: `lib/models/parsed_result.dart`

Lab test result extracted from a document.

```dart
ParsedResult({
  int? id,
  required int recordId,       // FK to records.id
  required String testName,    // raw name from OCR/PDF
  required String testNameNormalized, // canonical name (e.g. "hemoglobin")
  required double value,
  required String unit,
  double? refMin,
  double? refMax,
  required String flag,        // 'normal' | 'high' | 'low'
  required String testDate,    // ISO date "YYYY-MM-DD"
  required DateTime parsedAt,
})
```

Flag helpers (use in UI):
- `.isNormal` / `.isHigh` / `.isLow`
- `.flagColor` — Color for the status chip
- `.flagIcon` — IconData (arrow_upward / arrow_downward / check)
- `.flagLabel` — Russian label ("Норма" / "Повышен" / "Понижен")

---

## RecordsProvider

File: `lib/providers/records_provider.dart`

```
State:     _records (all records, sorted date DESC)
           _categoryCounts (Map<String, int>)
           _loading, _searchQuery, _filterCategory

Getters:   records         — filtered + searched list
           recentRecords   — first 5 items
           categoryCounts  — raw map

Mutations: loadRecords()          — reload from DB
           addRecord(record)      — insert + prepend + update counts
           updateRecord(record)   — update in DB + update list
           deleteRecord(record)   — delete from DB + remove from list
           setSearchQuery(q)      — client-side text filter
           setFilterCategory(cat) — client-side category filter
           clearFilters()
```

**Pattern:** `addRecord` uses optimistic update — it inserts to DB, then
prepends with the saved id via `copyWith(id: id)`, then notifies.
On error it still notifies (so loading spinner clears) then rethrows.

---

## ParsedResultsProvider

File: `lib/providers/parsed_results_provider.dart`

```
State:     _recordResults  — results for one record (from loadForRecord)
           _allResults     — all results across all records (from loadAll)
           _loading, _error, _allLoaded

Key getter: resultsByTestName
            Map<String, List<ParsedResult>> grouped by testNameNormalized,
            each list sorted by testDate ASC,
            keys sorted by most recent testDate DESC.
            Use this for the dynamics (trend) screen.
```

### Parse-Record Workflow

Triggered by `parseRecord(MedicalRecord record)`:

1. Iterate `record.attachments`:
   - `.pdf` files → `PdfTextService.extractText(path)`
   - `.jpg/.jpeg/.png` → `OcrService.extractText(path)`
2. Combine extracted text into a `StringBuffer`.
3. Call `LabParserService.parse(text, recordId, testDate)`.
4. Delete existing parsed results for the record, insert new ones.
5. Reload `_recordResults` from DB, set `_allLoaded = false`.
6. Returns `bool` — `true` if any results were parsed.

**Rule:** Always call `parseRecord` after attaching a new document to a
`tests`-category record. Check `provider.error` after the call.

---

## Provider Setup (app.dart)

Providers are registered with `MultiProvider` at app root:

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => RecordsProvider()),
    ChangeNotifierProvider(create: (_) => MeasurementsProvider()),
    ChangeNotifierProvider(create: (_) => ParsedResultsProvider()),
  ],
  child: MaterialApp(...),
)
```

Load initial data in the first screen's `initState`:
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    context.read<RecordsProvider>().loadRecords();
    context.read<MeasurementsProvider>().loadMeasurements();
  });
}
```

---

## Adding a New Feature Checklist

- [ ] **Model** — add fields to the model class; update `toMap()`/`fromMap()`
- [ ] **Schema** — add column/table DDL to `lib/database/tables.dart`
- [ ] **Migration** — bump DB version, add `if (oldVersion < N)` guard
- [ ] **DatabaseHelper** — add CRUD methods for new fields
- [ ] **Provider** — add state + mutation + `notifyListeners()`
- [ ] **UI** — consume via `context.watch<T>()`, mutate via `context.read<T>()`
- [ ] **Parse** — if records now produce ParsedResults, wire `parseRecord()`
