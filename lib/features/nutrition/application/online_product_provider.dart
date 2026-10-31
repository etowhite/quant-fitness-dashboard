import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/open_food_facts_service.dart';
import '../data/food_product.dart';

final openFoodFactsProvider = Provider((ref) {
  final service = OpenFoodFactsService();
  ref.onDispose(service.close);
  return service;
});
final onlineProductProvider = FutureProvider.autoDispose
    .family<List<FoodProduct>, String>((ref, query) async {
  var active = true;
  if (query.trim().length < 2) return [];
  final debounce = Completer<void>();
  final timer = Timer(const Duration(milliseconds: 500), debounce.complete);
  ref.onDispose(() {
    active = false;
    timer.cancel();
    if (!debounce.isCompleted) debounce.complete();
  });
  await debounce.future;
  if (!active || query.trim().length < 2) return [];
  return ref.read(openFoodFactsProvider).search(query);
});
