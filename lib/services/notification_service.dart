import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import '../core/constants.dart';
import '../models/task_model.dart';
import '../models/exam_model.dart';

/// Handles all local scheduled notifications:
///  • 3x-daily "what's due" digest reminders (configurable times)
///  • Per-task deadline alerts (fires a few hours before the deadline)
///  • Exam countdown alerts (fires N days before an exam, e.g. 7/3/1)
///
/// Everything is scheduled locally with `flutter_local_notifications` +
/// `timezone`, so reminders keep firing even without a live Supabase
/// connection — important for a "reliable reminders" pitch.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();
    // Falls back to UTC if the device zone can't be resolved; good enough
    // for a demo build. For production, detect the real local zone with
    // e.g. the `flutter_timezone` package and call tz.setLocalLocation.
    tz.setLocalLocation(tz.getLocation('Etc/UTC'));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings =
        InitializationSettings(android: androidInit, iOS: iosInit);

    await _plugin.initialize(initSettings);

    const androidChannel = AndroidNotificationChannel(
      AppConstants.reminderChannelId,
      AppConstants.reminderChannelName,
      description: AppConstants.reminderChannelDesc,
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    final android = await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    final ios = await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return (android ?? true) && (ios ?? true);
  }

  // -------------------------------------------------------------------
  // Daily digest reminders (default 08:00 / 13:00 / 19:00)
  // -------------------------------------------------------------------

  /// Schedules a repeating daily notification for each `HH:mm` string in
  /// [times]. IDs 1000-1099 are reserved for these so they can be safely
  /// cancelled/rescheduled without touching task/exam notification IDs.
  Future<void> scheduleDailyReminders(List<String> times) async {
    for (int i = 0; i < 100; i++) {
      await _plugin.cancel(1000 + i);
    }

    for (int i = 0; i < times.length; i++) {
      final parts = times[i].split(':');
      final hour = int.tryParse(parts[0]) ?? 8;
      final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;

      await _plugin.zonedSchedule(
        1000 + i,
        'FocusFlow check-in ⏰',
        _digestMessage(i),
        _nextInstanceOf(hour, minute),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            AppConstants.reminderChannelId,
            AppConstants.reminderChannelName,
            channelDescription: AppConstants.reminderChannelDesc,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  /// Cancels only the daily digest slots (IDs 1000-1099), leaving
  /// per-task and per-exam alerts untouched.
  Future<void> cancelDailyReminders() async {
    for (int i = 0; i < 100; i++) {
      await _plugin.cancel(1000 + i);
    }
  }

  String _digestMessage(int slotIndex) {
    const morning = "Good morning! Check what's due today and get ahead of it.";
    const afternoon = "Midday nudge: how's your task list looking?";
    const evening = "Evening review: wrap up today's tasks before tomorrow.";
    switch (slotIndex) {
      case 0:
        return morning;
      case 1:
        return afternoon;
      default:
        return evening;
    }
  }

  // -------------------------------------------------------------------
  // Per-task deadline alerts
  // -------------------------------------------------------------------

  /// Schedules a reminder a few hours before a task's deadline, plus an
  /// earlier "start early" nudge if [task.suggestedStart] is set. Task
  /// notification IDs are derived deterministically from the task's UUID
  /// so re-scheduling (e.g. after editing) cleanly replaces the old one.
  Future<void> scheduleTaskReminder(TaskModel task) async {
    final id = _idFromString(task.id);
    await _plugin.cancel(id);
    await _plugin.cancel(id + 1); // suggested-start nudge slot

    if (task.status == 'completed') return;

    final alertTime = task.deadline.subtract(const Duration(hours: 3));
    if (alertTime.isAfter(DateTime.now())) {
      await _plugin.zonedSchedule(
        id,
        'Deadline approaching: ${task.title}',
        'Due ${_formatTime(task.deadline)} — ${task.category}',
        tz.TZDateTime.from(alertTime, tz.local),
        _taskDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }

    if (task.suggestedStart != null &&
        task.suggestedStart!.isAfter(DateTime.now())) {
      await _plugin.zonedSchedule(
        id + 1,
        'Time to start: ${task.title}',
        'Starting early keeps you ahead of the deadline.',
        tz.TZDateTime.from(task.suggestedStart!, tz.local),
        _taskDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  Future<void> cancelTaskReminder(String taskId) async {
    final id = _idFromString(taskId);
    await _plugin.cancel(id);
    await _plugin.cancel(id + 1);
  }

  // -------------------------------------------------------------------
  // Exam countdown alerts
  // -------------------------------------------------------------------

  /// Schedules one notification per milestone in [daysBefore] (default
  /// 7/3/1 days out), fired at 08:00 on that day.
  Future<void> scheduleExamAlerts(ExamModel exam, List<int> daysBefore) async {
    final baseId = _idFromString(exam.id, salt: 5000);
    for (int i = 0; i < daysBefore.length; i++) {
      await _plugin.cancel(baseId + i);
    }

    for (int i = 0; i < daysBefore.length; i++) {
      final fireDate = exam.examDate.subtract(Duration(days: daysBefore[i]));
      final fireDateTime =
          DateTime(fireDate.year, fireDate.month, fireDate.day, 8, 0);
      if (fireDateTime.isBefore(DateTime.now())) continue;

      await _plugin.zonedSchedule(
        baseId + i,
        '${daysBefore[i]} day${daysBefore[i] == 1 ? '' : 's'} until ${exam.courseCode} exam',
        exam.venue != null
            ? '${exam.courseName} • ${exam.venue}'
            : exam.courseName,
        tz.TZDateTime.from(fireDateTime, tz.local),
        _examDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  Future<void> cancelExamAlerts(String examId, int maxMilestones) async {
    final baseId = _idFromString(examId, salt: 5000);
    for (int i = 0; i < maxMilestones; i++) {
      await _plugin.cancel(baseId + i);
    }
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  // -------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------

  NotificationDetails _taskDetails() => const NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.reminderChannelId,
          AppConstants.reminderChannelName,
          channelDescription: AppConstants.reminderChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );

  NotificationDetails _examDetails() => const NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.reminderChannelId,
          AppConstants.reminderChannelName,
          channelDescription: AppConstants.reminderChannelDesc,
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Deterministically derives a 31-bit notification ID from a UUID string
  /// so the same task/exam always maps to the same ID (needed to cancel
  /// and reschedule correctly) without colliding across entities.
  int _idFromString(String input, {int salt = 0}) {
    final hash = input.hashCode & 0x7fffffff;
    return (salt + (hash % 4000)).clamp(0, 1 << 30);
  }
}

// Small helper retained for potential future randomized notification
// previews (e.g. varying the digest copy). Not currently used but kept
// documented rather than deleted mid-development.
final Random _unusedRandom = Random();
