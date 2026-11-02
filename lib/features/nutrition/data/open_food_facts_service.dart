import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../domain/hydration.dart';
import 'food_product.dart';

typedef FoodFactsFetch = Future<Map<String, dynamic>> Function(Uri uri);

class SearchCancelled implements Exception {
  const SearchCancelled();
}

class FoodSearchRateLimit implements Exception {
  const FoodSearchRateLimit();
}

/// Closes the search's own HTTP client, including pending connections/sockets.
class SearchCancellation {
  final _done = Completer<void>();
  final _listeners = <void Function()>[];
  bool get cancelled => _done.isCompleted;
  Future<void> get done => _done.future;
  void check() {
    if (cancelled) throw const SearchCancelled();
  }

  void onCancel(void Function() callback) {
    if (cancelled) {
      callback();
    } else {
      _listeners.add(callback);
    }
  }

  void removeListener(void Function() callback) => _listeners.remove(callback);
  void cancel() {
    if (cancelled) return;
    _done.complete();
    for (final listener in List.of(_listeners)) {
      listener();
    }
    _listeners.clear();
  }
}

class OpenFoodFactsService {
  OpenFoodFactsService(
      {FoodFactsFetch? fetch,
      DateTime Function()? clock,
      HttpClient Function()? clientFactory})
      : _fetchOverride = fetch,
        _clock = clock ?? DateTime.now,
        _clientFactory = clientFactory ?? HttpClient.new;
  final FoodFactsFetch? _fetchOverride;
  final DateTime Function() _clock;
  final HttpClient Function() _clientFactory;
  final _client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  final _cache = <String, List<FoodProduct>>{};
  final _searchTimes = <DateTime>[];
  SearchCancellation? _activeSearch;
  bool _closed = false;
  DateTime? _blockedUntil;
  static const fields =
      'product_name,product_name_ru,brands,nutriments,code,categories_tags,serving_size,quantity';
  static bool validBarcode(String value) =>
      RegExp(r'^(?:\d{8}|\d{12,14})$').hasMatch(value);
  void close() {
    _closed = true;
    _activeSearch?.cancel();
    _client.close(force: true);
  }

  void _searchBudget() {
    final now = _clock();
    if (_blockedUntil != null && now.isBefore(_blockedUntil!)) {
      throw const FoodSearchRateLimit();
    }
    _searchTimes
        .removeWhere((at) => now.difference(at) >= const Duration(minutes: 1));
    if (_searchTimes.length >= 10) throw const FoodSearchRateLimit();
    _searchTimes.add(now);
  }

  Future<Map<String, dynamic>> _get(Uri uri,
      {HttpClient? client, SearchCancellation? cancellation}) async {
    if (_closed) throw StateError('Service disposed');
    cancellation?.check();
    if (uri.scheme != 'https' ||
        !{'ru.openfoodfacts.org', 'world.openfoodfacts.org'}
            .contains(uri.host)) {
      throw ArgumentError('Invalid endpoint');
    }
    if (_fetchOverride != null) {
      final pending = _fetchOverride(uri);
      return cancellation == null
          ? pending
          : Future.any([
              pending,
              cancellation.done.then<Map<String, dynamic>>(
                  (_) => throw const SearchCancelled()),
            ]);
    }
    final request = await (client ?? _client)
        .getUrl(uri)
        .timeout(const Duration(seconds: 12));
    if (cancellation?.cancelled ?? false) {
      request.abort();
      throw const SearchCancelled();
    }
    void abort() => request.abort(const SearchCancelled());
    cancellation?.onCancel(abort);
    try {
      request.followRedirects = false;
      request.headers.set(HttpHeaders.userAgentHeader,
          'quant/1.4 (https://github.com/etowhite/quant-fitness-dashboard)');
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response =
          await request.close().timeout(const Duration(seconds: 12));
      if (response.statusCode == 404) {
        request.abort();
        return {};
      }
      if (response.statusCode == 429) {
        _blockedUntil = _clock().add(const Duration(minutes: 1));
        request.abort();
        throw const FoodSearchRateLimit();
      }
      if (response.statusCode != 200) {
        request.abort();
        throw const HttpException('Open Food Facts unavailable');
      }
      final bytes = <int>[];
      await for (final chunk in response.timeout(const Duration(seconds: 12))) {
        cancellation?.check();
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
    } catch (_) {
      request.abort();
      cancellation?.check();
      rethrow;
    } finally {
      cancellation?.removeListener(abort);
    }
  }

  Future<List<FoodProduct>> search(String text,
      {SearchCancellation? cancellation}) async {
    _activeSearch?.cancel();
    final token = cancellation ?? SearchCancellation();
    _activeSearch = token;
    token.check();
    final query = text.trim().toLowerCase();
    if (query.length < 2 || query.length > 120) return [];
    if (_closed) throw StateError('Service disposed');
    if (_cache.containsKey(query)) return _cache[query]!;
    final client = _clientFactory()
      ..connectionTimeout = const Duration(seconds: 10);
    void closeClient() => client.close(force: true);
    token.onCancel(closeClient);
    try {
      List<FoodProduct> products = [];
      for (final host in ['ru.openfoodfacts.org', 'world.openfoodfacts.org']) {
        token.check();
        _searchBudget();
        try {
          final json = await _get(
              Uri.https(host, '/cgi/search.pl', {
                'search_terms': query,
                'search_simple': '1',
                'action': 'process',
                'json': '1',
                'page_size': '20',
                'fields': fields,
              }),
              client: client,
              cancellation: token);
          final rows = json['products'];
          products = rows is List
              ? rows
                  .whereType<Map<String, dynamic>>()
                  .map(parseProduct)
                  .whereType<FoodProduct>()
                  .take(20)
                  .toList()
              : [];
          if (products.isNotEmpty) break;
        } on SearchCancelled {
          rethrow;
        } on FoodSearchRateLimit {
          rethrow;
        } catch (_) {
          token.check();
          if (host == 'world.openfoodfacts.org') rethrow;
        }
      }
      token.check();
      if (_cache.length >= 30) _cache.remove(_cache.keys.first);
      _cache[query] = products;
      return products;
    } finally {
      token.removeListener(closeClient);
      closeClient();
      if (identical(_activeSearch, token)) _activeSearch = null;
    }
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
      ..waterPercentage = Hydration.detect(rawName,
          categories: (row['categories_tags'] is List
              ? (row['categories_tags'] as List).whereType<String>()
              : const <String>[]),
          serving: [row['serving_size'], row['quantity']]
              .whereType<String>()
              .join(' '))
      ..calories = calories
      ..proteins = protein
      ..fats = fat
      ..carbs = carb;
  }
}
