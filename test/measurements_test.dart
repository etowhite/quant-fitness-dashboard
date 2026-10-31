import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:smart_fitness_dashboard/features/measurements/data/body_measurement.dart';
import 'package:smart_fitness_dashboard/features/measurements/domain/body_metric.dart';
import 'package:smart_fitness_dashboard/features/measurements/presentation/widgets/current_measurements_grid.dart';

void main() {
  setUpAll(() => initializeDateFormatting('ru'));

  test('each metric skips missing values and sorts chronologically', () {
    final rows = [
      BodyMeasurement()
        ..date = DateTime(2026, 10, 31)
        ..waist = 82,
      BodyMeasurement()
        ..date = DateTime(2026, 10, 29)
        ..chest = 101,
      BodyMeasurement()
        ..date = DateTime(2026, 10, 28)
        ..waist = 84,
    ];
    expect(BodyMetric.waist.series(rows).map((p) => p.value), [84, 82]);
    expect(BodyMetric.chest.series(rows).single.value, 101);
    expect(BodyMetric.biceps.series(rows), isEmpty);
  });

  testWidgets('partial new measurement does not hide older values',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
      body: SingleChildScrollView(
          child: CurrentMeasurementsGrid(history: [
        BodyMeasurement()
          ..date = DateTime(2026, 10, 31)
          ..waist = 82.8,
        BodyMeasurement()
          ..date = DateTime(2026, 10, 30)
          ..chest = 100
          ..waist = 84,
      ])),
    )));
    expect(find.text('100.0 см'), findsOneWidget);
    expect(find.text('82.8 см'), findsOneWidget);
    expect(find.text('−1.2 см'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
