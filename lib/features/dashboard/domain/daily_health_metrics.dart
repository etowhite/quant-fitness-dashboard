import '../../../shared/models/metric_point.dart';

typedef HealthValuePoint = MetricPoint;

class DailyHealthMetrics {
  DailyHealthMetrics({
    required this.fetchedAt,
    this.activityDataAt,
    this.bodyDataAt,
    this.historyAuthorized = false,
    this.historyAvailable = false,
    this.caloriesAreTotal = false,
    required this.stepsToday,
    required this.activeCaloriesToday,
    required this.latestWeight,
    required this.latestBodyFat,
    required List<HealthValuePoint> weightHistory,
  }) : weightHistory = List.unmodifiable(weightHistory);

  final DateTime fetchedAt;
  final DateTime? activityDataAt, bodyDataAt;
  final bool historyAuthorized;
  final bool historyAvailable;
  final bool caloriesAreTotal;
  // Null means no samples; zero is a real measured value.
  final int? stepsToday;
  final double? activeCaloriesToday;
  final HealthValuePoint? latestWeight; // kg
  final HealthValuePoint? latestBodyFat; // percent, 0–100
  final List<HealthValuePoint> weightHistory;

  bool get isEmpty =>
      stepsToday == null &&
      activeCaloriesToday == null &&
      latestWeight == null &&
      latestBodyFat == null;
}
