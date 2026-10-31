import '../../../core/localization/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/validation/input_limits.dart';
import '../../nutrition/presentation/nutrition_input.dart';
import '../application/user_goals_provider.dart';
import '../domain/user_goals.dart';

class UserGoalsCard extends ConsumerWidget {
  const UserGoalsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(userGoalsProvider);
    final goals = ref.watch(effectiveUserGoalsProvider);
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                      child: QText('Дневные цели',
                          style: Theme.of(context).textTheme.titleLarge)),
                  TextButton(
                      onPressed: state.isLoading
                          ? null
                          : () => showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                useSafeArea: true,
                                backgroundColor:
                                    Theme.of(context).colorScheme.surface,
                                shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(24))),
                                builder: (_) =>
                                    EditUserGoalsSheet(initial: goals),
                              ),
                      child: const QText('Изменить')),
                ]),
                if (state.isLoading) const LinearProgressIndicator(),
                if (state.hasError) ...[
                  const QText(
                      'Не удалось прочитать или сохранить цели. Показаны последние доступные нормы.'),
                  TextButton(
                      onPressed: state.isLoading
                          ? null
                          : () => ref.invalidate(userGoalsProvider),
                      child: const QText('Повторить')),
                ],
                const SizedBox(height: 12),
                QText(
                    '${goals.calories.toStringAsFixed(0)} ккал · ${goals.steps} шагов',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                QText('Вода: ${goals.waterMl} мл',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary)),
                QText(
                    'Б ${goals.proteins.toStringAsFixed(1)} · Ж ${goals.fats.toStringAsFixed(1)} · У ${goals.carbs.toStringAsFixed(1)} г'),
              ],
            )));
  }
}

class EditUserGoalsSheet extends ConsumerStatefulWidget {
  const EditUserGoalsSheet({required this.initial, super.key});
  final UserGoals initial;
  @override
  ConsumerState<EditUserGoalsSheet> createState() => _EditUserGoalsSheetState();
}

class _EditUserGoalsSheetState extends ConsumerState<EditUserGoalsSheet> {
  final _form = GlobalKey<FormState>();
  late final List<TextEditingController> _fields;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final g = widget.initial;
    _fields = [g.calories, g.proteins, g.fats, g.carbs, g.steps, g.waterMl]
        .map((value) => TextEditingController(text: value.toString()))
        .toList();
  }

  @override
  void dispose() {
    for (final field in _fields) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    final values = _fields
        .take(4)
        .map((f) => parseNutritionNumber(f.text, positive: true)!)
        .toList();
    final goals = UserGoals(
        calories: values[0],
        proteins: values[1],
        fats: values[2],
        carbs: values[3],
        steps: int.parse(_fields[4].text.trim()),
        waterMl: int.parse(_fields[5].text.trim()));
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(userGoalsProvider.notifier).save(goals);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(
            () => _error = 'Не удалось сохранить цели. Повторите попытку.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_saving,
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.85,
          child: Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                  key: _form,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        QText('Изменить цели',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        const QText(
                            'Все цели должны быть больше нуля. Шаги — целое число.'),
                        for (var i = 0; i < 6; i++)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: TextFormField(
                                controller: _fields[i],
                                enabled: !_saving,
                                keyboardType: TextInputType.numberWithOptions(
                                    decimal: i < 4),
                                decoration: InputDecoration(
                                    labelText: context.tr([
                                  'Калории, ккал',
                                  'Белки, г',
                                  'Жиры, г',
                                  'Углеводы, г',
                                  'Шаги',
                                  'Вода, мл'
                                ][i])),
                                validator: (text) => i >= 4
                                    ? ((int.tryParse(text?.trim() ?? '') ?? 0) <= 0 ||
                                            (int.tryParse(text!.trim()) ?? 0) >
                                                (i == 4
                                                    ? InputLimits.dailySteps
                                                    : InputLimits.waterGoalMl)
                                        ? context.tr(
                                            'Введите целое число от 1 до ${(i == 4 ? InputLimits.dailySteps : InputLimits.waterGoalMl)}')
                                        : null)
                                    : validateLocalizedNumber(context, text,
                                        positive: true,
                                        max: i == 0
                                            ? InputLimits.dailyCalories
                                            : InputLimits.dailyMacro)),
                          ),
                        if (_error != null) QText(_error!),
                        const SizedBox(height: 24),
                        FilledButton(
                            onPressed: _saving ? null : _save,
                            child: QText(
                                _saving ? 'Сохранение…' : 'Сохранить цели')),
                        TextButton(
                            onPressed:
                                _saving ? null : () => Navigator.pop(context),
                            child: const QText('Отмена')),
                      ])),
            ),
          ),
        ),
      );
}
