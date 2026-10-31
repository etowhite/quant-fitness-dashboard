import '../domain/daily_health_metrics.dart';

// Keep one point per instant; sorting prevents a folded/vertical chart line.
List<HealthValuePoint> orderedWeights(List<HealthValuePoint> history) {
  final byTime = <int, HealthValuePoint>{};
  for (final point in history) {
    if (point.value.isFinite && point.value > 0) {
      byTime[point.date.millisecondsSinceEpoch] = point;
    }
  }
  return byTime.values.toList()..sort((a, b) => a.date.compareTo(b.date));
}

double? weightDelta(DailyHealthMetrics? metrics) {
  final latest = metrics?.latestWeight;
  if (latest == null) return null;
  final previous = orderedWeights(metrics!.weightHistory)
      .where((point) => point.date.isBefore(latest.date));
  return previous.isEmpty ? null : latest.value - previous.last.value;
}
