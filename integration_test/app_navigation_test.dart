import 'package:smart_fitness_dashboard/features/settings/data/app_preferences_repository.dart';
import 'package:smart_fitness_dashboard/core/localization/app_language.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smart_fitness_dashboard/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app initializes Isar and navigates all four tabs',
      (tester) async {
    await (await SharedPreferences.getInstance())
        .setBool('hasCompletedOnboarding', true);
    await AppPreferencesRepository().save(language: AppLanguage.ru);
    await app.main();
    for (var i = 0;
        i < 100 && find.byType(NavigationBar).evaluate().isEmpty;
        i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.byType(NavigationBar), findsOneWidget);
    final navigation = find.byType(NavigationBar);
    await tester
        .tap(find.descendant(of: navigation, matching: find.text('Питание')));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 30));
    expect(find.text('Сводка дня'), findsOneWidget);
    await tester
        .tap(find.descendant(of: navigation, matching: find.text('Замеры')));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 30));
    expect(find.text('Антропометрия'), findsOneWidget);
    await tester
        .tap(find.descendant(of: navigation, matching: find.text('Настройки')));
    await tester.pumpAndSettle();
    expect(find.text('Оформление'), findsOneWidget);
    await tester
        .tap(find.descendant(of: navigation, matching: find.text('Дашборд')));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 30));
    expect(find.text('Питание сегодня'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
