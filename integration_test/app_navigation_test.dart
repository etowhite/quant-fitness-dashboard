import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_fitness_dashboard/core/database/database_provider.dart';
import 'package:smart_fitness_dashboard/core/database/local_day.dart';
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
    // Interrupt the selected-tab indicator repeatedly, without waiting for its
    // previous animation. The retained page must never leave outgoing routes.
    for (var i = 0; i < 16; i++) {
      final tab = AppTab.values[i % 4];
      await tester.tap(find.byKey(ValueKey('tab-${tab.name}')));
      await tester.pump(const Duration(milliseconds: 20));
      expect(find.byType(RetainedTabView), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    await tester.tap(find.byKey(const ValueKey('tab-dashboard')));
    await tester.pumpAndSettle();
    const channel = MethodChannel('quant/home_widgets');
    final nativeLayouts =
        await channel.invokeListMethod<String>('testWidgetViews');
    expect(nativeLayouts, hasLength(20));
    final container =
        ProviderScope.containerOf(tester.element(find.byType(DashboardShell)));
    final db = await container.read(databaseServiceProvider.future);
    final today = localDay(DateTime.now());
    final before = await db.watchWater(today).first;
    final initial = before.fold<int>(0, (sum, r) => sum + r.volumeMl);
    final saved = db.watchWater(today).firstWhere((rows) =>
        rows.fold<int>(0, (sum, r) => sum + r.volumeMl) == initial + 750);
    for (var i = 0; i < 3; i++) {
      await channel.invokeMethod<void>('testWidgetAddWater');
    }
    await saved.timeout(const Duration(seconds: 90));
    // Exercise native MediaStore and FileProvider with an actual PNG, not a path.
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawColor(const Color(0xFF121212), BlendMode.src);
    final picture = recorder.endRecording();
    final image = await picture.toImage(320, 240);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    picture.dispose();
    const reports = MethodChannel('quant/report_image');
    expect(await reports.invokeMethod<bool>('save', png!.buffer.asUint8List()),
        true);
    expect(await reports.invokeMethod<bool>('share', png.buffer.asUint8List()),
        true);
    expect(tester.takeException(), isNull);
  });
}
