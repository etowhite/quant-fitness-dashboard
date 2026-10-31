import '../../water/application/water_presets_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/backup/backup_service.dart';
import '../../../core/database/database_provider.dart';
import '../../../shared/widgets/quant_logo.dart';
import '../../goals/application/user_goals_provider.dart';
import '../../goals/domain/user_goals.dart';
import '../../settings/application/theme_settings_provider.dart';
import '../../settings/application/reminder_settings_provider.dart';
import '../../settings/domain/theme_settings.dart';
import '../../dashboard/application/daily_health_provider.dart';
import '../application/onboarding_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pages = PageController();
  int _step = 0;
  bool _busy = false;
  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: QText(context.tr('Не удалось сохранить настройки.'))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finish() =>
      ref.read(onboardingProvider.notifier).setCompleted(true);
  void _move(int page) => _pages.animateToPage(page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubicEmphasized);
  Future<void> _connect() async {
    try {
      await ref
          .read(dailyHealthProvider.notifier)
          .refresh(requestPermissions: true);
    } catch (_) {/* Access can be granted later. */}
    try {
      await ref.read(notificationServiceProvider).requestPermission();
    } catch (_) {/* Permission is optional. */}
    await _finish();
  }

  Future<void> _import() async {
    final service = BackupService(
        await ref.read(databaseServiceProvider.future),
        ref.read(userGoalsRepositoryProvider),
        ref.read(appPreferencesRepositoryProvider));
    final doc = await service.chooseImport();
    if (doc == null || !mounted) return;
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
                title: const QText('Восстановить копию?'),
                content: const QText(
                    'Текущие данные будут заменены резервной копией.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const QText('Отмена')),
                  FilledButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: const QText('Восстановить'))
                ]));
    if (confirmed != true) return;
    await service.restore(doc);
    ref.invalidate(userGoalsProvider);
    ref.invalidate(themeSettingsProvider);
    ref.invalidate(localeProvider);
    ref.invalidate(reminderSettingsProvider);
    ref.invalidate(waterPresetsProvider);
    await _finish();
  }

  Widget _panel(List<Widget> children) => Card(
      child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children)));
  Widget _page(String title, String subtitle, List<Widget> children) =>
      SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            QText('Шаг ${_step + 1} из 3',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 12),
            QText(title,
                style: Theme.of(context)
                    .textTheme
                    .headlineLarge
                    ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -1)),
            const SizedBox(height: 12),
            QText(subtitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 24),
            ...children
          ]));
  @override
  Widget build(BuildContext context) {
    final theme =
        ref.watch(themeSettingsProvider).valueOrNull ?? const ThemeSettings();
    final language =
        ref.watch(localeProvider).valueOrNull ?? AppLanguage.system;
    final goals = ref.watch(effectiveUserGoalsProvider);
    return Scaffold(
        body: SafeArea(
            child: Column(children: [
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            if (_step > 0)
              IconButton(
                  onPressed: _busy ? null : () => _move(_step - 1),
                  icon: const Icon(Icons.arrow_back),
                  tooltip: context.tr('Назад')),
            TextButton(
                onPressed: _busy ? null : () => _run(_finish),
                child: const QText('Пропустить')),
            const Spacer(),
            for (var i = 0; i < 3; i++)
              AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(left: 6),
                  height: 8,
                  width: i == _step ? 32 : 8,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: i == _step
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant)),
          ])),
      if (_step == 0)
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: OutlinedButton.icon(
                onPressed: _busy ? null : () => _run(_import),
                style: OutlinedButton.styleFrom(
                    shape: const StadiumBorder(),
                    minimumSize: const Size.fromHeight(52)),
                icon: const Icon(Icons.file_open_outlined),
                label: const QText('Импорт резервной копии JSON'))),
      if (_busy) const LinearProgressIndicator(),
      Expanded(
          child: PageView(
              controller: _pages,
              onPageChanged: (v) => setState(() => _step = v),
              physics: _busy ? const NeverScrollableScrollPhysics() : null,
              children: [
            _page('Знакомство с quant',
                'Питание, движение и прогресс — в твоем ритме.', [
              const Center(child: QuantLogo(size: 100)),
              const SizedBox(height: 20),
              _panel([
                for (final feature in [
                  (Icons.watch_outlined, 'Синхронизация часов и весов'),
                  (Icons.qr_code_scanner, 'Умный дневник КБЖУ и штрихкоды'),
                  (Icons.water_drop_outlined, 'Водный баланс и замеры')
                ])
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(children: [
                        Icon(feature.$1,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(child: QText(feature.$2))
                      ]))
              ]),
              const SizedBox(height: 16),
              SegmentedButton<AppLanguage>(
                  segments: const [
                    ButtonSegment(value: AppLanguage.ru, label: QText('RU')),
                    ButtonSegment(value: AppLanguage.en, label: QText('EN')),
                    ButtonSegment(
                        value: AppLanguage.system, label: QText('Авто'))
                  ],
                  selected: {
                    language
                  },
                  onSelectionChanged: _busy
                      ? null
                      : (v) => _run(() =>
                          ref.read(localeProvider.notifier).save(v.first))),
              const SizedBox(height: 16),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final p in AccentPalette.values)
                  ChoiceChip(
                      avatar:
                          CircleAvatar(backgroundColor: p.primary, radius: 8),
                      label: QText(p.label),
                      selected: p == theme.palette,
                      onSelected: _busy
                          ? null
                          : (_) => _run(() => ref
                              .read(themeSettingsProvider.notifier)
                              .save(theme.copyWith(palette: p))))
              ]),
              const SizedBox(height: 12),
              SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                        value: ThemeMode.light, label: QText('Светлая')),
                    ButtonSegment(
                        value: ThemeMode.dark, label: QText('Темная')),
                    ButtonSegment(value: ThemeMode.system, label: QText('Авто'))
                  ],
                  selected: {
                    theme.mode
                  },
                  onSelectionChanged: _busy
                      ? null
                      : (v) => _run(() => ref
                          .read(themeSettingsProvider.notifier)
                          .save(theme.copyWith(mode: v.first)))),
            ]),
            _page('Твои дневные ориентиры',
                'Небольшие шаги складываются в большой прогресс.', [
              Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final preset in [
                      ('Сушка', 1800.0),
                      ('Баланс', 2200.0),
                      ('Набор', 2600.0)
                    ])
                      ActionChip(
                          shape: const StadiumBorder(),
                          label: QText(preset.$1),
                          onPressed: _busy
                              ? null
                              : () => _goals(goals, calories: preset.$2))
                  ]),
              const SizedBox(height: 16),
              _panel([
                _stepper(
                    'Калории',
                    goals.calories.round(),
                    50,
                    () => _goals(goals, calories: goals.calories - 50),
                    () => _goals(goals, calories: goals.calories + 50),
                    500,
                    20000),
                const Divider(),
                _stepper(
                    'Шаги',
                    goals.steps,
                    500,
                    () => _goals(goals, steps: goals.steps - 500),
                    () => _goals(goals, steps: goals.steps + 500),
                    500,
                    100000),
                const Divider(),
                _stepper(
                    'Вода',
                    goals.waterMl,
                    250,
                    () => _goals(goals, water: goals.waterMl - 250),
                    () => _goals(goals, water: goals.waterMl + 250),
                    250,
                    20000)
              ]),
            ]),
            _page(
                'Подключить Health Connect и уведомления?',
                'quant читает шаги любых часов и фитнес-трекеров и вес/жир умных весов через Health Connect локально на устройстве. Сначала включи выгрузку в исходных приложениях. Разрешения можно отозвать в любой момент.',
                [
                  _panel([
                    const Center(child: QuantLogo(size: 128)),
                    const SizedBox(height: 20),
                    QText('quant',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineLarge)
                  ]),
                ]),
          ])),
      Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            FilledButton(
                onPressed: _busy
                    ? null
                    : () => _step == 2 ? _run(_connect) : _move(_step + 1),
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(58),
                    shape: const StadiumBorder()),
                child: QText(_step == 2 ? 'Подключить и начать' : 'Далее')),
            if (_step == 2) ...[
              const SizedBox(height: 10),
              OutlinedButton(
                  onPressed: _busy ? null : () => _run(_finish),
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(58),
                      shape: const StadiumBorder()),
                  child: const QText('Продолжить без подключения'))
            ],
          ])),
    ])));
  }

  void _goals(UserGoals old, {double? calories, int? steps, int? water}) =>
      _run(() => ref.read(userGoalsProvider.notifier).save(UserGoals(
          calories: calories ?? old.calories,
          proteins: old.proteins,
          fats: old.fats,
          carbs: old.carbs,
          steps: steps ?? old.steps,
          waterMl: water ?? old.waterMl)));
  Widget _stepper(String label, int value, int step, VoidCallback minus,
          VoidCallback plus, int min, int max) =>
      Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Expanded(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  QText(label),
                  QText(
                      '$value${label == 'Калории' ? ' ккал' : label == 'Вода' ? ' мл' : ''}',
                      style: Theme.of(context).textTheme.headlineSmall)
                ])),
            IconButton.filledTonal(
                onPressed: _busy || value - step < min ? null : minus,
                icon: const Icon(Icons.remove),
                tooltip: context.tr('Уменьшить')),
            const SizedBox(width: 8),
            IconButton.filled(
                onPressed: _busy || value + step > max ? null : plus,
                icon: const Icon(Icons.add),
                tooltip: context.tr('Увеличить')),
          ]));
}
