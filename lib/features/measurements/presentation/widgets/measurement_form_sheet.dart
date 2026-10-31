import '../../../../core/localization/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/database_provider.dart';
import '../../../../core/database/local_day.dart';
import '../../../../core/validation/input_limits.dart';
import '../../../nutrition/presentation/nutrition_input.dart';
import '../../application/body_measurements_provider.dart';
import '../../data/body_measurement.dart';

class MeasurementFormSheet extends ConsumerStatefulWidget {
  const MeasurementFormSheet({super.key});
  @override
  ConsumerState<MeasurementFormSheet> createState() =>
      _MeasurementFormSheetState();
}

class _MeasurementFormSheetState extends ConsumerState<MeasurementFormSheet> {
  final _form = GlobalKey<FormState>();
  final _values = List.generate(4, (_) => TextEditingController());
  final _note = TextEditingController();
  DateTime _date = localDay(DateTime.now());
  bool _loading = true, _saving = false, _existing = false;
  bool _loadFailed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDay();
  }

  Future<void> _loadDay() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
      _error = null;
    });
    try {
      final database = await ref.read(databaseServiceProvider.future);
      final row = await database.getBodyMeasurementForDay(_date);
      if (!mounted) return;
      final values = [row?.chest, row?.waist, row?.hips, row?.biceps];
      for (var i = 0; i < 4; i++) {
        _values[i].text = values[i]?.toString() ?? '';
      }
      _note.text = row?.note ?? '';
      setState(() {
        _existing = row != null;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _error =
              'Не удалось загрузить запись за эту дату. Повторите попытку.';
          _loadFailed = true;
          _loading = false;
        });
      }
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
        context: context,
        initialDate: _date,
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
        helpText: context.tr('Дата замера'),
        cancelText: context.tr('Отмена'),
        confirmText: context.tr('Выбрать'));
    if (!mounted || date == null || localDay(date) == _date) return;
    setState(() => _date = localDay(date));
    await _loadDay();
  }

  Future<void> _save() async {
    if (_saving || _loading || _loadFailed || !_form.currentState!.validate()) {
      return;
    }
    final values = _values
        .map((field) => field.text.trim().isEmpty
            ? null
            : parseNutritionNumber(field.text, positive: true))
        .toList();
    if (values.every((value) => value == null) && _note.text.trim().isEmpty) {
      setState(() => _error = 'Заполните хотя бы один параметр или заметку.');
      return;
    }
    final measurement = BodyMeasurement()
      ..date = _date
      ..chest = values[0]
      ..waist = values[1]
      ..hips = values[2]
      ..biceps = values[3]
      ..note = _note.text.trim().isEmpty ? null : _note.text.trim();
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(bodyMeasurementActionsProvider).save(measurement);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(
            () => _error = 'Не удалось сохранить замер. Повторите попытку.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    for (final value in _values) {
      value.dispose();
    }
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_saving,
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.9,
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
                        QText('Новый замер',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                            onPressed: _saving || _loading ? null : _pickDate,
                            icon: const Icon(Icons.calendar_today_outlined),
                            label: QText(
                                DateFormat('d MMMM yyyy', context.languageCode)
                                    .format(_date))),
                        if (_loading) const LinearProgressIndicator(),
                        if (_existing)
                          const QText(
                              'Запись за эту дату уже есть. Сохранение заменит ее значениями формы.'),
                        const SizedBox(height: 8),
                        const QText('Можно заполнить только нужные параметры.'),
                        for (var i = 0; i < 4; i++)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: TextFormField(
                                controller: _values[i],
                                enabled: !_saving && !_loading && !_loadFailed,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                decoration: InputDecoration(
                                    labelText: context.tr([
                                      'Грудь',
                                      'Талия',
                                      'Бедра',
                                      'Бицепс'
                                    ][i]),
                                    suffixText: context.tr('см')),
                                validator: (text) =>
                                    text == null || text.trim().isEmpty
                                        ? null
                                        : validateLocalizedNumber(context, text,
                                            positive: true,
                                            max: InputLimits.circumferenceCm)),
                          ),
                        const SizedBox(height: 16),
                        TextFormField(
                            controller: _note,
                            enabled: !_saving && !_loading && !_loadFailed,
                            maxLines: 3,
                            maxLength: InputLimits.note,
                            decoration: InputDecoration(
                                labelText: context.tr('Заметка'))),
                        if (_error != null) ...[
                          QText(_error!),
                          if (_loadFailed)
                            TextButton(
                                onPressed: _saving ? null : _loadDay,
                                child: const QText('Загрузить запись заново')),
                        ],
                        const SizedBox(height: 20),
                        FilledButton(
                            onPressed: _saving || _loading || _loadFailed
                                ? null
                                : _save,
                            child: QText(
                                _saving ? 'Сохранение…' : 'Сохранить замер')),
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
