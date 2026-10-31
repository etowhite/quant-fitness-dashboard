import 'package:isar_community/isar.dart';

part 'food_product.g.dart';

@collection
class FoodProduct {
  Id? id;

  @Index(type: IndexType.value, caseSensitive: false)
  late String name;

  String category = 'Другое';
  @Index()
  String? catalogueKey;
  @Index()
  String? barcode;
  String? source;

  // All values are per 100 g of edible product.
  late double calories;
  late double proteins;
  late double fats;
  late double carbs;
}
