import 'hydration_editor.dart';
import 'package:smart_fitness_dashboard/core/theme/app_spacing.dart';
import 'package:smart_fitness_dashboard/shared/widgets/labeled_field.dart';
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
import 'saved_food_widgets.dart';
import '../../data/recipe.dart';

Future<bool?> showAddFoodSheet(
  BuildContext context, {
  required DateTime date,
  String mealType = 'Завтрак',
  FoodProduct? product,
}) =>
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      sheetAnimationStyle: const AnimationStyle(
          duration: Duration(milliseconds: 420),
          reverseDuration: Duration(milliseconds: 300)),
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) =>
          AddFoodSheet(date: date, initialMeal: mealType, product: product),
    );

class AddFoodSheet extends ConsumerStatefulWidget {
  const AddFoodSheet(
      {required this.date, required this.initialMeal, this.product, super.key});
  final FoodProduct? product;
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
  bool _byServings = false;
  String? _error;
  double? _waterPercentage;
  List<FoodProduct> _retainedLocal = [];
  List<FoodProduct> _retainedOnline = [];

  @override
  void initState() {
    super.initState();
    _meal = widget.initialMeal;
    _selected = widget.product;
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
      if (mounted) {
        setState(() {
          _selected = saved;
          _waterPercentage = null;
        });
      }
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
    final grams = _grams!;
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
          weightGrams: grams,
          waterPercentage: _waterPercentage ?? product.waterPercentage);
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
    final amount = parseNutritionNumber(text!, positive: true)!;
    final grams = _byServings ? amount * _servingGrams! : amount;
    if (grams > InputLimits.portionGrams) {
      return context.tr('Слишком большой вес порции');
    }
    final factor = grams / 100;
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
                          const SizedBox(height: AppSpacing.section),
                          LabeledField(
                              label: context.tr('Прием пищи'),
                              child: DropdownButtonFormField<String>(
                                initialValue: _meal,
                                isExpanded: true,
                                decoration: const InputDecoration(),
                                items: IsarDatabaseService.mealTypes
                                    .map((meal) => DropdownMenuItem(
                                        value: meal, child: QText(meal)))
                                    .toList(),
                                onChanged: _saving
                                    ? null
                                    : (meal) => setState(() => _meal = meal!),
                              )),
                          const SizedBox(height: AppSpacing.section),
                          if (_selected == null)
                            ..._searchWidgets()
                          else
                            ..._portionWidgets(),
                        ]),
            ),
          ),
        ),
      );

  void _selectLocal(FoodProduct product) {
    FocusScope.of(context).unfocus();
    setState(() {
      _selected = product;
      _waterPercentage = null;
      _byServings = false;
      _weight.text = '100';
    });
  }

  List<Widget> _searchWidgets() {
    final products = ref.watch(productSearchProvider(_query));
    final online = _query.length >= 2
        ? ref.watch(onlineProductProvider(_query))
        : const AsyncData(<FoodProduct>[]);
    // Keep still-relevant rows during refresh/debounce. New network responses
    // only append to the local-first list; no full-list loading replacement.
    if (products.hasValue) _retainedLocal = products.requireValue;
    if (online.hasValue) _retainedOnline = online.requireValue;
    final normalized = _query.toLowerCase();
    bool matches(FoodProduct p) =>
        normalized.isEmpty ||
        normalized
            .split(RegExp(r'\s+'))
            .every((word) => p.name.toLowerCase().contains(word));
    final local = (products.valueOrNull ?? _retainedLocal)
        .where(matches)
        .toList()
      ..sort((a, b) {
        final exactA = a.name.toLowerCase() == normalized;
        final exactB = b.name.toLowerCase() == normalized;
        return exactA == exactB ? a.name.compareTo(b.name) : (exactA ? -1 : 1);
      });
    final remote =
        online.valueOrNull ?? _retainedOnline.where(matches).toList();
    String identity(FoodProduct p) => p.barcode != null
        ? 'barcode:${p.barcode!}'
        : p.stableKey ?? ('name:${p.name.toLowerCase()}');
    final seen = <String>{};
    final items = <({FoodProduct product, bool remote})>[
      for (final p in local)
        if (seen.add(identity(p))) (product: p, remote: false),
      for (final p in remote)
        if (seen.add(identity(p))) (product: p, remote: true),
    ];
    return [
      LabeledField(
          label: context.tr('Найти продукт'),
          child: TextField(
              key: const ValueKey('food-search-input'),
              controller: _search,
              onChanged: _searchChanged,
              maxLength: 120,
              decoration: InputDecoration(
                  counterText: '',
                  hintText: context.tr('Начните вводить название'),
                  prefixIcon: const Icon(Icons.search)))),
      const SizedBox(height: 8),
      SizedBox(
          height: 4,
          child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _lookingUp || online.isLoading
                  ? const LinearProgressIndicator(
                      key: ValueKey('search-loading'))
                  : const SizedBox.shrink())),
      const SizedBox(height: AppSpacing.actionGap),
      if (_error != null) QText(_error!),
      Wrap(spacing: 10, runSpacing: 10, children: [
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
      if (_query.isEmpty) SavedFoods(onSelected: _selectLocal),
      if (_query.length >= 2)
        Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.small),
            child: QText(
                'Название запроса отправляется в Open Food Facts. Проверьте КБЖУ по этикетке. Поиск ограничен 10 запросами в минуту.',
                style: Theme.of(context).textTheme.bodySmall)),
      for (final (index, row) in items.indexed) ...[
        if (index > 0) const Divider(height: 1, thickness: 1),
        ListTile(
            key: ValueKey('food-result-${identity(row.product)}'),
            contentPadding: EdgeInsets.zero,
            title: Text(row.product.name),
            subtitle: QText(row.product.recipeJson != null &&
                    !Recipe.decode(row.product.recipeJson!).complete
                ? 'Расчёт неполный: у ингредиента нет КБЖУ. Добавление в дневник недоступно.'
                : '${row.product.calories.round()} ккал / 100 г${row.remote ? ' · Open Food Facts · сохранить офлайн' : ' · ${row.product.category}'}'),
            trailing: FavoriteButton(product: row.product),
            onTap: _lookingUp
                ? null
                : () {
                    if (row.remote) {
                      _chooseOnline(row.product);
                    } else {
                      _selectLocal(row.product);
                    }
                  }),
      ],
      if (items.isEmpty &&
          !products.isLoading &&
          !online.isLoading &&
          !products.hasError)
        const Padding(
            padding: EdgeInsets.all(AppSpacing.cardInset),
            child: QText('Продукты не найдены. Создайте свой продукт.')),
      if (products.hasError)
        TextButton(
            onPressed: () => ref.invalidate(productSearchProvider(_query)),
            child: const QText('Не удалось загрузить справочник.')),
      if (online.hasError && online.error is! SearchCancelled)
        TextButton(
            onPressed: () => ref.invalidate(onlineProductProvider(_query)),
            child: QText(online.error is FoodSearchRateLimit
                ? 'Лимит Open Food Facts. Повторите позже.'
                : 'Онлайн-поиск недоступен. Повторить')),
    ];
  }

  List<Widget> _portionWidgets() {
    final product = _selected!;
    final recipe =
        product.recipeJson == null ? null : Recipe.decode(product.recipeJson!);
    final grams = _validatePortion(_weight.text) == null ? _grams : null;
    final factor = (grams ?? 0) / 100;
    return [
      Row(children: [
        Expanded(
            child: Text(product.name,
                style: Theme.of(context).textTheme.titleMedium)),
        FavoriteButton(product: product)
      ]),
      if (recipe != null && !recipe.complete)
        const QText(
            'Расчёт неполный: у ингредиента нет КБЖУ. Добавление в дневник недоступно.'),
      if (recipe?.servings != null)
        Wrap(
            spacing: AppSpacing.small,
            runSpacing: AppSpacing.small,
            children: [
              ChoiceChip(
                  label: const QText('Граммы'),
                  selected: !_byServings,
                  onSelected: (_) => setState(() {
                        _byServings = false;
                        _weight.text = '100';
                      })),
              ChoiceChip(
                  label: const QText('Порции'),
                  selected: _byServings,
                  onSelected: (_) => setState(() {
                        _byServings = true;
                        _weight.text = '1';
                      })),
            ]),
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
                    _waterPercentage = null;
                    _byServings = false;
                    _weight.text = '100';
                    _error = null;
                  }),
          child: const QText('Выбрать другой продукт')),
      const SizedBox(height: AppSpacing.section),
      Form(
          key: _portionForm,
          child: LabeledField(
              label:
                  context.tr(_byServings ? 'Количество порций' : 'Вес порции'),
              child: TextFormField(
                controller: _weight,
                enabled: !_saving,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                    suffixText: context.tr(_byServings ? 'порций' : 'г')),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: _validatePortion,
                onChanged: (_) => setState(() {}),
              ))),
      const SizedBox(height: AppSpacing.actionGap),
      if (!_byServings)
        Wrap(spacing: 10, runSpacing: 10, children: [
          for (final weight in [50, 100, 150, 200, 250])
            ChoiceChip(
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                label: QText('$weight г'),
                selected: grams == weight,
                onSelected: _saving
                    ? null
                    : (_) => setState(() => _weight.text = '$weight'))
        ]),
      const SizedBox(height: AppSpacing.section),
      HydrationEditor(
          percentage: _waterPercentage ?? product.waterPercentage,
          grams: grams ?? 0,
          enabled: !_saving,
          onChanged: (v) => setState(() => _waterPercentage = v)),
      const SizedBox(height: AppSpacing.section),
      if (grams != null && recipe?.complete != false)
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
          onPressed: _saving || recipe?.complete == false ? null : _add,
          child: QText(_saving ? 'Добавление…' : 'Добавить в дневник')),
    ];
  }

  double? get _servingGrams {
    final raw = _selected?.recipeJson;
    if (raw == null) return null;
    final r = Recipe.decode(raw);
    return r.servings == null ? null : r.yieldGrams / r.servings!;
  }

  double? get _grams {
    final value = parseNutritionNumber(_weight.text, positive: true);
    return value == null ? null : value * (_byServings ? _servingGrams! : 1);
  }
}
