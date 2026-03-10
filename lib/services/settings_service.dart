import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';
import '../models/ride_log.dart';
import '../models/week_plan.dart';

class SettingsService {
  static const _settingsKey = 'app_settings';
  static const _weekPlanKey = 'week_plan';
  static const _goingOutAfterWorkKey = 'going_out_after_work';
  static const _goingOutAfterWorkDateKey = 'going_out_after_work_date';
  static const _rideLogKey = 'ride_log';

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_settingsKey);
    if (json == null) return const AppSettings();
    try {
      return AppSettings.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return const AppSettings();
    }
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  Future<WeekPlan?> loadWeekPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_weekPlanKey);
    if (json == null) return null;
    try {
      final plan = WeekPlan.fromJson(jsonDecode(json) as Map<String, dynamic>);
      final expectedKey = WeekPlan.mondayKey(DateTime.now());
      if (plan.weekStartDate != expectedKey) return null;
      return plan;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveWeekPlan(WeekPlan plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_weekPlanKey, jsonEncode(plan.toJson()));
  }

  Future<WeekPlan> getOrCreateWeekPlan(AppSettings settings) async {
    final existing = await loadWeekPlan();
    if (existing != null) return existing;
    return WeekPlan.fromTypical(
      forDate: DateTime.now(),
      monday: settings.typicalMonday,
      tuesday: settings.typicalTuesday,
      thursday: settings.typicalThursday,
    );
  }

  Future<bool?> getGoingOutAfterWork() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString(_goingOutAfterWorkDateKey);
    if (dateStr == null) return null;
    final today = DateTime.now();
    final saved = DateTime.parse(dateStr);
    if (saved.year == today.year &&
        saved.month == today.month &&
        saved.day == today.day) {
      return prefs.getBool(_goingOutAfterWorkKey);
    }
    return null;
  }

  Future<void> setGoingOutAfterWork(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    await prefs.setBool(_goingOutAfterWorkKey, value);
    await prefs.setString(_goingOutAfterWorkDateKey, today.toIso8601String());
  }

  Future<RideLog> loadRideLog() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_rideLogKey);
    if (json == null) return const RideLog();
    try {
      return RideLog.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return const RideLog();
    }
  }

  Future<void> saveRideLog(RideLog log) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_rideLogKey, jsonEncode(log.toJson()));
  }
}
