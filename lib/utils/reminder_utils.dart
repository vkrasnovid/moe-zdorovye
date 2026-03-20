import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/reminder.dart';

const _weekdayNames = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
const _weekdayFull = ['понедельник', 'вторник', 'среду', 'четверг', 'пятницу', 'субботу', 'воскресенье'];

String scheduleDescription(Reminder r) {
  final timeStr = _formatTime(r.timeMinutes);
  switch (r.scheduleType) {
    case ScheduleType.daily:
      return 'Ежедневно в $timeStr';
    case ScheduleType.once:
      if (r.nextDueDate == null) return 'Один раз в $timeStr';
      final dateStr = DateFormat('d MMM yyyy', 'ru').format(r.nextDueDate!);
      return '$dateStr в $timeStr';
    case ScheduleType.weekly:
      final days = _activeDays(r.weekdaysMask);
      if (days.length == 1) {
        return 'Каждый ${_weekdayFull[days.first - 1]} в $timeStr';
      }
      return '${days.map((d) => _weekdayNames[d - 1]).join(', ')} в $timeStr';
    case ScheduleType.custom:
      final days = _activeDays(r.weekdaysMask);
      if (days.isEmpty) return 'В $timeStr';
      return '${days.map((d) => _weekdayNames[d - 1]).join(', ')} в $timeStr';
  }
}

String reminderTypeLabel(ReminderType t) {
  switch (t) {
    case ReminderType.medication:
      return 'Лекарство';
    case ReminderType.doctorVisit:
      return 'Визит к врачу';
    case ReminderType.vaccination:
      return 'Вакцинация';
  }
}

IconData reminderTypeIcon(ReminderType t) {
  switch (t) {
    case ReminderType.medication:
      return Icons.medication_outlined;
    case ReminderType.doctorVisit:
      return Icons.medical_services_outlined;
    case ReminderType.vaccination:
      return Icons.vaccines_outlined;
  }
}

String _formatTime(int minutes) {
  final h = (minutes ~/ 60).toString().padLeft(2, '0');
  final m = (minutes % 60).toString().padLeft(2, '0');
  return '$h:$m';
}

List<int> _activeDays(int mask) {
  final days = <int>[];
  for (int i = 1; i <= 7; i++) {
    if (mask & (1 << (i - 1)) != 0) days.add(i);
  }
  return days;
}
