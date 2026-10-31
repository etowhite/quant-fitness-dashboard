import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:smart_fitness_dashboard/features/dashboard/domain/daily_health_metrics.dart';
import 'package:smart_fitness_dashboard/features/dashboard/presentation/weight_history.dart';
import 'package:smart_fitness_dashboard/features/dashboard/presentation/widgets/weight_chart_card.dart';
import 'package:smart_fitness_dashboard/features/dashboard/presentation/widgets/nutrition_summary_card.dart';
import 'package:smart_fitness_dashboard/features/nutrition/application/daily_food_diary.dart';
import 'package:smart_fitness_dashboard/features/goals/domain/user_goals.dart';
import 'package:smart_fitness_dashboard/features/dashboard/presentation/widgets/health_metrics_grid.dart';
import 'package:smart_fitness_dashboard/features/nutrition/presentation/widgets/daily_nutrition_summary.dart';

void main() {
  setUpAll(() => initializeDateFormatting('ru'));

  testWidgets(
      'custom goals drive calorie, macro and step progress consistently',
      (tester) async {
    const goals = UserGoals(
        calories: 1000, proteins: 100, fats: 50, carbs: 200, steps: 5000);
    const totals =
        NutritionTotals(calories: 500, proteins: 50, fats: 25, carbs: 100);
    final metrics = DailyHealthMetrics(
        fetchedAt: DateTime(2026, 10, 31),
        stepsToday: 2500,
        activeCaloriesToday: 200,
        latestWeight: null,
        latestBodyFat: null,
        weightHistory: []);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
      child: Column(children: [
        const NutritionSummaryCard(totals: totals, goals: goals),
        const DailyNutritionSummary(totals: totals, goals: goals),
        HealthMetricsGrid(
            metrics: metrics, loading: false, stepGoal: goals.steps),
      ]),
    ))));
    expect(
        tester
            .widget<CircularProgressIndicator>(
                find.byType(CircularProgressIndicator))
            .value,
        0.5);
    for (final bar in tester.widgetList<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator))) {
      expect(bar.value, 0.5);
    }
    expect(find.text('500 / 1000 ккал'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  test(
      'weight delta uses earlier timestamp, not input order or duplicate instant',
      () {
    final first = HealthValuePoint(date: DateTime(2026, 10, 29), value: 80);
    final last = HealthValuePoint(date: DateTime(2026, 10, 31), value: 79.7);
    final metrics = DailyHealthMetrics(
        fetchedAt: last.date,
        stepsToday: null,
        activeCaloriesToday: null,
        latestWeight: last,
        latestBodyFat: null,
        weightHistory: [last, first, last]);
    expect(orderedWeights(metrics.weightHistory), hasLength(2));
    expect(weightDelta(metrics), closeTo(-0.3, 0.00001));
  });

  testWidgets('single timestamp shows empty chart; flat weight range is valid',
      (tester) async {
    final date = DateTime(2026, 10, 31);
    final point = HealthValuePoint(date: date, value: 80);
    Widget host(List<HealthValuePoint> history) => MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: WeightChartCard(history: history))));
    await tester.pumpWidget(host([point, point]));
    expect(find.text('Для графика нужны хотя бы два измерения веса.'),
        findsOneWidget);
    await tester.pumpWidget(host([
      point,
      HealthValuePoint(date: date.add(const Duration(hours: 1)), value: 80),
    ]));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('over-goal calories and macros clamp progress to one',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
      body: SingleChildScrollView(
          child: NutritionSummaryCard(
        totals: NutritionTotals(
            calories: 2400, proteins: 160, fats: 80, carbs: 260),
      )),
    )));
    expect(find.text('ккал сверх нормы'), findsOneWidget);
    expect(
        tester
            .widget<CircularProgressIndicator>(
                find.byType(CircularProgressIndicator))
            .value,
        1);
    for (final bar in tester.widgetList<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator))) {
      expect(bar.value, 1);
    }
    expect(tester.takeException(), isNull);
  });
}
