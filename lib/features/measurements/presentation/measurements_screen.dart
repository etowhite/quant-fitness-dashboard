import '../../../core/localization/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/widgets/time_series_chart_card.dart';
import '../application/body_measurements_provider.dart';
import '../data/body_measurement.dart';
import '../domain/body_metric.dart';
import 'widgets/current_measurements_grid.dart';
import 'widgets/measurement_form_sheet.dart';

class MeasurementsScreen extends ConsumerStatefulWidget {
  const MeasurementsScreen({super.key});
  @override
  ConsumerState<MeasurementsScreen> createState() => _MeasurementsScreenState();
}

class _MeasurementsScreenState extends ConsumerState<MeasurementsScreen> {
  BodyMetric _metric = BodyMetric.waist;
  bool _sheetOpen = false;
  final _deleting = <int>{};

  Future<void> _newMeasurement() async {
    if (_sheetOpen) return;
    setState(() => _sheetOpen = true);
    try {
      await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Theme.of(context).colorScheme.surface,
          builder: (_) => const MeasurementFormSheet());
    } finally {
      if (mounted) setState(() => _sheetOpen = false);
    }
  }

  Future<void> _delete(BodyMeasurement row) async {
    if (_deleting.contains(row.id)) return;
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const QText('Удалить замер?'),
              content: QText(
                  'Все параметры и заметка за ${DateFormat('d MMM yyyy', context.languageCode).format(row.date.toLocal())} будут удалены.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const QText('Отмена')),
                TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const QText('Удалить'))
              ],
            ));
    if (!mounted || confirmed != true) return;
    setState(() => _deleting.add(row.id!));
    try {
      await ref.read(bodyMeasurementActionsProvider).delete(row.id!);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: QText('Не удалось удалить замер. Повторите попытку.')));
      }
    } finally {
      if (mounted) setState(() => _deleting.remove(row.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(bodyMeasurementHistoryProvider);
    return Scaffold(
      appBar: AppBar(title: const QText('Замеры')),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: _sheetOpen ? null : _newMeasurement,
          icon: const Icon(Icons.add),
          label: const QText('Новый замер')),
      body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          children: [
            QText('Антропометрия',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            history.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Column(children: [
                const QText('Не удалось загрузить историю замеров.'),
                TextButton(
                    onPressed: () =>
                        ref.invalidate(bodyMeasurementHistoryProvider),
                    child: const QText('Повторить'))
              ]),
              data: (rows) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CurrentMeasurementsGrid(history: rows),
                    const SizedBox(height: 16),
                    TimeSeriesChartCard(
                        history: _metric.series(rows),
                        title: 'Прогресс замеров',
                        subtitle: '${_metric.label} · см',
                        unit: 'см',
                        emptyText:
                            'Для графика нужны хотя бы два замера выбранного параметра.',
                        controls: Wrap(spacing: 8, runSpacing: 8, children: [
                          for (final metric in BodyMetric.values)
                            ChoiceChip(
                                label: QText(metric.label),
                                selected: metric == _metric,
                                onSelected: (_) =>
                                    setState(() => _metric = metric)),
                        ])),
                    const SizedBox(height: 24),
                    QText('История замеров',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    if (rows.isEmpty)
                      const QText(
                          'Пока нет замеров. Добавьте первый, чтобы отслеживать прогресс.'),
                    for (final row in rows)
                      Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Card(
                              child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                            QText(
                                                DateFormat('d MMM yyyy',
                                                        context.languageCode)
                                                    .format(row.date.toLocal()),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium),
                                            const SizedBox(height: 8),
                                            Wrap(
                                                spacing: 16,
                                                runSpacing: 8,
                                                children: [
                                                  for (final metric
                                                      in BodyMetric.values)
                                                    if (metric.read(row) !=
                                                        null)
                                                      QText(
                                                          '${metric.label}: ${metric.read(row)!.toStringAsFixed(1)} см'),
                                                ]),
                                            if (row.note?.isNotEmpty == true)
                                              Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 8),
                                                  child: Text(row.note!)),
                                          ])),
                                      IconButton(
                                          onPressed: _deleting.contains(row.id)
                                              ? null
                                              : () => _delete(row),
                                          tooltip: context.tr('Удалить замер'),
                                          icon:
                                              const Icon(Icons.delete_outline)),
                                    ],
                                  )))),
                  ]),
            ),
          ]),
    );
  }
}
