import 'dart:convert';
import 'package:flutter/services.dart';
import '../../features/nutrition/data/food_product.dart';

Future<List<FoodProduct>> loadBaseFoodProducts() async {
  final json =
      jsonDecode(await rootBundle.loadString('assets/data/ru_base_foods.json'))
          as Map<String, dynamic>;
  return (json['foods'] as List)
      .map((row) => FoodProduct()
        ..name = row['name'] as String
        ..category = row['category'] as String
        ..catalogueKey = row['id'] as String
        ..source = row['source'] as String
        ..calories = (row['calories'] as num).toDouble()
        ..proteins = (row['proteins'] as num).toDouble()
        ..fats = (row['fats'] as num).toDouble()
        ..carbs = (row['carbs'] as num).toDouble())
      .toList();
}
