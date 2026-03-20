import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum ReminderType { medication, doctorVisit, vaccination }

enum ScheduleType { once, daily, weekly, custom }

class Reminder {
  final int? id;
  final int profileId;
  final ReminderType type;
  final String title;
  final String? body;
  final ScheduleType scheduleType;
  final int timeMinutes; // minutes since midnight
  final int weekdaysMask; // bitmask Mon=1 ... Sun=64
  final DateTime? nextDueDate;
  final bool isActive;
  final int? linkedRecordId;
  final DateTime createdAt;

  Reminder({
    this.id,
    required this.profileId,
    required this.type,
    required this.title,
    this.body,
    required this.scheduleType,
    required this.timeMinutes,
    this.weekdaysMask = 0,
    this.nextDueDate,
    this.isActive = true,
    this.linkedRecordId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  TimeOfDay get time => TimeOfDay(hour: timeMinutes ~/ 60, minute: timeMinutes % 60);

  Reminder copyWith({
    int? id,
    int? profileId,
    ReminderType? type,
    String? title,
    String? body,
    ScheduleType? scheduleType,
    int? timeMinutes,
    int? weekdaysMask,
    DateTime? nextDueDate,
    bool? isActive,
    int? linkedRecordId,
    DateTime? createdAt,
  }) {
    return Reminder(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      scheduleType: scheduleType ?? this.scheduleType,
      timeMinutes: timeMinutes ?? this.timeMinutes,
      weekdaysMask: weekdaysMask ?? this.weekdaysMask,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      isActive: isActive ?? this.isActive,
      linkedRecordId: linkedRecordId ?? this.linkedRecordId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    debugPrint('[Reminder.toMap] DEBUG: serializing reminder id=$id title=$title type=${type.name}');
    return {
      if (id != null) 'id': id,
      'profile_id': profileId,
      'type': type.name,
      'title': title,
      'body': body,
      'schedule_type': scheduleType.name,
      'time_minutes': timeMinutes,
      'weekdays_mask': weekdaysMask,
      'next_due_date': nextDueDate?.millisecondsSinceEpoch,
      'is_active': isActive ? 1 : 0,
      'linked_record_id': linkedRecordId,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    final reminder = Reminder(
      id: map['id'] as int?,
      profileId: map['profile_id'] as int,
      type: ReminderType.values.firstWhere((e) => e.name == map['type']),
      title: map['title'] as String,
      body: map['body'] as String?,
      scheduleType: ScheduleType.values.firstWhere((e) => e.name == map['schedule_type']),
      timeMinutes: map['time_minutes'] as int,
      weekdaysMask: map['weekdays_mask'] as int,
      nextDueDate: map['next_due_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['next_due_date'] as int)
          : null,
      isActive: (map['is_active'] as int) == 1,
      linkedRecordId: map['linked_record_id'] as int?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
    debugPrint('[Reminder.fromMap] DEBUG: deserialized reminder id=${reminder.id} title=${reminder.title}');
    return reminder;
  }
}
