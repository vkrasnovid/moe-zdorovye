import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../models/reminder.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static NotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      debugPrint('[NotificationService] DEBUG: already initialized, skipping');
      return;
    }
    debugPrint('[NotificationService] INFO: initialize() start');
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(initSettings);
    _initialized = true;
    debugPrint('[NotificationService] INFO: initialize() success platform=${defaultTargetPlatform.name}');

    // Create Android notification channel
    const channel = AndroidNotificationChannel(
      'reminders',
      'Напоминания',
      importance: Importance.max,
      description: 'Напоминания о лекарствах, визитах и вакцинациях',
    );
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(channel);
    debugPrint('[NotificationService] DEBUG: Android channel created id=reminders');
  }

  Future<void> requestPermissions() async {
    debugPrint('[NotificationService] DEBUG: requestPermissions entry');
    final ios = _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (ios != null) {
      final granted = await ios.requestPermissions(alert: true, badge: true, sound: true);
      if (granted == false) {
        debugPrint('[NotificationService] WARN: iOS notification permission denied');
      }
    }
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      if (granted == false) {
        debugPrint('[NotificationService] WARN: Android notification permission denied');
      }
    }
  }

  Future<void> scheduleReminder(Reminder r) async {
    if (r.id == null) return;
    debugPrint('[NotificationService] DEBUG: scheduleReminder id=${r.id} title=${r.title} scheduleType=${r.scheduleType.name}');

    final notifDetails = NotificationDetails(
      android: const AndroidNotificationDetails(
        'reminders',
        'Напоминания',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    try {
      switch (r.scheduleType) {
        case ScheduleType.daily:
          await _plugin.periodicallyShow(
            r.id!,
            r.title,
            r.body,
            RepeatInterval.daily,
            notifDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          );
          debugPrint('[NotificationService] DEBUG: scheduled daily notification id=${r.id}');

        case ScheduleType.once:
          if (r.nextDueDate == null) {
            debugPrint('[NotificationService] WARN: once reminder id=${r.id} has no nextDueDate, skipping');
            return;
          }
          final scheduled = tz.TZDateTime.from(
            r.nextDueDate!.copyWith(hour: r.time.hour, minute: r.time.minute, second: 0),
            tz.local,
          );
          await _plugin.zonedSchedule(
            r.id!,
            r.title,
            r.body,
            scheduled,
            notifDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
          debugPrint('[NotificationService] DEBUG: scheduled once notification id=${r.id} at=$scheduled');

        case ScheduleType.weekly:
        case ScheduleType.custom:
          // Schedule one notification per active weekday
          for (int weekday = 1; weekday <= 7; weekday++) {
            final bit = 1 << (weekday - 1);
            if (r.weekdaysMask & bit == 0) continue;
            final notifId = r.id! * 10 + weekday;
            await _plugin.zonedSchedule(
              notifId,
              r.title,
              r.body,
              _nextInstanceOfWeekday(weekday, r.time.hour, r.time.minute),
              notifDetails,
              matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
              uiLocalNotificationDateInterpretation:
                  UILocalNotificationDateInterpretation.absoluteTime,
            );
            debugPrint('[NotificationService] DEBUG: scheduled weekly notification id=$notifId weekday=$weekday');
          }
      }
    } catch (e, st) {
      debugPrint('[NotificationService] ERROR: scheduleReminder failed id=${r.id}: $e\n$st');
    }
  }

  Future<void> cancelReminder(int reminderId) async {
    debugPrint('[NotificationService] DEBUG: cancelReminder id=$reminderId');
    // Cancel base notification
    await _plugin.cancel(reminderId);
    // Cancel all weekday variants
    for (int weekday = 1; weekday <= 7; weekday++) {
      await _plugin.cancel(reminderId * 10 + weekday);
    }
  }

  Future<void> cancelAll() async {
    debugPrint('[NotificationService] DEBUG: cancelAll');
    await _plugin.cancelAll();
  }

  tz.TZDateTime _nextInstanceOfWeekday(int weekday, int hour, int minute) {
    var now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    // weekday: 1=Mon...7=Sun, DateTime weekday: 1=Mon...7=Sun (compatible)
    while (scheduled.weekday != weekday || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}

extension _DateTimeHMS on DateTime {
  DateTime copyWith({int? hour, int? minute, int? second}) {
    return DateTime(year, month, day, hour ?? this.hour, minute ?? this.minute, second ?? this.second);
  }
}
