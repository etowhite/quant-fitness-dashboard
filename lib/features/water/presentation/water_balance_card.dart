import '../../nutrition/application/food_diary_provider.dart';
import 'package:smart_fitness_dashboard/core/theme/app_spacing.dart';
import 'package:smart_fitness_dashboard/shared/widgets/quant_dialog.dart';
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
  bool _editing = false;
  String? _error;

  void _settingsError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: QText('Не удалось сохранить настройки кнопок воды')));
  }

  Future<void> _manage(int volume) async {
    if (_busy || _editing) return;
    setState(() => _editing = true);
    // Unsupported haptics must not prevent access to the menu.
    HapticFeedback.selectionClick().catchError((Object _) {});
    try {
      final action = await showModalBottomSheet<String>(
          context: context,
          useSafeArea: true,
          builder: (c) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                QText('+$volume мл', style: Theme.of(c).textTheme.titleMedium),
                ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: const QText('Изменить'),
                    onTap: () => Navigator.pop(c, 'edit')),
                const Divider(height: 1),
                ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: const QText('Удалить'),
                    onTap: () => Navigator.pop(c, 'delete')),
              ])));
      if (!mounted) return;
      if (action == 'edit') {
        await _edit(volume);
      } else if (action == 'delete') {
        await ref.read(waterPresetsProvider.notifier).remove(volume);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const QText('Кнопка воды удалена'),
            action: SnackBarAction(
                label: context.tr('Отменить'),
                onPressed: () async {
                  try {
                    await ref
                        .read(waterPresetsProvider.notifier)
                        .restore(volume);
                  } catch (_) {
                    _settingsError();
                  }
                })));
      }
    } catch (_) {
      _settingsError();
    } finally {
      if (mounted) setState(() => _editing = false);
    }
  }

  Future<void> _edit(int volume) async {
    final field = TextEditingController(text: '$volume');
    final form = GlobalKey<FormState>();
    final presets = await ref.read(waterPresetsProvider.future);
    if (!mounted) {
      field.dispose();
      return;
    }
    final result = await showDialog<int>(
        context: context,
        builder: (c) => QuantDialog(
                title: const QText('Изменить кнопку воды'),
                content: Form(
                    key: form,
                    child: LabeledField(
                        label: c.tr('Объем, мл'),
                        child: TextFormField(
                            controller: field,
                            autofocus: true,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4)
                            ],
                            validator: (v) => _validateVolume(c, v,
                                presets: presets, excluding: volume)))),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: const QText('Отмена')),
                  FilledButton(
                      onPressed: () {
                        if (form.currentState!.validate()) {
                          Navigator.pop(c, int.parse(field.text));
                        }
                      },
                      child: const QText('Сохранить'))
                ]));
    Future<void>.delayed(const Duration(milliseconds: 400), field.dispose);
    if (result != null) {
      await ref.read(waterPresetsProvider.notifier).replace(volume, result);
    }
  }

  String? _validateVolume(BuildContext context, String? value,
      {List<int>? presets, int? excluding}) {
    final number = int.tryParse(value ?? '');
    if (number == null || number < 1 || number > 5000) {
      return context.tr('Введите от 1 до 5000 мл');
    }
    if (number != excluding && (presets?.contains(number) ?? false)) {
      return context.tr('Кнопка с таким объемом уже есть');
    }
    return null;
  }

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
            builder: (context, update) => QuantDialog(
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
                                validator: (v) => _validateVolume(context, v,
                                    presets: remember ? presets : null))),
                        CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const QText('Сохранить кнопку'),
                            subtitle: presets.length >=
                                    WaterPresetsRepository.maxButtons
                                ? const QText('Можно сохранить до 11 кнопок')
                                : null,
                            value: remember,
                            onChanged: presets.length >=
                                    WaterPresetsRepository.maxButtons
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
      if (result.remember) {
        await ref.read(waterPresetsProvider.notifier).add(result.volume);
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
    final hydration = ref.watch(dailyHydrationProvider(widget.date));
    final goal = ref.watch(effectiveUserGoalsProvider).waterMl;
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(AppSpacing.cardInset),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.water_drop_outlined,
                    color: Theme.of(context).colorScheme.secondary),
                const SizedBox(width: 8),
                Expanded(
                    child: QText('Водный баланс',
                        style: Theme.of(context).textTheme.titleMedium))
              ]),
              const SizedBox(height: AppSpacing.actionGap),
              hydration.when(
                  data: (balance) {
                    final rows = water.valueOrNull ?? [];
                    final total = balance.totalMl;
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
                          const SizedBox(height: 6),
                          QText(
                              'в т.ч. ${balance.foodMl.round()} мл из напитков и еды',
                              style: Theme.of(context).textTheme.bodySmall),
                          const SizedBox(height: 10),
                          AnimatedProgress(
                              value: (total / goal).clamp(0.0, 1.0),
                              color: Theme.of(context).colorScheme.secondary,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .secondary
                                  .withAlpha(26),
                              minHeight: 6),
                          const SizedBox(height: AppSpacing.actionGap),
                          Wrap(
                              spacing: AppSpacing.chipGap,
                              runSpacing: AppSpacing.chipGap,
                              children: [
                                for (final volume in ref
                                        .watch(waterPresetsProvider)
                                        .valueOrNull ??
                                    <int>[])
                                  OutlinedButton(
                                      key: ValueKey('water-preset-$volume'),
                                      style: OutlinedButton.styleFrom(
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          shape: const StadiumBorder()),
                                      onPressed: _busy || _editing
                                          ? null
                                          : () => _change(volume),
                                      onLongPress: _busy || _editing
                                          ? null
                                          : () => _manage(volume),
                                      child: QText('+$volume мл')),
                              ]),
                          if ((ref.watch(waterPresetsProvider).valueOrNull ??
                                  [])
                              .isNotEmpty)
                            const SizedBox(height: AppSpacing.chipGap),
                          LayoutBuilder(builder: (context, box) {
                            final label = context.tr('Свой объем');
                            final style =
                                Theme.of(context).textTheme.labelLarge!;
                            final scaler = MediaQuery.textScalerOf(context);
                            double heightFor(bool icon) {
                              var height = AppSpacing.actionMinHeight;
                              for (var n = 0; n < 8; n++) {
                                final available = box.maxWidth -
                                    height -
                                    AppSpacing.chipGap -
                                    24 -
                                    (icon ? 32 : 0);
                                if (available < 32) return double.infinity;
                                final painter = TextPainter(
                                    text: TextSpan(text: label, style: style),
                                    textDirection: Directionality.of(context),
                                    textScaler: scaler)
                                  ..layout(maxWidth: available);
                                final next = (painter.height + 24).clamp(
                                    AppSpacing.actionMinHeight,
                                    double.infinity);
                                painter.dispose();
                                if ((next - height).abs() < .5) return next;
                                height = next;
                              }
                              return double.infinity;
                            }

                            var showIcon = true;
                            var height = heightFor(true);
                            if (!height.isFinite || height > box.maxWidth / 2) {
                              showIcon = false;
                              height = heightFor(false);
                            }
                            final compact =
                                !height.isFinite || height > box.maxWidth / 2;
                            if (compact) height = AppSpacing.actionMinHeight;
                            const text = QText('Свой объем',
                                textAlign: TextAlign.center);
                            final customLabel = compact
                                ? const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: QText('Свой объем',
                                        maxLines: 1, softWrap: false))
                                : text;
                            return SizedBox(
                                height: height,
                                child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                          child: OutlinedButton(
                                              key: const ValueKey(
                                                  'water-custom'),
                                              onPressed: _busy || _editing
                                                  ? null
                                                  : _custom,
                                              style: OutlinedButton.styleFrom(
                                                  minimumSize: Size.zero,
                                                  padding:
                                                      const EdgeInsets.all(12),
                                                  tapTargetSize:
                                                      MaterialTapTargetSize
                                                          .shrinkWrap),
                                              child: showIcon
                                                  ? Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                          const Icon(Icons.add),
                                                          const SizedBox(
                                                              width: 8),
                                                          Expanded(
                                                              child:
                                                                  customLabel)
                                                        ])
                                                  : customLabel)),
                                      const SizedBox(width: AppSpacing.chipGap),
                                      SizedBox(
                                          width: height,
                                          child: IconButton(
                                              key: const ValueKey('water-undo'),
                                              style: IconButton.styleFrom(
                                                  minimumSize: Size.zero,
                                                  shape: const CircleBorder(),
                                                  tapTargetSize:
                                                      MaterialTapTargetSize
                                                          .shrinkWrap),
                                              onPressed: _busy || rows.isEmpty
                                                  ? null
                                                  : () => _change(null),
                                              tooltip: context.tr(
                                                  'Отменить последнюю порцию'),
                                              icon: Icon(
                                                  Icons.remove_circle_outline,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .secondary))),
                                    ]));
                          }),
                        ]);
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => TextButton(
                      onPressed: () {
                        ref.invalidate(waterProvider(widget.date));
                        ref.invalidate(foodDiaryProvider(widget.date));
                      },
                      child: const QText('Повторить загрузку воды'))),
              if (_error != null) QText(_error!),
            ])));
  }
}
