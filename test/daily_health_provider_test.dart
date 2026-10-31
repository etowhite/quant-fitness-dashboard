import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_fitness_dashboard/core/health/health_connect_service.dart';
import 'package:smart_fitness_dashboard/features/dashboard/application/daily_health_provider.dart';
import 'package:smart_fitness_dashboard/features/dashboard/domain/daily_health_metrics.dart';

class FakeService extends HealthConnectService {
  HealthAccess access = HealthAccess.denied;
  bool fail = false;
  int requests = 0;
  final metrics = DailyHealthMetrics(
    fetchedAt: DateTime(2026, 10, 31),
    stepsToday: null,
    activeCaloriesToday: null,
    latestWeight: null,
    latestBodyFat: null,
    weightHistory: [],
  );

  @override
  Future<HealthAccess> checkAccess() async => access;
  @override
  Future<HealthAccess> requestPermissions() async {
    requests++;
    return access = HealthAccess.granted;
  }

  @override
  Future<DailyHealthMetrics> fetchTodayMetrics() async {
    if (fail) throw StateError('read failed');
    return metrics;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'does not request permissions automatically; explicit grant loads empty data',
      () async {
    final service = FakeService();
    final container = ProviderContainer(overrides: [
      healthConnectServiceProvider.overrideWithValue(service),
    ]);
    addTearDown(container.dispose);
    expect((await container.read(dailyHealthProvider.future)).access,
        HealthAccess.denied);
    expect(service.requests, 0);
    await container
        .read(dailyHealthProvider.notifier)
        .refresh(requestPermissions: true);
    expect(container.read(dailyHealthProvider).requireValue.isEmpty, isTrue);
    expect(service.requests, 1);
  });

  test('read failure is an error, not empty metrics; retry recovers', () async {
    final service = FakeService()..access = HealthAccess.granted;
    final container = ProviderContainer(overrides: [
      healthConnectServiceProvider.overrideWithValue(service),
    ]);
    addTearDown(container.dispose);
    await container.read(dailyHealthProvider.future);
    service.fail = true;
    await container.read(dailyHealthProvider.notifier).refresh();
    expect(container.read(dailyHealthProvider).hasError, isTrue);
    // A failed refresh keeps the previous successful snapshot visible.
    expect(container.read(dailyHealthProvider).valueOrNull?.metrics,
        same(service.metrics));
    service.fail = false;
    await container.read(dailyHealthProvider.notifier).refresh();
    expect(container.read(dailyHealthProvider).hasError, isFalse);
  });
  test(
      'explicit connect waits for initial access check then requests permission',
      () async {
    final service = FakeService();
    final container = ProviderContainer(
        overrides: [healthConnectServiceProvider.overrideWithValue(service)]);
    addTearDown(container.dispose);
    await container
        .read(dailyHealthProvider.notifier)
        .refresh(requestPermissions: true);
    expect(service.requests, 1);
    expect(container.read(dailyHealthProvider).requireValue.access,
        HealthAccess.granted);
  });
}
