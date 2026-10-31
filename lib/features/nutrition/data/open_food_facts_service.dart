import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'food_product.dart';

typedef FoodFactsFetch = Future<Map<String, dynamic>> Function(Uri uri);

class OpenFoodFactsService {
  OpenFoodFactsService({FoodFactsFetch? fetch}) : _fetchOverride = fetch;
  final FoodFactsFetch? _fetchOverride;
  final _client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  final _cache = <String, List<FoodProduct>>{};
  DateTime? _lastSearch;
  int _generation = 0;
  bool _closed = false;
  static const fields = 'product_name,product_name_ru,brands,nutriments,code';
  static bool validBarcode(String value) =>
      RegExp(r'^(?:\d{8}|\d{12,14})$').hasMatch(value);

  void close() {
    _closed = true;
    _generation++;
    _client.close(force: true);
  }

  Future<Map<String, dynamic>> _get(Uri uri) async {
    if (_closed) throw StateError('Service disposed');
    if (_fetchOverride != null) return _fetchOverride(uri);
    if (uri.scheme != 'https' || uri.host != 'world.openfoodfacts.org') {
      throw ArgumentError('Invalid endpoint');
    }
    final request =
        await _client.getUrl(uri).timeout(const Duration(seconds: 12));
    request.followRedirects = false;
    request.headers.set(HttpHeaders.userAgentHeader,
        'quant/1.4 (https://github.com/etowhite/quant-fitness-dashboard)');
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    final response = await request.close().timeout(const Duration(seconds: 12));
    if (response.statusCode == 404) {
      request.abort();
      return {};
    }
    if (response.statusCode != 200) {
      request.abort();
      throw HttpException(response.statusCode == 429
          ? 'Лимит Open Food Facts. Повторите позже.'
          : 'Open Food Facts недоступен');
    }
    final bytes = <int>[];
    await for (final chunk in response.timeout(const Duration(seconds: 12))) {
      if (bytes.length + chunk.length > 2 * 1024 * 1024) {
        request.abort();
        throw const FormatException('Response too large');
      }
      bytes.addAll(chunk);
    }
    final result = jsonDecode(utf8.decode(bytes));
    if (result is! Map<String, dynamic>) {
      throw const FormatException('Invalid response');
    }
    return result;
  }

  Future<List<FoodProduct>> search(String text) async {
    final query = text.trim().toLowerCase();
    if (query.length < 2 || query.length > 120) return [];
    if (_cache.containsKey(query)) return _cache[query]!;
    final generation = ++_generation;
    // Search is limited to 10/minute. Coalesce queued type-ahead searches.
    final wait = _lastSearch == null
        ? Duration.zero
        : const Duration(seconds: 6) - DateTime.now().difference(_lastSearch!);
    if (!wait.isNegative) await Future<void>.delayed(wait);
    if (_closed || generation != _generation) return [];
    _lastSearch = DateTime.now();
    final json =
        await _get(Uri.https('world.openfoodfacts.org', '/cgi/search.pl', {
      'search_terms': query,
      'search_simple': '1',
      'action': 'process',
      'json': '1',
      'page_size': '20',
      'fields': fields,
    }));
    final rows = json['products'];
    final products = rows is List
        ? rows
            .whereType<Map<String, dynamic>>()
            .map(parseProduct)
            .whereType<FoodProduct>()
            .take(20)
            .toList()
        : <FoodProduct>[];
    if (_cache.length >= 30) _cache.remove(_cache.keys.first);
    _cache[query] = products;
    return products;
  }

  Future<FoodProduct?> barcode(String code) async {
    if (!validBarcode(code)) {
      throw const FormatException('Введите 8 или 12–14 цифр');
    }
    final json = await _get(Uri.https('world.openfoodfacts.org',
        '/api/v2/product/$code.json', {'fields': fields}));
    final row = json['product'];
    return row is Map<String, dynamic>
        ? parseProduct({...row, 'code': code})
        : null;
  }

  static FoodProduct? parseProduct(Map<String, dynamic> row) {
    final code = row['code']?.toString() ?? '';
    if (!validBarcode(code)) return null;
    final rawName = row['product_name_ru'] is String &&
            (row['product_name_ru'] as String).trim().isNotEmpty
        ? row['product_name_ru']
        : row['product_name'];
    if (rawName is! String || rawName.trim().isEmpty) return null;
    final nutriments = row['nutriments'];
    if (nutriments is! Map<String, dynamic>) return null;
    double? number(String key, double max) {
      final raw = nutriments[key];
      final n =
          raw is num ? raw.toDouble() : double.tryParse(raw?.toString() ?? '');
      return n != null && n.isFinite && n >= 0 && n <= max ? n : null;
    }

    var calories = number('energy-kcal_100g', 1000);
    final kj = number('energy_100g', 4184);
    if (calories == null && kj != null && nutriments['energy_unit'] == 'kJ') {
      calories = kj / 4.184;
    }
    final protein = number('proteins_100g', 100),
        fat = number('fat_100g', 100),
        carb = number('carbohydrates_100g', 100);
    if (calories == null || protein == null || fat == null || carb == null) {
      return null;
    }
    final brands =
        row['brands'] is String ? (row['brands'] as String).trim() : '';
    final name = '${rawName.trim()}${brands.isEmpty ? '' : ' · $brands'}';
    return FoodProduct()
      ..name = name.length <= 120 ? name : name.substring(0, 120)
      ..barcode = code
      ..category = 'Open Food Facts'
      ..source = 'Open Food Facts · ODbL'
      ..calories = calories
      ..proteins = protein
      ..fats = fat
      ..carbs = carb;
  }
}
