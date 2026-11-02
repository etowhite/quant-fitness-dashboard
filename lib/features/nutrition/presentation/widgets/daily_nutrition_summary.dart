import 'package:smart_fitness_dashboard/core/theme/app_spacing.dart';
import '../../../../shared/widgets/expressive_motion.dart';
import '../../../../core/localization/app_strings.dart';
import 'package:flutter/material.dart';

import '../../application/daily_food_diary.dart';
import '../../../goals/domain/user_goals.dart';

class DailyNutritionSummary extends StatelessWidget {
  const DailyNutritionSummary(
      {required this.totals, required this.goals, super.key});
  final NutritionTotals totals;
  final UserGoals goals;

  @override
  Widget build(BuildContext context) => Card(
          child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardInset),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          QText('Сводка дня', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.section),
          Wrap(spacing: 24, runSpacing: 16, children: [
            _value(context, 'Калории', totals.calories, goals.calories, 'ккал'),
            _value(context, 'Белки', totals.proteins, goals.proteins, 'г'),
            _value(context, 'Жиры', totals.fats, goals.fats, 'г'),
            _value(context, 'Углеводы', totals.carbs, goals.carbs, 'г'),
          ]),
        ]),
      ));

  Widget _value(BuildContext context, String label, double value, double goal,
          String unit) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          QText(label,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          AnimatedMetric(
              value: value,
              format: (current) =>
                  '${current.toStringAsFixed(label == 'Калории' ? 0 : 1)} / ${goal.toStringAsFixed(goal == goal.roundToDouble() ? 0 : 1)} $unit',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600)),
        ],
      );
}
