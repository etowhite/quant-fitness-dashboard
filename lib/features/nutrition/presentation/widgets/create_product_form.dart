import '../../domain/hydration.dart';
import 'hydration_editor.dart';
import 'package:smart_fitness_dashboard/core/theme/app_spacing.dart';
import 'package:smart_fitness_dashboard/shared/widgets/labeled_field.dart';
import '../../../../core/localization/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../../../core/validation/input_limits.dart';
import '../../data/food_product.dart';
import '../nutrition_input.dart';

class CreateProductForm extends ConsumerStatefulWidget {
  const CreateProductForm(
      {required this.onCreated,
      required this.onCancel,
      this.initialName = '',
      super.key});
  final String initialName;
  final ValueChanged<FoodProduct> onCreated;
  final VoidCallback onCancel;

  @override
  ConsumerState<CreateProductForm> createState() => _CreateProductFormState();
}

class _CreateProductFormState extends ConsumerState<CreateProductForm> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  final _numbers = List.generate(4, (_) => TextEditingController());
  bool _saving = false;
  String? _error;
  double _waterPercentage = 0;
  bool _hydrationEdited = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initialName);
    _waterPercentage = Hydration.detect(widget.initialName);
  }

  @override
  void dispose() {
    _name.dispose();
    for (final controller in _numbers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final product = FoodProduct()
      ..waterPercentage = _waterPercentage
      ..name = _name.text.trim()
      ..calories = parseNutritionNumber(_numbers[0].text)!
      ..proteins = parseNutritionNumber(_numbers[1].text)!
      ..fats = parseNutritionNumber(_numbers[2].text)!
      ..carbs = parseNutritionNumber(_numbers[3].text)!;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final database = await ref.read(databaseServiceProvider.future);
      await database.saveCustomProduct(product);
      if (mounted) widget.onCreated(product);
    } catch (_) {
      if (mounted) {
        setState(
            () => _error = 'Не удалось сохранить продукт. Повторите попытку.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          QText('Свой продукт', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const QText('Пищевая ценность на 100 г'),
          const SizedBox(height: AppSpacing.section),
          LabeledField(
              label: context.tr('Название'),
              child: TextFormField(
                  controller: _name,
                  onChanged: (name) {
                    if (!_hydrationEdited) {
                      setState(() => _waterPercentage = Hydration.detect(name));
                    }
                  },
                  enabled: !_saving,
                  maxLength: InputLimits.productName,
                  decoration: const InputDecoration(),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? context.tr('Введите название')
                      : null)),
          for (var i = 0; i < _numbers.length; i++)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: LabeledField(
                  label: context.tr([
                    'Калории, ккал',
                    'Белки, г',
                    'Жиры, г',
                    'Углеводы, г'
                  ][i]),
                  child: TextFormField(
                      controller: _numbers[i],
                      enabled: !_saving,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(),
                      validator: (value) => validateLocalizedNumber(
                          context, value,
                          max: i == 0
                              ? InputLimits.caloriesPer100g
                              : InputLimits.macroPer100g))),
            ),
          const SizedBox(height: AppSpacing.section),
          HydrationEditor(
              percentage: _waterPercentage,
              grams: 100,
              enabled: !_saving,
              onChanged: (v) => setState(() {
                    _hydrationEdited = true;
                    _waterPercentage = v;
                  })),
          if (_error != null)
            Padding(
                padding: const EdgeInsets.only(top: 12), child: QText(_error!)),
          const SizedBox(height: 20),
          FilledButton(
              onPressed: _saving ? null : _save,
              child: QText(_saving ? 'Сохранение…' : 'Сохранить продукт')),
          const SizedBox(height: AppSpacing.actionGap),
          TextButton(
              onPressed: _saving ? null : widget.onCancel,
              child: const QText('Назад к поиску')),
        ],
      ));
}
