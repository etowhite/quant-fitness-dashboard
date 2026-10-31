import '../../../../shared/widgets/expressive_motion.dart';
import '../../../../core/localization/app_strings.dart';
import 'package:flutter/material.dart';

import '../../../nutrition/application/daily_food_diary.dart';
import '../../../goals/domain/user_goals.dart';
import 'dashboard_card.dart';

class NutritionSummaryCard extends StatelessWidget {
  const NutritionSummaryCard(
      {required this.totals, this.goals = const UserGoals(), super.key});
  final NutritionTotals totals;
  final UserGoals goals;

  @override
  Widget build(BuildContext context) {
    final calorieGoal = goals.calories;
    final remaining = calorieGoal - totals.calories;
    final ring = Semantics(
      label:
          'Калории: потреблено ${totals.calories.round()} из ${calorieGoal.round()}',
      child: SizedBox(
          width: 174,
          height: 174,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                  child: CircularProgressIndicator(
                value: _progress(totals.calories, calorieGoal),
                strokeWidth: 10,
                strokeCap: StrokeCap.round,
                color: Theme.of(context).colorScheme.primary,
                backgroundColor:
                    Theme.of(context).colorScheme.primary.withAlpha(26),
              )),
              Column(mainAxisSize: MainAxisSize.min, children: [
                AnimatedMetric(
                    value: remaining.abs(),
                    format: (value) => value.round().toString(),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary)),
                QText(remaining >= 0 ? 'ккал осталось' : 'ккал сверх нормы',
                    style: Theme.of(context).textTheme.bodySmall),
              ]),
            ],
          )),
    );
    final macros = Column(children: [
      _macro(context, 'Белки', totals.proteins, goals.proteins),
      const SizedBox(height: 16),
      _macro(context, 'Жиры', totals.fats, goals.fats),
      const SizedBox(height: 16),
      _macro(context, 'Углеводы', totals.carbs, goals.carbs),
    ]);
    return DashboardCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      QText('Питание сегодня', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 6),
      AnimatedMetric(
          value: totals.calories,
          format: (value) => '${value.round()} / ${calorieGoal.round()} ккал',
          style:
              TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      const SizedBox(height: 24),
      LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth < 440 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.3) {
          return Column(children: [
            Center(child: ring),
            const SizedBox(height: 28),
            macros
          ]);
        }
        return Row(children: [
          ring,
          const SizedBox(width: 32),
          Expanded(child: macros)
        ]);
      }),
    ]));
  }

  static double _progress(double value, double goal) =>
      goal <= 0 ? 0 : (value / goal).clamp(0.0, 1.0).toDouble();

  Widget _macro(BuildContext context, String name, double value, double goal) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(alignment: WrapAlignment.spaceBetween, spacing: 16, children: [
            QText(name),
            AnimatedMetric(
                value: value,
                format: (current) =>
                    '${current.toStringAsFixed(1)} / ${goal.round()} г',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AnimatedProgress(
                value: _progress(value, goal),
                minHeight: 6,
                color: Theme.of(context).colorScheme.primary,
                backgroundColor:
                    Theme.of(context).colorScheme.primary.withAlpha(26),
                semanticsLabel:
                    '$name: ${value.toStringAsFixed(1)} из ${goal.round()} граммов',
              )),
        ],
      );
}
