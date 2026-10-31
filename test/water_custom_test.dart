import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_fitness_dashboard/core/database/database_provider.dart';
import 'package:smart_fitness_dashboard/core/database/isar_database_service.dart';
import 'package:smart_fitness_dashboard/core/backup/backup_document.dart';
import 'package:smart_fitness_dashboard/features/goals/domain/user_goals.dart';
import 'package:smart_fitness_dashboard/features/water/application/water_presets_provider.dart';
import 'package:smart_fitness_dashboard/features/water/application/water_provider.dart';
import 'package:smart_fitness_dashboard/features/water/presentation/water_balance_card.dart';
import 'package:smart_fitness_dashboard/features/water/data/water_log_entry.dart';

class WaterDatabase implements IsarDatabaseService {
  final portions = <int>[];
  @override
  Future<int> addWater(DateTime date, int volumeMl) async {
    portions.add(volumeMl);
    return portions.length;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
      'custom portions persist, reject invalid input and roundtrip through backup',
      () async {
    final repository = WaterPresetsRepository();
    await repository.save([330, 750, 330]);
    expect(await WaterPresetsRepository().load(), [330, 750]);
    await expectLater(repository.save([0]), throwsFormatException);
    await expectLater(repository.save([5001]), throwsFormatException);
    final doc = BackupDocument(
        goals: const UserGoals(),
        products: [],
        entries: [],
        measurements: [],
        waterPresets: [330, 750]);
    expect(BackupDocument.decode(doc.encode()).waterPresets, [330, 750]);
    final old = jsonDecode(doc.encode()) as Map<String, dynamic>;
    old['version'] = 4;
    old.remove('waterPresets');
    expect(BackupDocument.decode(jsonEncode(old)).waterPresets,
        WaterPresetsRepository.defaults);
  });
  testWidgets(
      'custom dialog validates and adds chosen day portion with persistent quick button',
      (tester) async {
    final day = DateTime(2026, 10, 31);
    final db = WaterDatabase();
    final ref = ProviderContainer(overrides: [
      databaseServiceProvider.overrideWith((ref) async => db),
      waterProvider(day).overrideWith((ref) => Stream.value(<WaterLogEntry>[])),
    ]);
    addTearDown(ref.dispose);
    await ref.read(waterPresetsProvider.future);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: ref,
        child: MaterialApp(home: Scaffold(body: WaterBalanceCard(date: day)))));
    await tester.pumpAndSettle();
    final buttons = tester.widget<Wrap>(find.byType(Wrap));
    expect(buttons.spacing, 10);
    expect(buttons.runSpacing, 10);
    for (final button
        in tester.widgetList<OutlinedButton>(find.byType(OutlinedButton))) {
      expect(button.style?.tapTargetSize, MaterialTapTargetSize.shrinkWrap);
    }
    await tester.tap(find.text('Свой объем'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Добавить воду'));
    await tester.pumpAndSettle();
    expect(find.text('Введите от 1 до 5000 мл'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '330');
    await tester.tap(find.byType(CheckboxListTile));
    await tester.tap(find.text('Добавить воду'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(db.portions, [330]);
    expect(await WaterPresetsRepository().load(), [150, 250, 330, 500]);
    expect(find.text('+330 мл'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
