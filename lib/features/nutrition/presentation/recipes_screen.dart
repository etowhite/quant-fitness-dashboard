import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/localization/app_strings.dart';
import '../../../shared/widgets/labeled_field.dart';
import '../application/product_search_provider.dart';
import '../application/saved_products_provider.dart';
import '../data/food_product.dart';
import '../data/recipe.dart';
import 'nutrition_input.dart';
import 'widgets/add_food_sheet.dart';
import 'widgets/saved_food_widgets.dart';

class RecipesScreen extends ConsumerWidget {
  const RecipesScreen({required this.date, super.key});
  final DateTime date;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
      appBar: AppBar(title: const QText('Мои рецепты')),
      floatingActionButton: FloatingActionButton.extended(
          icon: const Icon(Icons.add),
          label: const QText('Создать рецепт'),
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const RecipeEditor()))),
      body: ref.watch(recipesProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(
              child: TextButton(
                  onPressed: () => ref.invalidate(recipesProvider),
                  child: const QText('Повторить'))),
          data: (items) => items.isEmpty
              ? const Center(
                  child: Padding(
                      padding: EdgeInsets.all(24),
                      child: QText(
                          'Создайте рецепт из ингредиентов и укажите итоговый вес блюда.')))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                  children: [
                      for (final p in items)
                        Card(
                            child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Row(children: [
                                        Expanded(
                                            child: Text(p.name,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleLarge)),
                                        FavoriteButton(product: p)
                                      ]),
                                      RecipePreview(
                                          recipe: Recipe.decode(p.recipeJson!)),
                                      Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            OutlinedButton.icon(
                                                icon: const Icon(
                                                    Icons.edit_outlined),
                                                label: const QText('Изменить'),
                                                onPressed: () => Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (_) =>
                                                            RecipeEditor(
                                                                product: p)))),
                                            OutlinedButton.icon(
                                                icon: const Icon(Icons.add),
                                                label: const QText(
                                                    'Добавить в дневник'),
                                                onPressed: !Recipe.decode(
                                                            p.recipeJson!)
                                                        .complete
                                                    ? null
                                                    : () => showAddFoodSheet(
                                                        context,
                                                        date: date,
                                                        product: p)),
                                            IconButton(
                                                tooltip: context.tr('Удалить'),
                                                icon: const Icon(
                                                    Icons.delete_outline),
                                                onPressed: () async {
                                                  final yes = await showDialog<
                                                          bool>(
                                                      context: context,
                                                      builder: (c) =>
                                                          AlertDialog(
                                                              title: const QText(
                                                                  'Удалить рецепт?'),
                                                              content: const QText(
                                                                  'Записи дневника останутся без изменений.'),
                                                              actions: [
                                                                TextButton(
                                                                    onPressed: () =>
                                                                        Navigator.pop(
                                                                            c,
                                                                            false),
                                                                    child: const QText(
                                                                        'Отмена')),
                                                                FilledButton(
                                                                    onPressed: () =>
                                                                        Navigator.pop(
                                                                            c,
                                                                            true),
                                                                    child: const QText(
                                                                        'Удалить'))
                                                              ]));
                                                  if (yes == true) {
                                                    try {
                                                      await (await ref.read(
                                                              databaseServiceProvider
                                                                  .future))
                                                          .deleteRecipe(p);
                                                      ref.invalidate(
                                                          frequentProductsProvider);
                                                    } catch (_) {
                                                      if (context.mounted) {
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                                const SnackBar(
                                                                    content: QText(
                                                                        'Не удалось сохранить')));
                                                      }
                                                    }
                                                  }
                                                })
                                          ])
                                    ])))
                    ])));
}

class RecipePreview extends StatelessWidget {
  const RecipePreview({required this.recipe, super.key});
  final Recipe recipe;
  @override
  Widget build(BuildContext context) {
    String number(double v, int digits) => NumberFormat.decimalPatternDigits(
            locale: context.languageCode, decimalDigits: digits)
        .format(v);
    String numbers(List<double> v) =>
        '${number(v[0], 0)} ${context.tr('ккал')} · ${context.tr('Б/Ж/У')} ${v.skip(1).map((v) => number(v, 1)).join(' / ')} ${context.tr('г')}';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (!recipe.complete)
        const QText(
            'Расчёт неполный: у ингредиента нет КБЖУ. Добавление в дневник недоступно.')
      else ...[
        Text('${context.tr('Всего')}: ${numbers(recipe.totals!)}'),
        Text('${context.tr('На 100 г')}: ${numbers(recipe.per100!)}'),
        if (recipe.perServing != null)
          Text('${context.tr('На порцию')}: ${numbers(recipe.perServing!)}')
      ],
      Text('${number(recipe.yieldGrams, 1)} ${context.tr('г готового блюда')}'),
    ]);
  }
}

class RecipeEditor extends ConsumerStatefulWidget {
  const RecipeEditor({this.product, super.key});
  final FoodProduct? product;
  @override
  ConsumerState<RecipeEditor> createState() => _RecipeEditorState();
}

class _RecipeEditorState extends ConsumerState<RecipeEditor> {
  final name = TextEditingController(),
      yieldWeight = TextEditingController(),
      servings = TextEditingController();
  final form = GlobalKey<FormState>();
  List<RecipeIngredient> ingredients = [];
  bool busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    final p = widget.product;
    if (p != null) {
      final r = Recipe.decode(p.recipeJson!);
      name.text = p.name;
      yieldWeight.text = '${r.yieldGrams}';
      servings.text = r.servings == null ? '' : '${r.servings}';
      ingredients = [...r.ingredients];
    }
  }

  @override
  void dispose() {
    name.dispose();
    yieldWeight.dispose();
    servings.dispose();
    super.dispose();
  }

  Recipe? get current {
    final y = parseNutritionNumber(yieldWeight.text, positive: true);
    final s = servings.text.trim().isEmpty
        ? null
        : parseNutritionNumber(servings.text, positive: true);
    if (y == null ||
        ingredients.isEmpty ||
        servings.text.isNotEmpty && s == null) {
      return null;
    }
    final r = Recipe(ingredients: ingredients, yieldGrams: y, servings: s);
    try {
      r.validate();
      return r;
    } catch (_) {
      return null;
    }
  }

  Future<double?> mass(double initial) async {
    final c = TextEditingController(text: '$initial');
    final key = GlobalKey<FormState>();
    final result = await showDialog<double>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const QText('Масса ингредиента'),
                content: Form(
                    key: key,
                    child: TextFormField(
                        controller: c,
                        autofocus: true,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (v) => validateLocalizedNumber(ctx, v,
                            positive: true, max: 100000),
                        decoration: InputDecoration(suffixText: ctx.tr('г')))),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const QText('Отмена')),
                  FilledButton(
                      onPressed: () {
                        if (key.currentState!.validate()) {
                          Navigator.pop(ctx,
                              parseNutritionNumber(c.text, positive: true));
                        }
                      },
                      child: const QText('Сохранить'))
                ]));
    // Dialog disposal follows its exit animation.
    Future<void>.delayed(const Duration(milliseconds: 400), c.dispose);
    return result;
  }

  Future<void> addIngredient() async {
    final p = await showModalBottomSheet<FoodProduct>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => const _IngredientPicker());
    if (p == null || !mounted) return;
    final g = await mass(100);
    if (g != null && mounted) {
      setState(() {
        ingredients.add(RecipeIngredient.product(p, g));
        if (yieldWeight.text.isEmpty) {
          yieldWeight.text =
              '${ingredients.fold<double>(0, (s, i) => s + i.grams)}';
        }
      });
    }
  }

  Future<void> save() async {
    if (busy || !form.currentState!.validate()) return;
    final r = current;
    if (r == null) {
      setState(() => error = 'Проверьте ингредиенты и итоговый вес.');
      return;
    }
    setState(() => busy = true);
    try {
      final old = widget.product;
      final v = r.per100;
      final p = FoodProduct()
        ..id = old?.id
        ..stableKey = old?.stableKey
        ..isFavorite = old?.isFavorite ?? false
        ..name = name.text.trim()
        ..category = 'Мои рецепты'
        ..source = 'quant recipe'
        ..recipeJson = r.encode()
        ..calories = v?[0] ?? 0
        ..proteins = v?[1] ?? 0
        ..fats = v?[2] ?? 0
        ..carbs = v?[3] ?? 0;
      await (await ref.read(databaseServiceProvider.future))
          .saveCustomProduct(p);
      ref.invalidate(frequentProductsProvider);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => error = 'Не удалось сохранить');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: !busy,
      child: Scaffold(
          appBar: AppBar(
              title: QText(widget.product == null
                  ? 'Создать рецепт'
                  : 'Изменить рецепт')),
          body: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  16, 12, 16, 24 + MediaQuery.viewInsetsOf(context).bottom),
              child: Form(
                  key: form,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LabeledField(
                            label: context.tr('Название блюда'),
                            child: TextFormField(
                                controller: name,
                                maxLength: 120,
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? context.tr('Введите название')
                                    : null)),
                        const SizedBox(height: 16),
                        Card(
                            child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(children: [
                                  for (final (index, i)
                                      in ingredients.indexed) ...[
                                    ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(i.name),
                                        subtitle: Text(
                                            '${i.grams} ${context.tr('г')}'),
                                        onTap: () async {
                                          final g = await mass(i.grams);
                                          if (g != null && mounted) {
                                            setState(() => ingredients[index] =
                                                RecipeIngredient(
                                                    name: i.name,
                                                    key: i.key,
                                                    grams: g,
                                                    calories: i.calories,
                                                    proteins: i.proteins,
                                                    fats: i.fats,
                                                    carbs: i.carbs));
                                          }
                                        },
                                        trailing: IconButton(
                                            tooltip: context.tr('Удалить'),
                                            icon: const Icon(Icons.close),
                                            onPressed: () => setState(() =>
                                                ingredients.removeAt(index)))),
                                    const Divider(height: 1)
                                  ],
                                  OutlinedButton.icon(
                                      onPressed: busy ? null : addIngredient,
                                      icon: const Icon(Icons.add),
                                      label: const QText('Добавить ингредиент'))
                                ]))),
                        const SizedBox(height: 16),
                        const QText(
                            'Укажите вес после приготовления. Сумма ингредиентов — только начальное значение.'),
                        const SizedBox(height: 8),
                        LabeledField(
                            label: context.tr('Итоговый вес готового блюда'),
                            child: TextFormField(
                                controller: yieldWeight,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                validator: (v) => validateLocalizedNumber(
                                    context, v, positive: true, max: 100000),
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                    suffixText: context.tr('г')))),
                        const SizedBox(height: 12),
                        OutlinedButton(
                            key: const ValueKey('recipe-use-ingredient-mass'),
                            style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12)),
                            onPressed: () => setState(() => yieldWeight.text =
                                '${ingredients.fold<double>(0, (s, i) => s + i.grams)}'),
                            child: const QText(
                                'Использовать сумму массы ингредиентов',
                                textAlign: TextAlign.center)),
                        const SizedBox(height: 16),
                        LabeledField(
                            label:
                                context.tr('Количество порций (необязательно)'),
                            child: TextFormField(
                                controller: servings,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? null
                                    : validateLocalizedNumber(context, v,
                                        positive: true, max: 10000),
                                onChanged: (_) => setState(() {}))),
                        const SizedBox(height: 16),
                        if (current != null)
                          Card(
                              child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: RecipePreview(recipe: current!))),
                        if (error != null) QText(error!),
                        const SizedBox(height: 16),
                        FilledButton(
                            onPressed: busy ? null : save,
                            child: QText(busy ? 'Сохранение…' : 'Сохранить')),
                      ])))));
}

class _IngredientPicker extends ConsumerStatefulWidget {
  const _IngredientPicker();
  @override
  ConsumerState<_IngredientPicker> createState() => _IngredientPickerState();
}

class _IngredientPickerState extends ConsumerState<_IngredientPicker> {
  String query = '';
  @override
  Widget build(BuildContext context) => SizedBox(
      height: MediaQuery.sizeOf(context).height * .8,
      child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            const QText('Добавить ингредиент'),
            const SizedBox(height: 12),
            TextField(
                onChanged: (v) => setState(() => query = v),
                decoration: InputDecoration(
                    hintText: context.tr('Найти продукт'),
                    prefixIcon: const Icon(Icons.search))),
            const SizedBox(height: 12),
            Expanded(
                child: ref.watch(productSearchProvider(query)).when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) =>
                        const QText('Не удалось загрузить справочник.'),
                    data: (items) => ListView(children: [
                          for (final p
                              in items.where((p) => p.recipeJson == null))
                            ListTile(
                                title: Text(p.name),
                                subtitle: Text(
                                    '${p.calories} ${context.tr('ккал')} / 100 ${context.tr('г')}'),
                                onTap: () => Navigator.pop(context, p))
                        ])))
          ])));
}
