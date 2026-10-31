import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/database/data_reset_service.dart';
import '../../../../core/database/data_reset_provider.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/backup/backup_service.dart';
import '../../../goals/application/user_goals_provider.dart';
import '../../application/theme_settings_provider.dart';

class DataManagementCard extends ConsumerStatefulWidget {
  const DataManagementCard({super.key});
  @override
  ConsumerState<DataManagementCard> createState() => _DataManagementCardState();
}

class _DataManagementCardState extends ConsumerState<DataManagementCard> {
  bool _busy = false;
  static const labels = [
    'История дневника питания и воды',
    'Пользовательские и кэшированные продукты',
    'История замеров тела',
    'Цели, тема и расписание уведомлений'
  ];
  Future<void> _export(BuildContext dialogContext) async {
    try {
      final service = BackupService(
          await ref.read(databaseServiceProvider.future),
          ref.read(userGoalsRepositoryProvider),
          ref.read(appPreferencesRepositoryProvider));
      final saved = await service.export();
      if (dialogContext.mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(
            content: QText(saved ? 'Резервная копия сохранена' : 'Отмена')));
      }
    } catch (_) {
      if (dialogContext.mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(
            content: QText(
                'Не удалось выполнить операцию. Проверьте файл, свободное место и доступ к документу.')));
      }
    }
  }

  Future<void> _reset(bool factory) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final service = await ref.read(dataResetServiceProvider.future);
      final counts = await service.counts();
      if (!mounted) return;
      Set<ResetCategory>? selected;
      if (factory) {
        final confirmed = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (c) => _FactoryDialog(export: () => _export(c)));
        if (confirmed != true) return;
        selected = ResetCategory.values.toSet();
      } else {
        selected = await showDialog<Set<ResetCategory>>(
            context: context, builder: (c) => _SelectiveDialog(counts: counts));
        if (selected == null || selected.isEmpty) return;
        if (!mounted) return;
        final confirmed = await showDialog<bool>(
            context: context,
            builder: (c) => AlertDialog(
                    title: const QText('Очистить выбранные данные?'),
                    content: const QText(
                        'Это действие нельзя отменить. Остальные категории сохранятся.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: const QText('Отмена')),
                      FilledButton(
                          onPressed: () => Navigator.pop(c, true),
                          child: const QText('Очистить выбранное'))
                    ]));
        if (confirmed != true) return;
      }
      await service.clear(selected, factory: factory);
      if (!mounted) return;
      invalidatePreferences(ref, factory: factory);
      if (!factory) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: QText('Данные очищены')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: QText('Не удалось выполнить сброс. Повторите попытку.')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
      child: Padding(
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            QText('Управление данными и сброс',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: Theme.of(context).colorScheme.error)),
            const SizedBox(height: 12),
            const QText(
                'Очистка необратима. Перед удалением сохраните JSON-копию.'),
            const SizedBox(height: 12),
            if (_busy) const LinearProgressIndicator(),
            OutlinedButton(
                onPressed: _busy ? null : () => _reset(false),
                child: const QText('Выборочная очистка данных')),
            TextButton.icon(
                style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error),
                onPressed: _busy ? null : () => _reset(true),
                icon: const Icon(Icons.delete_forever_outlined),
                label: const QText('Полный сброс приложения')),
          ])));
}

class _SelectiveDialog extends StatefulWidget {
  const _SelectiveDialog({required this.counts});
  final Map<ResetCategory, int> counts;
  @override
  State<_SelectiveDialog> createState() => _SelectiveDialogState();
}

class _SelectiveDialogState extends State<_SelectiveDialog> {
  final selected = <ResetCategory>{};
  @override
  Widget build(BuildContext context) => AlertDialog(
          title: const QText('Выборочная очистка данных'),
          content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                for (final c in ResetCategory.values)
                  CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: QText(_DataManagementCardState.labels[c.index]),
                      subtitle: QText('Записей: ${widget.counts[c] ?? 0}'),
                      value: selected.contains(c),
                      onChanged: (v) => setState(() =>
                          v == true ? selected.add(c) : selected.remove(c)))
              ]))),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const QText('Отмена')),
            FilledButton(
                onPressed: selected.isEmpty
                    ? null
                    : () => Navigator.pop(context, selected),
                child: const QText('Очистить выбранное'))
          ]);
}

class _FactoryDialog extends StatefulWidget {
  const _FactoryDialog({required this.export});
  final Future<void> Function() export;
  @override
  State<_FactoryDialog> createState() => _FactoryDialogState();
}

class _FactoryDialogState extends State<_FactoryDialog> {
  bool exporting = false;
  @override
  Widget build(BuildContext context) => AlertDialog(
          title: const QText('Сбросить все данные?'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const QText(
                'Будут удалены дневник, вода, продукты, замеры и настройки. Приложение вернется к первому шагу ознакомления.'),
            const SizedBox(height: 16),
            OutlinedButton.icon(
                onPressed: exporting
                    ? null
                    : () async {
                        setState(() => exporting = true);
                        try {
                          await widget.export();
                        } finally {
                          if (mounted) setState(() => exporting = false);
                        }
                      },
                icon: const Icon(Icons.save_alt),
                label: const QText('Сначала экспортировать JSON'))
          ]),
          actions: [
            TextButton(
                onPressed:
                    exporting ? null : () => Navigator.pop(context, false),
                child: const QText('Отмена')),
            FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError),
                onPressed:
                    exporting ? null : () => Navigator.pop(context, true),
                child: const QText('Сбросить приложение'))
          ]);
}
