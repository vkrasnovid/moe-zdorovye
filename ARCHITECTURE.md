# Архитектура МоёЗдоровье

## Слои приложения

```
┌─────────────────────────────────────┐
│              UI (Screens)           │  ← Flutter-виджеты, только отображение
├─────────────────────────────────────┤
│          Providers (State)          │  ← ChangeNotifier, бизнес-логика
├─────────────────────────────────────┤
│        DatabaseHelper (DAO)         │  ← Обёртка над sqflite, SQL-запросы
├─────────────────────────────────────┤
│          SQLite (sqflite)           │  ← Локальное хранилище на устройстве
└─────────────────────────────────────┘
```

### UI → Provider

Экраны получают данные через `context.watch<Provider>()` / `context.read<Provider>()`. Прямых обращений к БД из виджетов нет.

### Provider → Database

`RecordsProvider` и `MeasurementsProvider` вызывают методы `DatabaseHelper` и оповещают виджеты через `notifyListeners()`. `DatabaseHelper` реализован как синглтон.

### Файлы

`FileService` копирует выбранные пользователем файлы в приватную директорию приложения (`getApplicationDocumentsDirectory()`). В БД хранятся только абсолютные пути к файлам.

---

## Схема базы данных

База данных: `moe_zdorovye.db` (SQLite, версия 1).

### Таблица `records`

| Колонка | Тип | Описание |
|---|---|---|
| `id` | INTEGER PK AUTOINCREMENT | Идентификатор |
| `category` | TEXT NOT NULL | Категория: `tests`, `imaging`, `prescriptions`, `vaccinations`, `conditions` |
| `title` | TEXT NOT NULL | Заголовок записи |
| `date` | INTEGER NOT NULL | Дата события (Unix ms) |
| `notes` | TEXT | Произвольные заметки |
| `attachments` | TEXT | JSON-массив путей к файлам, напр. `["/data/.../file.jpg"]` |
| `extra_data` | TEXT | JSON-объект с полями, специфичными для категории |
| `created_at` | INTEGER NOT NULL | Дата создания записи (Unix ms) |

**Поля `extra_data` по категориям:**

| Категория | Ключи |
|---|---|
| `tests` | `lab` |
| `imaging` | `type`, `body_area`, `clinic` |
| `prescriptions` | `doctor_name`, `specialty`, `medications` |
| `vaccinations` | `vaccine`, `dose`, `clinic`, `next_dose` |
| `conditions` | `severity` |

### Таблица `measurements`

| Колонка | Тип | Описание |
|---|---|---|
| `id` | INTEGER PK AUTOINCREMENT | Идентификатор |
| `type` | TEXT NOT NULL | Тип: `bloodPressure`, `weight`, `temperature`, `bloodSugar`, `heartRate` |
| `value` | REAL NOT NULL | Основное значение |
| `value2` | REAL | Второе значение (только для давления — диастолическое) |
| `date_time` | INTEGER NOT NULL | Дата и время измерения (Unix ms) |
| `notes` | TEXT | Заметки |

---

## QR-шеринг

Механизм передачи данных врачу без интернета и без облака.

```
Пациент (устройство)                     Врач (браузер)
─────────────────────                    ───────────────
1. Выбирает записи
2. SharingService.start()
   └─ shelf запускает HTTP-сервер
      на порту 8080
3. QrService строит URL:
   http://<WiFi-IP>:8080
4. qr_flutter рисует QR-код
                                  5. Сканирует QR-код
                                  6. Браузер GET http://<IP>:8080
                               ←─ 7. Сервер отдаёт HTML-страницу
                                     с записями (только чтение)
                               ←─ 8. GET /files/<name> — скачать файл
5. Закрывает экран шеринга
   └─ SharingService.stop()
      └─ HttpServer.close(force: true)
```

**Детали реализации:**

- `SharingService` (`shelf` + `shelf_router`) обрабатывает два маршрута:
  - `GET /` — возвращает сгенерированный HTML с выбранными записями.
  - `GET /files/<filename>` — отдаёт прикреплённый файл по имени с корректным MIME-типом.
- HTML-страница генерируется на Dart в методе `_buildHtml()` с экранированием всех пользовательских данных.
- Сервер слушает на `InternetAddress.anyIPv4` (все интерфейсы), IP для QR берётся через `NetworkInfo().getWifiIP()`.
- Оба устройства обязаны быть в одной Wi-Fi-сети.

---

## Управление состоянием

Используется пакет `provider` (паттерн `ChangeNotifier`).

| Provider | Ответственность |
|---|---|
| `RecordsProvider` | Список медицинских записей, фильтрация, поиск, счётчики по категориям |
| `MeasurementsProvider` | Список измерений показателей здоровья, фильтрация по типу |

Оба провайдера регистрируются в корне дерева виджетов через `MultiProvider` в `app.dart`.
