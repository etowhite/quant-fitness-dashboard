import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_fitness_dashboard/features/water/application/water_provider.dart';
import 'package:smart_fitness_dashboard/features/water/data/water_log_entry.dart';
import 'package:smart_fitness_dashboard/features/water/presentation/water_balance_card.dart';
import 'package:smart_fitness_dashboard/features/goals/application/user_goals_provider.dart';
import 'package:smart_fitness_dashboard/features/goals/domain/user_goals.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets(
      'water progress uses user goal and selected day; quick portions available',
      (tester) async {
    final day = DateTime(2026, 10, 31);
    await tester.pumpWidget(ProviderScope(overrides: [
      effectiveUserGoalsProvider
          .overrideWithValue(const UserGoals(waterMl: 1000)),
      waterProvider(day).overrideWith((ref) => Stream.value([
            WaterLogEntry()
              ..date = day
              ..recordedAt = day
              ..volumeMl = 250
          ])),
    ], child: MaterialApp(home: Scaffold(body: WaterBalanceCard(date: day)))));
    await tester.pumpAndSettle();
    expect(find.text('250 / 1000 мл'), findsOneWidget);
    expect(
        tester
            .widget<LinearProgressIndicator>(
                find.byType(LinearProgressIndicator))
            .value,
        .25);
    for (final n in [150, 250, 500]) {
      expect(find.text('+$n мл'), findsOneWidget);
    }
    expect(find.byTooltip('Отменить последнюю порцию'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
