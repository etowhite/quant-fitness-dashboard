import '../domain/hydration.dart';
import '../data/food_log_entry.dart';

class NutritionTotals {
  const NutritionTotals(
      {this.calories = 0, this.proteins = 0, this.fats = 0, this.carbs = 0});
  final double calories;
  final double proteins;
  final double fats;
  final double carbs;
}

class DailyFoodDiary {
  DailyFoodDiary(List<FoodLogEntry> entries)
      : entries = List.unmodifiable(entries),
        totals = entries.fold(
            const NutritionTotals(),
            (total, entry) => NutritionTotals(
                  calories: total.calories + entry.calories,
                  proteins: total.proteins + entry.proteins,
                  fats: total.fats + entry.fats,
                  carbs: total.carbs + entry.carbs,
                ));

  final List<FoodLogEntry> entries;
  final NutritionTotals totals;
  double get waterMl => entries.fold(
      0.0,
      (total, entry) =>
          total + Hydration.volume(entry.weightGrams, entry.waterPercentage));
}
