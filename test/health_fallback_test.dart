import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:smart_fitness_dashboard/core/health/health_connect_service.dart';
import 'package:smart_fitness_dashboard/core/health/interval_totals.dart';

final day = DateTime(2026, 10, 31);
HealthDataPoint sample(HealthDataType type, double value, int from, int to,
        {String source = 'any.provider'}) =>
    HealthDataPoint(
        uuid: '$source-$type-$from-$to-$value',
        value: NumericHealthValue(numericValue: value),
        type: type,
        unit: type == HealthDataType.STEPS
            ? HealthDataUnit.COUNT
            : type == HealthDataType.WEIGHT
                ? HealthDataUnit.KILOGRAM
                : HealthDataUnit.KILOCALORIE,
        dateFrom: day.add(Duration(minutes: from)),
        dateTo: day.add(Duration(minutes: to)),
        sourcePlatform: HealthPlatformType.googleHealthConnect,
        sourceDeviceId: '',
        sourceId: source,
        sourceName: source);

class FakeHealth extends Health {
  int? aggregate;
  final data = <HealthDataType, List<HealthDataPoint>>{};
  Set<HealthDataType> granted = HealthConnectService.types.toSet();
  final reads = <HealthDataType>[];
  @override
  Future<void> configure() async {}
  @override
  Future<HealthConnectSdkStatus?> getHealthConnectSdkStatus() async =>
      HealthConnectSdkStatus.sdkAvailable;
  @override
  Future<bool?> hasPermissions(List<HealthDataType> types,
          {List<HealthDataAccess>? permissions}) async =>
      types.every(granted.contains);
  @override
  Future<bool> isHealthDataHistoryAvailable() async => false;
  @override
  Future<int?> getTotalStepsInInterval(DateTime startTime, DateTime endTime,
          {bool includeManualEntry = true}) async =>
      aggregate;
  @override
  Future<List<HealthDataPoint>> getHealthDataFromTypes(
      {required List<HealthDataType> types,
      required DateTime startTime,
      required DateTime endTime,
      List<RecordingMethod> recordingMethodsToFilter = const []}) async {
    reads.addAll(types);
    return types.expand((t) => data[t] ?? <HealthDataPoint>[]).toList();
  }
}

class TestService extends HealthConnectService {
  TestService(FakeHealth health)
      : super(health: health, clock: () => day.add(const Duration(hours: 12)));
  @override
  bool get isSupportedPlatform => true;
  @override
  Future<bool> activityPermissionGranted() async => true;
}

void main() {
  test(
      'report history uses positive aggregate and preserves unknown versus explicit zero',
      () async {
    final health = FakeHealth()..aggregate = 4500;
    var result = await TestService(health)
        .fetchReportHistory(day, day.add(const Duration(hours: 12)));
    expect(result.steps[day], 4500);
    health.aggregate = 0;
    result = await TestService(health)
        .fetchReportHistory(day, day.add(const Duration(hours: 12)));
    expect(result.steps, isEmpty);
    health.data[HealthDataType.STEPS] = [
      sample(HealthDataType.STEPS, 0, 0, 10)
    ];
    result = await TestService(health)
        .fetchReportHistory(day, day.add(const Duration(hours: 12)));
    expect(result.steps[day], 0);
  });
  test('raw fallback merges competing devices and clips midnight intervals',
      () {
    final points = [
      sample(HealthDataType.STEPS, 100, 0, 10),
      sample(HealthDataType.STEPS, 200, 5, 15, source: 'another.vendor')
    ];
    expect(
        nonOverlappingTotal(points, day, day.add(const Duration(hours: 1)),
            maxValue: 1000000),
        250);
    expect(
        nonOverlappingTotal([
          sample(HealthDataType.STEPS, 100, -5, 5)
        ], day, day.add(const Duration(hours: 1)), maxValue: 1000000),
        50);
  });
  test(
      'zero and null aggregate use de-duplicated raw steps; total calories fallback is labelled',
      () async {
    for (final value in [null, 0]) {
      final health = FakeHealth()..aggregate = value;
      final steps = sample(HealthDataType.STEPS, 200, 0, 10);
      health.data[HealthDataType.STEPS] = [
        steps,
        steps,
        sample(HealthDataType.STEPS, 150, 0, 10, source: 'other.watch')
      ];
      health.data[HealthDataType.ACTIVE_ENERGY_BURNED] = [
        sample(HealthDataType.ACTIVE_ENERGY_BURNED, 0, 0, 10)
      ];
      health.data[HealthDataType.TOTAL_CALORIES_BURNED] = [
        sample(HealthDataType.TOTAL_CALORIES_BURNED, 300, 0, 10)
      ];
      final metrics = await TestService(health).fetchTodayMetrics();
      expect(metrics.stepsToday, 200);
      expect(metrics.activeCaloriesToday, 300);
      expect(metrics.caloriesAreTotal, isTrue);
    }
  });
  test(
      'valid aggregate remains authoritative; active energy prevents total fallback',
      () async {
    final health = FakeHealth()..aggregate = 1234;
    health.data[HealthDataType.STEPS] = [
      sample(HealthDataType.STEPS, 9999, 0, 10)
    ];
    health.data[HealthDataType.ACTIVE_ENERGY_BURNED] = [
      sample(HealthDataType.ACTIVE_ENERGY_BURNED, 80, 0, 10)
    ];
    final metrics = await TestService(health).fetchTodayMetrics();
    expect(metrics.stepsToday, 1234);
    expect(metrics.activeCaloriesToday, 80);
    expect(metrics.caloriesAreTotal, isFalse);
    expect(health.reads, isNot(contains(HealthDataType.TOTAL_CALORIES_BURNED)));
  });
  test('partial permissions keep weight available and never query denied types',
      () async {
    final health = FakeHealth()..granted = {HealthDataType.WEIGHT};
    health.data[HealthDataType.WEIGHT] = [
      sample(HealthDataType.WEIGHT, 72, 10, 10)
    ];
    final metrics = await TestService(health).fetchTodayMetrics();
    expect(metrics.latestWeight?.value, 72);
    expect(metrics.stepsToday, isNull);
    expect(health.reads, [HealthDataType.WEIGHT]);
  });
}
