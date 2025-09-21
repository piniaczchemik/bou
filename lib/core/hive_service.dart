// lib/core/hive_service.dart
import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static const String boxUser = 'user_profile';
  static const String boxMeals = 'meal_targets';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox(boxUser),
      Hive.openBox(boxMeals),
    ]);
  }

  // ---------- Dates ----------
  static String _dkey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DateTime weekStartMonday(DateTime d) {
    final wd = d.weekday; // Mon=1..Sun=7
    return DateTime(d.year, d.month, d.day).subtract(Duration(days: wd - 1));
  }

  // ---------- User profile ----------
  static int getBaselineDailyKcal({int fallback = 2600}) {
    final b = Hive.box(boxUser);
    return (b.get('baselineDailyKcal') as int?) ?? fallback;
  }

  static Future<void> setBaselineDailyKcal(int kcal) async {
    final b = Hive.box(boxUser);
    await b.put('baselineDailyKcal', kcal);
  }

  static int getWeeklyBonusKcalSoFar(DateTime now) {
    final b = Hive.box(boxUser);
    final startStr = b.get('weeklyBonusStart') as String?;
    final storedStart = startStr != null ? DateTime.parse(startStr) : null;
    final thisMonday = weekStartMonday(now);

    if (storedStart == null || storedStart != thisMonday) {
      b.put('weeklyBonusStart', _dkey(thisMonday));
      b.put('weeklyBonusKcalSoFar', 0);
      return 0;
    }
    return (b.get('weeklyBonusKcalSoFar') as int?) ?? 0;
  }

  static Future<void> addWeeklyBonusKcal(int add, DateTime now) async {
    final b = Hive.box(boxUser);
    final current = getWeeklyBonusKcalSoFar(now);
    await b.put('weeklyBonusKcalSoFar', current + add);
    await b.put('weeklyBonusStart', _dkey(weekStartMonday(now)));
  }

  // ---------- Meal targets (per-day bonus) ----------
  static int getDailyBonusKcal(DateTime day) {
    final m = Hive.box(boxMeals);
    return (m.get(_dkey(day)) as int?) ?? 0;
  }

  static Future<void> setDailyBonusKcal(DateTime day, int bonus) async {
    final m = Hive.box(boxMeals);
    await m.put(_dkey(day), bonus);
  }

  static Future<void> addDailyBonusKcal(DateTime day, int add) async {
    final current = getDailyBonusKcal(day);
    await setDailyBonusKcal(day, current + add);
  }
}
