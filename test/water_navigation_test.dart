import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_fitness_dashboard/app/dashboard_shell.dart';
import 'package:smart_fitness_dashboard/core/database/database_provider.dart';
import 'package:smart_fitness_dashboard/core/database/isar_database_service.dart';
import 'package:smart_fitness_dashboard/core/home_widgets/home_widgets.dart';
import 'package:smart_fitness_dashboard/features/nutrition/data/food_log_entry.dart';
import 'package:smart_fitness_dashboard/features/measurements/data/body_measurement.dart';
import 'package:smart_fitness_dashboard/features/water/data/water_log_entry.dart';
import 'package:smart_fitness_dashboard/features/water/presentation/water_balance_card.dart';
import 'package:smart_fitness_dashboard/features/settings/application/reminder_settings_provider.dart';
import 'localization_onboarding_test.dart' show LocalNotifications;

class ShellDatabase implements IsarDatabaseService {
  final portions = <int>[];
  @override
  Stream<List<FoodLogEntry>> watchFoodLogEntriesForDay(DateTime date) =>
      Stream.value([]);
  @override
  Stream<List<BodyMeasurement>> watchBodyMeasurementHistory() =>
      Stream.value([]);
  @override
  Stream<Set<DateTime>> watchRecordedDiaryDates() =>
      Stream.value({DateTime.now()});
  @override
  Stream<List<WaterLogEntry>> watchWater(DateTime date) => Stream.value([]);
  @override
  Future<int> addWater(DateTime day, int amount) async {
    portions.add(amount);
    return portions.length;
  }

  @override
  Future<bool> close() async => true;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() => initializeDateFormatting());
  testWidgets(
      'water exists only in Nutrition, widget route opens it and adding still works',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    HomeWidgets.route.value = null;
    final db = ShellDatabase();
    final container = ProviderContainer(overrides: [
      databaseServiceProvider.overrideWith((ref) async => db),
      notificationServiceProvider.overrideWithValue(LocalNotifications()),
    ]);
    addTearDown(container.dispose);
    addTearDown(() => HomeWidgets.route.value = null);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: DashboardShell())));
    await tester.pumpAndSettle();
    expect(find.byType(WaterBalanceCard), findsNothing);
    expect(tester.widget<Scaffold>(find.byType(Scaffold).first).extendBody,
        isTrue);
    expect(
        tester
            .widget<Scaffold>(find.byType(Scaffold).first)
            .bottomNavigationBar,
        isNull);
    HomeWidgets.route.value = 'water';
    await tester.pumpAndSettle();
    expect(container.read(selectedTabProvider), AppTab.nutrition);
    expect(find.byType(WaterBalanceCard), findsOneWidget);
    await tester.drag(
        find.byType(ListView).hitTestable().first, const Offset(0, 1000));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Предыдущий день'));
    await tester.pumpAndSettle();
    final today = DateTime.now();
    final currentDay = DateTime(today.year, today.month, today.day);
    expect(tester.widget<WaterBalanceCard>(find.byType(WaterBalanceCard)).date,
        isNot(currentDay));
    HomeWidgets.route.value = 'water';
    await tester.pumpAndSettle();
    expect(tester.widget<WaterBalanceCard>(find.byType(WaterBalanceCard)).date,
        currentDay);
    await tester.ensureVisible(find.text('+250 мл'));
    await tester.tap(find.text('+250 мл'));
    await tester.pumpAndSettle();
    expect(db.portions, [250]);
    await tester.tap(find.byKey(const ValueKey('tab-dashboard')));
    await tester.pumpAndSettle();
    expect(find.byType(WaterBalanceCard), findsNothing);
    expect(find.byType(WaterBalanceCard, skipOffstage: false), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
