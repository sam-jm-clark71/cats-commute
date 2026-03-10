import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import '../models/app_settings.dart';
import '../models/week_plan.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _morningId    = 1;
  static const int _sundayId     = 10;
  static const int _eveningBase  = 20; // +0..6 for day offset

  static Future<void> initialize() async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/London'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);
  }

  static Future<void> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
  }

  /// Schedule all upcoming notifications based on current settings + week plan.
  static Future<void> scheduleAll({
    required AppSettings settings,
    required WeekPlan? weekPlan,
  }) async {
    await _plugin.cancelAll();

    final now = DateTime.now();

    // 1. Sunday evening → weekly planning
    await _scheduleSundayPlanning(now, settings);

    // 2. Morning notification on office days (today or future this week)
    if (weekPlan != null) {
      await _scheduleMorningNotifs(settings, weekPlan, now);
      await _scheduleEveningCheckIns(settings, weekPlan, now);
    }
  }

  // ── Sunday weekly planning ───────────────────────────────────────────────

  static Future<void> _scheduleSundayPlanning(DateTime now, AppSettings settings) async {
    int daysUntilSunday = DateTime.sunday - now.weekday;
    if (daysUntilSunday <= 0) daysUntilSunday += 7;

    if (now.weekday == DateTime.sunday && now.hour < settings.eveningNotifHour) {
      daysUntilSunday = 0;
    }

    final sunday = now.add(Duration(days: daysUntilSunday));
    final notifTime = tz.TZDateTime(
      tz.local,
      sunday.year, sunday.month, sunday.day,
      settings.eveningNotifHour, settings.eveningNotifMinute,
    );

    if (notifTime.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      _sundayId,
      '🗓️ New week coming up!',
      "Tap to let me know which days you're in the office next week",
      notifTime,
      _details(channelId: 'evening', channelName: 'Evening check-ins'),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ── Morning notifications ─────────────────────────────────────────────────

  static Future<void> _scheduleMorningNotifs(
    AppSettings settings,
    WeekPlan weekPlan,
    DateTime now,
  ) async {
    // Only schedule morning notif for today if it's an office day
    if (!weekPlan.isOfficeDay(now)) return;

    final notifTime = tz.TZDateTime(
      tz.local,
      now.year, now.month, now.day,
      settings.morningNotifHour,
      settings.morningNotifMinute,
    );

    if (notifTime.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      _morningId,
      "🚲 Time to check your commute",
      "Open Cat's Commute for today's recommendation",
      notifTime,
      _details(channelId: 'morning', channelName: 'Morning commute'),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ── Evening check-ins (night before each office day) ─────────────────────

  static Future<void> _scheduleEveningCheckIns(
    AppSettings settings,
    WeekPlan weekPlan,
    DateTime now,
  ) async {
    for (int i = 1; i <= 6; i++) {
      final candidate = now.add(Duration(days: i));
      if (!weekPlan.isOfficeDay(candidate)) continue;

      final eve = now.add(Duration(days: i - 1));
      final notifTime = tz.TZDateTime(
        tz.local,
        eve.year, eve.month, eve.day,
        settings.eveningNotifHour, settings.eveningNotifMinute,
      );

      if (notifTime.isBefore(tz.TZDateTime.now(tz.local))) continue;

      await _plugin.zonedSchedule(
        _eveningBase + i,
        '🌙 Heads up for tomorrow',
        "Are you still heading into the office tomorrow?",
        notifTime,
        _details(channelId: 'evening', channelName: 'Evening check-ins'),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  static NotificationDetails _details({
    required String channelId,
    required String channelName,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    );
  }
}
