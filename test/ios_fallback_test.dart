import 'package:smart_fitness_dashboard/core/backup/backup_document.dart';
import 'package:smart_fitness_dashboard/features/goals/domain/user_goals.dart';
import 'package:smart_fitness_dashboard/features/measurements/data/body_measurement.dart';
import 'package:smart_fitness_dashboard/core/health/health_connect_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_fitness_dashboard/core/health/local_health.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('HealthKit fractions are converted to percentages only on iOS', () {
    expect(normalizeBodyFat(0.192, iOS: true), closeTo(19.2, 0.001));
    expect(normalizeBodyFat(19.2, iOS: false), 19.2);
  });
  test('backup v9 preserves local body composition', () {
    final doc = BackupDocument(
        goals: const UserGoals(),
        products: [],
        entries: [],
        measurements: [
          BodyMeasurement()
            ..date = DateTime(2026, 11, 3)
            ..weight = 72.5
            ..bodyFat = 19.2
        ]);
    final restored = BackupDocument.decode(doc.encode());
    expect(restored.measurements.single.weight, 72.5);
    expect(restored.measurements.single.bodyFat, 19.2);
  });
  test('sideload never calls HealthKit and fails closed without entitlement',
      () async {
    final service = HealthConnectService(iOS: true);
    expect(await service.checkAccess(), HealthAccess.unavailable);
    expect(await service.requestPermissions(), HealthAccess.unavailable);
    expect(service.sourceMode, HealthSourceMode.localFallback);
    await expectLater(
        service.fetchTodayMetrics(), throwsA(isA<HealthAccessException>()));
  });
  test('manual activity is daily, persistent, nullable and validated',
      () async {
    SharedPreferences.setMockInitialValues({});
    final repo = ManualActivityRepository();
    final day = DateTime(2026, 11, 3);
    expect((await repo.load(day)).steps, isNull);
    await repo.save(day, 8500, 321.5);
    expect((await ManualActivityRepository().load(day)).steps, 8500);
    expect((await repo.load(DateTime(2026, 11, 4))).steps, isNull);
    await expectLater(repo.save(day, -1, 5), throwsArgumentError);
    await expectLater(repo.save(day, 1, double.nan), throwsArgumentError);
    await repo.save(day, null, null);
    expect((await repo.load(day)).steps, isNull);
  });
}
