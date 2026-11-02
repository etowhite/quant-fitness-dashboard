import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/local_day.dart';
import '../../../core/health/local_health.dart';
import '../../../core/localization/app_strings.dart';
import '../../../shared/widgets/labeled_field.dart';
import '../../measurements/data/body_measurement.dart';
import '../application/daily_health_provider.dart';

Future<void> showManualHealthDialog(BuildContext context, WidgetRef ref,
    {required bool body}) async {
  final day = localDay(DateTime.now());
  final db = await ref.read(databaseServiceProvider.future);
  final row = await db.getBodyMeasurementForDay(day);
  final activity = await ManualActivityRepository().load(day);
  if (!context.mounted) return;
  final first = TextEditingController(
      text: (body ? row?.weight : activity.steps)?.toString() ?? '');
  final second = TextEditingController(
      text: (body ? row?.bodyFat : activity.calories)?.toString() ?? '');
  final form = GlobalKey<FormState>();
  bool saving = false;
  String? error;
  await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
                  title: QText(
                      body ? 'Вес и процент жира' : 'Активность за сегодня'),
                  content: SingleChildScrollView(
                      child: Form(
                          key: form,
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            const QText(
                                'Ручные значения хранятся только на устройстве. Пустое поле активности возвращает автоматические данные.'),
                            const SizedBox(height: 16),
                            for (var i = 0; i < 2; i++)
                              Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: LabeledField(
                                      label: context.tr(body
                                          ? (i == 0 ? 'Вес, кг' : 'Жир, %')
                                          : (i == 0
                                              ? 'Шаги'
                                              : 'Активные ккал')),
                                      child: TextFormField(
                                          controller: i == 0 ? first : second,
                                          keyboardType: const TextInputType
                                              .numberWithOptions(decimal: true),
                                          validator: (text) {
                                            if (text == null ||
                                                text.trim().isEmpty) {
                                              return null;
                                            }
                                            final n = double.tryParse(
                                                text.replaceAll(',', '.'));
                                            final max = body
                                                ? (i == 0 ? 1000 : 100)
                                                : (i == 0 ? 1000000 : 100000);
                                            if (n == null ||
                                                !n.isFinite ||
                                                n < 0 ||
                                                n > max ||
                                                body && i == 0 && n == 0 ||
                                                !body &&
                                                    i == 0 &&
                                                    n != n.roundToDouble()) {
                                              return context.tr(
                                                  'Введите корректное значение');
                                            }
                                            return null;
                                          }))),
                            if (error != null) QText(error!),
                          ]))),
                  actions: [
                    TextButton(
                        onPressed: saving ? null : () => Navigator.pop(context),
                        child: const QText('Отмена')),
                    FilledButton(
                        onPressed: saving
                            ? null
                            : () async {
                                if (!form.currentState!.validate()) return;
                                double? value(TextEditingController c) =>
                                    double.tryParse(
                                        c.text.replaceAll(',', '.'));
                                setState(() {
                                  saving = true;
                                  error = null;
                                });
                                try {
                                  if (body) {
                                    final measurement =
                                        row ?? (BodyMeasurement()..date = day);
                                    measurement.weight = value(first);
                                    measurement.bodyFat = value(second);
                                    await db.saveBodyMeasurement(measurement);
                                  } else {
                                    await ManualActivityRepository().save(day,
                                        value(first)?.round(), value(second));
                                  }
                                  await ref
                                      .read(dailyHealthProvider.notifier)
                                      .refresh();
                                  if (context.mounted) Navigator.pop(context);
                                } catch (_) {
                                  if (context.mounted) {
                                    setState(() {
                                      saving = false;
                                      error =
                                          'Не удалось сохранить. Попробуйте еще раз.';
                                    });
                                  }
                                }
                              },
                        child: const QText('Сохранить')),
                  ])));
  // Dialog route transitions may still reference controllers; dispose after transition.
  await Future<void>.delayed(const Duration(milliseconds: 350));
  first.dispose();
  second.dispose();
}
