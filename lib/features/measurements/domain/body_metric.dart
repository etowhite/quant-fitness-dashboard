import '../../../shared/models/metric_point.dart';
import '../data/body_measurement.dart';

enum BodyMetric {
  waist('Талия'),
  chest('Грудь'),
  hips('Бедра'),
  biceps('Бицепс');

  const BodyMetric(this.label);
  final String label;

  double? read(BodyMeasurement measurement) => switch (this) {
        BodyMetric.waist => measurement.waist,
        BodyMetric.chest => measurement.chest,
        BodyMetric.hips => measurement.hips,
        BodyMetric.biceps => measurement.biceps,
      };

  List<MetricPoint> series(List<BodyMeasurement> history) {
    final points = <MetricPoint>[];
    for (final row in history) {
      final value = read(row);
      if (value != null && value.isFinite && value > 0) {
        points.add(MetricPoint(date: row.date.toLocal(), value: value));
      }
    }
    return points..sort((a, b) => a.date.compareTo(b.date));
  }
}
