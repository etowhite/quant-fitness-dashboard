import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/isar_database_service.dart';
import '../database/local_day.dart';
import '../localization/app_strings.dart';
import '../../features/settings/data/app_preferences_repository.dart';
import '../../features/goals/data/user_goals_repository.dart';
import '../../features/nutrition/application/daily_food_diary.dart';
import '../../features/water/data/water_log_entry.dart';
import 'package:isar_community/isar.dart';

abstract final class HomeWidgets {
  static const channel = MethodChannel('quant/home_widgets');
  static const privacyKey = 'quant.widgets.hide';
  static const activityKey = 'quant.widgets.activity';
  static final route = ValueNotifier<String?>(null);
  static Future<void> refresh() async {
    if (!Platform.isAndroid) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await channel.invokeMethod<void>('refresh', {
        'hide': prefs.getBool(privacyKey) ??
            prefs.getBool('quant.appLock') ??
            false,
      });
    } on PlatformException catch (_) {
      /* Launcher unavailable: app data is safe. */
    } on MissingPluginException catch (_) {/* Unit tests / unsupported host. */}
  }

  static Future<void> init() async {
    if (!Platform.isAndroid) return;
    channel.setMethodCallHandler((call) async {
      if (call.method == 'route') {
        route.value = null;
        route.value = call.arguments as String?;
      }
    });
    try {
      route.value = await channel.invokeMethod<String>('initialRoute');
      await refresh();
    } on MissingPluginException catch (_) {}
  }

  static Future<void> saveActivity(int? steps, DateTime fetchedAt) async {
    if (!Platform.isAndroid) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        activityKey,
        jsonEncode({
          'day': dayKey(fetchedAt),
          'zone': fetchedAt.timeZoneOffset.inMinutes,
          'steps': steps,
          'at': fetchedAt.millisecondsSinceEpoch,
        }));
    await refresh();
  }

  static String dayKey(DateTime date) =>
      '${date.year}-${date.month}-${date.day}';
}

/// Called only by an Android WorkManager job. No permission prompts or UI.
Future<Map<String, dynamic>> runWidgetJob(Map<String, dynamic> job) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();
  final db = await IsarDatabaseService.init();
  try {
    final action = job['action'];
    if (action == 'add' || action == 'undo') {
      await db.applyWidgetWater(
          job['id'] as String, action == 'add' ? job['volume'] as int : null,
          now: DateTime.fromMillisecondsSinceEpoch(job['at'] as int));
    }
    return await buildWidgetSnapshot(db, prefs);
  } finally {
    await db.close();
  }
}

Future<Map<String, dynamic>> buildWidgetSnapshot(
    IsarDatabaseService db, SharedPreferences prefs,
    {DateTime? clock}) async {
  final now = clock ?? DateTime.now();
  final goals = await UserGoalsRepository().load();
  final settings = await AppPreferencesRepository().load();
  final locale = settings.language.locale ??
      WidgetsBinding.instance.platformDispatcher.locale;
  final strings = AppStrings(locale);
  final totals = DailyFoodDiary(await db.getFoodLogEntriesForDay(now)).totals;
  final water = await db.isar.waterLogEntries
      .where()
      .dateEqualTo(localDay(now))
      .findAll();
  final sum = water.fold<int>(0, (sum, item) => sum + item.volumeMl);
  int? steps;
  final raw = prefs.getString(HomeWidgets.activityKey);
  if (raw != null) {
    try {
      final saved = jsonDecode(raw) as Map;
      if (saved['day'] == HomeWidgets.dayKey(now) &&
          saved['zone'] == now.timeZoneOffset.inMinutes) {
        steps = saved['steps'] as int?;
      }
    } on FormatException catch (_) {
    } on TypeError catch (_) {}
  }
  return {
    'day': HomeWidgets.dayKey(now),
    'zone': now.timeZoneOffset.inMinutes,
    'calories': totals.calories,
    'calorieGoal': goals.calories,
    'proteins': totals.proteins,
    'fats': totals.fats,
    'carbs': totals.carbs,
    'water': sum,
    'waterGoal': goals.waterMl,
    'steps': steps,
    'stepGoal': goals.steps,
    'hidden': prefs.getBool(HomeWidgets.privacyKey) ??
        prefs.getBool('quant.appLock') ??
        false,
    'mode': settings.theme.mode.name,
    'amoled': settings.theme.amoled,
    'accent': settings.theme.palette.primary.toARGB32(),
    'language': locale.languageCode,
    'labels': {
      for (final text in [
        'Калории',
        'Вода',
        'Шаги',
        'Б',
        'Ж',
        'У',
        'мл',
        'ккал',
        'Откройте quant для синхронизации',
        'Данные скрыты',
        'Не удалось сохранить',
        'Обновление…',
        'Отменить',
        'Виджет',
        'Виджеты главного экрана'
      ])
        text: strings.text(text)
    },
  };
}

class WidgetPrivacyCard extends StatefulWidget {
  const WidgetPrivacyCard({super.key});
  @override
  State<WidgetPrivacyCard> createState() => _WidgetPrivacyCardState();
}

class _WidgetPrivacyCardState extends State<WidgetPrivacyCard> {
  bool? _hidden;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _hidden = prefs.getBool(HomeWidgets.privacyKey) ??
          prefs.getBool('quant.appLock') ??
          false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
      child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.widgets_outlined),
                title: QText('Виджеты главного экрана'),
                subtitle: QText('Добавьте quant через меню виджетов Android')),
            SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const QText('Скрывать показатели на виджетах'),
                subtitle: const QText(
                    'Быстрое добавление воды доступно. Защищённые экраны требуют входа.'),
                value: _hidden ?? true,
                onChanged: _hidden == null
                    ? null
                    : (v) async {
                        final prefs = await SharedPreferences.getInstance();
                        if (await prefs.setBool(HomeWidgets.privacyKey, v)) {
                          if (mounted) setState(() => _hidden = v);
                          await HomeWidgets.refresh();
                        }
                      }),
          ])));
}
