import 'package:flutter/material.dart';
import '../../features/settings/data/app_preferences_repository.dart';
import '../localization/app_strings.dart';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../../features/settings/domain/reminder_settings.dart';

class NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _initializing;
  Future<bool> _queue = Future.value(true);
  static const channelId = 'quant_reminders_v1';
  AppStrings _strings = const AppStrings(Locale('ru'));
  NotificationDetails get details => NotificationDetails(
      android: AndroidNotificationDetails(
          channelId, _strings.text('quant · напоминания'),
          channelDescription: _strings.text('Вода, питание и замеры'),
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          visibility: NotificationVisibility.private,
          icon: 'ic_stat_quant'));

  Future<void> init() async {
    if (!Platform.isAndroid) return;
    final language = (await AppPreferencesRepository().load()).language;
    _strings = AppStrings(
        language.locale ?? WidgetsBinding.instance.platformDispatcher.locale);
    try {
      await (_initializing ??= _init());
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone));
    } catch (_) {
      _initializing = null;
      rethrow;
    }
  }

  Future<void> _init() async {
    tzdata.initializeTimeZones();
    await _plugin.initialize(const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_quant')));
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()!
        .createNotificationChannel(AndroidNotificationChannel(
            channelId, _strings.text('quant · напоминания'),
            description: _strings.text('Вода, питание и замеры'),
            importance: Importance.defaultImportance));
  }

  Future<bool> apply(ReminderSettings settings,
      {bool requestPermission = false}) {
    settings.validate();
    final result = _queue
        .catchError((Object _) => false)
        .then((_) => _apply(settings, requestPermission));
    _queue = result;
    return result;
  }

  Future<bool> _apply(ReminderSettings settings, bool requestPermission) async {
    if (!Platform.isAndroid) return true;
    await init();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()!;
    final enabled = requestPermission && settings.anyEnabled
        ? await android.requestNotificationsPermission() ?? false
        : await android.areNotificationsEnabled() ?? false;
    if (settings.anyEnabled && !enabled) {
      await _plugin.cancelAll();
      return false;
    }
    final exact = await android.canScheduleExactNotifications() ?? false;
    await _plugin.cancelAll();
    final now = tz.TZDateTime.now(tz.local);
    for (final slot in buildReminderSlots(settings)) {
      var next = tz.TZDateTime(tz.local, now.year, now.month, now.day,
          slot.minute ~/ 60, slot.minute % 60);
      while (!next.isAfter(now) ||
          (slot.weekday != 0 && next.weekday != slot.weekday)) {
        next = tz.TZDateTime(tz.local, next.year, next.month, next.day + 1,
            slot.minute ~/ 60, slot.minute % 60);
      }
      await _plugin.zonedSchedule(slot.id, _strings.text(slot.title),
          _strings.text(slot.body), next, details,
          androidScheduleMode: exact
              ? AndroidScheduleMode.exactAllowWhileIdle
              : AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: slot.weekday == 0
              ? DateTimeComponents.time
              : DateTimeComponents.dayOfWeekAndTime);
    }
    return true;
  }

  Future<bool> requestExact() async {
    if (!Platform.isAndroid) return false;
    await init();
    return await _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()!
            .requestExactAlarmsPermission() ??
        false;
  }

  Future<void> cancelAll() async {
    final result = _queue.catchError((Object _) => false).then((_) async {
      if (Platform.isAndroid) {
        await (_initializing ??= _init());
        await _plugin.cancelAll();
      }
      return true;
    });
    _queue = result;
    await result;
  }

  Future<bool> requestPermission() async {
    if (!Platform.isAndroid) return false;
    await init();
    return await _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()!
            .requestNotificationsPermission() ??
        false;
  }

  Future<bool> testNotification() async {
    if (!Platform.isAndroid) return false;
    await init();
    final allowed = await _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()!
            .requestNotificationsPermission() ??
        false;
    if (!allowed) return false;
    await _plugin.show(9001, 'quant',
        _strings.text('Напоминания работают. Хорошего дня!'), details);
    return true;
  }
}
