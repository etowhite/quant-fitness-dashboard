import 'package:smart_fitness_dashboard/shared/widgets/labeled_field.dart';
import '../../../core/localization/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_provider.dart';
import '../../goals/application/user_goals_provider.dart';
import '../application/water_provider.dart';
import '../application/water_presets_provider.dart';
import '../../../shared/widgets/expressive_motion.dart';
import 'package:flutter/services.dart';

class WaterBalanceCard extends ConsumerStatefulWidget {
  const WaterBalanceCard({required this.date, super.key});
  final DateTime date;
  @override
  ConsumerState<WaterBalanceCard> createState() => _WaterBalanceCardState();
}

class _WaterBalanceCardState extends ConsumerState<WaterBalanceCard> {
  bool _busy = false;
  String? _error;
  Future<void> _custom() async {
    final field = TextEditingController();
    final form = GlobalKey<FormState>();
    var remember = false;
    final presets = await ref.read(waterPresetsProvider.future);
    if (!mounted) {
      field.dispose();
      return;
    }
    final result = await showDialog<({int volume, bool remember})>(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, update) => AlertDialog(
                  title: const QText('Свой объем воды'),
                  content: Form(
                      key: form,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        LabeledField(
                            label: context.tr('Объем, мл'),
                            child: TextFormField(
                                controller: field,
                                autofocus: true,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(4)
                                ],
                                decoration:
                                    const InputDecoration(hintText: '330'),
                                validator: (v) {
                                  final number = int.tryParse(v ?? '');
                                  return number == null ||
                                          number < 1 ||
                                          number > 5000
                                      ? context.tr('Введите от 1 до 5000 мл')
                                      : null;
                                })),
                        CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const QText('Сохранить кнопку'),
                            subtitle: presets.length >= 8
                                ? const QText('Можно сохранить до 8 кнопок')
                                : null,
                            value: remember,
                            onChanged: presets.length >= 8
                                ? null
                                : (v) => update(() => remember = v ?? false)),
                      ])),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const QText('Отмена')),
                    FilledButton(
                        onPressed: () {
                          if (form.currentState!.validate()) {
                            Navigator.pop(context, (
                              volume: int.parse(field.text),
                              remember: remember
                            ));
                          }
                        },
                        child: const QText('Добавить воду'))
                  ],
                )));
    // Wait for the dialog exit animation before disposing its controller.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    field.dispose();
    if (!mounted || result == null) return;
    try {
      if (result.remember &&
          ![150, 250, 500, ...presets].contains(result.volume)) {
        await ref
            .read(waterPresetsProvider.notifier)
            .save([...presets, result.volume]);
      }
      await _change(result.volume);
    } catch (_) {
      if (mounted) {
        setState(
            () => _error = 'Не удалось сохранить воду. Повторите попытку.');
      }
    }
  }

  Future<void> _change(int? volume) async {
    if (_busy) return;
    final date = widget.date;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final db = await ref.read(databaseServiceProvider.future);
      if (volume == null) {
        await db.undoWater(date);
      } else {
        await db.addWater(date, volume);
      }
    } catch (_) {
      if (mounted) {
        setState(
            () => _error = 'Не удалось сохранить воду. Повторите попытку.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final water = ref.watch(waterProvider(widget.date));
    final goal = ref.watch(effectiveUserGoalsProvider).waterMl;
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(20),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.water_drop_outlined,
                    color: Theme.of(context).colorScheme.secondary),
                const SizedBox(width: 8),
                QText('Водный баланс',
                    style: Theme.of(context).textTheme.titleMedium)
              ]),
              const SizedBox(height: 12),
              water.when(
                  data: (rows) {
                    final total =
                        rows.fold<int>(0, (sum, r) => sum + r.volumeMl);
                    return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedMetric(
                              value: total.toDouble(),
                              format: (value) => '${value.round()} / $goal мл',
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 10),
                          AnimatedProgress(
                              value: (total / goal).clamp(0.0, 1.0),
                              color: Theme.of(context).colorScheme.secondary,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .secondary
                                  .withAlpha(26),
                              minHeight: 6),
                          const SizedBox(height: 12),
                          Wrap(spacing: 10, runSpacing: 10, children: [
                            for (final volume in {
                              150,
                              250,
                              500,
                              ...?ref.watch(waterPresetsProvider).valueOrNull
                            })
                              OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      shape: const StadiumBorder()),
                                  onPressed:
                                      _busy ? null : () => _change(volume),
                                  child: QText('+$volume мл')),
                            OutlinedButton.icon(
                                onPressed: _busy ? null : _custom,
                                style: OutlinedButton.styleFrom(
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    shape: const StadiumBorder()),
                                icon: const Icon(Icons.add),
                                label: const QText('Свой объем')),
                            IconButton(
                                style: IconButton.styleFrom(
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap),
                                onPressed: _busy || rows.isEmpty
                                    ? null
                                    : () => _change(null),
                                tooltip:
                                    context.tr('Отменить последнюю порцию'),
                                icon: Icon(Icons.remove_circle_outline,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondary)),
                          ]),
                        ]);
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => TextButton(
                      onPressed: () =>
                          ref.invalidate(waterProvider(widget.date)),
                      child: const QText('Повторить загрузку воды'))),
              if (_error != null) QText(_error!),
            ])));
  }
}
