import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_fitness_dashboard/core/backup/backup_document.dart';
import 'package:smart_fitness_dashboard/features/goals/domain/user_goals.dart';
import 'package:smart_fitness_dashboard/features/measurements/data/body_measurement.dart';
import 'package:smart_fitness_dashboard/features/nutrition/data/food_product.dart';
import 'package:smart_fitness_dashboard/features/water/data/water_log_entry.dart';

void main() {
  BackupDocument sample() =>
      BackupDocument(goals: const UserGoals(steps: 8000), products: [
        FoodProduct()
          ..name = 'Тест'
          ..calories = 100
          ..proteins = 10
          ..fats = 2
          ..carbs = 15
      ], entries: [], measurements: [
        BodyMeasurement()
          ..date = DateTime(2026, 10, 31)
          ..waist = 80
          ..note = 'Тест'
      ], water: [
        WaterLogEntry()
          ..date = DateTime(2026, 10, 31)
          ..recordedAt = DateTime(2026, 10, 31, 12)
          ..volumeMl = 250
      ]);

  test('backup round trip preserves offline data and goals without source IDs',
      () {
    final result = BackupDocument.decode(sample().encode());
    expect(result.goals.steps, 8000);
    expect(result.products.single.name, 'Тест');
    expect(result.products.single.id, isNull);
    expect(result.measurements.single.waist, 80);
    expect(result.measurements.single.note, 'Тест');
    expect(result.water.single.volumeMl, 250);
    expect(result.goals.waterMl, 2000);
  });

  test('rejects invalid schema, limits, duplicate days and invalid goals', () {
    for (final mutate in <void Function(Map<String, dynamic>)>[
      (j) => j['version'] = 99,
      (j) => j['water'][0]['volumeMl'] = -250,
      (j) => j['water'][0]['volumeMl'] = 5001,
      (j) => j['products'][0]['calories'] = 1001,
      (j) => j['products'][0]['fats'] = -1,
      (j) => j['measurements'][0]['waist'] = 501,
      (j) => j['measurements'].add(j['measurements'][0]),
      (j) => j['goals']['steps'] = 0,
      (j) => j['goals']['calories'] = 'invalid',
      (j) => j['products'] = 'not a list',
    ]) {
      final json = jsonDecode(sample().encode()) as Map<String, dynamic>;
      mutate(json);
      expect(
          () => BackupDocument.decode(jsonEncode(json)), throwsFormatException);
    }
  });
  test('version 1 migrates without water records and preserves old goals', () {
    final json = jsonDecode(sample().encode()) as Map<String, dynamic>;
    json['version'] = 1;
    json.remove('water');
    (json['goals'] as Map).remove('waterMl');
    final restored = BackupDocument.decode(jsonEncode(json));
    expect(restored.water, isEmpty);
    expect(restored.goals.waterMl, 2000);
  });
}
