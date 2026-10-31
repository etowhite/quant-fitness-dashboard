import '../../../../core/localization/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:isar_community/isar.dart';

import '../../../../core/database/database_provider.dart';
import '../../../../core/database/isar_database_service.dart';
import '../../../../core/validation/input_limits.dart';
import '../../application/product_search_provider.dart';
import '../../data/food_product.dart';
import '../nutrition_input.dart';
import 'create_product_form.dart';
import '../../application/online_product_provider.dart';
import '../../data/open_food_facts_service.dart';
import 'barcode_scanner_screen.dart';

Future<bool?> showAddFoodSheet(
  BuildContext context, {
  required DateTime date,
  String mealType = 'Завтрак',
}) =>
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      sheetAnimationStyle: const AnimationStyle(
          duration: Duration(milliseconds: 420),
          reverseDuration: Duration(milliseconds: 300)),
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => AddFoodSheet(date: date, initialMeal: mealType),
    );

class AddFoodSheet extends ConsumerStatefulWidget {
  const AddFoodSheet(
      {required this.date, required this.initialMeal, super.key});
  final DateTime date;
  final String initialMeal;

  @override
  ConsumerState<AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends ConsumerState<AddFoodSheet> {
  final _search = TextEditingController();
  final _weight = TextEditingController(text: '100');
  final _portionForm = GlobalKey<FormState>();
  String _query = '';
  late String _meal;
  FoodProduct? _selected;
  bool _creating = false;
  bool _saving = false;
  bool _lookingUp = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _meal = widget.initialMeal;
  }

  @override
  void dispose() {
    _search.dispose();
    _weight.dispose();
    super.dispose();
  }

  void _searchChanged(String value) {
    setState(() {
      _query = value.trim();
      _error = null;
    });
  }

  Future<void> _chooseOnline(FoodProduct product) async {
    if (_lookingUp) return;
    setState(() {
      _lookingUp = true;
      _error = null;
    });
    try {
      final db = await ref.read(databaseServiceProvider.future);
      final saved = await db.cacheOnlineProduct(product);
      if (mounted) setState(() => _selected = saved);
    } catch (_) {
      if (mounted) {
        setState(
            () => _error = 'Не удалось сохранить продукт для офлайн-доступа.');
      }
    } finally {
      if (mounted) setState(() => _lookingUp = false);
    }
  }

  Future<void> _barcode() async {
    final code = await Navigator.push<String>(
        context,
        MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => const BarcodeScannerScreen()));
    if (!mounted || code == null) return;
    if (!OpenFoodFactsService.validBarcode(code)) {
      setState(() => _error = 'Введите 8 или 12–14 цифр штрихкода.');
      return;
    }
    setState(() {
      _lookingUp = true;
      _error = null;
    });
    try {
      final db = await ref.read(databaseServiceProvider.future);
      final local =
          await db.isar.foodProducts.where().barcodeEqualTo(code).findFirst();
      final product =
          local ?? await ref.read(openFoodFactsProvider).barcode(code);
      if (product == null) {
        if (mounted) {
          setState(() => _error =
              'Нет полной этикетки КБЖУ для этого кода. Создайте продукт вручную.');
        }
      } else {
        final saved = local ?? await db.cacheOnlineProduct(product);
        if (mounted) setState(() => _selected = saved);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error =
            'Поиск недоступен. Проверьте сеть или создайте продукт вручную.');
      }
    } finally {
      if (mounted) setState(() => _lookingUp = false);
    }
  }

  Future<void> _add() async {
    if (_saving || !_portionForm.currentState!.validate()) return;
    final product = _selected!;
    final grams = parseNutritionNumber(_weight.text, positive: true)!;
    final meal = _meal;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final database = await ref.read(databaseServiceProvider.future);
      await database.addProductToDiary(
          product: product,
          date: widget.date,
          mealType: meal,
          weightGrams: grams);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(
            () => _error = 'Не удалось добавить запись. Повторите попытку.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _validatePortion(String? text) {
    final error = validateLocalizedNumber(context, text,
        positive: true, max: InputLimits.portionGrams);
    if (error != null) return error;
    final factor = parseNutritionNumber(text!, positive: true)! / 100;
    final product = _selected!;
    if (![product.calories, product.proteins, product.fats, product.carbs]
        .every((value) => (value * factor).isFinite)) {
      return context.tr('Слишком большой вес порции');
    }
    return null;
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
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: _creating
                  ? CreateProductForm(
                      initialName: _search.text.trim(),
                      onCancel: () => setState(() => _creating = false),
                      onCreated: (product) => setState(() {
                        _creating = false;
                        _selected = product;
                        _error = null;
                      }),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                          Row(children: [
                            Expanded(
                                child: QText('Добавить еду',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge)),
                            IconButton(
                                onPressed: _saving
                                    ? null
                                    : () => Navigator.pop(context),
                                tooltip: context.tr('Закрыть'),
                                icon: const Icon(Icons.close)),
                          ]),
                          QText(
                              DateFormat('d MMMM yyyy', context.languageCode)
                                  .format(widget.date),
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant)),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: _meal,
                            isExpanded: true,
                            decoration: InputDecoration(
                                labelText: context.tr('Прием пищи')),
                            items: IsarDatabaseService.mealTypes
                                .map((meal) => DropdownMenuItem(
                                    value: meal, child: QText(meal)))
                                .toList(),
                            onChanged: _saving
                                ? null
                                : (meal) => setState(() => _meal = meal!),
                          ),
                          const SizedBox(height: 16),
                          if (_selected == null)
                            ..._searchWidgets()
                          else
                            ..._portionWidgets(),
                        ]),
            ),
          ),
        ),
      );

  List<Widget> _searchWidgets() {
    final products = ref.watch(productSearchProvider(_query));
    final online = _query.length >= 2
        ? ref.watch(onlineProductProvider(_query))
        : const AsyncData(<FoodProduct>[]);
    return [
      TextField(
          controller: _search,
          onChanged: _searchChanged,
          decoration: InputDecoration(
              labelText: context.tr('Найти продукт'),
              hintText: context.tr('Начните вводить название'),
              prefixIcon: const Icon(Icons.search))),
      const SizedBox(height: 8),
      AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _lookingUp || online.isLoading
              ? const LinearProgressIndicator(key: ValueKey('search-loading'))
              : const SizedBox(height: 4)),
      if (_error != null) QText(_error!),
      Wrap(spacing: 8, runSpacing: 8, children: [
        OutlinedButton.icon(
            onPressed: _lookingUp ? null : _barcode,
            icon: const Icon(Icons.qr_code_scanner),
            label: const QText('Найти по штрихкоду')),
        OutlinedButton.icon(
            onPressed: () {
              FocusScope.of(context).unfocus();
              setState(() => _creating = true);
            },
            icon: const Icon(Icons.add),
            label: const QText('Создать свой продукт')),
      ]),
      const Divider(height: 24, thickness: 1),
      const SizedBox(height: 8),
      products.when(
        skipLoadingOnReload: false,
        data: (items) => items.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(20),
                child: QText('Продукты не найдены. Создайте свой продукт.'))
            : Column(children: [
                for (final product in items) ...[
                  if (product != items.first)
                    const Divider(height: 1, thickness: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(product.name),
                    subtitle: QText(
                        '${product.category} · ${product.calories.round()} ккал\nБ ${product.proteins.toStringAsFixed(1)} · Ж ${product.fats.toStringAsFixed(1)} · У ${product.carbs.toStringAsFixed(1)} / 100 г${product.source == null ? '' : '\n${product.source}'}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      setState(() => _selected = product);
                    },
                  ),
                ],
                if (items.length == 30)
                  const QText('Уточните название, чтобы сузить поиск.'),
              ]),
        loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator())),
        error: (error, stack) => Column(children: [
          const QText('Не удалось загрузить справочник.'),
          TextButton(
              onPressed: () => ref.invalidate(productSearchProvider(_query)),
              child: const QText('Повторить'))
        ]),
      ),
      if (_query.length >= 2) ...[
        const Divider(height: 32),
        QText('Open Food Facts · ODbL',
            style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
        QText(
            'Название запроса отправляется в Open Food Facts. Проверьте КБЖУ по этикетке. Поиск ограничен 10 запросами в минуту.',
            style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        online.when(
            skipLoadingOnReload: false,
            data: (items) => items.isEmpty
                ? const QText('Нет продуктов с полным КБЖУ.')
                : Column(children: [
                    for (final p in items.where((p) =>
                        !(products.valueOrNull ?? <FoodProduct>[]).any(
                            (local) =>
                                local.barcode != null &&
                                local.barcode == p.barcode))) ...[
                      const Divider(height: 1, thickness: 1),
                      ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(p.name),
                          subtitle: QText(
                              '${p.calories.round()} ккал / 100 г · сохранить офлайн'),
                          trailing: const Icon(Icons.cloud_download_outlined),
                          onTap: _lookingUp ? null : () => _chooseOnline(p)),
                    ],
                  ]),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => TextButton(
                onPressed: () => ref.invalidate(onlineProductProvider(_query)),
                child: const QText('Онлайн-поиск недоступен. Повторить'))),
      ],
    ];
  }

  List<Widget> _portionWidgets() {
    final product = _selected!;
    final grams = _validatePortion(_weight.text) == null
        ? parseNutritionNumber(_weight.text, positive: true)
        : null;
    final factor = (grams ?? 0) / 100;
    return [
      Text(product.name, style: Theme.of(context).textTheme.titleMedium),
      if (product.source != null)
        QText(product.source!,
            style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      TextButton(
          onPressed: _saving
              ? null
              : () => setState(() {
                    _selected = null;
                    _error = null;
                  }),
          child: const QText('Выбрать другой продукт')),
      Form(
          key: _portionForm,
          child: TextFormField(
            controller: _weight,
            enabled: !_saving,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
                labelText: context.tr('Вес порции'),
                suffixText: context.tr('г')),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: _validatePortion,
            onChanged: (_) => setState(() {}),
          )),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final weight in [50, 100, 150, 200, 250])
          ChoiceChip(
              label: QText('$weight г'),
              selected: grams == weight,
              onSelected: _saving
                  ? null
                  : (_) => setState(() => _weight.text = '$weight'))
      ]),
      const SizedBox(height: 20),
      if (grams != null)
        QText(
            '${(product.calories * factor).toStringAsFixed(0)} ккал\n'
            'Б ${(product.proteins * factor).toStringAsFixed(1)} · Ж ${(product.fats * factor).toStringAsFixed(1)} · У ${(product.carbs * factor).toStringAsFixed(1)} г',
            style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 18,
                height: 1.6)),
      if (_error != null) QText(_error!),
      const SizedBox(height: 20),
      FilledButton(
          onPressed: _saving ? null : _add,
          child: QText(_saving ? 'Добавление…' : 'Добавить в дневник')),
    ];
  }
}
