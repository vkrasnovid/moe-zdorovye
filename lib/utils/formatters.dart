import 'package:intl/intl.dart';

class AppFormatters {
  static final _dateFormat = DateFormat('dd.MM.yyyy', 'ru');
  static final _dateTimeFormat = DateFormat('dd.MM.yyyy HH:mm', 'ru');
  static final _timeFormat = DateFormat('HH:mm', 'ru');

  static String formatDate(DateTime date) => _dateFormat.format(date);
  static String formatDateTime(DateTime date) => _dateTimeFormat.format(date);
  static String formatTime(DateTime date) => _timeFormat.format(date);

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes Б';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} КБ';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} МБ';
  }
}
