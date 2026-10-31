import 'package:flutter_test/flutter_test.dart';
import 'package:smart_fitness_dashboard/features/nutrition/data/open_food_facts_service.dart';

Map<String, dynamic> label() => {
      'code': '3017620422003',
      'product_name': 'English',
      'product_name_ru': 'Продукт',
      'brands': 'Марка',
      'nutriments': <String, dynamic>{
        'energy-kcal_100g': 150,
        'proteins_100g': 10,
        'fat_100g': 6,
        'carbohydrates_100g': 14
      }
    };
void main() {
  test('parses per 100g, chooses Russian name and retains attribution', () {
    final p = OpenFoodFactsService.parseProduct(label())!;
    expect(p.name, 'Продукт · Марка');
    expect(p.calories, 150);
    expect(p.barcode, '3017620422003');
    expect(p.source, contains('ODbL'));
  });
  test('missing, negative, nonfinite and implausible nutrients are rejected',
      () {
    for (final value in [null, -1, double.infinity, 1001, 'bad']) {
      final row = label();
      (row['nutriments'] as Map)['energy-kcal_100g'] = value;
      expect(OpenFoodFactsService.parseProduct(row), isNull);
    }
    final row = label();
    (row['nutriments'] as Map)['proteins_100g'] = 101;
    expect(OpenFoodFactsService.parseProduct(row), isNull);
  });
  test('only numeric UPC/EAN/GTIN formats accepted; barcode URL is HTTPS',
      () async {
    Uri? requested;
    final service = OpenFoodFactsService(fetch: (uri) async {
      requested = uri;
      return {'product': label()};
    });
    addTearDown(service.close);
    expect(await service.barcode('3017620422003'), isNotNull);
    expect(requested!.scheme, 'https');
    expect(requested!.path, '/api/v2/product/3017620422003.json');
    await expectLater(service.barcode('../etc'), throwsFormatException);
    expect(OpenFoodFactsService.validBarcode('123456789'), isFalse);
  });
  test('search encodes query and caches repeated requests', () async {
    var calls = 0;
    final service = OpenFoodFactsService(fetch: (uri) async {
      calls++;
      expect(uri.queryParameters['search_terms'], 'молоко & йогурт');
      return {
        'products': [
          label(),
          {'code': 'bad'}
        ]
      };
    });
    addTearDown(service.close);
    expect(await service.search('Молоко & йогурт'), hasLength(1));
    expect(await service.search('молоко & йогурт'), hasLength(1));
    expect(calls, 1);
  });
}
