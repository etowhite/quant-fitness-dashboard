import 'package:flutter/material.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/quant_dialog.dart';
import '../../../../shared/widgets/labeled_field.dart';
import '../../domain/hydration.dart';
import '../nutrition_input.dart';

class HydrationEditor extends StatelessWidget {
  const HydrationEditor(
      {required this.percentage,
      required this.grams,
      required this.onChanged,
      this.enabled = true,
      super.key});
  final double percentage, grams;
  final ValueChanged<double> onChanged;
  final bool enabled;

  Future<void> _edit(BuildContext context) async {
    final field = TextEditingController(
        text: percentage.toStringAsFixed(percentage % 1 == 0 ? 0 : 1));
    final form = GlobalKey<FormState>();
    final result = await showDialog<double>(
        context: context,
        builder: (c) => QuantDialog(
                title: const QText('Доля воды в продукте'),
                content: Form(
                    key: form,
                    child: LabeledField(
                        label: c.tr('Процент воды, 0–100%'),
                        child: TextFormField(
                            key: const ValueKey('hydration-percentage-input'),
                            controller: field,
                            autofocus: true,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(suffixText: '%'),
                            validator: (v) =>
                                validateLocalizedNumber(c, v, max: 100)))),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: const QText('Отмена')),
                  FilledButton(
                      onPressed: () {
                        if (form.currentState!.validate()) {
                          Navigator.pop(c, parseNutritionNumber(field.text));
                        }
                      },
                      child: const QText('Сохранить'))
                ]));
    await Future<void>.delayed(const Duration(milliseconds: 300));
    field.dispose();
    if (context.mounted && result != null) {
      onChanged(Hydration.validate(result));
    }
  }

  @override
  Widget build(BuildContext context) {
    final percent = percentage.toStringAsFixed(percentage % 1 == 0 ? 0 : 1);
    final volume = Hydration.volume(grams, percentage).round();
    return Row(children: [
      Expanded(
          child: OutlinedButton.icon(
              key: const ValueKey('hydration-edit'),
              onPressed: enabled ? () => _edit(context) : null,
              icon: const Icon(Icons.water_drop_outlined),
              label: QText('Учитывать в воде: $percent% (+$volume мл)',
                  textAlign: TextAlign.center))),
      const SizedBox(width: AppSpacing.small),
      Semantics(
          label: context.tr('Учитывать в водном балансе'),
          child: Switch(
              key: const ValueKey('hydration-toggle'),
              value: percentage > 0,
              onChanged: enabled ? (v) => onChanged(v ? 100 : 0) : null)),
    ]);
  }
}
