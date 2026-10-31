import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:smart_fitness_dashboard/features/nutrition/application/product_search_provider.dart';
import 'package:smart_fitness_dashboard/features/nutrition/data/food_product.dart';
import 'package:smart_fitness_dashboard/features/nutrition/presentation/widgets/add_food_sheet.dart';
import 'package:smart_fitness_dashboard/features/nutrition/presentation/widgets/create_product_form.dart';

void main() {
  setUpAll(() => initializeDateFormatting('ru'));

  testWidgets('selection uses 100 g; portion preview accepts comma and chips',
      (tester) async {
    final product = FoodProduct()
      ..name = 'Тестовый продукт'
      ..calories = 100
      ..proteins = 10
      ..fats = 2
      ..carbs = 15;
    await tester.pumpWidget(ProviderScope(
        overrides: [
          productSearchProvider('')
              .overrideWith((ref) => Stream.value([product])),
        ],
        child: MaterialApp(
            home: Scaffold(
                body: AddFoodSheet(
          date: DateTime(2026, 10, 31),
          initialMeal: 'Обед',
        )))));
    await tester.pumpAndSettle();
    expect(find.text('Обед'), findsOneWidget);
    await tester.tap(find.text('Тестовый продукт'));
    await tester.pumpAndSettle();
    expect(find.textContaining('100 ккал\n'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '150,6');
    await tester.pump();
    expect(find.textContaining('Б 15.1'), findsOneWidget);
    await tester.ensureVisible(find.text('200 г'));
    await tester.tap(find.text('200 г'));
    await tester.pump();
    expect(find.textContaining('200 ккал\n'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('invalid custom product is not saved', (tester) async {
    var created = false;
    await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
            home: Scaffold(
      body: SingleChildScrollView(
          child: CreateProductForm(
        onCreated: (_) => created = true,
        onCancel: () {},
      )),
    ))));
    await tester.ensureVisible(find.text('Сохранить продукт'));
    await tester.tap(find.text('Сохранить продукт'));
    await tester.pump();
    expect(find.text('Введите название'), findsOneWidget);
    expect(find.text('Введите число от нуля'), findsNWidgets(4));
    expect(created, isFalse);
    expect(tester.takeException(), isNull);
  });
}
