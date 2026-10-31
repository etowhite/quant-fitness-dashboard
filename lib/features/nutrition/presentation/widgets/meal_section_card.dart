import '../../../../shared/widgets/expressive_motion.dart';
import '../../../../core/localization/app_strings.dart';
import 'package:flutter/material.dart';

import '../../data/food_log_entry.dart';

class MealSectionCard extends StatelessWidget {
  const MealSectionCard(
      {required this.mealType,
      required this.entries,
      required this.onAdd,
      required this.onDelete,
      super.key});
  final String mealType;
  final List<FoodLogEntry> entries;
  final VoidCallback onAdd;
  final Future<bool> Function(FoodLogEntry) onDelete;

  @override
  Widget build(BuildContext context) {
    final calories = entries.fold(0.0, (sum, entry) => sum + entry.calories);
    return Card(
        child: Padding(
      padding: const EdgeInsets.all(16),
      child: AnimatedSize(
          duration: expressiveDuration,
          curve: Curves.easeOutExpo,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
              duration: expressiveDuration,
              switchInCurve: Curves.easeOutExpo,
              child: Column(
                  key: ValueKey(entries.map((e) => e.id).join(',')),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            QText(mealType,
                                style: Theme.of(context).textTheme.titleMedium),
                            AnimatedMetric(
                                value: calories,
                                format: (value) => '${value.round()} ккал',
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary)),
                          ])),
                      IconButton(
                          onPressed: onAdd,
                          tooltip: context.tr('Добавить: $mealType'),
                          icon: Icon(Icons.add_circle_outline,
                              color: Theme.of(context).colorScheme.primary)),
                    ]),
                    if (entries.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: QText('Пока нет продуктов',
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
                      ),
                    for (final entry in entries) ...[
                      const Divider(height: 1, thickness: .5),
                      Dismissible(
                        key: ValueKey('food-log-${entry.id}'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.all(16),
                            color: Theme.of(context).colorScheme.errorContainer,
                            child: const Icon(Icons.delete_outline)),
                        // The Isar watcher removes the row after commit. Returning false avoids
                        // keeping a fully dismissed widget while a watcher event is in flight.
                        confirmDismiss: (_) => onDelete(entry),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(entry.productName,
                                    style:
                                        Theme.of(context).textTheme.titleSmall),
                                const SizedBox(height: 4),
                                QText(
                                    '${entry.weightGrams.toStringAsFixed(1)} г · ${entry.calories.round()} ккал'),
                                QText(
                                    'Б ${entry.proteins.toStringAsFixed(1)} · Ж ${entry.fats.toStringAsFixed(1)} · У ${entry.carbs.toStringAsFixed(1)} г',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant)),
                              ]),
                        ),
                      ),
                    ],
                  ]))),
    ));
  }
}
