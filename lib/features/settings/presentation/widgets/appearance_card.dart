import 'package:smart_fitness_dashboard/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../shared/widgets/expressive_motion.dart';
import '../../application/theme_settings_provider.dart';
import '../../domain/theme_settings.dart';

class AppearanceCard extends ConsumerWidget {
  const AppearanceCard({super.key});
  Future<void> _save(
      BuildContext context, WidgetRef ref, ThemeSettings value) async {
    try {
      await ref.read(themeSettingsProvider.notifier).save(value);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: QText('Не удалось сохранить настройки.')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(themeSettingsProvider);
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(AppSpacing.cardInset),
            child: settings.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => TextButton(
                  onPressed: () => ref.invalidate(themeSettingsProvider),
                  child: const QText('Повторить')),
              data: (s) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    QText('Оформление',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.section),
                    ResponsiveChoices(labels: const [
                      'Авто',
                      'Светлая',
                      'Темная'
                    ], children: [
                      for (final mode in [
                        (ThemeMode.system, 'Авто'),
                        (ThemeMode.light, 'Светлая'),
                        (ThemeMode.dark, 'Темная')
                      ])
                        CapsuleChoice(
                            label: mode.$2,
                            selected: mode.$1 == s.mode,
                            onPressed: () =>
                                _save(context, ref, s.copyWith(mode: mode.$1)))
                    ]),
                    const Divider(height: 32),
                    QText('Цветовая палитра',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.actionGap),
                    ResponsiveChoices(
                        labels: [
                          for (final p in AccentPalette.presets) p.label
                        ],
                        leadingWidth: 20,
                        children: [
                          for (final p in AccentPalette.presets)
                            CapsuleChoice(
                                label: p.label,
                                selected: s.palette == p,
                                color: p.primary,
                                onPressed: () =>
                                    _save(context, ref, s.copyWith(palette: p)))
                        ]),
                    const SizedBox(height: 8),
                    SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const QText('Чистый черный фон'),
                        subtitle: const QText('AMOLED · для темной темы'),
                        value: s.amoled,
                        onChanged: (v) =>
                            _save(context, ref, s.copyWith(amoled: v))),
                  ]),
            )));
  }
}
