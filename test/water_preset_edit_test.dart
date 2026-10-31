import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_fitness_dashboard/core/backup/backup_document.dart';
import 'package:smart_fitness_dashboard/core/database/database_provider.dart';
import 'package:smart_fitness_dashboard/features/goals/domain/user_goals.dart';
import 'package:smart_fitness_dashboard/features/water/application/water_presets_provider.dart';
import 'package:smart_fitness_dashboard/features/water/application/water_provider.dart';
import 'package:smart_fitness_dashboard/features/water/data/water_log_entry.dart';
import 'package:smart_fitness_dashboard/features/water/presentation/water_balance_card.dart';
import 'water_custom_test.dart' show WaterDatabase;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
      'legacy additional buttons migrate; edits and empty list survive restart and backup',
      () async {
    SharedPreferences.setMockInitialValues({
      WaterPresetsRepository.legacyKey: ['700']
    });
    var container = ProviderContainer();
    expect(await container.read(waterPresetsProvider.future),
        [150, 250, 500, 700]);
    final notifier = container.read(waterPresetsProvider.notifier);
    await notifier.replace(150, 100);
    await notifier.remove(250);
    await expectLater(notifier.replace(100, 500), throwsStateError);
    await expectLater(notifier.replace(100, 0), throwsFormatException);
    // Separate operations serialize rather than losing one another's changes.
    await Future.wait([notifier.add(330), notifier.add(450)]);
    container.dispose();
    container = ProviderContainer();
    addTearDown(container.dispose);
    expect(await container.read(waterPresetsProvider.future),
        [100, 330, 450, 500, 700]);
    await container.read(waterPresetsProvider.notifier).save([]);
    expect(await WaterPresetsRepository().load(), isEmpty);
    final doc = BackupDocument(
        goals: const UserGoals(),
        products: [],
        entries: [],
        measurements: [],
        waterPresets: []);
    expect(BackupDocument.decode(doc.encode()).waterPresets, isEmpty);
    final legacy = jsonDecode(doc.encode()) as Map<String, dynamic>;
    legacy['version'] = 6;
    legacy['waterPresets'] = [700];
    expect(BackupDocument.decode(jsonEncode(legacy)).waterPresets,
        [150, 250, 500, 700]);
  });

  testWidgets(
      'long press edits or removes only button; tap adds once; deletion undo restores',
      (tester) async {
    final day = DateTime(2026, 11, 1);
    final db = WaterDatabase();
    final container = ProviderContainer(overrides: [
      databaseServiceProvider.overrideWith((ref) async => db),
      waterProvider(day).overrideWith((ref) => Stream.value(<WaterLogEntry>[])),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
            home: Scaffold(
                body: SingleChildScrollView(
                    child: WaterBalanceCard(date: day))))));
    await tester.pumpAndSettle();
    await tester.longPress(find.byKey(const ValueKey('water-preset-250')));
    await tester.pumpAndSettle();
    expect(db.portions, isEmpty);
    await tester.tap(find.text('Изменить'));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField))
            .controller!
            .text,
        '250');
    await tester.enterText(find.byType(TextFormField), '150');
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();
    expect(find.text('Кнопка с таким объемом уже есть'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '0');
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();
    expect(find.text('Введите от 1 до 5000 мл'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '700');
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();
    expect(db.portions, isEmpty);
    expect(await WaterPresetsRepository().load(), [150, 500, 700]);
    await tester.tap(find.byKey(const ValueKey('water-preset-700')));
    await tester.pumpAndSettle();
    expect(db.portions, [700]);
    await tester.longPress(find.byKey(const ValueKey('water-preset-700')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Удалить'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('water-preset-700')), findsNothing);
    expect(db.portions, [700]);
    await tester.tap(find.text('Отменить'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('water-preset-700')), findsOneWidget);
    expect(await WaterPresetsRepository().load(), [150, 500, 700]);
    expect(db.portions, [700]);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
