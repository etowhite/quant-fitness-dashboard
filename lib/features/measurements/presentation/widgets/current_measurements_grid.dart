import 'package:smart_fitness_dashboard/core/theme/app_spacing.dart';
import '../../../../core/localization/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/body_measurement.dart';
import '../../domain/body_metric.dart';

class CurrentMeasurementsGrid extends StatelessWidget {
  const CurrentMeasurementsGrid({required this.history, super.key});
  final List<BodyMeasurement> history;

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final columns = constraints.maxWidth < 320 ||
                MediaQuery.textScalerOf(context).scale(1) > 1.5
            ? 1
            : 2;
        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(spacing: 12, runSpacing: 12, children: [
          for (final metric in [
            BodyMetric.chest,
            BodyMetric.waist,
            BodyMetric.hips,
            BodyMetric.biceps
          ])
            SizedBox(width: width, child: _card(context, metric)),
        ]);
      });

  Widget _card(BuildContext context, BodyMetric metric) {
    final points = metric.series(history);
    final latest = points.isEmpty ? null : points.last;
    final delta = points.length < 2
        ? null
        : latest!.value - points[points.length - 2].value;
    final color = metric.index.isEven
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.secondary;
    final difference = delta == null
        ? 'Нет предыдущего замера'
        : '${delta.abs() < 0.05 ? '' : delta > 0 ? '+' : '−'}${delta.abs().toStringAsFixed(1)} см';
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                QText(metric.label,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.actionGap),
                QText(
                    latest == null
                        ? '— см'
                        : '${latest.value.toStringAsFixed(1)} см',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(color: color)),
                const SizedBox(height: 4),
                QText(
                    latest == null
                        ? 'Еще нет измерений'
                        : DateFormat('d MMM yyyy', context.languageCode)
                            .format(latest.date),
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
                QText(difference,
                    style: TextStyle(
                        color: delta == null
                            ? Theme.of(context).colorScheme.onSurfaceVariant
                            : color)),
              ],
            )));
  }
}
