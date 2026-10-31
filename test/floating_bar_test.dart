import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_fitness_dashboard/app/dashboard_shell.dart';

void main() {
  testWidgets(
      'floating pill navigation fits narrow phones and selects each tab',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final width in [320.0, 390.0]) {
      tester.view.physicalSize = Size(width, 844);
      var selected = AppTab.dashboard;
      await tester.pumpWidget(MaterialApp(
          home: StatefulBuilder(
              builder: (context, update) => Scaffold(
                  body: const SizedBox.expand(),
                  bottomNavigationBar: FloatingBottomBar(
                      selected: selected,
                      onSelected: (tab) => update(() => selected = tab))))));
      for (final tab in AppTab.values) {
        await tester.tap(find.byKey(ValueKey('tab-${tab.name}')));
        await tester.pumpAndSettle();
        expect(selected, tab);
        expect(tester.takeException(), isNull);
      }
    }
  });
}
