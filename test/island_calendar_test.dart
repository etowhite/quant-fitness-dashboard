import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:smart_fitness_dashboard/core/database/database_provider.dart';
import 'package:smart_fitness_dashboard/features/nutrition/presentation/widgets/diary_calendar_sheet.dart';
import 'package:smart_fitness_dashboard/features/dashboard/presentation/widgets/health_metrics_grid.dart';
import 'package:smart_fitness_dashboard/features/dashboard/presentation/widgets/dashboard_card.dart';
import 'package:smart_fitness_dashboard/shared/widgets/scroll_island.dart';

void main() {
  setUpAll(() => initializeDateFormatting());
  testWidgets('metrics always stay equal-sized side by side on narrow phones',
      (tester) async {
    tester.view.physicalSize = const Size(320, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final scale in [1.0, 1.6]) {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: MediaQuery(
                  data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                  child: const SingleChildScrollView(
                      child: Padding(
                          padding: EdgeInsets.all(16),
                          child: HealthMetricsGrid(
                              metrics: null,
                              loading: false,
                              stepGoal: 10000)))))));
      await tester.pumpAndSettle();
      final cards = find.byType(DashboardCard);
      final first = tester.getRect(cards.at(0));
      final second = tester.getRect(cards.at(1));
      expect(first.size, second.size);
      expect(first.top, second.top);
      expect(second.left - first.right, 12);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
      'user downward scrolling hides island, upward scrolling reveals it',
      (tester) async {
    final visibility = <bool>[];
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: ScrollIslandListener(
      onVisibilityChanged: visibility.add,
      child: ListView(
          children: List.generate(
              40, (i) => SizedBox(height: 80, child: Text('row $i')))),
    ))));
    await tester.drag(find.byType(ListView), const Offset(0, -250));
    await tester.pumpAndSettle();
    expect(visibility, contains(false));
    visibility.clear();
    await tester.drag(find.byType(ListView), const Offset(0, 100));
    await tester.pumpAndSettle();
    expect(visibility.last, true);
  });

  testWidgets(
      'calendar marks food/water days reactively and selects correct month date',
      (tester) async {
    final dates = StreamController<Set<DateTime>>();
    addTearDown(dates.close);
    DateTime? selected;
    await tester.pumpWidget(ProviderScope(
        overrides: [
          recordedDiaryDatesProvider.overrideWith((ref) => dates.stream),
        ],
        child: MaterialApp(
            home: Scaffold(
                body: Builder(
                    builder: (context) => TextButton(
                        onPressed: () async {
                          selected = await showModalBottomSheet<DateTime>(
                              context: context,
                              isScrollControlled: true,
                              builder: (_) => DiaryCalendarSheet(
                                  selected: DateTime(2026, 11, 1)));
                        },
                        child: const Text('open')))))));
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    dates.add({DateTime(2026, 11, 3), DateTime(2026, 11, 20)});
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('calendar-dot-3')), findsOneWidget);
    expect(find.byKey(const ValueKey('calendar-dot-20')), findsOneWidget);
    dates.add({DateTime(2026, 11, 20)});
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('calendar-dot-3')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('calendar-next')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('calendar-dot-20')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('calendar-day-4')));
    await tester.pumpAndSettle();
    expect(selected, DateTime(2026, 12, 4));
    expect(tester.takeException(), isNull);
  });
}
