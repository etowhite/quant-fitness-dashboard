import '../nutrition/domain/hydration.dart';
import '../../core/database/local_day.dart';
import '../nutrition/data/food_log_entry.dart';
import '../water/data/water_log_entry.dart';
import '../dashboard/domain/daily_health_metrics.dart';

class ReportAverage {
  const ReportAverage(this.total, this.days);
  final double total;
  final int days;
  double? get mean => days == 0 ? null : total / days;
}

class ReportData {
  ReportData(
      {required this.start,
      required this.end,
      required this.weights,
      required List<FoodLogEntry> food,
      required List<WaterLogEntry> water,
      required Map<DateTime, int> steps,
      required this.waterGoal,
      required this.stepGoal,
      this.healthIncomplete = false}) {
    bool inRange(DateTime d) => !d.isBefore(start) && !d.isAfter(end);
    final calories = <DateTime, double>{};
    final volumes = <DateTime, double>{};
    for (final e in food.where((e) => inRange(e.date))) {
      final ml = Hydration.volume(e.weightGrams, e.waterPercentage);
      if (ml > 0) {
        volumes.update(localDay(e.date), (v) => v + ml, ifAbsent: () => ml);
      }
      calories.update(localDay(e.date), (v) => v + e.calories,
          ifAbsent: () => e.calories);
    }
    for (final e in water.where((e) => inRange(e.date))) {
      volumes.update(localDay(e.date), (v) => v + e.volumeMl,
          ifAbsent: () => e.volumeMl.toDouble());
    }
    final counts = {
      for (final e in steps.entries.where((e) => inRange(e.key)))
        localDay(e.key): e.value
    };
    nutrition = ReportAverage(
        calories.values.fold(0.0, (a, b) => a + b), calories.length);
    hydration = ReportAverage(
        volumes.values.fold(0.0, (a, b) => a + b), volumes.length);
    activity =
        ReportAverage(counts.values.fold(0.0, (a, b) => a + b), counts.length);
    waterGoalDays = volumes.values.where((v) => v >= waterGoal).length;
    stepGoalDays = counts.values.where((v) => v >= stepGoal).length;
    weights = weights.where((w) => inRange(w.date)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }
  final DateTime start, end;
  List<HealthValuePoint> weights;
  final int waterGoal, stepGoal;
  final bool healthIncomplete;
  late final ReportAverage nutrition, hydration, activity;
  late final int waterGoalDays, stepGoalDays;
  double? get weightChange =>
      weights.length < 2 ? null : weights.last.value - weights.first.value;
}
