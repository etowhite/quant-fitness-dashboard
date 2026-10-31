import '../localization/app_language.dart';
import '../../features/water/application/water_presets_provider.dart';
import '../../features/settings/domain/theme_settings.dart';
import '../../features/settings/domain/reminder_settings.dart';
import 'dart:convert';
import '../../features/nutrition/data/recipe.dart';

import '../../features/goals/domain/user_goals.dart';
import '../../features/measurements/data/body_measurement.dart';
import '../../features/nutrition/data/food_log_entry.dart';
import '../../features/nutrition/data/food_product.dart';
import '../validation/input_limits.dart';
import '../database/isar_database_service.dart';
import '../database/local_day.dart';
import '../../features/water/data/water_log_entry.dart';

class BackupDocument {
  BackupDocument(
      {required this.goals,
      required this.products,
      required this.entries,
      required this.measurements,
      this.language = AppLanguage.system,
      this.waterPresets = WaterPresetsRepository.defaults,
      this.theme = const ThemeSettings(),
      this.reminders = const ReminderSettings(),
      this.water = const []});
  static const maxBytes = 10 * 1024 * 1024;
  final UserGoals goals;
  final AppLanguage language;
  final List<int> waterPresets;
  final ThemeSettings theme;
  final ReminderSettings reminders;
  final List<FoodProduct> products;
  final List<FoodLogEntry> entries;
  final List<BodyMeasurement> measurements;
  final List<WaterLogEntry> water;

  String encode() => jsonEncode({
        'format': 'smart_fitness_backup',
        'version': 7,
        'waterPresets': WaterPresetsRepository.validate(waterPresets),
        'language': language.name,
        'application': 'quant',
        'theme': theme.toJson(),
        'reminders': reminders.toJson(),
        'goals': goals.toJson(),
        'products': [
          for (final p in products)
            {
              'name': p.name,
              'calories': p.calories,
              'proteins': p.proteins,
              'fats': p.fats,
              'carbs': p.carbs,
              'category': p.category,
              'catalogueKey': p.catalogueKey,
              'barcode': p.barcode,
              'source': p.source,
              'stableKey': p.stableKey,
              'isFavorite': p.isFavorite,
              'recipeJson': p.recipeJson
            }
        ],
        'entries': [
          for (final e in entries)
            {
              'date': e.date.toIso8601String(),
              'mealType': e.mealType,
              'productName': e.productName,
              'productKey': e.productKey,
              'weightGrams': e.weightGrams,
              'calories': e.calories,
              'proteins': e.proteins,
              'fats': e.fats,
              'carbs': e.carbs
            }
        ],
        'measurements': [
          for (final m in measurements)
            {
              'date': m.date.toIso8601String(),
              'chest': m.chest,
              'waist': m.waist,
              'hips': m.hips,
              'biceps': m.biceps,
              'note': m.note
            }
        ],
        'water': [
          for (final w in water)
            {
              'date': w.date.toIso8601String(),
              'recordedAt': w.recordedAt.toIso8601String(),
              'volumeMl': w.volumeMl
            }
        ],
      });

  factory BackupDocument.decode(String source) {
    if (utf8.encode(source).length > maxBytes) {
      throw const FormatException('Файл больше 10 МБ');
    }
    final raw = jsonDecode(source);
    if (raw is! Map<String, dynamic> ||
        raw['format'] != 'smart_fitness_backup' ||
        (raw['version'] != 1 &&
            raw['version'] != 2 &&
            raw['version'] != 3 &&
            raw['version'] != 4 &&
            raw['version'] != 5 &&
            raw['version'] != 6 &&
            raw['version'] != 7)) {
      throw const FormatException('Неподдерживаемый формат копии');
    }
    List<Map<String, dynamic>> rows(String key) {
      final value = raw[key];
      if (value is! List ||
          value.length > 50000 ||
          value.any((e) => e is! Map<String, dynamic>)) {
        throw const FormatException('Некорректный список записей');
      }
      return value.cast<Map<String, dynamic>>();
    }

    String text(Map<String, dynamic> row, String key, int max,
        {bool empty = false}) {
      final v = row[key];
      if (v is! String || v.length > max || (!empty && v.trim().isEmpty)) {
        throw const FormatException('Некорректный текст');
      }
      return v.trim();
    }

    double number(Map<String, dynamic> row, String key, double max,
        {bool positive = false}) {
      final v = row[key];
      if (v is! num ||
          !v.isFinite ||
          v < 0 ||
          v > max ||
          (positive && v == 0)) {
        throw const FormatException('Число вне допустимых границ');
      }
      return v.toDouble();
    }

    DateTime date(Map<String, dynamic> row) {
      final value = DateTime.tryParse(text(row, 'date', 40));
      if (value == null || value.year < 1900 || value.year > 2200) {
        throw const FormatException('Некорректная дата');
      }
      return value.toLocal();
    }

    final products = [
      for (final r in rows('products'))
        FoodProduct()
          ..name = text(r, 'name', InputLimits.productName)
          ..calories = number(r, 'calories', InputLimits.caloriesPer100g)
          ..proteins = number(r, 'proteins', InputLimits.macroPer100g)
          ..fats = number(r, 'fats', InputLimits.macroPer100g)
          ..carbs = number(r, 'carbs', InputLimits.macroPer100g)
          ..category =
              r['category'] == null ? 'Другое' : text(r, 'category', 80)
          ..catalogueKey =
              r['catalogueKey'] == null ? null : text(r, 'catalogueKey', 100)
          ..barcode = r['barcode'] == null ? null : text(r, 'barcode', 14)
          ..source = r['source'] == null ? null : text(r, 'source', 200)
          ..stableKey =
              r['stableKey'] == null ? null : text(r, 'stableKey', 200)
          ..isFavorite = r['isFavorite'] == true
          ..recipeJson =
              r['recipeJson'] == null ? null : text(r, 'recipeJson', 200000)
    ];
    final keys = <String>{};
    final productRows = rows('products');
    for (final (index, p) in products.indexed) {
      p.stableKey ??= IsarDatabaseService.productIdentity(p);
      final rawFavorite = productRows[index]['isFavorite'];
      if (rawFavorite != null && rawFavorite is! bool) {
        throw const FormatException('Invalid favorite flag');
      }
      if (p.stableKey != null && !keys.add(p.stableKey!)) {
        throw const FormatException('Duplicate product key');
      }
      if (p.recipeJson != null) {
        final r = Recipe.decode(p.recipeJson!);
        final v = r.per100;
        p.calories = v?[0] ?? 0;
        p.proteins = v?[1] ?? 0;
        p.fats = v?[2] ?? 0;
        p.carbs = v?[3] ?? 0;
      }
    }
    final entries = <FoodLogEntry>[];
    for (final r in rows('entries')) {
      final meal = text(r, 'mealType', 20);
      if (!IsarDatabaseService.mealTypes.contains(meal)) {
        throw const FormatException('Неизвестный прием пищи');
      }
      entries.add(FoodLogEntry()
        ..date = date(r)
        ..mealType = meal
        ..productName = text(r, 'productName', InputLimits.productName)
        ..productKey =
            r['productKey'] == null ? null : text(r, 'productKey', 200)
        ..weightGrams =
            number(r, 'weightGrams', InputLimits.portionGrams, positive: true)
        ..calories = number(r, 'calories', 100000)
        ..proteins = number(r, 'proteins', 100000)
        ..fats = number(r, 'fats', 100000)
        ..carbs = number(r, 'carbs', 100000));
    }
    final measurements = <BodyMeasurement>[];
    final days = <DateTime>{};
    for (final r in rows('measurements')) {
      final day = localDay(date(r));
      if (!days.add(day)) {
        throw const FormatException('Повторяющийся день замера');
      }
      double? optional(String k) => r[k] == null
          ? null
          : number(r, k, InputLimits.circumferenceCm, positive: true);
      measurements.add(BodyMeasurement()
        ..date = day
        ..chest = optional('chest')
        ..waist = optional('waist')
        ..hips = optional('hips')
        ..biceps = optional('biceps')
        ..note = r['note'] == null
            ? null
            : text(r, 'note', InputLimits.note, empty: true));
    }
    if (raw['goals'] is! Map<String, dynamic>) {
      throw const FormatException('Нет целей');
    }
    final water = <WaterLogEntry>[];
    final waterTotals = <DateTime, int>{};
    for (final r
        in raw['version'] == 1 ? <Map<String, dynamic>>[] : rows('water')) {
      final day = localDay(date(r));
      final volume = r['volumeMl'];
      final time = DateTime.tryParse(text(r, 'recordedAt', 40));
      if (volume is! int ||
          volume <= 0 ||
          volume > InputLimits.waterPortionMl ||
          time == null ||
          time.year < 1900 ||
          time.year > 2200) {
        throw const FormatException('Некорректная запись воды');
      }
      waterTotals[day] = (waterTotals[day] ?? 0) + volume;
      if (waterTotals[day]! > InputLimits.waterDailyMl) {
        throw const FormatException('Слишком много воды за день');
      }
      water.add(WaterLogEntry()
        ..date = day
        ..volumeMl = volume
        ..recordedAt = time.toLocal());
    }
    for (final p in products) {
      if (p.barcode != null &&
          !RegExp(r'^(?:\d{8}|\d{12,14})$').hasMatch(p.barcode!)) {
        throw const FormatException('Некорректный штрихкод');
      }
    }
    return BackupDocument(
        goals: UserGoals.fromJson(raw['goals'] as Map<String, dynamic>),
        products: products,
        entries: entries,
        measurements: measurements,
        water: water,
        waterPresets: (raw['version'] as int) >= 7
            ? WaterPresetsRepository.validate(raw['waterPresets'])
            : WaterPresetsRepository.validate({
                ...WaterPresetsRepository.defaults,
                if ((raw['version'] as int) >= 5)
                  ...WaterPresetsRepository.validate(raw['waterPresets'])
              }.toList()),
        language: (raw['version'] as int) >= 4
            ? AppLanguage.parse(raw['language'])
            : AppLanguage.system,
        theme: (raw['version'] as int) >= 3
            ? ThemeSettings.fromJson(_settingsMap(raw, 'theme'))
            : const ThemeSettings(),
        reminders: (raw['version'] as int) >= 3
            ? ReminderSettings.fromJson(_settingsMap(raw, 'reminders'))
            : const ReminderSettings());
  }
}

Map<String, dynamic> _settingsMap(Map<String, dynamic> raw, String key) {
  final value = raw[key];
  if (value is! Map<String, dynamic>) {
    throw const FormatException('Нет настроек');
  }
  return value;
}
