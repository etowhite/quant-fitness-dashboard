import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_fitness_dashboard/core/localization/app_language.dart';
import 'package:smart_fitness_dashboard/core/localization/locale_provider.dart';
import 'package:smart_fitness_dashboard/features/goals/application/user_goals_provider.dart';
import 'package:smart_fitness_dashboard/features/onboarding/application/onboarding_provider.dart';
import 'package:smart_fitness_dashboard/features/settings/application/theme_settings_provider.dart';
import 'package:smart_fitness_dashboard/features/settings/application/reminder_settings_provider.dart';
import 'package:smart_fitness_dashboard/features/settings/presentation/widgets/appearance_card.dart';
import 'package:smart_fitness_dashboard/shared/widgets/expressive_motion.dart';
import 'package:smart_fitness_dashboard/shared/widgets/labeled_field.dart';
import 'localization_onboarding_test.dart'
    show LocalizedHarness, LocalNotifications;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<ProviderContainer> mount(
      WidgetTester tester, AppLanguage language) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer(overrides: [
      notificationServiceProvider.overrideWithValue(LocalNotifications()),
    ]);
    addTearDown(container.dispose);
    await container.read(localeProvider.notifier).save(language);
    await container.read(themeSettingsProvider.future);
    await container.read(userGoalsProvider.future);
    await container.read(onboardingProvider.future);
    await container.read(reminderSettingsProvider.future);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container, child: const LocalizedHarness()));
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('reminder buttons have equal 48px bounds and 12px gap',
      (tester) async {
    final container = await mount(tester, AppLanguage.ru);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container, child: const LocalizedHarness(settings: true)));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Проверить уведомление'), 300,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    final exact = find.ancestor(
        of: find.text('Разрешить точные напоминания'),
        matching: find.byWidgetPredicate((w) => w is OutlinedButton));
    final test = find.ancestor(
        of: find.text('Проверить уведомление'),
        matching: find.byWidgetPredicate((w) => w is FilledButton));
    expect(tester.getSize(exact).height, 48);
    expect(tester.getSize(test).height, 48);
    expect(tester.getSize(exact).width, tester.getSize(test).width);
    expect(tester.getTopLeft(test).dy - tester.getBottomLeft(exact).dy, 12);
    final list = tester.widget<ListView>(find.byType(ListView));
    expect(list.padding, const EdgeInsets.fromLTRB(16, 12, 16, 120));
    expect(tester.takeException(), isNull);
  });

  for (final language in [AppLanguage.ru, AppLanguage.en]) {
    testWidgets(
        'onboarding capsules and import share one scroll at 320px: $language',
        (tester) async {
      await mount(tester, language);
      expect(find.byType(SegmentedButton<ThemeMode>), findsNothing);
      expect(find.byType(SegmentedButton<AppLanguage>), findsNothing);
      final import = find.text(language == AppLanguage.ru
          ? 'Импорт резервной копии JSON'
          : 'Import JSON backup');
      final scroll = find.ancestor(
          of: import, matching: find.byType(SingleChildScrollView));
      expect(scroll, findsOneWidget);
      expect(find.descendant(of: scroll, matching: find.byType(AppearanceCard)),
          findsOneWidget);
      final light = find.text(language == AppLanguage.ru ? 'Светлая' : 'Light');
      await tester.ensureVisible(light);
      await tester.pumpAndSettle();
      final label = tester.widget<Text>(light);
      expect(label.maxLines, 1);
      expect(label.softWrap, false);
      expect(find.byType(CapsuleChoice), findsWidgets);
      await tester.ensureVisible(import);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'all three onboarding goals accept exact keyboard values and reject bounds',
      (tester) async {
    final container = await mount(tester, AppLanguage.ru);
    await tester.tap(find.text('Далее'));
    await tester.pumpAndSettle();
    for (final goal in [('Калории', 850), ('Шаги', 12345), ('Вода', 2330)]) {
      final target = find.byKey(ValueKey('edit-goal-${goal.$1}'));
      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.pumpAndSettle();
      final input = find.byKey(const ValueKey('goal-value-input'));
      expect(find.ancestor(of: input, matching: find.byType(LabeledField)),
          findsOneWidget);
      expect(
          tester
              .widget<TextField>(
                  find.descendant(of: input, matching: find.byType(TextField)))
              .decoration
              ?.labelText,
          isNull);
      await tester.enterText(input, '0');
      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.enterText(input, '${goal.$2}');
      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
    }
    final goals = container.read(effectiveUserGoalsProvider);
    expect(goals.calories, 850);
    expect(goals.steps, 12345);
    expect(goals.waterMl, 2330);
    expect(tester.takeException(), isNull);
  });
}
