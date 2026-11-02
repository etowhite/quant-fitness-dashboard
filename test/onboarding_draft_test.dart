import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_fitness_dashboard/features/goals/data/user_goals_repository.dart';
import 'package:smart_fitness_dashboard/features/goals/domain/user_goals.dart';
import 'package:smart_fitness_dashboard/features/goals/application/user_goals_provider.dart';
import 'package:smart_fitness_dashboard/features/onboarding/application/onboarding_provider.dart';
import 'package:smart_fitness_dashboard/core/localization/locale_provider.dart';
import 'localization_onboarding_test.dart' show LocalizedHarness;

class CountingGoals extends UserGoalsRepository {
  int writes = 0;
  UserGoals value = const UserGoals(
      calories: 2300, proteins: 160, steps: 8500, waterMl: 2250);
  @override
  Future<UserGoals> load() async => value;
  @override
  Future<void> save(UserGoals goals) async {
    writes++;
    value = goals;
  }
}

void main() {
  testWidgets(
      'goal taps update only local rows; Next writes once; completion does not repeat save',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final repo = CountingGoals();
    final c = ProviderContainer(
        overrides: [userGoalsRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(c.dispose);
    await c.read(localeProvider.future);
    await c.read(userGoalsProvider.future);
    await c.read(onboardingProvider.future);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: c, child: const LocalizedHarness()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Далее'));
    await tester.pumpAndSettle();
    final pageView = tester.widget<PageView>(find.byType(PageView));
    final pageState = tester.state(find.byType(PageView));
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.byTooltip('Увеличить').first);
      await tester.pump();
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(
          identical(tester.widget<PageView>(find.byType(PageView)), pageView),
          isTrue);
    }
    expect(find.text('2500 ккал'), findsOneWidget);
    await tester.tap(find.text('Сушка'));
    await tester.pump();
    expect(find.text('1800 ккал'), findsOneWidget);
    expect(identical(tester.widget<PageView>(find.byType(PageView)), pageView),
        isTrue);
    expect(identical(tester.state(find.byType(PageView)), pageState), isTrue);
    expect(identical(tester.widget<MaterialApp>(find.byType(MaterialApp)), app),
        isTrue);
    expect(repo.writes, 0);
    expect(c.read(effectiveUserGoalsProvider).calories, 2300);
    await tester.tap(find.text('Далее'));
    await tester.pumpAndSettle();
    expect(repo.writes, 1);
    expect(repo.value.calories, 1800);
    expect(repo.value.proteins, 160);
    expect(repo.value.steps, 8500);
    await tester.tap(find.text('Продолжить без подключения'));
    await tester.pumpAndSettle();
    expect(repo.writes, 1);
    expect(find.text('dashboard sentinel'), findsOneWidget);
  });
}
