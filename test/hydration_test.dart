import 'package:smart_fitness_dashboard/features/reports/report_data.dart';
import 'package:smart_fitness_dashboard/features/water/data/water_log_entry.dart';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_fitness_dashboard/features/nutrition/domain/hydration.dart';
import 'package:smart_fitness_dashboard/features/nutrition/data/food_product.dart';
import 'package:smart_fitness_dashboard/features/nutrition/data/food_log_entry.dart';
import 'package:smart_fitness_dashboard/features/nutrition/application/daily_food_diary.dart';
import 'package:smart_fitness_dashboard/core/backup/backup_document.dart';
import 'package:smart_fitness_dashboard/features/goals/domain/user_goals.dart';

void main() {
  test('reports combine food water and manual water on the same day', () {
    final day = DateTime(2026, 11, 2);
    final food = FoodLogEntry()
      ..date = day
      ..weightGrams = 250
      ..waterPercentage = 98
      ..calories = 0;
    final data = ReportData(
        start: day,
        end: day,
        weights: [],
        food: [food],
        water: [
          WaterLogEntry()
            ..date = day
            ..volumeMl = 250
        ],
        steps: {},
        waterGoal: 400,
        stepGoal: 10000);
    expect(data.hydration.mean, 495);
    expect(data.hydration.days, 1);
    expect(data.waterGoalDays, 1);
  });
  test('liquid detection distinguishes drinks from solid/dry lookalikes', () {
    for (final c in <String, double>{
      'Вода минеральная': 100,
      'Чай черный': 98,
      'Кофе без сахара': 98,
      'Cola Zero': 98,
      'Кола': 90,
      'Сок яблочный': 90,
      'Кефир': 88,
      'Молоко': 88,
      'Питьевой йогурт': 88,
      'Протеиновый коктейль': 88,
      'Борщ с говядиной': 80,
      'Окрошка на кефире': 80,
      'Сырный суп': 80,
      'Руккола': 0,
      'Шоколад молочный': 0,
      'Milk chocolate': 0,
      'Chocolate milk': 88,
      'Milk chocolate drink': 88,
      'Сыр моцарелла (цельное молоко)': 0,
      'Молоко сухое': 0,
      'Protein powder': 0,
      'Картофельное пюре (молоко)': 0,
      'Чайная колбаса': 0,
      'Греческий йогурт': 0
    }.entries) {
      expect(Hydration.detect(c.key), c.value, reason: c.key);
    }
    expect(Hydration.detect('Brand', categories: ['en:waters']), 100);
    expect(Hydration.detect('Brand', categories: ['en:milks']), 88);
    expect(Hydration.detect('Brand', categories: ['en:soups']), 80);
    expect(Hydration.detect('Brand', serving: '250 ml'), 90);
  });
  test('percent limits and per-portion water are finite and additive', () {
    for (final v in [-1.0, 100.01, double.nan, double.infinity]) {
      expect(() => Hydration.validate(v), throwsArgumentError);
    }
    expect(Hydration.volume(250, 98), 245);
    expect(Hydration.volume(330, 0), 0);
    final e = FoodLogEntry()
      ..date = DateTime(2026)
      ..mealType = 'Обед'
      ..productName = 'Cola Zero'
      ..weightGrams = 250
      ..waterPercentage = 98
      ..calories = 0
      ..proteins = 0
      ..fats = 0
      ..carbs = 0;
    expect(DailyFoodDiary([e]).waterMl, 245);
    expect(DailyFoodDiary([]).waterMl, 0);
  });
  test(
      'backup v8 snapshots roundtrip; old backups retain zero; invalid percent rejected',
      () {
    final p = FoodProduct()
      ..name = 'Milk'
      ..waterPercentage = 88
      ..calories = 50
      ..proteins = 3
      ..fats = 2
      ..carbs = 5;
    final e = FoodLogEntry()
      ..date = DateTime(2026)
      ..mealType = 'Обед'
      ..productName = 'Milk'
      ..weightGrams = 250
      ..waterPercentage = 85
      ..calories = 125
      ..proteins = 7.5
      ..fats = 5
      ..carbs = 12.5;
    final doc = BackupDocument(
        goals: const UserGoals(),
        products: [p],
        entries: [e],
        measurements: []);
    final restored = BackupDocument.decode(doc.encode());
    expect(restored.products.single.waterPercentage, 88);
    expect(restored.entries.single.waterPercentage, 85);
    final raw = jsonDecode(doc.encode()) as Map<String, dynamic>;
    raw['version'] = 7;
    (raw['products'] as List).single.remove('waterPercentage');
    (raw['entries'] as List).single.remove('waterPercentage');
    final old = BackupDocument.decode(jsonEncode(raw));
    expect(old.products.single.waterPercentage, 0);
    expect(old.entries.single.waterPercentage, 0);
    (raw['entries'] as List).single['waterPercentage'] = 101;
    expect(() => BackupDocument.decode(jsonEncode(raw)), throwsFormatException);
  });
}
