import '../../core/localization/app_strings.dart';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/metric_point.dart';

class TimeSeriesChartCard extends StatelessWidget {
  const TimeSeriesChartCard(
      {required this.history,
      required this.title,
      required this.subtitle,
      required this.unit,
      required this.emptyText,
      this.accent,
      this.controls,
      super.key});
  final List<MetricPoint> history;
  final String title, subtitle, unit, emptyText;
  final Color? accent;
  final Widget? controls;

  @override
  Widget build(BuildContext context) {
    final unique = <int, MetricPoint>{};
    for (final point in history) {
      if (point.value.isFinite && point.value > 0) {
        unique[point.date.millisecondsSinceEpoch] = point;
      }
    }
    final points = unique.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(20),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              QText(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              QText(subtitle,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              if (controls != null) ...[const SizedBox(height: 12), controls!],
              const SizedBox(height: 24),
              if (points.length < 2)
                SizedBox(
                    height: 160,
                    child: Center(
                      child: QText(emptyText, textAlign: TextAlign.center),
                    ))
              else
                LayoutBuilder(
                    builder: (context, constraints) =>
                        _chart(context, points, constraints.maxWidth)),
            ])));
  }

  Widget _chart(BuildContext context, List<MetricPoint> points, double width) {
    final accent = this.accent ?? Theme.of(context).colorScheme.secondary;
    final origin = points.first.date.millisecondsSinceEpoch;
    const dayMs = 86400000.0;
    final spots = points
        .map((p) =>
            FlSpot((p.date.millisecondsSinceEpoch - origin) / dayMs, p.value))
        .toList();
    final minValue = points.map((p) => p.value).reduce(math.min);
    final maxValue = points.map((p) => p.value).reduce(math.max);
    final padding = math.max(0.5, (maxValue - minValue) * 0.2);
    final span = spots.last.x;
    final labelWidth = 90 * MediaQuery.textScalerOf(context).scale(10) / 10;
    final axisDivisions = ((width - 42) / labelWidth).floor().clamp(1, 3);
    String dateAt(double x, String pattern) =>
        DateFormat(pattern, context.languageCode).format(
            DateTime.fromMillisecondsSinceEpoch(origin + (x * dayMs).round()));

    return Semantics(
      label: context.tr('График: ${points.length} измерений, '
          'от ${points.first.value.toStringAsFixed(1)} до ${points.last.value.toStringAsFixed(1)} $unit'),
      child: SizedBox(
          height: 220,
          child: LineChart(LineChartData(
            minX: 0,
            maxX: span,
            minY: math.max(0, minValue - padding).toDouble(),
            maxY: maxValue + padding,
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(
                    color: Theme.of(context)
                        .colorScheme
                        .outlineVariant
                        .withAlpha(100),
                    strokeWidth: 1)),
            titlesData: FlTitlesData(
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      interval: math.max(
                          0.5, (maxValue - minValue + padding * 2) / 3),
                      getTitlesWidget: (value, meta) => QText(
                          value.toStringAsFixed(1),
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontSize: 10)))),
              bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: span / axisDivisions,
                      getTitlesWidget: (value, meta) => SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 10,
                            fitInside: SideTitleFitInsideData.fromTitleMeta(
                                meta,
                                distanceFromEdge: 0),
                            child: QText(
                                dateAt(value, span < 1 ? 'HH:mm' : 'd MMM'),
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    fontSize: 10)),
                          ))),
            ),
            lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) =>
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              getTooltipItems: (touched) => touched
                  .map((spot) => LineTooltipItem(
                        '${spot.y.toStringAsFixed(1)} ${context.tr(unit)}\n${dateAt(spot.x, 'd MMM, HH:mm')}',
                        TextStyle(color: accent, fontWeight: FontWeight.w600),
                      ))
                  .toList(),
            )),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                preventCurveOverShooting: true,
                barWidth: 3,
                color: accent,
                isStrokeCapRound: true,
                shadow: Shadow(color: accent.withAlpha(89), blurRadius: 10),
                dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, bar, index) =>
                        FlDotCirclePainter(
                            radius: 3,
                            color: accent,
                            strokeWidth: 5,
                            strokeColor: accent.withAlpha(46))),
                belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [accent.withAlpha(56), accent.withAlpha(3)],
                    )),
              )
            ],
          ))),
    );
  }
}
