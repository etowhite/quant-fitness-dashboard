import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_fitness_dashboard/core/database/database_provider.dart';
import 'package:smart_fitness_dashboard/core/localization/app_strings.dart';
import 'package:smart_fitness_dashboard/core/theme/app_spacing.dart';
import 'package:smart_fitness_dashboard/core/theme/app_theme.dart';
import 'package:smart_fitness_dashboard/features/settings/domain/theme_settings.dart';
import 'package:smart_fitness_dashboard/features/settings/presentation/widgets/data_management_card.dart';
import 'package:smart_fitness_dashboard/features/water/application/water_presets_provider.dart';
import 'package:smart_fitness_dashboard/features/water/application/water_provider.dart';
import 'package:smart_fitness_dashboard/features/water/data/water_log_entry.dart';
import 'package:smart_fitness_dashboard/features/water/presentation/water_balance_card.dart';
import 'water_custom_test.dart' show WaterDatabase;

class _Database extends WaterDatabase {
  int undos = 0;
  @override
  Future<bool> undoWater(DateTime date) async {
    undos++;
    return true;
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final brightness in Brightness.values) {
    testWidgets('action geometry in $brightness, narrow screens and large text',
        (tester) async {
      final day = DateTime(2026, 11, 1);
      final db = _Database();
      final container = ProviderContainer(overrides: [
        databaseServiceProvider.overrideWith((ref) async => db),
        waterProvider(day).overrideWith((ref) => Stream.value([
              WaterLogEntry()
                ..date = day
                ..recordedAt = day
                ..volumeMl = 250
            ])),
      ]);
      addTearDown(container.dispose);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.devicePixelRatio = 1;
      for (final width in [320.0, 280.0]) {
        tester.view.physicalSize = Size(width, 1200);
        for (final scale in [1.0, 1.6, 2.0]) {
          for (final presets in [
            <int>[150, 250, 500, 700],
            <int>[]
          ]) {
            await container.read(waterPresetsProvider.notifier).save(presets);
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
                    home: MediaQuery(
                        data: MediaQueryData(
                            textScaler: TextScaler.linear(scale)),
                        child: Scaffold(
                            body: SingleChildScrollView(
                                child: Column(children: [
                          const DataManagementCard(),
                          WaterBalanceCard(date: day)
                        ])))))));
            await tester.pumpAndSettle();
            final custom =
                tester.getRect(find.byKey(const ValueKey('water-custom')));
            final undo =
                tester.getRect(find.byKey(const ValueKey('water-undo')));
            expect(custom.center.dy, closeTo(undo.center.dy, .01),
                reason: '$width/$scale/$presets');
            expect(custom.height, closeTo(undo.height, .01));
            expect(undo.width, closeTo(undo.height, .01));
            expect(undo.left - custom.right, closeTo(AppSpacing.chipGap, .01));
            final label = tester.getRect(find.text('Свой объем'));
            expect(label.top, greaterThanOrEqualTo(custom.top));
            expect(label.bottom, lessThanOrEqualTo(custom.bottom));
            final addIcon = find.descendant(
                of: find.byKey(const ValueKey('water-custom')),
                matching: find.byType(Icon));
            if (addIcon.evaluate().isNotEmpty) {
              final minusIcon = tester.getCenter(find.descendant(
                  of: find.byKey(const ValueKey('water-undo')),
                  matching: find.byType(Icon)));
              expect(tester.getCenter(addIcon).dy, closeTo(minusIcon.dy, .01));
            }
            final selective = tester
                .getRect(find.byKey(const ValueKey('data-clear-selective')));
            final factory = tester
                .getRect(find.byKey(const ValueKey('data-clear-factory')));
            expect(selective.left, factory.left);
            expect(selective.width, factory.width);
            expect(factory.top - selective.bottom,
                closeTo(AppSpacing.actionGap, .01));
            expect(tester.takeException(), isNull,
                reason: '$width/$scale/$presets');
          }
        }
      }
      await tester.ensureVisible(find.byKey(const ValueKey('water-undo')));
      await tester.tap(find.byKey(const ValueKey('water-undo')));
      await tester.pumpAndSettle();
      expect(db.undos, 1);
      await tester.tap(find.byKey(const ValueKey('water-custom')));
      await tester.pumpAndSettle();
      expect(find.text('Свой объем воды'), findsOneWidget);
      await tester.tap(find.text('Отмена'));
      await tester.pumpAndSettle();
      expect(db.portions, isEmpty);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  }
}
