# Code Review Report — МоеЗдоровье

**Reviewed:** 26 Dart files in `lib/`
**Date:** 2026-03-20
**Reviewer:** Claude Sonnet 4.6

---

## Critical Issues

### CRIT-1 — HTTP server binds to all interfaces (`InternetAddress.anyIPv4`)
**File:** `lib/services/sharing_service.dart:29`
```dart
_server = await shelf_io.serve(handler, InternetAddress.anyIPv4, AppConstants.localServerPort);
```
The server listens on `0.0.0.0` — every network interface on the device (Wi-Fi, USB tethering, VPN, any future hotspot). The UI message says "both devices must be on the same Wi-Fi", but the server is reachable from any network the phone is connected to simultaneously. The intent is clearly to serve only on the local Wi-Fi IP already retrieved (`ip = await NetworkInfo().getWifiIP()`), but the actual bind address contradicts this. Should bind to that specific IP instead.

---

### CRIT-2 — No authentication on the local HTTP server
**File:** `lib/services/sharing_service.dart` (entire file)
Once the server is started, **any device on any reachable network** can open `http://<ip>:8080` and view all shared medical records and download all attached files — without any PIN, token, or one-time code. The QR code displays the URL but does not embed a secret. Sensitive health data (diagnoses, medications, lab results, images) is exposed with zero access control for the entire duration the server is running.

---

### CRIT-3 — No error handling in providers; `_loading` flag permanently stuck on DB failure
**Files:** `lib/providers/records_provider.dart:40–47`, `lib/providers/measurements_provider.dart:16–22`
```dart
Future<void> loadRecords() async {
  _loading = true;
  notifyListeners();
  _records = await _db.getAllRecords();   // throws → _loading stays true forever
  _categoryCounts = await _db.getCategoryCounts();
  _loading = false;
  notifyListeners();
}
```
If any DB operation throws (disk full, corruption, first-launch race), `_loading` is never set back to `false`. The UI shows an infinite spinner and becomes unrecoverable without a restart. The same pattern applies to `addRecord`, `updateRecord`, `deleteRecord`, `addMeasurement`, `updateMeasurement`, `deleteMeasurement` — all silently swallow failures.

---

### CRIT-4 — `_saving` flag never reset on error in `AddRecordScreen`
**File:** `lib/screens/add_record/add_record_screen.dart:270–298`
```dart
Future<void> _save() async {
  if (!_formKey.currentState!.validate()) return;
  setState(() => _saving = true);
  // ...
  await provider.updateRecord(record);  // throws → _saving stays true
  if (mounted) Navigator.pop(context);
  // _saving is never reset to false in the error path
}
```
If the provider call throws, `_saving` is never set back to `false`. The Save/Add button becomes permanently disabled for the remainder of the screen's lifetime.

---

### CRIT-5 — Force-unwrap of nullable `.id` without guard
**Files:** `lib/providers/records_provider.dart:66`, `lib/providers/measurements_provider.dart:40`
```dart
await _db.deleteRecord(record.id!);   // records_provider.dart:66
await _db.deleteMeasurement(m.id!);   // measurements_provider.dart:40
```
If a record/measurement is passed to `deleteRecord`/`deleteMeasurement` before it has been persisted (id == null), this throws `Null check operator used on a null value`. There is no prior guard. The `addRecord` flow inserts and then does `copyWith(id: id)`, but any concurrent call or future refactor could produce a null-id object reaching this path.

---

### CRIT-6 — `fromName` uses `firstWhere` without `orElse` — throws on unknown enum value
**Files:** `lib/models/category.dart:87–89`, `lib/models/measurement.dart:64–66`
```dart
static RecordCategory fromName(String name) {
  return RecordCategory.values.firstWhere((e) => e.name == name);
}
```
If the database contains a category or measurement type string that does not match any current enum value (e.g., after a future rename, or data from a newer app version), `firstWhere` throws a `StateError` and crashes deserialization of the entire record list. All data becomes inaccessible.

---

## Warnings

### WARN-1 — `logRequests()` middleware active in production
**File:** `lib/services/sharing_service.dart:26`
```dart
final handler = Pipeline().addMiddleware(logRequests()).addHandler(router.call);
```
All inbound HTTP requests (including file paths and timing) are printed to stdout/logcat. On a rooted or developer-connected device this leaks metadata about which medical files are being accessed. Should be removed or gated on a debug flag.

---

### WARN-2 — Numeric measurement validator accepts non-numeric input
**File:** `lib/screens/measurements/measurements_screen.dart:245,254,266`
```dart
validator: (v) => v == null || v.trim().isEmpty ? 'Введите значение' : null,
```
The validator only rejects empty strings. "abc", "1.2.3", or "1e" all pass validation. In `_save()`:
```dart
final value = double.tryParse(_valueController.text.replaceAll(',', '.')) ?? 0;
```
A failed parse silently stores `0.0` as the measurement value — a clinically meaningless record with no user feedback.

---

### WARN-3 — `RecordDetailScreen` holds stale data after editing
**File:** `lib/screens/record_detail/record_detail_screen.dart:9`
`RecordDetailScreen` is a `StatelessWidget` that takes `MedicalRecord record` by value at construction. After the user presses the edit button and updates the record, the detail screen still displays the old data. The provider is updated, but the detail screen is not rebuilt because it has no connection to the provider.

---

### WARN-4 — Global filter state in `RecordsProvider` not cleaned up on screen disposal
**File:** `lib/screens/records/records_screen.dart:25–29`
`RecordsScreen.initState()` calls `provider.setFilterCategory(widget.initialCategory)` but `dispose()` never calls `provider.clearFilters()`. When the user opens `RecordsScreen` for a specific category, then navigates back, the category filter remains active in the provider. The home screen's "recent records" list (which reads `provider.records`) will return a filtered subset instead of all records.

---

### WARN-5 — `searchRecords` in `DatabaseHelper` is dead code
**File:** `lib/database/database_helper.dart:69–78`
`DatabaseHelper.searchRecords()` is implemented but never called. `RecordsProvider._filteredRecords` performs in-memory filtering on the full dataset instead. For a user with hundreds of records, loading everything into memory and filtering client-side is wasteful and inconsistent with the existing DB-level API.

---

### WARN-6 — `MeasurementType.name` and `RecordCategory.name` shadow Dart's built-in enum `.name`
**Files:** `lib/models/measurement.dart:10–23`, `lib/models/category.dart:12–25`
Since Dart 2.15, all enums have a built-in `.name` property returning the enum member's identifier string (e.g., `MeasurementType.bloodPressure.name == 'bloodPressure'`). The extensions define their own `get name` with identical return values, shadowing the built-in. This compiles but causes analyzer warnings and is a maintenance trap — the built-in name should be used directly without the extensions.

---

### WARN-7 — `_recordWord` pluralization duplicated
**Files:** `lib/widgets/category_card.dart:66–70`, `lib/services/sharing_service.dart:141–145`
Identical Russian pluralization logic is copy-pasted into two unrelated files. A divergence in one copy (e.g., for a different locale) would cause inconsistent UI.

---

### WARN-8 — `_extraLabels` / `_extraLabel` mapping duplicated
**Files:** `lib/screens/record_detail/record_detail_screen.dart:225–237`, `lib/services/sharing_service.dart:147–162`
The mapping from extra-data keys to Russian display labels is duplicated across two files. `AddRecordScreen._extraFieldsForCategory` is a third related location. A new category field added in `AddRecordScreen` must be manually added to all three locations.

---

### WARN-9 — Redundant double-read in `_buildSelectionView`
**File:** `lib/screens/sharing/sharing_screen.dart:50–52`
```dart
final records = provider.records.isNotEmpty
    ? provider.records
    : context.read<RecordsProvider>().records;
```
Both branches access the same provider object (`Consumer`'s `provider` vs `context.read<RecordsProvider>()`). The `context.read` fallback will never return different data. This reads as if there is a meaningful fallback, but there is none.

---

### WARN-10 — No database migration strategy
**File:** `lib/database/database_helper.dart:22`
```dart
return openDatabase(path, version: 1, onCreate: ...);
```
`onUpgrade` is not defined. Adding a column, index, or table in a future version will silently fail for existing installations (sqflite opens the old schema without running DDL). Schema changes require explicit migration callbacks.

---

### WARN-11 — `SharingService` field `records` is not a defensive copy
**File:** `lib/services/sharing_service.dart:13`
```dart
final List<MedicalRecord> records;
SharingService({required this.records});
```
The passed list is stored directly. In `_startServer`, a filtered `.toList()` is passed, so the list itself is a copy — but the `MedicalRecord` objects inside are shared references. If the provider mutates a record's attachment list while the server is running, the served HTML could reflect those changes mid-session.

---

### WARN-12 — PDF files cannot be opened from the attachment viewer
**File:** `lib/widgets/file_attachment.dart:131–140`
`_openFile` only handles images (opens `_ImageViewer`). Tapping a PDF attachment does nothing — no feedback to the user, no error message. PDFs are accepted as uploads (`file_picker` allows `.pdf`) but are silently non-interactive in the viewer.

---

## Suggestions

### SUG-1 — No file size limit on attachments
**File:** `lib/services/file_service.dart`, `lib/screens/add_record/add_record_screen.dart`
`FileService.saveAttachment` copies any file without size validation. A user could attach a large video file from the gallery, consuming substantial app storage without warning.

---

### SUG-2 — `QrService` is unused and nearly empty
**File:** `lib/services/qr_service.dart`
```dart
class QrService {
  static String buildUrl(String ip, int port) => 'http://$ip:$port';
}
```
`QrService.buildUrl` is never called — `SharingService.start()` constructs the URL directly as a string literal. The class should either be used or removed.

---

### SUG-3 — Hard-coded color constants repeated throughout the codebase
`Color(0xFF00897B)` (teal) appears in at least 10 files. These should be referenced via `Theme.of(context).colorScheme` or a named constant in `colors.dart` / `AppTheme`.

---

### SUG-4 — `formatDate(...).substring(0, 5)` is fragile
**File:** `lib/widgets/measurement_chart.dart:89`
```dart
AppFormatters.formatDate(last[idx].dateTime).substring(0, 5)
```
This assumes `formatDate` always returns at least 5 characters in `dd.MM` format. It works for the current `DateFormat('dd.MM.yyyy')` but will silently break (index out of range or wrong result) if the format is ever changed.

---

### SUG-5 — `MeasurementsProvider` has no per-type loading indicator
**File:** `lib/providers/measurements_provider.dart`
A single `_loading` bool covers all types. When the user switches between measurement tabs, `_loading = true` is set globally, causing all unrelated content to show a spinner while only one type is being fetched.

---

### SUG-6 — No tests
There are no unit or widget tests for any layer: DB queries, serialization (`fromMap`/`toMap`), provider logic, or the HTTP server routing. For a health data application, at minimum the serialization round-trips and the file-serving allow-list logic should have test coverage.

---

### SUG-7 — `DatabaseHelper` singleton is not closed
`DatabaseHelper._db` is opened but never closed. This is acceptable for a mobile app where the process lifetime matches the app lifetime, but there is no `close()` method at all — making it impossible to write integration tests that need to reset state between runs.

---

### SUG-8 — `_AddMeasurementSheet` uses `Function(Measurement)` instead of typed callback
**File:** `lib/screens/measurements/measurements_screen.dart:190`
```dart
final Function(Measurement) onSaved;
```
Should be `ValueChanged<Measurement>` or `void Function(Measurement)` for type safety and clarity.

---

## Summary

**Result: FAIL**

The codebase is well-structured for a personal health app — clean architecture with Provider, good separation of models/DB/services/UI, proper `dispose()` patterns for controllers, and readable code throughout. However, several issues prevent a passing grade:

**Security (CRIT-1, CRIT-2):** The local HTTP server has no authentication and binds to all interfaces. Any other device on any reachable network can access sensitive medical data while the server is running. These are the most important issues to address.

**Reliability (CRIT-3, CRIT-4, CRIT-5, CRIT-6):** Providers have no error handling, leaving the UI frozen on any DB failure. The save button can become permanently stuck. Force-unwrapped nulls and `firstWhere` without `orElse` represent unhandled crash paths.

**Data integrity (WARN-3, WARN-4, WARN-2):** Stale data in the detail screen, lingering filter state, and silent coercion of invalid numeric input to `0.0` affect data correctness.

**Maintainability (WARN-7, WARN-8, WARN-5):** Duplicated business logic in 3+ places and dead code increase the maintenance burden.

Priority order for fixes: CRIT-2 → CRIT-1 → CRIT-3 → CRIT-4 → CRIT-6 → WARN-2 → CRIT-5 → remaining.
