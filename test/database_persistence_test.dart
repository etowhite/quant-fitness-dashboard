import 'package:smart_fitness_dashboard/core/database/data_reset_service.dart';
import 'package:smart_fitness_dashboard/core/notifications/notification_service.dart';
import 'package:smart_fitness_dashboard/features/settings/data/app_preferences_repository.dart';
import 'package:smart_fitness_dashboard/features/settings/domain/theme_settings.dart';
import 'package:smart_fitness_dashboard/features/settings/domain/reminder_settings.dart';
import 'package:smart_fitness_dashboard/core/localization/app_language.dart';
import 'package:smart_fitness_dashboard/features/measurements/data/body_measurement.dart';
import 'package:smart_fitness_dashboard/features/nutrition/data/food_log_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:smart_fitness_dashboard/core/database/isar_database_service.dart';
import 'package:smart_fitness_dashboard/features/nutrition/data/food_product.dart';
import 'package:smart_fitness_dashboard/features/water/data/water_log_entry.dart';
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
    if (fail && goals.waterMl == 2500) throw StateError('disk error');
    value = goals;
  }
}

class ResetNotifications extends NotificationService {
  int cancellations = 0;
  @override
  Future<void> cancelAll() async {
    cancellations++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  setUpAll(() async {
    final config = File('.dart_tool/package_config.json').absolute;
    final packages =
        (jsonDecode(await config.readAsString()) as Map)['packages'] as List;
    final package =
        packages.firstWhere((p) => p['name'] == 'isar_community_flutter_libs');
    final root = config.uri.resolve('${package['rootUri']}/');
    await Isar.initializeIsarCore(libraries: {
      Abi.current(): root
          .resolve(
              Platform.isWindows ? 'windows/libisar.dll' : 'linux/libisar.so')
          .toFilePath()
    });
  });
  test(
      'additive seeds, water isolation/undo, offline barcode cache and import rollback',
      () async {
    final directory = await Directory.systemTemp.createTemp('fitness_db_');
    var db = await IsarDatabaseService.init(
        directory: directory.path, name: 'contract');
    addTearDown(() async {
      if (db.isar.isOpen) await db.close();
      await directory.delete(recursive: true);
    });
    final count = await db.isar.foodProducts.count();
    expect(count, greaterThanOrEqualTo(300));
    await db.saveCustomProduct(FoodProduct()
      ..name = 'Мой продукт'
      ..calories = 10
      ..proteins = 1
      ..fats = 0
      ..carbs = 2);
    final day = DateTime(2026, 10, 31);
    await db.addWater(day, 150);
    await db.addWater(day, 250);
    await db.addWater(day.add(const Duration(days: 1)), 500);
    await db.undoWater(day);
    expect(
        (await db.isar.waterLogEntries.where().dateEqualTo(day).findAll())
            .single
            .volumeMl,
        150);
    await expectLater(db.addWater(day, 0), throwsArgumentError);
    await expectLater(db.addWater(day, 5001), throwsArgumentError);
    final online = FoodProduct()
      ..name = 'Упаковка'
      ..barcode = '3017620422003'
      ..source = 'Open Food Facts · ODbL'
      ..calories = 100
      ..proteins = 5
      ..fats = 4
      ..carbs = 11;
    final first = await db.cacheOnlineProduct(online);
    final again = await db.cacheOnlineProduct(online);
    expect(first.id, again.id);
    await db.close();
    db = await IsarDatabaseService.init(
        directory: directory.path, name: 'contract');
    expect(await db.isar.foodProducts.count(), count + 2);
    expect(await db.isar.waterLogEntries.count(), 2);
    final goals = MemoryGoals();
    final service = BackupService(db, goals);
    final backup =
        BackupDocument(goals: const UserGoals(waterMl: 2500), products: [
      online
    ], entries: [], measurements: [], water: [
      WaterLogEntry()
        ..date = day
        ..recordedAt = day
        ..volumeMl = 500
    ]);
    goals.fail = true;
    await expectLater(service.restore(backup), throwsStateError);
    expect(await db.isar.waterLogEntries.count(), 2);
    expect(goals.value.waterMl, 2000);
    goals.fail = false;
    await service.restore(backup);
    expect(
        (await db.isar.waterLogEntries.where().findAll()).single.volumeMl, 500);
    expect(goals.value.waterMl, 2500);
  }, skip: !Platform.isWindows && !Platform.isLinux);
  test(
      'selective clear preserves unselected data; factory atomically reseeds collections and resets preferences',
      () async {
    final directory = await Directory.systemTemp.createTemp('quant_reset_');
    final db = await IsarDatabaseService.init(
        directory: directory.path, name: 'reset_contract');
    addTearDown(() async {
      await db.close();
      await directory.delete(recursive: true);
    });
    final goals = MemoryGoals();
    goals.value = const UserGoals(steps: 8000);
    final preferences = AppPreferencesRepository();
    await preferences.save(
        language: AppLanguage.en,
        theme: const ThemeSettings(palette: AccentPalette.sunsetCoral),
        reminders: const ReminderSettings(water: true));
    await (await SharedPreferences.getInstance())
        .setBool('hasCompletedOnboarding', true);
    final notifications = ResetNotifications();
    final reset = DataResetService(db, goals, preferences, notifications);
    final day = DateTime(2026, 10, 31);
    await db.addWater(day, 250);
    await db.addFoodLogEntry(FoodLogEntry()
      ..date = day
      ..mealType = 'Завтрак'
      ..productName = 'Тест'
      ..weightGrams = 100
      ..calories = 100
      ..proteins = 10
      ..fats = 2
      ..carbs = 15);
    await db.saveBodyMeasurement(BodyMeasurement()
      ..date = day
      ..waist = 80);
    await db.saveCustomProduct(FoodProduct()
      ..name = 'Мой продукт'
      ..calories = 10
      ..proteins = 1
      ..fats = 0
      ..carbs = 2);
    expect((await reset.counts())[ResetCategory.diary], 2);
    await reset.clear({ResetCategory.diary});
    expect(await db.isar.foodLogEntries.count(), 0);
    expect(await db.isar.waterLogEntries.count(), 0);
    expect(await db.isar.bodyMeasurements.count(), 1);
    expect(goals.value.steps, 8000);
    expect((await preferences.load()).theme.palette, AccentPalette.sunsetCoral);
    expect(notifications.cancellations, 0);
    await reset.clear({ResetCategory.products});
    expect(await db.isar.foodProducts.count(), greaterThanOrEqualTo(300));
    expect(await db.searchProducts('Мой продукт'), isEmpty);
    expect(await db.isar.bodyMeasurements.count(), 1);
    await reset.clear({ResetCategory.preferences});
    expect(goals.value.steps, 10000);
    expect((await preferences.load()).reminders.water, isFalse);
    expect((await preferences.load()).language, AppLanguage.en);
    expect(
        (await SharedPreferences.getInstance())
            .getBool('hasCompletedOnboarding'),
        isTrue);
    expect(notifications.cancellations, 1);
    await db.addWater(day, 150);
    await reset.clear({}, factory: true);
    expect(await db.isar.foodLogEntries.count(), 0);
    expect(await db.isar.waterLogEntries.count(), 0);
    expect(await db.isar.bodyMeasurements.count(), 0);
    expect(await db.isar.foodProducts.count(), greaterThanOrEqualTo(300));
    expect((await SharedPreferences.getInstance()).getKeys(), isEmpty);
    expect((await preferences.load()).language, AppLanguage.system);
    expect(notifications.cancellations, 2);
  }, skip: !Platform.isWindows && !Platform.isLinux);
}
