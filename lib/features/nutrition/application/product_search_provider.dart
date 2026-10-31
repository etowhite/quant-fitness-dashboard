import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../data/food_product.dart';

final productSearchProvider = StreamProvider.autoDispose
    .family<List<FoodProduct>, String>((ref, query) async* {
  final database = await ref.watch(databaseServiceProvider.future);
  yield* database.watchProducts(query);
});
