import 'package:smart_fitness_dashboard/core/theme/app_spacing.dart';
import 'package:smart_fitness_dashboard/shared/widgets/quant_dialog.dart';
import '../../../../features/water/application/water_presets_provider.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../settings/application/theme_settings_provider.dart';
import '../../../settings/application/reminder_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/backup/backup_service.dart';
import '../../../../core/database/database_provider.dart';
import '../../../goals/application/user_goals_provider.dart';

class BackupCard extends ConsumerStatefulWidget {
  const BackupCard({super.key});
  @override
  ConsumerState<BackupCard> createState() => _BackupCardState();
}

class _BackupCardState extends ConsumerState<BackupCard> {
  bool _busy = false;
  Future<void> _run(bool importing) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final service = BackupService(
          await ref.read(databaseServiceProvider.future),
          ref.read(userGoalsRepositoryProvider),
          ref.read(appPreferencesRepositoryProvider));
      String? message;
      if (importing) {
        final document = await service.chooseImport();
        if (document == null || !mounted) return;
        final confirmed = await showDialog<bool>(
            context: context,
            builder: (c) => QuantDialog(
                    title: const QText('Восстановить копию?'),
                    content: QText(
                        'Текущие продукты, дневник, вода, замеры, цели и настройки будут заменены.\n'
                        'В копии: ${document.products.length} продуктов, ${document.entries.length} '
                        'записей питания, ${document.measurements.length} замеров, ${document.water.length} порций воды.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: const QText('Отмена')),
                      FilledButton(
                          onPressed: () => Navigator.pop(c, true),
                          child: const QText('Восстановить'))
                    ]));
        if (confirmed != true) return;
        await service.restore(document);
        ref.invalidate(userGoalsProvider);
        ref.invalidate(themeSettingsProvider);
        ref.invalidate(localeProvider);
        ref.invalidate(reminderSettingsProvider);
        ref.invalidate(waterPresetsProvider);
        message = 'Данные восстановлены';
      } else if (await service.export()) {
        message = 'Резервная копия сохранена';
      }
      if (mounted && message != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: QText(message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: QText(
                'Не удалось выполнить операцию. Проверьте файл, свободное место и доступ к документу.')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
      child: Padding(
          padding: const EdgeInsets.all(AppSpacing.cardInset),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            QText('Резервная копия данных',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const QText(
                'Продукты, дневник, вода, замеры, цели и настройки. JSON не зашифрован: храните файл в надежном месте. '
                'В системном выборе укажите папку на устройстве. Данные Health Connect не включены.'),
            const SizedBox(height: AppSpacing.actionGap),
            if (_busy) const LinearProgressIndicator(),
            Wrap(spacing: 10, runSpacing: 10, children: [
              OutlinedButton.icon(
                  onPressed: _busy ? null : () => _run(false),
                  icon: const Icon(Icons.save_alt),
                  label: const QText('Экспорт в JSON')),
              OutlinedButton.icon(
                  onPressed: _busy ? null : () => _run(true),
                  icon: const Icon(Icons.restore),
                  label: const QText('Импорт из JSON')),
            ]),
          ])));
}
