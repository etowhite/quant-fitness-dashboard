import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_fitness_dashboard/core/theme/app_theme.dart';
import 'package:smart_fitness_dashboard/features/settings/domain/theme_settings.dart';
import 'package:smart_fitness_dashboard/features/dashboard/presentation/widgets/dashboard_card.dart';

void main() {
  testWidgets(
      'cards and controls inherit the same 1px outline in light, dark and AMOLED',
      (tester) async {
    for (final config in [
      (Brightness.light, false),
      (Brightness.dark, false),
      (Brightness.dark, true)
    ]) {
      final theme = AppTheme.build(ThemeSettings(amoled: config.$2), config.$1);
      final expected = config.$1 == Brightness.light
          ? const Color(0xFFD0D5DD)
          : const Color(0xFF2E2E36);
      await tester.pumpWidget(MaterialApp(
          theme: theme,
          home: const Scaffold(
              body: SingleChildScrollView(
                  child: Column(children: [
            DashboardCard(child: Text('dashboard card')),
            Card(child: Text('plain card')),
            TextField(decoration: InputDecoration(labelText: 'Input')),
            Divider(),
            ChoiceChip(label: Text('250 ml'), selected: false),
          ])))));
      await tester.pumpAndSettle();
      expect(theme.colorScheme.outlineVariant, expected);
      final shape = theme.cardTheme.shape! as RoundedRectangleBorder;
      expect(shape.side, BorderSide(color: expected, width: 1));
      expect(shape.borderRadius, BorderRadius.circular(24));
      expect(theme.dividerTheme.color, expected);
      expect(theme.dividerTheme.thickness, 1);
      expect(theme.chipTheme.side, BorderSide(color: expected));
      final input =
          theme.inputDecorationTheme.enabledBorder! as OutlineInputBorder;
      expect(input.borderSide, BorderSide(color: expected));
      expect(theme.outlinedButtonTheme.style!.side!.resolve({})!.width, 1);
      expect(theme.textButtonTheme.style!.side!.resolve({})!.color, expected);
      final rendered = tester
          .widgetList<Material>(find.descendant(
              of: find.byType(Card), matching: find.byType(Material)))
          .where((m) => m.shape is RoundedRectangleBorder);
      expect(rendered.length, 2);
      expect(
          rendered.map((m) => (m.shape! as RoundedRectangleBorder).side.color),
          everyElement(expected));
      expect(tester.takeException(), isNull);
    }
  });
}
