import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:smart_fitness_dashboard/core/health/health_connect_service.dart';

void main() {
  HealthDataPoint point(String source, double value, HealthDataType type,
          {int minute = 0}) =>
      HealthDataPoint(
          uuid: '$source-$value',
          value: NumericHealthValue(numericValue: value),
          type: type,
          unit: type == HealthDataType.WEIGHT
              ? HealthDataUnit.KILOGRAM
              : HealthDataUnit.KILOCALORIE,
          dateFrom: DateTime(2026, 10, 31, 12, minute),
          dateTo: DateTime(2026, 10, 31, 12, minute),
          sourcePlatform: HealthPlatformType.googleHealthConnect,
          sourceDeviceId: '',
          sourceId: source,
          sourceName: source);

  test('coincident records resolve deterministically for any provider', () {
    final points = [
      point('phone', 70, HealthDataType.WEIGHT),
      point('com.vendor.scale', 71, HealthDataType.WEIGHT),
      point('phone', 200, HealthDataType.ACTIVE_ENERGY_BURNED),
      point('com.vendor.tracker', 180, HealthDataType.ACTIVE_ENERGY_BURNED),
      point('com.vendor.scale', 72, HealthDataType.WEIGHT, minute: 1)
    ];
    for (final input in [points, points.reversed.toList()]) {
      final result = prioritizeHealthSources(input);
      expect(result, hasLength(3));
      expect(result.where((p) => p.sourceId == 'phone'), isEmpty);
    }
  });
}
