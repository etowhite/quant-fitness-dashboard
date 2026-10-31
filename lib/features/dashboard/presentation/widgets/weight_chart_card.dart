import 'package:flutter/material.dart';

import '../../../../shared/widgets/time_series_chart_card.dart';
import '../../domain/daily_health_metrics.dart';

class WeightChartCard extends StatelessWidget {
  const WeightChartCard({required this.history, super.key});
  final List<HealthValuePoint> history;

  @override
  Widget build(BuildContext context) => TimeSeriesChartCard(
        history: history,
        title: 'Динамика веса',
        subtitle: 'Последние 30 дней · кг',
        unit: 'кг',
        emptyText: 'Для графика нужны хотя бы два измерения веса.',
      );
}
