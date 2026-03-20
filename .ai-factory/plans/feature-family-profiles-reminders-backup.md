# Implementation Plan: Family Profiles, Reminders & Local Backup

Branch: feature/family-profiles-reminders-backup
Created: 2026-03-20

## Settings
- Testing: no
- Logging: verbose
- Docs: no

## Commit Plan
- **Commit 1** (after tasks 1–4): `feat: add family profiles model, DB migration, and provider`
- **Commit 2** (after tasks 5–7): `feat: implement profile management UI and data scoping`
- **Commit 3** (after tasks 8–11): `feat: add reminders model, notifications service, and provider`
- **Commit 4** (after tasks 12–15): `feat: implement reminders UI with full scheduling`
- **Commit 5** (after tasks 16–19): `feat: implement local backup export, import, and auto-backup`

## Tasks

### Phase 1: Family Profiles — Data Layer

- [x] Task 1: Profile model and DB migration

  Create `lib/models/profile.dart` with `Profile` class:
  - Fields: `id`, `name`, `avatarColor` (stored as int hex), `isDefault` (bool), `createdAt`
  - `toMap()` / `fromMap()` with full DEBUG logging on serialization
  - Add `profiles` table to `lib/database/tables.dart`:
    ```sql
    CREATE TABLE profiles (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      avatar_color INTEGER NOT NULL DEFAULT 4280391411,
      is_default INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL
    )
    ```
  - Bump DB version to 3 in `database_helper.dart`, add `onUpgrade` branch:
    - Create `profiles` table
    - Add `profile_id INTEGER` column to `records` table (nullable, defaults NULL)
    - Add `profile_id INTEGER` column to `measurements` table (nullable, defaults NULL)
    - Insert a default profile row ("Я", blue) and back-fill all existing records/measurements with its id
  - LOGGING REQUIREMENTS:
    - DEBUG: log each migration step ("Migrating DB from v2 to v3: creating profiles table")
    - DEBUG: log back-fill counts ("Back-filled N records, M measurements with default profile id=X")
    - ERROR: log and rethrow any migration exceptions

  Files: `lib/models/profile.dart`, `lib/database/tables.dart`, `lib/database/database_helper.dart`

- [x] Task 2: CRUD methods for profiles in DatabaseHelper

  Add to `database_helper.dart`:
  - `Future<int> insertProfile(Profile p)`
  - `Future<List<Profile>> getProfiles()`
  - `Future<Profile?> getProfile(int id)`
  - `Future<int> updateProfile(Profile p)`
  - `Future<int> deleteProfile(int id)` — guard: refuse deletion if only one profile remains
  - Scope existing `getRecords()` and `getMeasurements()` with optional `profileId` filter
  - Scope existing `getCategoryCounts()` with optional `profileId` filter:
    ```dart
    Future<Map<String, int>> getCategoryCounts({int? profileId})
    ```
    Add `WHERE profile_id = ?` when profileId is non-null; this ensures the HomeScreen category badge counts are per-profile.
  - LOGGING REQUIREMENTS:
    - DEBUG: log entry/exit for each method with arguments
    - DEBUG: log row count returned by queries
    - WARN: log when deleteProfile is blocked due to single-profile constraint

  Files: `lib/database/database_helper.dart`

- [x] Task 3: ProfilesProvider

  Create `lib/providers/profiles_provider.dart` extending `ChangeNotifier`:
  - State: `List<Profile> _profiles`, `Profile? _activeProfile`
  - `loadProfiles()` — loads from DB, sets first `isDefault=1` as active (or first in list)
  - `setActiveProfile(int id)` — updates `_activeProfile`, calls `notifyListeners()`
  - `createProfile(String name, Color color)` — inserts, reloads
  - `updateProfile(Profile p)` — updates in DB, reloads
  - `deleteProfile(int id)` — only allowed if profiles.length > 1; auto-switch active if deleted
  - Expose `int? get activeProfileId => _activeProfile?.id`
  - LOGGING REQUIREMENTS:
    - DEBUG: log every state transition with profile id and name
    - INFO: log active profile switch events
    - WARN: log attempted deletion of last profile
    - ERROR: log DB exceptions with stack trace

  Files: `lib/providers/profiles_provider.dart`

- [x] Task 4: Scope RecordsProvider and MeasurementsProvider by active profile

  Modify `lib/providers/records_provider.dart`:
  - Constructor or `loadRecords()` accepts `int? profileId`
  - Pass `profileId` to `DatabaseHelper.getRecords(profileId: ...)` in all load calls
  - `insertRecord` and `updateRecord` must set `profileId` field on the model before saving

  Modify `lib/providers/measurements_provider.dart`:
  - Apply `profileId` inside `loadForType(MeasurementType type)` — add optional `int? profileId` parameter and pass it to `DatabaseHelper.getMeasurementsByType(type.name, profileId: profileId)`
  - Add a helper method `reloadAllForProfile(int? profileId)` that re-triggers `loadForType` for every key currently present in `_byType` map, using the new profileId. This is called when the active profile switches.
  - NOTE: there is no existing `loadMeasurements()` method — do NOT reference that name anywhere; always use `loadForType()` / `reloadAllForProfile()`

  Modify `lib/models/record.dart`:
  - Add nullable `profileId` field, include in `toMap()`/`fromMap()`

  Modify `lib/models/measurement.dart`:
  - Add nullable `profileId` field, include in `toMap()`/`fromMap()`

  LOGGING REQUIREMENTS:
  - DEBUG: log which profileId is being used on every load call
  - DEBUG: log count of records/measurements returned per profile

  Files: `lib/providers/records_provider.dart`, `lib/providers/measurements_provider.dart`, `lib/models/record.dart`, `lib/models/measurement.dart`

<!-- Commit checkpoint: tasks 1–4 → feat: add family profiles model, DB migration, and provider -->

### Phase 2: Family Profiles — UI

- [x] Task 5: Register ProfilesProvider and wire active-profile refresh

  Modify `lib/app.dart`:
  - Add `ProfilesProvider` to the `MultiProvider` list (before `RecordsProvider` and `MeasurementsProvider` so they can read it)
  - Add `RemindersProvider` to the `MultiProvider` list (done in Task 11 — just note the registration slot here)

  Modify `lib/screens/home/home_screen.dart` to wire active-profile reload:
  - In `initState`, after loading profiles via `addPostFrameCallback`, call `ProfilesProvider.loadProfiles()` then trigger initial `RecordsProvider.loadRecords(profileId: activeId)` and `MeasurementsProvider.reloadAllForProfile(activeId)`
  - Add a `Consumer<ProfilesProvider>` wrapper in `build()` that detects `activeProfileId` changes and re-triggers `RecordsProvider.loadRecords()` and `MeasurementsProvider.reloadAllForProfile()` when the active profile changes. Use a local `_lastProfileId` variable in the state to detect changes and avoid redundant reloads.
  - Do NOT use ProxyProvider — the project pattern (used in HomeScreen initState) is `addPostFrameCallback` + direct provider calls.

  LOGGING REQUIREMENTS:
  - DEBUG: log when provider wiring fires and which profileId propagated

  Files: `lib/app.dart`, `lib/screens/home/home_screen.dart`

- [x] Task 6: Profile switcher widget in HomeScreen app bar / drawer

  Create `lib/widgets/profile_switcher.dart`:
  - Shows a circular avatar with initials + `avatarColor` background and the active profile name
  - On tap: opens a bottom sheet (`showModalBottomSheet`) listing all profiles
  - Each profile row: avatar, name, radio indicator for active; tap to switch
  - "+ Добавить профиль" row at the bottom → opens add-profile dialog (inline, not separate screen)
  - Long-press on a profile row → opens edit/delete popup menu (except if it is the last profile)

  Modify `lib/screens/home/home_screen.dart`:
  - Place `ProfileSwitcher` as a leading widget in the `AppBar` or as a persistent header row below the app bar
  - When active profile changes → reload records and measurements

  All UI labels in Russian: "Профили", "Добавить профиль", "Активный профиль", "Удалить", "Редактировать"

  LOGGING REQUIREMENTS:
  - DEBUG: log which profile was selected and when
  - DEBUG: log bottom-sheet open/close events

  Files: `lib/widgets/profile_switcher.dart`, `lib/screens/home/home_screen.dart`

- [x] Task 7: Add/edit profile dialog with color picker

  Create `lib/widgets/profile_form_dialog.dart` (shown as bottom sheet):
  - Text field: "Имя профиля" (required, max 30 chars)
  - Color swatch row: 8 predefined Material colors to pick avatar color
  - "Сохранить" / "Отмена" buttons
  - Validation: name cannot be blank, name cannot duplicate an existing profile name
  - Handles both create and edit modes (receives optional `Profile?` parameter)

  LOGGING REQUIREMENTS:
  - DEBUG: log dialog open with mode (create vs edit)
  - DEBUG: log form submission with values before save
  - WARN: log validation failures with reason

  Files: `lib/widgets/profile_form_dialog.dart`

<!-- Commit checkpoint: tasks 5–7 → feat: implement profile management UI and data scoping -->

### Phase 3: Reminders — Data Layer

- [x] Task 8: Reminder model and DB table

  Create `lib/models/reminder.dart`:
  - Enum `ReminderType`: `medication`, `doctorVisit`, `vaccination`
  - Enum `ScheduleType`: `once`, `daily`, `weekly`, `custom` (custom = specific weekdays mask)
  - Class `Reminder`:
    - `id`, `profileId` (int), `type` (ReminderType), `title` (String), `body` (String?)
    - `scheduleType` (ScheduleType), `time` (TimeOfDay stored as minutes since midnight int)
    - `weekdaysMask` (int, bitmask 1–127 for Mon–Sun; used when scheduleType=weekly/custom)
    - `nextDueDate` (DateTime?, for once/vaccination alerts)
    - `isActive` (bool), `linkedRecordId` (int?, optional link to a vaccine/prescription record)
    - `createdAt` (DateTime)
  - `toMap()` / `fromMap()` — store enums as strings, DateTime as ms, TimeOfDay as int

  Add `reminders` table to `lib/database/tables.dart`:
  ```sql
  CREATE TABLE reminders (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    profile_id INTEGER NOT NULL,
    type TEXT NOT NULL,
    title TEXT NOT NULL,
    body TEXT,
    schedule_type TEXT NOT NULL,
    time_minutes INTEGER NOT NULL,
    weekdays_mask INTEGER NOT NULL DEFAULT 0,
    next_due_date INTEGER,
    is_active INTEGER NOT NULL DEFAULT 1,
    linked_record_id INTEGER,
    created_at INTEGER NOT NULL
  )
  ```
  Bump DB to version 4 in `database_helper.dart`; `onUpgrade` v3→v4 creates `reminders` table.

  **Also update `onCreate` in `_initDatabase()`** to create ALL 5 tables for fresh installs at v4:
  ```dart
  onCreate: (db, version) async {
    await db.execute(Tables.createRecords);
    await db.execute(Tables.createMeasurements);
    await db.execute(Tables.createParsedResults);
    await db.execute(Tables.createProfiles);
    await db.execute(Tables.createReminders);
    // Insert default profile for new installs
    await db.insert('profiles', {'name': 'Я', 'avatar_color': 4280391411, 'is_default': 1, 'created_at': DateTime.now().millisecondsSinceEpoch});
  }
  ```
  Without this, new users who install the app fresh after v4 will be missing the `profiles` and `reminders` tables.

  LOGGING REQUIREMENTS:
  - DEBUG: log migration step
  - DEBUG: log serialization on fromMap/toMap

  Files: `lib/models/reminder.dart`, `lib/database/tables.dart`, `lib/database/database_helper.dart`

- [x] Task 9: CRUD methods for reminders in DatabaseHelper

  Add to `database_helper.dart`:
  - `Future<int> insertReminder(Reminder r)`
  - `Future<List<Reminder>> getReminders({int? profileId, bool activeOnly = false})`
  - `Future<int> updateReminder(Reminder r)`
  - `Future<int> deleteReminder(int id)`

  LOGGING REQUIREMENTS:
  - DEBUG: log entry/exit, arguments, and row counts

  Files: `lib/database/database_helper.dart`

- [x] Task 10: Add flutter_local_notifications dependency and NotificationService

  Add to `pubspec.yaml`:
  ```yaml
  flutter_local_notifications: ^18.0.0
  timezone: ^0.9.0
  ```
  Run `flutter pub get`.

  **Android permissions** — add to `android/app/src/main/AndroidManifest.xml` (inside `<manifest>` tag):
  ```xml
  <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
  <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
  <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
  ```
  Also register the `flutter_local_notifications` boot receiver in `AndroidManifest.xml` as required by the package docs.

  Create `lib/services/notification_service.dart`:
  - Singleton `NotificationService`
  - `initialize()` — sets up Android/iOS channels; call from `main.dart` before `runApp()`
    - Initialize timezone: call `tz.initializeTimeZones()` and `tz.setLocalLocation(tz.getLocation(...))`  at the top of `initialize()` — required before any `zonedSchedule` call
    - Android channel: id=`reminders`, name=`Напоминания`, importance=max
  - `scheduleReminder(Reminder r)` — converts `Reminder` fields to a `zonedSchedule` or `periodicallyShow` call:
    - `once` / vaccination due: `zonedSchedule` at `nextDueDate` + `r.time`
    - `daily`: `periodicallyShow` with `RepeatInterval.daily` at scheduled time
    - `weekly` / `custom`: use `zonedSchedule` with `matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime` for each active weekday (schedule N notifications with id = reminderId * 10 + weekday)
  - `cancelReminder(int reminderId)` — cancels all notification ids for this reminder (base id and weekday variants)
  - `cancelAll()`
  - `requestPermissions()` — iOS only; on Android 13+ call `requestNotificationsPermission()`

  Modify `lib/main.dart`:
  - Make `main()` async: `Future<void> main() async { ... }`
  - Call `await NotificationService.instance.initialize()` before `runApp()`
  - Request permissions after first frame

  LOGGING REQUIREMENTS:
  - DEBUG: log each scheduled notification with id, title, trigger time
  - INFO: log initialize() success with platform
  - WARN: log when permission is denied
  - ERROR: log scheduling failures with full context

  Files: `pubspec.yaml`, `lib/services/notification_service.dart`, `lib/main.dart`, `android/app/src/main/AndroidManifest.xml`

- [x] Task 11: RemindersProvider

  Create `lib/providers/reminders_provider.dart` extending `ChangeNotifier`:
  - State: `List<Reminder> _reminders`, `bool _loading`, `String? _error`
  - `loadReminders(int profileId)` — load from DB filtered by profileId
  - `addReminder(Reminder r)` — insert to DB + call `NotificationService.scheduleReminder(r)` + reload
  - `updateReminder(Reminder r)` — update in DB + cancel old + reschedule + reload
  - `toggleActive(int id)` — flip `isActive`; cancel or reschedule notification accordingly
  - `deleteReminder(int id)` — delete from DB + cancel notification + reload
  - `rescheduleAll(int profileId)` — called on app start to re-register all active reminders (handles app reinstall)

  Register in `lib/app.dart` MultiProvider.

  LOGGING REQUIREMENTS:
  - DEBUG: log every operation with reminder id/title
  - INFO: log add/delete events
  - WARN: log when scheduleReminder fails (do not crash — reminder is saved but notification may not fire)
  - ERROR: log DB exceptions

  Files: `lib/providers/reminders_provider.dart`, `lib/app.dart`

<!-- Commit checkpoint: tasks 8–11 → feat: add reminders model, notifications service, and provider -->

### Phase 4: Reminders — UI

- [x] Task 12: Reminders list screen

  Create `lib/screens/reminders/reminders_screen.dart`:
  - `AppBar` title: "Напоминания"
  - Body: `Consumer<RemindersProvider>` → `ListView` of reminder cards
  - Each card shows: icon by type (pill/stethoscope/vaccine), title, schedule summary (e.g. "Ежедневно в 08:00", "Пн, Ср, Пт в 19:00", "12 апр. 2026 в 10:00"), active toggle (`Switch`)
  - Empty state: centered icon + "Нет напоминаний" text + "Добавить" button
  - FAB: "+" → opens add-reminder sheet
  - Swipe-to-delete with `Dismissible` (red background, trash icon)
  - Tap on card → opens edit-reminder sheet

  Add navigation to reminders screen from `HomeScreen` (e.g., bottom nav bar item or app bar action icon with bell).

  LOGGING REQUIREMENTS:
  - DEBUG: log screen mount and reminder count
  - DEBUG: log swipe-delete events with reminder id

  Files: `lib/screens/reminders/reminders_screen.dart`, `lib/screens/home/home_screen.dart`

- [x] Task 13: Add/edit reminder bottom sheet

  Create `lib/screens/reminders/reminder_form_sheet.dart` (shown via `showModalBottomSheet`):

  Fields:
  - Dropdown "Тип": Лекарство / Визит к врачу / Вакцинация
  - Text field "Название" (required)
  - Text field "Описание" (optional)
  - Dropdown "Расписание": Один раз / Ежедневно / Еженедельно / Выбрать дни
  - Time picker: "Время напоминания" (shows `TimePickerDialog`)
  - Weekday selector (shown only for Еженедельно/Выбрать дни): 7 toggle chips Пн Вт Ср Чт Пт Сб Вс
  - Date picker (shown only for Один раз / Вакцинация): "Дата"
  - Optional: dropdown to link to an existing record (shows records of matching category: prescriptions for medication, vaccinations for vaccination)
  - "Сохранить" button (validates: title non-empty, at least one weekday if weekly, date if once)

  LOGGING REQUIREMENTS:
  - DEBUG: log sheet open, mode (create/edit), and all field values on submit
  - WARN: log validation failures with specific field name

  Files: `lib/screens/reminders/reminder_form_sheet.dart`

- [x] Task 14: Schedule summary helpers and reminder type display names

  Create `lib/utils/reminder_utils.dart`:
  - `String scheduleDescription(Reminder r)` — human-readable Russian schedule string:
    - daily: "Ежедневно в HH:MM"
    - once: "DD MMM YYYY в HH:MM"
    - weekly (single day): "Каждый [день] в HH:MM"
    - custom: "[Пн, Ср, Пт] в HH:MM"
  - `String reminderTypeLabel(ReminderType t)` — "Лекарство" / "Визит к врачу" / "Вакцинация"
  - `IconData reminderTypeIcon(ReminderType t)` — pill/stethoscope/vaccine icon

  LOGGING REQUIREMENTS:
  - No logging needed for pure utility functions

  Files: `lib/utils/reminder_utils.dart`

- [x] Task 15: Upcoming reminders widget on HomeScreen

  Create `lib/widgets/upcoming_reminders_card.dart`:
  - Shows next 3 reminders sorted by next trigger time
  - Title: "Ближайшие напоминания"
  - Each row: type icon, title, schedule summary
  - "Все напоминания →" link at the bottom
  - Hidden if no active reminders

  Add `UpcomingRemindersCard` to `HomeScreen` body below the category grid.

  LOGGING REQUIREMENTS:
  - DEBUG: log how many upcoming reminders are displayed

  Files: `lib/widgets/upcoming_reminders_card.dart`, `lib/screens/home/home_screen.dart`

<!-- Commit checkpoint: tasks 12–15 → feat: implement reminders UI with full scheduling -->

### Phase 5: Local Backup

- [x] Task 16: Add archive dependency and BackupService skeleton

  Add to `pubspec.yaml`:
  ```yaml
  archive: ^3.6.0
  file_picker: ^8.1.0   # for picking .zip on import (may already be present; check first)
  path_provider: ^2.0.0  # likely already present
  ```
  Run `flutter pub get`.

  Create `lib/services/backup_service.dart` — singleton `BackupService`:

  Constants:
  - `_dbFileName = 'moe_zdorovye.db'`
  - `_attachmentsDirName = 'attachments'` (or whatever directory FileService uses)

  Skeleton with method signatures and logging stubs:
  - `Future<File> exportBackup()` — returns path to created `.zip`
  - `Future<void> importBackup(File zipFile)` — restores DB + files
  - Helper `Future<Directory> _getBackupDir()` — returns `<Documents>/МоёЗдоровье/backups/`

  LOGGING REQUIREMENTS:
  - INFO: log method start and completion for export/import
  - DEBUG: log file paths at each step
  - ERROR: log and rethrow all IO exceptions with context

  Files: `pubspec.yaml`, `lib/services/backup_service.dart`

- [x] Task 17: Implement export and import in BackupService

  **Export (`exportBackup()`):**
  1. Close (or checkpoint) the SQLite DB via `DatabaseHelper().database` — call `db.execute('PRAGMA wal_checkpoint(FULL)')` to flush WAL (use `DatabaseHelper()` factory, NOT `.instance` — the existing singleton uses the factory constructor pattern)
  2. Read DB file bytes from `join(await getDatabasesPath(), _dbFileName)` — **NOT** from `getApplicationDocumentsDirectory()`. The SQLite DB is stored in the platform databases directory (returned by `sqflite`'s `getDatabasesPath()`), which is different from the app documents directory on Android.
  3. Read all attachment files recursively from `join((await getApplicationDocumentsDirectory()).path, _attachmentsDirName)/`
  4. Create an `Archive` object; add each file as `ArchiveFile`
  5. Encode with `ZipEncoder`
  6. Write to `<_getBackupDir()>/backup_<timestamp>.zip`
  7. Return the `File`

  **Import (`importBackup(File zipFile)`):**
  1. Warn user (caller is responsible for showing confirmation dialog before calling this)
  2. Close the DB connection: `await DatabaseHelper().close()` (using the factory constructor)
  3. Decode zip with `ZipDecoder`
  4. Restore DB file to `<app documents>/<_dbFileName>` (overwrite)
  5. Restore all attachment files to their original relative paths under `<app documents>/`
  6. Re-open DB: `await DatabaseHelper().database` (re-triggers singleton init via factory constructor)
  7. Reload all providers (caller responsibility — return a signal or use a callback)

  Add `close()` method to `DatabaseHelper` that nulls `_db` and calls `db.close()` (field is `_db`, not `_database` — check `database_helper.dart`)

  Also update `_dbPath` helper in `BackupService` to use `getDatabasesPath()` from sqflite:
  ```dart
  Future<String> _getDbPath() async => join(await getDatabasesPath(), _dbFileName);
  ```

  LOGGING REQUIREMENTS:
  - INFO: log export start, file count, total size, output path
  - INFO: log import start, file count, DB file presence in archive
  - DEBUG: log each file added to archive (name + size)
  - DEBUG: log each file restored during import
  - WARN: log if WAL checkpoint times out or fails (proceed anyway)
  - ERROR: log and rethrow any failure

  Files: `lib/services/backup_service.dart`, `lib/database/database_helper.dart`

- [x] Task 18: Auto-backup settings

  Add persistent auto-backup preferences using `shared_preferences`:
  - Add `shared_preferences` to `pubspec.yaml` if not already present
  - Create `lib/services/settings_service.dart` — simple singleton wrapping `SharedPreferences`:
    - `bool autoBackupEnabled` (default false)
    - `String autoBackupFrequency` — `'daily'` | `'weekly'` (default `'weekly'`)
    - `DateTime? lastAutoBackupAt`
    - Getters/setters that persist immediately

  Trigger auto-backup in `main.dart` after providers load:
  - If `autoBackupEnabled && now - lastAutoBackupAt > frequency` → call `BackupService.exportBackup()` silently in background
  - On success: update `lastAutoBackupAt`, log INFO
  - On failure: log ERROR, do not crash app

  LOGGING REQUIREMENTS:
  - INFO: log auto-backup trigger and outcome
  - DEBUG: log when auto-backup is skipped with reason (disabled, too soon)

  Files: `pubspec.yaml`, `lib/services/settings_service.dart`, `lib/main.dart`

- [x] Task 19: Backup/restore UI in SharingScreen

  Modify `lib/screens/sharing/sharing_screen.dart` (or create a new "Резервная копия" section within it):

  **"Резервная копия" section:**
  - "Создать резервную копию" button → calls `BackupService.exportBackup()` → shows share sheet (`Share.shareXFiles([...])`) so user can save to Files / send via messenger
  - "Восстановить из файла" button → opens `FilePicker` (filter: `.zip`) → shows confirmation dialog ("Восстановление заменит все текущие данные. Продолжить?") → calls `BackupService.importBackup()` → reloads all providers → shows success snackbar
  - Progress indicator (CircularProgressIndicator) shown during export/import

  **"Автоматическое резервирование" section:**
  - `SwitchListTile`: "Автобекап" with `SettingsService.autoBackupEnabled`
  - `ListTile` dropdown (shown when enabled): "Частота" — Ежедневно / Еженедельно
  - `ListTile`: "Последний бекап: [date]" (read-only)

  Show error snackbars on failure with Russian messages.
  All labels in Russian.

  LOGGING REQUIREMENTS:
  - DEBUG: log button taps and which operation started
  - INFO: log completion of export/import with file size or record count
  - ERROR: log failures shown to user

  Files: `lib/screens/sharing/sharing_screen.dart`

<!-- Commit checkpoint: tasks 16–19 → feat: implement local backup export, import, and auto-backup -->
