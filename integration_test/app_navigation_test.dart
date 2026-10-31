import 'package:smart_fitness_dashboard/app/dashboard_shell.dart';
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
        i < 100 && find.byType(FloatingBottomBar).evaluate().isEmpty;
        i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.byType(FloatingBottomBar), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('tab-nutrition')));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 30));
    expect(find.text('Сводка дня'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('tab-measurements')));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 30));
    expect(find.text('Антропометрия'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('tab-settings')));
    await tester.pumpAndSettle();
    expect(find.text('Оформление'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('tab-dashboard')));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 30));
    expect(find.text('Питание сегодня'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
