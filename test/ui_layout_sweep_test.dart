import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_fitness_dashboard/core/database/database_provider.dart';
import 'package:smart_fitness_dashboard/core/health/health_connect_service.dart';
import 'package:smart_fitness_dashboard/core/localization/app_strings.dart';
import 'package:smart_fitness_dashboard/core/theme/app_theme.dart';
import 'package:smart_fitness_dashboard/features/dashboard/application/daily_health_provider.dart';
import 'package:smart_fitness_dashboard/features/dashboard/presentation/dashboard_screen.dart';
import 'package:smart_fitness_dashboard/features/dashboard/presentation/widgets/health_metrics_grid.dart';
import 'package:smart_fitness_dashboard/features/dashboard/domain/daily_health_metrics.dart';
import 'package:smart_fitness_dashboard/features/goals/domain/user_goals.dart';
import 'package:smart_fitness_dashboard/features/goals/presentation/user_goals_card.dart';
import 'package:smart_fitness_dashboard/features/measurements/data/body_measurement.dart';
import 'package:smart_fitness_dashboard/features/measurements/presentation/measurements_screen.dart';
import 'package:smart_fitness_dashboard/features/measurements/presentation/widgets/measurement_form_sheet.dart';
import 'package:smart_fitness_dashboard/features/nutrition/application/product_search_provider.dart';
import 'package:smart_fitness_dashboard/features/nutrition/application/saved_products_provider.dart';
import 'package:smart_fitness_dashboard/features/nutrition/data/food_log_entry.dart';
import 'package:smart_fitness_dashboard/features/nutrition/data/food_product.dart';
import 'package:smart_fitness_dashboard/features/nutrition/data/recipe.dart';
import 'package:smart_fitness_dashboard/features/nutrition/presentation/nutrition_screen.dart';
import 'package:smart_fitness_dashboard/features/nutrition/presentation/recipes_screen.dart';
import 'package:smart_fitness_dashboard/features/nutrition/presentation/widgets/add_food_sheet.dart';
import 'package:smart_fitness_dashboard/features/nutrition/presentation/widgets/create_product_form.dart';
import 'package:smart_fitness_dashboard/features/nutrition/presentation/widgets/diary_calendar_sheet.dart';
import 'package:smart_fitness_dashboard/features/nutrition/presentation/widgets/saved_food_widgets.dart';
import 'package:smart_fitness_dashboard/features/onboarding/presentation/onboarding_screen.dart';
import 'package:smart_fitness_dashboard/features/settings/application/reminder_settings_provider.dart';
import 'package:smart_fitness_dashboard/features/settings/domain/theme_settings.dart';
import 'package:smart_fitness_dashboard/features/settings/presentation/settings_screen.dart';
import 'package:smart_fitness_dashboard/shared/widgets/quant_dialog.dart';
import 'package:smart_fitness_dashboard/app/dashboard_shell.dart';
import 'package:smart_fitness_dashboard/shared/widgets/time_series_chart_card.dart';
import 'package:smart_fitness_dashboard/shared/models/metric_point.dart';
import 'package:smart_fitness_dashboard/features/water/presentation/water_balance_card.dart';
import 'package:smart_fitness_dashboard/features/reports/report_screen.dart';
import 'water_navigation_test.dart' show ShellDatabase;
import 'localization_onboarding_test.dart' show LocalNotifications, FakeReset;
import 'package:smart_fitness_dashboard/core/database/data_reset_provider.dart';
import 'package:smart_fitness_dashboard/features/settings/presentation/widgets/data_management_card.dart';

const longName =
    'Домашнее блюдо с очень длинным названием и подробным описанием ингредиентов';
final day = DateTime(2026, 11, 1);
final recipe = Recipe(ingredients: [
  RecipeIngredient(
      name: longName,
      grams: 200,
      calories: 120,
      proteins: 12,
      fats: 4,
      carbs: 9)
], yieldGrams: 180, servings: 2.5);
FoodProduct product() => FoodProduct()
  ..name = longName
  ..calories = 120
  ..proteins = 12
  ..fats = 4
  ..carbs = 9
  ..recipeJson = recipe.encode();

class _Database extends ShellDatabase {
  @override
  Stream<List<FoodLogEntry>> watchFoodLogEntriesForDay(DateTime date) =>
      Stream.value([
        FoodLogEntry()
          ..id = 1
          ..date = date
          ..mealType = 'Завтрак'
          ..productName = longName
          ..weightGrams = 150
          ..calories = 180
          ..proteins = 18
          ..fats = 6
          ..carbs = 13.5
      ]);
  @override
  Stream<List<BodyMeasurement>> watchBodyMeasurementHistory() => Stream.value([
        BodyMeasurement()
          ..id = 1
          ..date = day
          ..waist = 85
          ..note = longName
      ]);
  @override
  Future<BodyMeasurement?> getBodyMeasurementForDay(DateTime date) async =>
      null;
}

class _Health extends DailyHealthNotifier {
  @override
  Future<DailyHealthState> build() async =>
      const DailyHealthState(access: HealthAccess.denied);
}

Future<void> _capture(WidgetTester tester, GlobalKey key, String name) async {
  if (Platform.environment['QUANT_UI_SCREENSHOTS'] != '1') return;
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory('.toolchains/ui-previews').create(recursive: true);
    await File('.toolchains/ui-previews/$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(() => initializeDateFormatting());
  for (final brightness in Brightness.values) {
    for (final width in [320.0, 390.0]) {
      for (final scale in [1.0, 1.6]) {
        testWidgets('UI sweep ${brightness.name}/$width/$scale',
            (tester) async {
          SharedPreferences.setMockInitialValues({});
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetViewInsets);
          if (Platform.environment['QUANT_UI_SCREENSHOTS'] == '1') {
            await tester.runAsync(() async {
              await (FontLoader('MaterialIcons')
                    ..addFont(
                        rootBundle.load('fonts/MaterialIcons-Regular.otf')))
                  .load();
              for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
                await (FontLoader('Inter')
                      ..addFont(
                          rootBundle.load('assets/fonts/Inter-$weight.ttf')))
                    .load();
              }
            });
          }
          final container = ProviderContainer(overrides: [
            databaseServiceProvider.overrideWith((ref) async => _Database()),
            dailyHealthProvider.overrideWith(_Health.new),
            dataResetServiceProvider.overrideWith((ref) async => FakeReset()),
            notificationServiceProvider.overrideWithValue(LocalNotifications()),
            favoriteProductsProvider
                .overrideWith((ref) => Stream.value([product()])),
            frequentProductsProvider
                .overrideWith((ref) => Stream.value([product()])),
            recipesProvider.overrideWith((ref) => Stream.value([product()])),
            productSearchProvider('')
                .overrideWith((ref) => Stream.value([product()])),
          ]);
          addTearDown(container.dispose);
          final cases = <String, Widget>{
            'dashboard':
                const Scaffold(body: SafeArea(child: DashboardScreen())),
            'nutrition': const NutritionScreen(),
            'measurements': const MeasurementsScreen(),
            'settings': const SettingsScreen(),
            'recipes': RecipesScreen(date: day),
            'recipe-form': RecipeEditor(product: product()),
            'food-search':
                Scaffold(body: AddFoodSheet(date: day, initialMeal: 'Завтрак')),
            'food-portion': Scaffold(
                body: AddFoodSheet(
                    date: day, initialMeal: 'Обед', product: product())),
            'product-form': Scaffold(
                body: SingleChildScrollView(
                    child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: CreateProductForm(
                            onCreated: (_) {}, onCancel: () {})))),
            'goals-form':
                const Scaffold(body: EditUserGoalsSheet(initial: UserGoals())),
            'measurement-form': const Scaffold(body: MeasurementFormSheet()),
            'onboarding': const OnboardingScreen(),
            'shell': const DashboardShell(),
            'reset-selective': const Scaffold(
                body: SingleChildScrollView(
                    padding: EdgeInsets.all(16), child: DataManagementCard())),
            'reset-factory': const Scaffold(
                body: SingleChildScrollView(
                    padding: EdgeInsets.all(16), child: DataManagementCard())),
            'water-dialog': Scaffold(
                body: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: WaterBalanceCard(date: day))),
            'calendar': Scaffold(body: DiaryCalendarSheet(selected: day)),
            'health-values': Scaffold(
                body: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: HealthMetricsGrid(
                        loading: false,
                        stepGoal: 10000,
                        metrics: DailyHealthMetrics(
                            fetchedAt: day,
                            activityDataAt: day,
                            bodyDataAt: day,
                            stepsToday: 12345,
                            activeCaloriesToday: 1250,
                            latestWeight: MetricPoint(date: day, value: 150.5),
                            latestBodyFat: MetricPoint(date: day, value: 35.5),
                            weightHistory: [
                              MetricPoint(
                                  date: day.subtract(const Duration(days: 1)),
                                  value: 151),
                              MetricPoint(date: day, value: 150.5)
                            ])))),
            'report-error': const ReportScreen(),
            'chart': Scaffold(
                body: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: TimeSeriesChartCard(
                        history: [
                          MetricPoint(date: day, value: 90),
                          MetricPoint(
                              date: day.add(const Duration(days: 12)),
                              value: 88)
                        ],
                        title: 'Прогресс',
                        subtitle: longName,
                        unit: 'кг',
                        emptyText: longName))),
            'favorites': Scaffold(
                body: SingleChildScrollView(
                    child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: SavedFoods(onSelected: (_) {})))),
            for (final failed in [false, true])
              'favorites-${failed ? 'error' : 'empty'}': ProviderScope(
                  overrides: [
                    favoriteProductsProvider.overrideWith((ref) => failed
                        ? Stream<List<FoodProduct>>.error(StateError('offline'))
                        : Stream.value([])),
                  ],
                  child: Scaffold(
                      body: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: SavedFoods(onSelected: (_) {})))),
          };
          final key = GlobalKey();
          for (final entry in cases.entries) {
            Future<void> settle() async {
              // The busy indicator behind a reset confirmation intentionally animates.
              if (entry.key.startsWith('reset-')) {
                await tester.pump();
                await tester.pump(const Duration(milliseconds: 420));
              } else {
                await tester.pumpAndSettle();
              }
            }

            await tester.pumpWidget(const SizedBox());
            await settle();
            await tester.pumpWidget(UncontrolledProviderScope(
                container: container,
                child: MaterialApp(
                    locale: const Locale('ru'),
                    supportedLocales: AppStrings.supportedLocales,
                    localizationsDelegates: const [
                      AppStrings.delegate,
                      ...GlobalMaterialLocalizations.delegates
                    ],
                    theme: AppTheme.build(const ThemeSettings(), brightness),
                    builder: (context, child) => MediaQuery(
                        data: MediaQuery.of(context)
                            .copyWith(textScaler: TextScaler.linear(scale)),
                        child: RepaintBoundary(key: key, child: child!)),
                    home: entry.value)));
            await settle();
            if (entry.key.startsWith('reset-')) {
              final button = find.byKey(ValueKey(entry.key == 'reset-selective'
                  ? 'data-clear-selective'
                  : 'data-clear-factory'));
              await tester.ensureVisible(button);
              await tester.tap(button);
              await settle();
            }
            if (entry.key == 'water-dialog') {
              await tester
                  .ensureVisible(find.byKey(const ValueKey('water-custom')));
              await tester.tap(find.byKey(const ValueKey('water-custom')));
              await settle();
            }
            if (entry.key.startsWith('favorites')) {
              await tester.tap(find.text('Избранные'));
              await settle();
            }
            expect(tester.takeException(), isNull,
                reason: '${entry.key} initial');
            final frequentLabel = find.text('Часто используемые');
            if (frequentLabel.evaluate().isNotEmpty) {
              expect(
                  tester
                      .renderObject<RenderParagraph>(frequentLabel.first)
                      .didExceedMaxLines,
                  isFalse,
                  reason: '${entry.key} chip label must not fade or truncate');
            }
            final prefix =
                '${brightness.name}-${width.round()}-$scale-${entry.key}';
            await _capture(tester, key, '$prefix-top');
            if (Platform.environment['QUANT_UI_SCREENSHOTS'] == '1') {
              if (entry.key == 'nutrition') {
                await tester.ensureVisible(find.byType(WaterBalanceCard));
                await settle();
                await _capture(tester, key, '$prefix-water');
              }
              if (entry.key == 'settings') {
                await tester.scrollUntilVisible(
                    find.text('Проверить уведомление'), 300,
                    scrollable: find.byType(Scrollable).first);
                await settle();
                await _capture(tester, key, '$prefix-reminders');
              }
            }
            final scrolls = find
                .byType(Scrollable)
                .hitTestable()
                .evaluate()
                .map((e) => (e as StatefulElement).state)
                .whereType<ScrollableState>()
                .where((s) =>
                    s.position.axis == Axis.vertical &&
                    s.position.viewportDimension > 150)
                .toList();
            if (scrolls.isNotEmpty) {
              final position = scrolls.first.position;
              for (var n = 0;
                  n < 30 && position.pixels < position.maxScrollExtent;
                  n++) {
                position.jumpTo(
                    (position.pixels + position.viewportDimension * .8)
                        .clamp(0, position.maxScrollExtent));
                await settle();
                expect(tester.takeException(), isNull,
                    reason: '${entry.key} scrolled $n');
              }
            }
            await _capture(tester, key, '$prefix-bottom');
            if (entry.key == 'recipe-form') {
              tester.view.viewInsets = const FakeViewPadding(bottom: 280);
              await settle();
              await tester.ensureVisible(find.text('Сохранить'));
              await settle();
              expect(tester.getBottomLeft(find.text('Сохранить')).dy,
                  lessThanOrEqualTo(520));
              expect(tester.takeException(), isNull, reason: 'recipe keyboard');
              tester.view.viewInsets = const FakeViewPadding();
              await settle();
              await tester.ensureVisible(find.text('Добавить ингредиент'));
              await tester.tap(find.text('Добавить ингредиент'));
              await settle();
              tester.view.viewInsets = const FakeViewPadding(bottom: 280);
              await settle();
              expect(tester.getBottomLeft(find.byType(ListView).last).dy,
                  lessThanOrEqualTo(520));
              expect(tester.takeException(), isNull,
                  reason: 'ingredient search keyboard');
              await _capture(tester, key, '$prefix-ingredient-keyboard');
              tester.view.viewInsets = const FakeViewPadding();
            }
            if (entry.key == 'onboarding') {
              for (var step = 2; step <= 3; step++) {
                await tester.tap(find.text('Далее'));
                await settle();
                expect(tester.takeException(), isNull,
                    reason: 'onboarding step $step');
                await _capture(tester, key, '$prefix-step-$step');
              }
            }
          }
          await tester.pumpWidget(const SizedBox());
          await tester.pumpAndSettle();
        });
      }
    }
  }
  for (final brightness in Brightness.values) {
    testWidgets('forms remain reachable above keyboard: ${brightness.name}',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      final container = ProviderContainer(overrides: [
        databaseServiceProvider.overrideWith((ref) async => _Database()),
        notificationServiceProvider.overrideWithValue(LocalNotifications()),
        favoriteProductsProvider.overrideWith((ref) => Stream.value([])),
        productSearchProvider('').overrideWith((ref) => Stream.value([])),
      ]);
      addTearDown(container.dispose);
      final cases = <String, (Widget, String)>{
        'measurement': (const MeasurementFormSheet(), 'Сохранить замер'),
        'goals': (
          const EditUserGoalsSheet(initial: UserGoals()),
          'Сохранить цели'
        ),
        'portion': (
          AddFoodSheet(date: day, initialMeal: 'Обед', product: product()),
          'Добавить в дневник'
        ),
        'product': (
          AddFoodSheet(date: day, initialMeal: 'Обед'),
          'Сохранить продукт'
        ),
      };
      for (final entry in cases.entries) {
        tester.view.viewInsets = const FakeViewPadding();
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        await tester.pumpWidget(UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
                locale: const Locale('ru'),
                supportedLocales: AppStrings.supportedLocales,
                localizationsDelegates: const [
                  AppStrings.delegate,
                  ...GlobalMaterialLocalizations.delegates
                ],
                theme: AppTheme.build(const ThemeSettings(), brightness),
                builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(textScaler: const TextScaler.linear(1.6)),
                    child: child!),
                home: Builder(
                    builder: (context) => Scaffold(
                        body: TextButton(
                            child: const Text('open'),
                            onPressed: () => showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                useSafeArea: true,
                                builder: (_) => entry.value.$1)))))));
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        if (entry.key == 'product') {
          await tester.ensureVisible(find.text('Создать свой продукт'));
          await tester.tap(find.text('Создать свой продукт'));
          await tester.pumpAndSettle();
        }
        await tester.enterText(
            find.byType(TextFormField).first, 'invalid number');
        tester.view.viewInsets = const FakeViewPadding(bottom: 280);
        await tester.pumpAndSettle();
        final save = find.text(entry.value.$2);
        await tester.ensureVisible(save);
        await tester.pumpAndSettle();
        expect(tester.getBottomLeft(save).dy, lessThanOrEqualTo(420),
            reason: entry.key);
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull,
            reason: '${entry.key} validation/keyboard');
        final scroll = find
            .byType(Scrollable)
            .evaluate()
            .map((e) => (e as StatefulElement).state)
            .whereType<ScrollableState>()
            .firstWhere((state) => state.position.axis == Axis.vertical);
        scroll.position.jumpTo(0);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull,
            reason: '${entry.key} validation messages');
      }
      tester.view.viewInsets = const FakeViewPadding();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  }
  testWidgets(
      'dialog scrolls long content above keyboard and separates overflow actions',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => QuantDialog(
                                title: const Text(longName),
                                content:
                                    Text(List.filled(8, longName).join('\n')),
                                actions: [
                                  TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text(
                                          'Cancel and return to the form')),
                                  FilledButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text(
                                          'Save all the entered changes'))
                                ])),
                    child: const Text('open'))))));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(tester.widget<AlertDialog>(find.byType(AlertDialog)).scrollable,
        isTrue);
    expect(
        tester
            .widget<AlertDialog>(find.byType(AlertDialog))
            .actionsOverflowButtonSpacing,
        12);
    expect(tester.takeException(), isNull);
  });
}
