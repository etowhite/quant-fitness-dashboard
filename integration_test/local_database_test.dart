import 'package:isar_community/isar.dart';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smart_fitness_dashboard/core/database/isar_database_service.dart';
import 'package:smart_fitness_dashboard/features/measurements/data/body_measurement.dart';
import 'package:smart_fitness_dashboard/features/nutrition/application/daily_food_diary.dart';
import 'package:smart_fitness_dashboard/features/nutrition/data/food_product.dart';
import 'package:smart_fitness_dashboard/core/backup/backup_document.dart';
import 'package:smart_fitness_dashboard/core/backup/backup_service.dart';
import 'package:smart_fitness_dashboard/features/goals/data/user_goals_repository.dart';
import 'package:smart_fitness_dashboard/features/goals/domain/user_goals.dart';

class MemoryGoals extends UserGoalsRepository {
  UserGoals value = const UserGoals();
  bool fail = false;
  @override
  Future<UserGoals> load() async => value;
  @override
  Future<void> save(UserGoals goals) async {
    if (fail && goals.steps == 7000) throw StateError('write failed');
    value = goals;
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'offline persistence, seeding, day boundaries, snapshots and upsert',
      (tester) async {
    final directory =
        await Directory.systemTemp.createTemp('fitness_isar_test_');
    var service = await IsarDatabaseService.init(
        directory: directory.path, name: 'local_database_test');
    addTearDown(() async {
      if (service.isar.isOpen) await service.close();
      await directory.delete(recursive: true);
    });
    final seedCount = await service.isar.foodProducts.count();
    expect(seedCount, greaterThanOrEqualTo(300));
    expect(await service.searchProducts('кУрИн'), isNotEmpty);
    final product = FoodProduct()
      ..name = 'Тест'
      ..calories = 100
      ..proteins = 10
      ..fats = 2
      ..carbs = 15;
    await service.saveCustomProduct(product);
    final day = DateTime(2026, 10, 31);
    final changes = service
        .watchFoodLogEntriesForDay(day)
        .firstWhere((rows) => rows.length == 1);
    await service.addProductToDiary(
        product: product, date: day, mealType: 'Завтрак', weightGrams: 150);
    await changes.timeout(const Duration(seconds: 5));
    await service.addProductToDiary(
        product: product,
        date: DateTime(2026, 11, 1),
        mealType: 'Обед',
        weightGrams: 100);
    product.calories = 999;
    await service.saveCustomProduct(product);
    final entries = await service.getFoodLogEntriesForDay(day);
    expect(entries, hasLength(1));
    expect(DailyFoodDiary(entries).totals.calories, 150);
    expect(DailyFoodDiary(entries).totals.proteins, 15);
    expect(await service.getBodyMeasurementHistory(), isEmpty);
    await service.saveBodyMeasurement(BodyMeasurement()
      ..date = day
      ..waist = 85
      ..note = 'Первый');
    final id = (await service.getLatestBodyMeasurement())!.id;
    await service.saveBodyMeasurement(BodyMeasurement()
      ..date = DateTime(2026, 10, 31, 22)
      ..waist = 84);
    final history = await service.getBodyMeasurementHistory();
    expect(history, hasLength(1));
    expect(history.single.id, id);
    expect(history.single.waist, 84);
    await service.close();
    service = await IsarDatabaseService.init(
        directory: directory.path, name: 'local_database_test');
    expect(await service.isar.foodProducts.where().findAll(),
        hasLength(seedCount + 1));
    expect((await service.getLatestBodyMeasurement())!.waist, 84);
    final latest = await service.getBodyMeasurementForDay(day);
    expect(latest!.waist, 84);
    expect(await service.deleteBodyMeasurement(latest.id!), isTrue);
    expect(await service.getBodyMeasurementHistory(), isEmpty);
    expect(await service.deleteFoodLogEntry(entries.single.id!), isTrue);
    expect(await service.getFoodLogEntriesForDay(day), isEmpty);
    final goals = MemoryGoals();
    final backup = BackupService(service, goals);
    final document =
        BackupDocument(goals: const UserGoals(steps: 7000), products: [
      FoodProduct()
        ..name = 'Восстановленный'
        ..calories = 50
        ..proteins = 1
        ..fats = 2
        ..carbs = 3
    ], entries: [], measurements: [
      BodyMeasurement()
        ..date = day
        ..waist = 75
    ]);
    goals.fail = true;
    await expectLater(backup.restore(document), throwsStateError);
    expect(await service.isar.foodProducts.where().findAll(),
        hasLength(seedCount + 1));
    expect(await service.getBodyMeasurementHistory(), isEmpty);
    expect(goals.value.steps, 10000);
    goals.fail = false;
    await backup.restore(document);
    expect((await service.searchProducts('')).single.name, 'Восстановленный');
    expect((await service.getLatestBodyMeasurement())!.waist, 75);
    expect(goals.value.steps, 7000);
  });
}
