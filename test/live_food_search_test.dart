import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:smart_fitness_dashboard/features/nutrition/data/open_food_facts_service.dart';
import 'package:smart_fitness_dashboard/features/nutrition/application/online_product_provider.dart';
import 'package:smart_fitness_dashboard/features/nutrition/application/product_search_provider.dart';
import 'package:smart_fitness_dashboard/features/nutrition/application/saved_products_provider.dart';
import 'package:smart_fitness_dashboard/features/nutrition/presentation/widgets/add_food_sheet.dart';
import 'package:smart_fitness_dashboard/features/nutrition/data/food_product.dart';
import 'open_food_facts_test.dart' show label;

class PendingHttpClient implements HttpClient {
  final pending = Completer<HttpClientRequest>();
  bool requested = false, closed = false;
  @override
  Future<HttpClientRequest> getUrl(Uri url) {
    requested = true;
    return pending.future;
  }

  @override
  set connectionTimeout(Duration? value) {}
  @override
  void close({bool force = false}) {
    closed = true;
    if (requested && !pending.isCompleted) {
      pending.completeError(const SocketException('cancelled'));
    }
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  setUpAll(() => initializeDateFormatting('ru'));
  test('RU first; world fallback; categories and ml reach hydration detector',
      () async {
    final hosts = <String>[];
    final service = OpenFoodFactsService(fetch: (uri) async {
      hosts.add(uri.host);
      if (uri.host == 'ru.openfoodfacts.org') {
        throw const SocketException('unavailable');
      }
      expect(uri.queryParameters['fields'], contains('categories_tags'));
      return {
        'products': [
          {
            ...label(),
            'product_name_ru': 'Cola Zero',
            'categories_tags': ['en:carbonated-drinks'],
            'serving_size': '250 ml'
          }
        ]
      };
    });
    addTearDown(service.close);
    expect((await service.search('кола')).single.waterPercentage, 98);
    expect(hosts, ['ru.openfoodfacts.org', 'world.openfoodfacts.org']);
  });
  test(
      'cancelling a production request closes its socket client, without world retry',
      () async {
    final client = PendingHttpClient();
    final token = SearchCancellation();
    final service = OpenFoodFactsService(clientFactory: () => client);
    addTearDown(service.close);
    final pending = service.search('молоко', cancellation: token);
    final done = expectLater(pending, throwsA(isA<SearchCancelled>()));
    await Future<void>.delayed(Duration.zero);
    expect(client.requested, isTrue);
    token.cancel();
    await done;
    expect(client.closed, isTrue);
  });
  test('new search cancels old work; late responses cannot populate its cache',
      () async {
    final first = Completer<Map<String, dynamic>>();
    var calls = 0;
    final service = OpenFoodFactsService(fetch: (uri) async {
      calls++;
      if (uri.queryParameters['search_terms'] == 'мо') return first.future;
      return {
        'products': [label()]
      };
    });
    addTearDown(service.close);
    final pending = service.search('мо');
    final old = expectLater(pending, throwsA(isA<SearchCancelled>()));
    await service.search('мол');
    await old;
    first.complete({
      'products': [label()]
    });
    expect(calls, 2);
    await service.search('мол');
    expect(calls, 2);
  });
  test('short queries skip HTTP; search budget is immediate and does not sleep',
      () async {
    var calls = 0;
    var now = DateTime(2026);
    final service = OpenFoodFactsService(
        clock: () => now,
        fetch: (uri) async {
          calls++;
          return {
            'products': [label()]
          };
        });
    addTearDown(service.close);
    expect(await service.search('м'), isEmpty);
    for (var i = 0; i < 10; i++) {
      await service.search('запрос$i');
    }
    expect(calls, 10);
    await expectLater(
        service.search('новый'), throwsA(isA<FoodSearchRateLimit>()));
    now = now.add(const Duration(minutes: 1));
    await service.search('новый');
    expect(calls, 11);
  });
  testWidgets(
      'typing starts online at 300ms despite local matches, preserves local rows and merges without submit',
      (tester) async {
    var calls = 0;
    final response = Completer<Map<String, dynamic>>();
    final service = OpenFoodFactsService(fetch: (uri) {
      calls++;
      return response.future;
    });
    final local = FoodProduct()
      ..name = 'Молоко местное'
      ..calories = 50
      ..proteins = 3
      ..fats = 2
      ..carbs = 5;
    final c = ProviderContainer(overrides: [
      openFoodFactsProvider.overrideWithValue(service),
      productSearchProvider('').overrideWith((ref) => Stream.value([local])),
      productSearchProvider('мо').overrideWith((ref) => Stream.value([local])),
      favoriteProductsProvider.overrideWith((ref) => Stream.value([])),
      frequentProductsProvider.overrideWith((ref) => Stream.value([])),
      recipesProvider.overrideWith((ref) => Stream.value([])),
    ]);
    addTearDown(c.dispose);
    addTearDown(service.close);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
            home: Scaffold(
                body:
                    AddFoodSheet(date: DateTime(2026), initialMeal: 'Обед')))));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('food-search-input')), 'мо');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 299));
    expect(calls, 0);
    expect(find.text('Молоко местное'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1));
    expect(calls, 1);
    expect(find.text('Молоко местное'), findsOneWidget);
    response.complete({
      'products': [
        {...label(), 'product_name_ru': 'Молоко онлайн'}
      ]
    });
    await tester.pumpAndSettle();
    expect(find.text('Молоко местное'), findsOneWidget);
    expect(find.text('Молоко онлайн · Марка'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
