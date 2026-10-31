import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_provider.dart';
import '../data/food_product.dart';
import '../data/food_log_entry.dart';
import 'package:isar_community/isar.dart';

final favoriteProductsProvider =
    StreamProvider.autoDispose<List<FoodProduct>>((ref) async* {
  final db = await ref.watch(databaseServiceProvider.future);
  yield* db.watchSavedProducts();
});
final recipesProvider =
    StreamProvider.autoDispose<List<FoodProduct>>((ref) async* {
  final db = await ref.watch(databaseServiceProvider.future);
  yield* db.watchSavedProducts(recipes: true);
});
final frequentProductsProvider =
    StreamProvider.autoDispose<List<FoodProduct>>((ref) async* {
  final db = await ref.watch(databaseServiceProvider.future);
  yield* db.isar.foodLogEntries
      .where()
      .watch(fireImmediately: true)
      .asyncMap((_) => db.frequentProducts());
});
