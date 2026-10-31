import '../../../core/home_widgets/home_widgets.dart';
import '../../reports/report_screen.dart';
import 'widgets/appearance_card.dart';
import '../../../core/security/app_lock.dart';
import 'widgets/language_card.dart';
import 'widgets/data_management_card.dart';
import '../../../core/localization/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/quant_logo.dart';
import '../../goals/presentation/user_goals_card.dart';
import '../../measurements/presentation/widgets/backup_card.dart';
import '../application/reminder_settings_provider.dart';
import '../domain/reminder_settings.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _busy = false;
  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: QText(
                'Не удалось сохранить. Проверьте значения и разрешения Android.')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _reminders(ReminderSettings value) =>
      _run(() => ref.read(reminderSettingsProvider.notifier).save(value));
  String _time(int minute) =>
      '${(minute ~/ 60).toString().padLeft(2, '0')}:${(minute % 60).toString().padLeft(2, '0')}';
  Future<void> _pick(int minute, void Function(int) changed) async {
    final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: minute ~/ 60, minute: minute % 60));
    if (time != null && mounted) changed(time.hour * 60 + time.minute);
  }

  Widget _card(String title, List<Widget> children) => Card(
      child: Padding(
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            QText(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ...children
          ])));
  @override
  Widget build(BuildContext context) {
    final reminders = ref.watch(reminderSettingsProvider);
    final status = ref.watch(notificationStatusProvider);
    return Scaffold(
        appBar: AppBar(title: const QText('Настройки')),
        body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
            children: [
              const LanguageCard(),
              const SizedBox(height: 16),
              const AppearanceCard(),
              const SizedBox(height: 16),
              const AppLockCard(),
              const SizedBox(height: 16),
              const WidgetPrivacyCard(),
              const SizedBox(height: 16),
              const UserGoalsCard(),
              const SizedBox(height: 16),
              Card(
                  child: ListTile(
                      leading: const Icon(Icons.image_outlined),
                      title: const QText('Экспорт отчёта'),
                      subtitle: const QText('Изображение за 7 или 30 дней'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ReportScreen())))),
              const SizedBox(height: 16),
              reminders.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => _retry('Не удалось загрузить напоминания',
                      () => ref.invalidate(reminderSettingsProvider)),
                  data: (s) => _card('Уведомления и напоминания', [
                        if (_busy) const LinearProgressIndicator(),
                        if (status != null)
                          Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: QText(status)),
                        SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const QText('Пить воду'),
                            value: s.water,
                            onChanged: _busy
                                ? null
                                : (v) => _reminders(s.copyWith(water: v))),
                        Wrap(spacing: 8, children: [
                          for (final interval in [90, 120, 180])
                            ChoiceChip(
                                label: QText(interval == 90
                                    ? '1,5 часа'
                                    : '${interval ~/ 60} часа'),
                                selected: s.waterInterval == interval,
                                onSelected: _busy
                                    ? null
                                    : (_) => _reminders(
                                        s.copyWith(waterInterval: interval)))
                        ]),
                        Wrap(spacing: 8, children: [
                          TextButton(
                              onPressed: _busy
                                  ? null
                                  : () => _pick(
                                      s.waterStart,
                                      (v) => _reminders(
                                          s.copyWith(waterStart: v))),
                              child: QText('С ${_time(s.waterStart)}')),
                          TextButton(
                              onPressed: _busy
                                  ? null
                                  : () => _pick(
                                      s.waterEnd,
                                      (v) =>
                                          _reminders(s.copyWith(waterEnd: v))),
                              child: QText('До ${_time(s.waterEnd)}')),
                        ]),
                        const Divider(),
                        _meal('Завтрак', s.breakfast,
                            (v) => _reminders(s.copyWith(breakfast: v))),
                        const Divider(height: 1, thickness: 1),
                        _meal('Обед', s.lunch,
                            (v) => _reminders(s.copyWith(lunch: v))),
                        const Divider(height: 1, thickness: 1),
                        _meal('Ужин', s.dinner,
                            (v) => _reminders(s.copyWith(dinner: v))),
                        const Divider(),
                        _meal('Взвешивание и замеры', s.measurements,
                            (v) => _reminders(s.copyWith(measurements: v))),
                        const SizedBox(height: 16),
                        const QText('Периодичность замеров'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                            isExpanded: true,
                            key: ValueKey(s.weekday),
                            initialValue: s.weekday,
                            decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 14),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(32))),
                            items: [
                              for (var i = 0; i < 8; i++)
                                DropdownMenuItem(
                                    value: i,
                                    child: QText([
                                      'Ежедневно',
                                      'Понедельник',
                                      'Вторник',
                                      'Среда',
                                      'Четверг',
                                      'Пятница',
                                      'Суббота',
                                      'Воскресенье'
                                    ][i]))
                            ],
                            onChanged: _busy
                                ? null
                                : (v) {
                                    if (v != null) {
                                      _reminders(s.copyWith(weekday: v));
                                    }
                                  }),
                        const SizedBox(height: 12),
                        const QText(
                            'Напоминания локальные. Android может задерживать их для экономии батареи. Точный режим требует отдельного разрешения.'),
                        const SizedBox(height: 8),
                        SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton.icon(
                                onPressed: _busy
                                    ? null
                                    : () => _run(() async {
                                          await ref
                                              .read(notificationServiceProvider)
                                              .requestExact();
                                          await ref
                                              .read(reminderSettingsProvider
                                                  .notifier)
                                              .refreshSchedule();
                                        }),
                                icon: const Icon(Icons.alarm),
                                label: const QText(
                                    'Разрешить точные напоминания',
                                    maxLines: 1,
                                    softWrap: false,
                                    overflow: TextOverflow.ellipsis))),
                        const SizedBox(height: 12),
                        SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: FilledButton.tonalIcon(
                                onPressed: _busy
                                    ? null
                                    : () => _run(() async {
                                          final sent = await ref
                                              .read(notificationServiceProvider)
                                              .testNotification();
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(SnackBar(
                                                    content: QText(sent
                                                        ? 'Тестовое уведомление отправлено'
                                                        : 'Разрешите уведомления в настройках Android')));
                                          }
                                        }),
                                icon: const Icon(Icons.notifications_outlined),
                                label: const QText('Проверить уведомление',
                                    maxLines: 1,
                                    softWrap: false,
                                    overflow: TextOverflow.ellipsis))),
                      ])),
              const SizedBox(height: 16),
              const BackupCard(),
              const SizedBox(height: 16),
              _card('О приложении', [
                const Row(children: [
                  QuantLogo(size: 56),
                  SizedBox(width: 16),
                  QText('quant',
                      style:
                          TextStyle(fontSize: 28, fontWeight: FontWeight.w700))
                ]),
                const SizedBox(height: 12),
                const QText('Версия 1.4.5 · питание, движение и прогресс'),
                const SizedBox(height: 8),
                const QText(
                    'Дневник хранится на устройстве. Health Connect доступен только для чтения. Поиск и штрихкоды отправляются в Open Food Facts; дневник и медицинские данные туда не передаются.'),
                const SizedBox(height: 8),
                const QText(
                    'Продукты: USDA FoodData Central (Public Domain) и Open Food Facts (ODbL). КБЖУ справочные, для готовых блюд зависят от рецепта.'),
              ]),
              const SizedBox(height: 16),
              const DataManagementCard(),
            ]));
  }

  Widget _retry(String message, VoidCallback retry) => Column(children: [
        QText(message),
        TextButton(onPressed: retry, child: const QText('Повторить'))
      ]);
  Widget _meal(String title, MealReminder meal,
          void Function(MealReminder) changed) =>
      Row(children: [
        Expanded(
            child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: QText(title),
                value: meal.enabled,
                onChanged:
                    _busy ? null : (v) => changed(meal.copyWith(enabled: v)))),
        ActionChip(
            label: Text(_time(meal.minute)),
            onPressed: _busy
                ? null
                : () => _pick(
                    meal.minute, (v) => changed(meal.copyWith(minute: v)))),
      ]);
}
