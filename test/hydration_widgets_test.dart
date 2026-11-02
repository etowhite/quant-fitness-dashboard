import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_fitness_dashboard/core/database/database_provider.dart';
import 'package:smart_fitness_dashboard/core/database/isar_database_service.dart';
import 'package:smart_fitness_dashboard/core/theme/app_theme.dart';
import 'package:smart_fitness_dashboard/features/settings/domain/theme_settings.dart';
import 'package:smart_fitness_dashboard/features/nutrition/data/food_product.dart';
import 'package:smart_fitness_dashboard/features/nutrition/application/saved_products_provider.dart';
import 'package:smart_fitness_dashboard/features/nutrition/presentation/widgets/add_food_sheet.dart';
import 'package:smart_fitness_dashboard/features/water/application/water_provider.dart';
import 'package:smart_fitness_dashboard/features/water/data/water_log_entry.dart';
import 'package:smart_fitness_dashboard/features/water/presentation/water_balance_card.dart';

class CaptureFoodDb implements IsarDatabaseService {
  double? savedPercent, savedGrams;
  @override
  Future<int> addProductToDiary(
      {required FoodProduct product,
      required DateTime date,
      required String mealType,
      required double weightGrams,
      double? waterPercentage}) async {
    savedPercent = waterPercentage;
    savedGrams = weightGrams;
    return 1;
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  setUpAll(() => initializeDateFormatting('ru'));
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('portion hydration preview, validated override and snapshot save',
      (tester) async {
    final p = FoodProduct()
      ..name = 'Cola Zero'
      ..waterPercentage = 98
      ..calories = 0
      ..proteins = 0
      ..fats = 0
      ..carbs = 0;
    final db = CaptureFoodDb();
    await tester.pumpWidget(ProviderScope(
        overrides: [
          databaseServiceProvider.overrideWith((ref) async => db),
          favoriteProductsProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: MaterialApp(
            home: Builder(
                builder: (context) => Scaffold(
                    body: TextButton(
                        onPressed: () => showAddFoodSheet(context,
                            date: DateTime(2026), product: p),
                        child: const Text('open')))))));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '250');
    await tester.pumpAndSettle();
    expect(find.text('Учитывать в воде: 98% (+245 мл)'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('hydration-edit')));
    await tester.tap(find.byKey(const ValueKey('hydration-edit')));
    await tester.pumpAndSettle();
    final input = find.byKey(const ValueKey('hydration-percentage-input'));
    await tester.enterText(input, '101');
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.enterText(input, '85');
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();
    expect(find.text('Учитывать в воде: 85% (+213 мл)'), findsOneWidget);
    await tester.ensureVisible(find.text('Добавить в дневник'));
    await tester.tap(find.text('Добавить в дневник'));
    await tester.pumpAndSettle();
    expect(db.savedPercent, 85);
    expect(db.savedGrams, 250);
    expect(p.waterPercentage, 98);
    expect(tester.takeException(), isNull);
  });
  for (final brightness in Brightness.values) {
    testWidgets('water card includes food breakdown in ${brightness.name}',
        (tester) async {
      final day = DateTime(2026);
      await tester.pumpWidget(ProviderScope(
          overrides: [
            dailyHydrationProvider(day).overrideWithValue(
                const AsyncData(DailyHydration(manualMl: 250, foodMl: 245))),
            waterProvider(day).overrideWith((ref) => Stream.value([
                  WaterLogEntry()
                    ..date = day
                    ..recordedAt = day
                    ..volumeMl = 250
                ])),
          ],
          child: MaterialApp(
              theme: AppTheme.build(const ThemeSettings(), brightness),
              home: Scaffold(
                  body: SingleChildScrollView(
                      child: WaterBalanceCard(date: day))))));
      await tester.pumpAndSettle();
      expect(find.text('495 / 2000 мл'), findsOneWidget);
      expect(find.text('в т.ч. 245 мл из напитков и еды'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
