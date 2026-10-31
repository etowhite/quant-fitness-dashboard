import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_fitness_dashboard/features/nutrition/data/food_product.dart';
import 'package:smart_fitness_dashboard/features/nutrition/presentation/recipes_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:smart_fitness_dashboard/features/nutrition/data/recipe.dart';
import 'package:smart_fitness_dashboard/features/nutrition/data/food_log_entry.dart';
import 'package:smart_fitness_dashboard/features/water/data/water_log_entry.dart';
import 'package:smart_fitness_dashboard/features/dashboard/domain/daily_health_metrics.dart';
import 'package:smart_fitness_dashboard/features/reports/report_data.dart';
import 'package:smart_fitness_dashboard/features/reports/report_screen.dart';
import 'package:smart_fitness_dashboard/core/localization/app_strings.dart';
import 'package:smart_fitness_dashboard/core/theme/app_theme.dart';
import 'package:smart_fitness_dashboard/features/settings/domain/theme_settings.dart';

void main() {
  setUpAll(() => initializeDateFormatting());
  testWidgets(
      'recipe editor updates preview for cooked weight and fractional servings',
      (tester) async {
    final recipe = Recipe(ingredients: [
      RecipeIngredient(
          name: 'Ingredient',
          grams: 200,
          calories: 100,
          proteins: 10,
          fats: 5,
          carbs: 15)
    ], yieldGrams: 200, servings: 2);
    final product = FoodProduct()
      ..name = 'Test dish'
      ..calories = 100
      ..proteins = 10
      ..fats = 5
      ..carbs = 15
      ..recipeJson = recipe.encode();
    await tester.pumpWidget(ProviderScope(
        child: MaterialApp(home: RecipeEditor(product: product))));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.ensureVisible(fields.at(1));
    await tester.enterText(fields.at(1), '400');
    await tester.ensureVisible(fields.at(2));
    await tester.enterText(fields.at(2), '4');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.textContaining('На 100 г: 50 ккал'));
    expect(find.textContaining('На порцию: 50 ккал'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  test(
      'recipe yield and fractional portions preserve full precision; unknown stays unknown',
      () {
    final ingredients = [
      RecipeIngredient(
          name: 'A',
          grams: 150,
          calories: 123.45,
          proteins: 10.2,
          fats: 3.4,
          carbs: 15.6),
      RecipeIngredient(
          name: 'B',
          grams: 50.5,
          calories: 240,
          proteins: 20,
          fats: 8,
          carbs: 22)
    ];
    final r =
        Recipe(ingredients: ingredients, yieldGrams: 175.25, servings: 2.5);
    const expected = 123.45 * 1.5 + 240 * .505;
    expect(r.totals![0], closeTo(expected, 1e-10));
    expect(r.per100![0], closeTo(expected * 100 / 175.25, 1e-10));
    expect(r.perServing![0], closeTo(expected / 2.5, 1e-10));
    final changed =
        Recipe(ingredients: ingredients, yieldGrams: 250, servings: 4);
    expect(changed.totals, r.totals);
    expect(changed.per100![0], closeTo(expected * .4, 1e-10));
    expect(Recipe.decode(r.encode()).totals, r.totals);
    final missing = Recipe(
        ingredients: [RecipeIngredient(name: 'Unknown', grams: 100)],
        yieldGrams: 100);
    expect(missing.totals, isNull);
    expect(missing.per100, isNull);
    expect(Recipe.decode(missing.encode()).complete, false);
    for (final bad in <double>[0, -1, double.nan, double.infinity]) {
      expect(() => Recipe(ingredients: ingredients, yieldGrams: bad).validate(),
          throwsFormatException);
      expect(
          () => Recipe(ingredients: ingredients, yieldGrams: 250, servings: bad)
              .validate(),
          throwsFormatException);
      expect(
          () => Recipe(
                  ingredients: [RecipeIngredient(name: 'A', grams: bad)],
                  yieldGrams: 100)
              .validate(),
          throwsFormatException);
    }
  });
  for (final days in [7, 30]) {
    ReportData sample() {
      final end = DateTime(2026, 11, 1, 12),
          start = DateTime(2026, 11, 2 - days);
      return ReportData(
          start: start,
          end: end,
          weights: [
            HealthValuePoint(date: start, value: 80),
            HealthValuePoint(date: end, value: 79.7)
          ],
          food: [
            FoodLogEntry()
              ..date = start
              ..calories = 0,
            FoodLogEntry()
              ..date = end
              ..calories = 2000
          ],
          water: [
            WaterLogEntry()
              ..date = start
              ..volumeMl = 250,
            WaterLogEntry()
              ..date = DateTime(2026, 11, 1)
              ..volumeMl = 2000
          ],
          steps: {start: 0, DateTime(2026, 11, 1): 10000},
          waterGoal: 2000,
          stepGoal: 10000);
    }

    test(
        'report $days days distinguishes missing days and explicit zero; one/no weights',
        () {
      final d = sample();
      expect(d.nutrition.days, 2);
      expect(d.nutrition.mean, 1000);
      expect(d.hydration.mean, 1125);
      expect(d.waterGoalDays, 1);
      expect(d.activity.mean, 5000);
      expect(d.stepGoalDays, 1);
      expect(d.weightChange, closeTo(-.3, 1e-9));
      final empty = ReportData(
          start: d.start,
          end: d.end,
          weights: [d.weights.first],
          food: [],
          water: [],
          steps: {},
          waterGoal: 2000,
          stepGoal: 10000);
      expect(empty.nutrition.mean, isNull);
      expect(empty.activity.mean, isNull);
      expect(empty.weightChange, isNull);
    });
    testWidgets(
        'report $days days renders full PNG at narrow width and large font',
        (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final key = GlobalKey();
      await tester.pumpWidget(MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: const [AppStrings.delegate],
          supportedLocales: AppStrings.supportedLocales,
          theme: AppTheme.build(const ThemeSettings(), Brightness.light),
          home: MediaQuery(
              data: const MediaQueryData(
                  size: Size(320, 800), textScaler: TextScaler.linear(1.6)),
              child: SingleChildScrollView(
                  child: RepaintBoundary(
                      key: key, child: ReportImage(data: sample()))))));
      await tester.pumpAndSettle();
      expect(
          find.textContaining('Compared with current goals'), findsOneWidget);
      expect(tester.takeException(), isNull);
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        expect(image.height, greaterThan(1600));
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        expect(png!.buffer.asUint8List().take(8),
            [137, 80, 78, 71, 13, 10, 26, 10]);
      });
    });
  }
}
