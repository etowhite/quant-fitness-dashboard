import '../../../../core/localization/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/daily_health_metrics.dart';
import '../weight_history.dart';
import 'dashboard_card.dart';

class HealthMetricsGrid extends StatelessWidget {
  const HealthMetricsGrid(
      {required this.metrics,
      required this.loading,
      required this.stepGoal,
      super.key});
  final DailyHealthMetrics? metrics;
  final bool loading;
  final int stepGoal;

  @override
  Widget build(BuildContext context) {
    final steps = metrics?.stepsToday;
    final calories = metrics?.activeCaloriesToday;
    final weight = metrics?.latestWeight;
    final fat = metrics?.latestBodyFat;
    final delta = weightDelta(metrics);
    final deltaLabel = delta == null
        ? null
        : delta.abs() < 0.05
            ? '0.0'
            : '${delta > 0 ? '+' : '−'}${delta.abs().toStringAsFixed(1)}';
    final activity =
        _card(context, 'Активность', 'Mi Fitness · Health Connect', [
      _value(
          context,
          steps == null
              ? '—'
              : NumberFormat.decimalPattern(context.languageCode)
                  .format(steps)),
      QText('шагов сегодня',
          style:
              TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      const SizedBox(height: 14),
      ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: steps == null || stepGoal <= 0
                ? 0
                : (steps / stepGoal).clamp(0.0, 1.0).toDouble(),
            color: Theme.of(context).colorScheme.secondary,
            backgroundColor:
                Theme.of(context).colorScheme.secondary.withAlpha(26),
            minHeight: 6,
            semanticsLabel: context.tr('Цель: $stepGoal шагов'),
          )),
      const SizedBox(height: 8),
      QText(
          'Цель: ${NumberFormat.decimalPattern(context.languageCode).format(stepGoal)}',
          style:
              TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      const SizedBox(height: 14),
      QText(calories == null
          ? '— активных ккал'
          : '${calories.round()} активных ккал'),
      _syncTime(context, metrics?.activityDataAt),
    ]);
    final body = _card(context, 'Состав тела', 'Picooc · Health Connect', [
      _value(context,
          weight == null ? '— кг' : '${weight.value.toStringAsFixed(1)} кг'),
      if (weight != null)
        QText(
            DateFormat('d MMM, HH:mm', context.languageCode)
                .format(weight.date),
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      const SizedBox(height: 12),
      QText(deltaLabel == null
          ? 'Нет предыдущего веса'
          : '$deltaLabel кг к предыдущему'),
      const SizedBox(height: 14),
      QText(fat == null ? 'Жир: —' : 'Жир: ${fat.value.toStringAsFixed(1)} %'),
      if (fat != null)
        QText(DateFormat('d MMM', context.languageCode).format(fat.date),
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      _syncTime(context, metrics?.bodyDataAt),
    ]);
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 340 ||
          MediaQuery.textScalerOf(context).scale(1) > 1.4) {
        return Column(children: [activity, const SizedBox(height: 16), body]);
      }
      return IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(child: activity),
        const SizedBox(width: 12),
        Expanded(child: body)
      ]));
    });
  }

  Widget _value(BuildContext context, String value) => QText(value,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: Theme.of(context).colorScheme.secondary,
          fontWeight: FontWeight.w700));

  Widget _syncTime(BuildContext context, DateTime? date) => Padding(
      padding: const EdgeInsets.only(top: 12),
      child: QText(
          date == null
              ? 'Последние данные: —'
              : 'Последние данные: ${DateFormat('d MMM, HH:mm', context.languageCode).format(date)}',
          style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant)));

  Widget _card(BuildContext context, String title, String source,
          List<Widget> content) =>
      DashboardCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        QText(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        QText(source,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 20),
        if (loading && metrics == null)
          Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(
                  color: Theme.of(context).colorScheme.secondary)),
        ...content,
      ]));
}
