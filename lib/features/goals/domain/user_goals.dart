import '../../../core/validation/input_limits.dart';

class UserGoals {
  const UserGoals(
      {this.calories = 2200,
      this.proteins = 150,
      this.fats = 70,
      this.carbs = 250,
      this.steps = 10000,
      this.waterMl = 2000});

  final double calories, proteins, fats, carbs;
  final int steps;
  final int waterMl;

  void validate() {
    if ([calories, proteins, fats, carbs].any((v) => !v.isFinite || v <= 0) ||
        steps <= 0 ||
        waterMl <= 0) {
      throw const FormatException(
          'Все цели должны быть положительными числами');
    }
    if (calories > InputLimits.dailyCalories ||
        steps > InputLimits.dailySteps ||
        waterMl > InputLimits.waterGoalMl ||
        [proteins, fats, carbs].any((v) => v > InputLimits.dailyMacro)) {
      throw const FormatException('Превышен допустимый предел дневной цели');
    }
  }

  Map<String, Object> toJson() => {
        'calories': calories,
        'proteins': proteins,
        'fats': fats,
        'carbs': carbs,
        'steps': steps,
        'waterMl': waterMl
      };

  factory UserGoals.fromJson(Map<String, dynamic> json) {
    double value(String key) {
      final number = json[key];
      if (number is! num || !number.isFinite) {
        throw const FormatException('Некорректное значение цели');
      }
      return number.toDouble();
    }

    final steps = json['steps'];
    final water =
        json['waterMl'] ?? 2000; // Migrate pre-water preferences/backups.
    if (water is! int) throw const FormatException('Некорректная цель воды');
    if (steps is! int) throw const FormatException('Некорректная цель шагов');
    final goals = UserGoals(
        calories: value('calories'),
        proteins: value('proteins'),
        fats: value('fats'),
        carbs: value('carbs'),
        steps: steps,
        waterMl: water);
    goals.validate();
    return goals;
  }
}
