import '../../../core/localization/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/database/isar_database_service.dart';
import '../../../core/database/local_day.dart';
import '../application/food_diary_provider.dart';
import '../../goals/application/user_goals_provider.dart';
import '../../water/presentation/water_balance_card.dart';
import '../data/food_log_entry.dart';
import 'widgets/add_food_sheet.dart';
import 'widgets/daily_nutrition_summary.dart';
import 'widgets/meal_section_card.dart';

class NutritionScreen extends ConsumerStatefulWidget {
  const NutritionScreen({super.key});

  @override
  ConsumerState<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends ConsumerState<NutritionScreen> {
  DateTime _date = localDay(DateTime.now());
  bool _sheetOpen = false;
  static final _firstDate = DateTime(1900);
  static final _lastDate = DateTime(2100, 12, 31);

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
        context: context,
        initialDate: _date,
        firstDate: _firstDate,
        lastDate: _lastDate,
        helpText: context.tr('Выберите дату'),
        cancelText: context.tr('Отмена'),
        confirmText: context.tr('Выбрать'));
    if (selected != null && mounted) setState(() => _date = localDay(selected));
  }

  void _moveDay(int offset) => setState(
      () => _date = DateTime(_date.year, _date.month, _date.day + offset));

  Future<void> _add([String meal = 'Завтрак']) async {
    if (_sheetOpen) return;
    setState(() => _sheetOpen = true);
    try {
      final added =
          await showAddFoodSheet(context, date: _date, mealType: meal);
      if (added == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: QText('Еда добавлена в дневник')));
      }
    } finally {
      if (mounted) setState(() => _sheetOpen = false);
    }
  }

  Future<bool> _delete(FoodLogEntry entry) async {
    try {
      final database = await ref.read(databaseServiceProvider.future);
      final deleted = await database.deleteFoodLogEntry(entry.id!);
      if (deleted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: QText('Удалено: ${entry.productName}'),
          action: SnackBarAction(
              label: context.tr('Отменить'),
              onPressed: () async {
                final copy = FoodLogEntry()
                  ..date = entry.date
                  ..mealType = entry.mealType
                  ..productName = entry.productName
                  ..weightGrams = entry.weightGrams
                  ..calories = entry.calories
                  ..proteins = entry.proteins
                  ..fats = entry.fats
                  ..carbs = entry.carbs;
                try {
                  await database.addFoodLogEntry(copy);
                } catch (_) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: QText('Не удалось восстановить запись.')));
                  }
                }
              }),
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: QText('Не удалось удалить запись. Попробуйте еще раз.')));
      }
    }
    return false; // Removal is driven by the committed Isar watcher event.
  }

  @override
  Widget build(BuildContext context) {
    final diary = ref.watch(foodDiaryProvider(_date));
    final goals = ref.watch(effectiveUserGoalsProvider);
    return Scaffold(
      appBar: AppBar(title: const QText('Питание')),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: _sheetOpen ? null : () => _add(),
          icon: const Icon(Icons.add),
          label: const QText('Добавить еду')),
      body: Column(children: [
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(children: [
              IconButton(
                  onPressed:
                      _date.isAfter(_firstDate) ? () => _moveDay(-1) : null,
                  tooltip: context.tr('Предыдущий день'),
                  icon: const Icon(Icons.chevron_left)),
              Expanded(
                  child: TextButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today_outlined, size: 18),
                      label: QText(
                          DateFormat('EEE, d MMM yyyy', context.languageCode)
                              .format(_date),
                          textAlign: TextAlign.center))),
              IconButton(
                  onPressed:
                      _date.isBefore(_lastDate) ? () => _moveDay(1) : null,
                  tooltip: context.tr('Следующий день'),
                  icon: const Icon(Icons.chevron_right)),
            ])),
        Expanded(
            child: diary.when(
          data: (day) => ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
              children: [
                DailyNutritionSummary(totals: day.totals, goals: goals),
                const SizedBox(height: 16),
                WaterBalanceCard(date: _date),
                for (final meal in IsarDatabaseService.mealTypes)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: MealSectionCard(
                        mealType: meal,
                        entries: day.entries
                            .where((entry) => entry.mealType == meal)
                            .toList(),
                        onAdd: () => _add(meal),
                        onDelete: _delete),
                  ),
              ]),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            const QText('Не удалось прочитать дневник.'),
            TextButton(
                onPressed: () => ref.invalidate(foodDiaryProvider(_date)),
                child: const QText('Повторить')),
          ])),
        )),
      ]),
    );
  }
}
