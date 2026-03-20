# МоеЗдоровье — Project Specification

## Overview
Android mobile app (Flutter) for storing and managing personal medical data.
All data stored locally (SQLite/Hive). No backend. No auth.
Russian language only (for now). iOS planned for future.

## Design
- Modern, minimalist UI
- Medical/health color palette: teal/green tones (#00897B primary, #B2DFDB light accent)
- Material Design 3
- Clean typography, generous whitespace

## Data Categories

### 1. Blood/Urine Tests (Анализы)
- Title, date, lab name (optional)
- Attach files: photo, PDF
- Notes field

### 2. Medical Imaging (Снимки)
- Type: X-ray, CT, MRI, Ultrasound
- Body area
- Date, clinic (optional)
- Attach images/files

### 3. Prescriptions (Рецепты/Назначения)
- Doctor name, specialty
- Date
- Medication list or free text
- Attach photo/PDF

### 4. Vaccinations (Вакцинации)
- Vaccine name
- Date
- Dose number (optional)
- Clinic/doctor (optional)
- Next dose date (optional)

### 5. Chronic Conditions & Allergies (Хронические заболевания и аллергии)
- Condition/allergy name
- Diagnosis date (optional)
- Severity (optional)
- Notes

### 6. Manual Measurements (Показатели здоровья)
- Type: blood pressure, weight, temperature, blood sugar, heart rate
- Value + unit (auto-set per type)
- Date & time
- Notes (optional)
- Show history chart per measurement type

## Core Features

### Home Screen
- Dashboard with category cards showing count of records
- Quick-add FAB button
- Recent records list

### Record Management
- CRUD for all categories
- Attach multiple files (photos from camera/gallery, PDFs)
- File viewer (image zoom, PDF viewer)
- Search across all records
- Filter by date range, category
- Sort by date

### QR Code Sharing (Doctor Mode)
- User selects specific records to share
- App generates QR code containing a local HTTP server URL (WiFi)
- Starts a temporary local HTTP server on the device
- Doctor scans QR → opens browser → sees selected records
- Read-only view for doctor
- Doctor can view/download attached files
- Server auto-stops when user closes sharing screen
- Both devices must be on the same WiFi network

### Local Storage
- SQLite (sqflite package) for structured data
- Files stored in app's local directory
- No cloud sync (for now)

## Technical Stack
- **Framework:** Flutter 3.x
- **Language:** Dart
- **Local DB:** sqflite (SQLite)
- **State Management:** Provider or Riverpod
- **File handling:** image_picker, file_picker
- **QR generation:** qr_flutter
- **QR scanning:** mobile_scanner
- **Local HTTP server:** shelf (dart package)
- **Charts:** fl_chart
- **PDF viewing:** flutter_pdfview
- **Image viewing:** photo_view

## Project Structure
```
lib/
  main.dart
  app.dart
  theme/
    app_theme.dart
    colors.dart
  models/
    record.dart
    category.dart
    measurement.dart
  database/
    database_helper.dart
    tables.dart
  screens/
    home/
    records/
    add_record/
    record_detail/
    measurements/
    sharing/
    settings/
  widgets/
    category_card.dart
    record_list_item.dart
    file_attachment.dart
    measurement_chart.dart
  services/
    file_service.dart
    sharing_service.dart
    qr_service.dart
  utils/
    constants.dart
    formatters.dart
```

## Non-functional Requirements
- Min Android SDK: 21 (Android 5.0)
- App size: < 30MB
- Smooth animations (60fps)
- Proper error handling for file operations
- Graceful handling of large files

## Out of Scope (for now)
- User authentication
- Cloud sync / backup
- iOS build
- Multi-language support
- Push notifications
- Data export (PDF reports)
