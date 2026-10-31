import '../../../core/localization/app_language.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/theme_settings.dart';
import '../domain/reminder_settings.dart';

class AppPreferencesRepository {
  static const key = 'quant.preferences.v1';
  Future<
      ({
        ThemeSettings theme,
        ReminderSettings reminders,
        AppLanguage language
      })> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(key);
    if (saved == null) {
      return (
        theme: const ThemeSettings(),
        reminders: const ReminderSettings(),
        language: AppLanguage.system
      );
    }
    if (saved.length > 16384) {
      throw const FormatException('Слишком большой документ настроек');
    }
    final json = jsonDecode(saved);
    if (json is! Map<String, dynamic> ||
        json['theme'] is! Map<String, dynamic> ||
        json['reminders'] is! Map<String, dynamic>) {
      throw const FormatException('Некорректные настройки');
    }
    return (
      language: AppLanguage.parse(json['language']),
      theme: ThemeSettings.fromJson(json['theme'] as Map<String, dynamic>),
      reminders:
          ReminderSettings.fromJson(json['reminders'] as Map<String, dynamic>)
    );
  }

  // Serializes independent theme/reminder updates to prevent lost writes.
  Future<void> _queue = Future.value();
  Future<void> save(
      {ThemeSettings? theme,
      ReminderSettings? reminders,
      AppLanguage? language}) {
    final result = _queue.catchError((Object _) {}).then((_) async {
      final previous = await load();
      final nextTheme = theme ?? previous.theme,
          nextReminders = reminders ?? previous.reminders;
      nextReminders.validate();
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setString(
          key,
          jsonEncode({
            'language': (language ?? previous.language).name,
            'theme': nextTheme.toJson(),
            'reminders': nextReminders.toJson()
          }))) {
        throw StateError('Не удалось сохранить настройки');
      }
    });
    _queue = result;
    return result;
  }
}
