import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/food_product.dart';
import '../data/open_food_facts_service.dart';

final openFoodFactsProvider = Provider((ref) {
  final service = OpenFoodFactsService();
  ref.onDispose(service.close);
  return service;
});
final onlineProductProvider = FutureProvider.autoDispose
    .family<List<FoodProduct>, String>((ref, query) async {
  if (query.trim().length < 2) return [];
  final cancellation = SearchCancellation();
  final debounce = Completer<void>();
  final timer =
      Timer(const Duration(milliseconds: 300), () => debounce.complete());
  ref.onDispose(() {
    cancellation.cancel();
    timer.cancel();
    if (!debounce.isCompleted) debounce.complete();
  });
  await debounce.future;
  if (cancellation.cancelled) return [];
  return ref
      .read(openFoodFactsProvider)
      .search(query, cancellation: cancellation);
});
