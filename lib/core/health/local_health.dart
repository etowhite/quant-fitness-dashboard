import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_provider.dart';
import '../database/local_day.dart';
import '../../features/dashboard/domain/daily_health_metrics.dart';

class ManualActivityRepository {
  String key(DateTime day) =>
      'manual_activity_${localDay(day).toIso8601String()}';
  Future<void> save(DateTime day, int? steps, double? calories) async {
    if (steps != null && (steps < 0 || steps > 1000000) ||
        calories != null &&
            (!calories.isFinite || calories < 0 || calories > 100000)) {
      throw ArgumentError('Invalid activity');
    }
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setStringList(
        key(day), [steps?.toString() ?? '', calories?.toString() ?? ''])) {
      throw StateError('Activity could not be saved');
    }
  }

  Future<({int? steps, double? calories})> load(DateTime day) async {
    final values =
        (await SharedPreferences.getInstance()).getStringList(key(day));
    return (
      steps: values == null ? null : int.tryParse(values.first),
      calories: values == null ? null : double.tryParse(values.last)
    );
  }
}

Future<DailyHealthMetrics> mergeLocalHealth(
    Ref ref, DailyHealthMetrics? remote) async {
  final now = DateTime.now();
  if (!Platform.isAndroid) {
    return remote ??
        DailyHealthMetrics(
            fetchedAt: now,
            stepsToday: null,
            activeCaloriesToday: null,
            latestWeight: null,
            latestBodyFat: null,
            weightHistory: []);
  }
  final rows = await (await ref.read(databaseServiceProvider.future))
      .getBodyMeasurementHistory();
  final weights = rows
      .where((r) => r.weight != null)
      .map((r) => HealthValuePoint(date: r.date, value: r.weight!))
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));
  final fats = rows.where((r) => r.bodyFat != null).toList();
  final manual = await ManualActivityRepository().load(now);
  return DailyHealthMetrics(
      fetchedAt: now,
      stepsToday: manual.steps ?? remote?.stepsToday,
      activeCaloriesToday: manual.calories ?? remote?.activeCaloriesToday,
      activityDataAt: manual.steps != null || manual.calories != null
          ? now
          : remote?.activityDataAt,
      latestWeight:
          remote?.latestWeight ?? (weights.isEmpty ? null : weights.last),
      latestBodyFat: remote?.latestBodyFat ??
          (fats.isEmpty
              ? null
              : HealthValuePoint(
                  date: fats.first.date, value: fats.first.bodyFat!)),
      weightHistory: remote?.weightHistory.isNotEmpty == true
          ? remote!.weightHistory
          : weights
              .where((p) =>
                  !p.date.isBefore(now.subtract(const Duration(days: 30))))
              .toList(),
      bodyDataAt:
          remote?.bodyDataAt ?? (weights.isEmpty ? null : weights.last.date),
      historyAuthorized: remote?.historyAuthorized ?? false,
      historyAvailable: remote?.historyAvailable ?? false,
      caloriesAreTotal:
          manual.calories == null && (remote?.caloriesAreTotal ?? false));
}
