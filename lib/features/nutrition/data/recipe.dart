import 'dart:convert';
import 'food_product.dart';

class RecipeIngredient {
  RecipeIngredient(
      {required this.name,
      required this.grams,
      this.key,
      this.calories,
      this.proteins,
      this.fats,
      this.carbs});
  final String name;
  final String? key;
  final double grams;
  final double? calories, proteins, fats, carbs;
  factory RecipeIngredient.product(FoodProduct p, double grams) =>
      RecipeIngredient(
          name: p.name,
          key: p.stableKey,
          grams: grams,
          calories: p.calories,
          proteins: p.proteins,
          fats: p.fats,
          carbs: p.carbs);
  bool get complete =>
      [calories, proteins, fats, carbs].every((v) => v != null);
  Map<String, dynamic> toJson() => {
        'name': name,
        'key': key,
        'grams': grams,
        'calories': calories,
        'proteins': proteins,
        'fats': fats,
        'carbs': carbs
      };
  factory RecipeIngredient.fromJson(Map<String, dynamic> j) {
    final name = j['name'];
    final key = j['key'];
    if (name is! String ||
        name.trim().isEmpty ||
        name.length > 120 ||
        (key != null && (key is! String || key.length > 200))) {
      throw const FormatException('Invalid ingredient');
    }
    double? value(String k) {
      final v = j[k];
      if (v == null && k != 'grams') return null;
      if (v is! num ||
          !v.isFinite ||
          v < 0 ||
          (k == 'grams' && (v <= 0 || v > 100000)) ||
          (k != 'grams' && v > (k == 'calories' ? 1000 : 100))) {
        throw const FormatException('Invalid ingredient value');
      }
      return v.toDouble();
    }

    return RecipeIngredient(
        name: name,
        key: key as String?,
        grams: value('grams')!,
        calories: value('calories'),
        proteins: value('proteins'),
        fats: value('fats'),
        carbs: value('carbs'));
  }
}

class Recipe {
  Recipe({required this.ingredients, required this.yieldGrams, this.servings});
  final List<RecipeIngredient> ingredients;
  final double yieldGrams;
  final double? servings;
  bool get complete => ingredients.every((i) => i.complete);
  List<double>? get totals => !complete
      ? null
      : [
          for (final field in [0, 1, 2, 3])
            ingredients.fold<double>(
                0,
                (s, i) =>
                    s +
                    [i.calories!, i.proteins!, i.fats!, i.carbs!][field] *
                        i.grams /
                        100)
        ];
  List<double>? get per100 => totals?.map((v) => v * 100 / yieldGrams).toList();
  List<double>? get perServing =>
      servings == null ? null : totals?.map((v) => v / servings!).toList();
  void validate() {
    if (ingredients.isEmpty ||
        ingredients.length > 100 ||
        !yieldGrams.isFinite ||
        yieldGrams <= 0 ||
        yieldGrams > 100000 ||
        (servings != null &&
            (!servings!.isFinite || servings! <= 0 || servings! > 10000))) {
      throw const FormatException('Invalid recipe');
    }
    for (final i in ingredients) {
      RecipeIngredient.fromJson(i.toJson());
    }
    final values = per100;
    if (values != null &&
        (values[0] > 1000 || values.skip(1).any((v) => v > 100))) {
      throw const FormatException('Unrealistic yield');
    }
  }

  String encode() {
    validate();
    return jsonEncode({
      'yield': yieldGrams,
      'servings': servings,
      'ingredients': ingredients.map((i) => i.toJson()).toList()
    });
  }

  factory Recipe.decode(String raw) {
    if (raw.length > 200000) throw const FormatException('Recipe too large');
    final j = jsonDecode(raw);
    if (j is! Map<String, dynamic> ||
        j['yield'] is! num ||
        j['ingredients'] is! List ||
        (j['servings'] != null && j['servings'] is! num)) {
      throw const FormatException('Invalid recipe');
    }
    final recipe = Recipe(
        ingredients: (j['ingredients'] as List)
            .map((i) =>
                RecipeIngredient.fromJson(Map<String, dynamic>.from(i as Map)))
            .toList(),
        yieldGrams: (j['yield'] as num).toDouble(),
        servings: (j['servings'] as num?)?.toDouble());
    recipe.validate();
    return recipe;
  }
}
