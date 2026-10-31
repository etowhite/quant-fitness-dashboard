import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/localization/app_strings.dart';
import '../../application/saved_products_provider.dart';
import '../../data/food_product.dart';

class FavoriteButton extends ConsumerStatefulWidget {
  const FavoriteButton({required this.product, super.key});
  final FoodProduct product;
  @override
  ConsumerState<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends ConsumerState<FavoriteButton> {
  bool busy = false;
  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(favoriteProductsProvider).valueOrNull;
    final p = widget.product;
    final selected = favorites?.any((f) =>
            f.stableKey == p.stableKey && p.stableKey != null ||
            f.barcode != null && f.barcode == p.barcode) ??
        p.isFavorite;
    return IconButton(
        tooltip: context.tr(selected ? 'Убрать из избранного' : 'В избранное'),
        onPressed: busy
            ? null
            : () async {
                setState(() => busy = true);
                try {
                  final db = await ref.read(databaseServiceProvider.future);
                  final saved = await db.setFavorite(p, !selected);
                  p.id = saved.id;
                  p.stableKey = saved.stableKey;
                  p.isFavorite = saved.isFavorite;
                  ref.invalidate(frequentProductsProvider);
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: QText('Не удалось сохранить')));
                  }
                } finally {
                  if (mounted) setState(() => busy = false);
                }
              },
        icon: Icon(selected ? Icons.star_rounded : Icons.star_outline_rounded));
  }
}

class SavedFoods extends ConsumerStatefulWidget {
  const SavedFoods({required this.onSelected, super.key});
  final ValueChanged<FoodProduct> onSelected;
  @override
  ConsumerState<SavedFoods> createState() => _SavedFoodsState();
}

class _SavedFoodsState extends ConsumerState<SavedFoods> {
  int tab = 0;
  @override
  Widget build(BuildContext context) {
    final data = ref.watch(tab == 0
        ? frequentProductsProvider
        : tab == 1
            ? favoriteProductsProvider
            : recipesProvider);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final (i, label)
            in ['Часто используемые', 'Избранные', 'Мои рецепты'].indexed)
          ChoiceChip(
              label: QText(label),
              selected: tab == i,
              onSelected: (_) => setState(() => tab = i))
      ]),
      const SizedBox(height: 8),
      data.when(
          data: (items) => items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: QText(tab == 0
                      ? 'Добавляйте еду в дневник — здесь появятся часто используемые продукты.'
                      : tab == 1
                          ? 'Нажмите звезду рядом с продуктом, чтобы сохранить его здесь.'
                          : 'Создайте рецепт во вкладке «Питание».'))
              : Column(children: [
                  for (final p in items.take(15)) ...[
                    ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(p.name),
                        trailing: FavoriteButton(product: p),
                        onTap: () => widget.onSelected(p)),
                    const Divider(height: 1)
                  ]
                ]),
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => TextButton(
              onPressed: () => ref.invalidate(tab == 0
                  ? frequentProductsProvider
                  : tab == 1
                      ? favoriteProductsProvider
                      : recipesProvider),
              child: const QText('Повторить'))),
      const Divider(height: 24),
    ]);
  }
}
