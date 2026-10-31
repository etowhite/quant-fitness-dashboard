import '../../features/settings/data/app_preferences_repository.dart';
import '../../features/water/application/water_presets_provider.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:isar_community/isar.dart';

import '../../features/goals/data/user_goals_repository.dart';
import '../../features/measurements/data/body_measurement.dart';
import '../../features/nutrition/data/food_log_entry.dart';
import '../../features/nutrition/data/food_product.dart';
import '../database/isar_database_service.dart';
import '../home_widgets/home_widgets.dart';
import 'backup_document.dart';
import '../../features/water/data/water_log_entry.dart';

class BackupService {
  BackupService(this.database, this.goals,
      [AppPreferencesRepository? preferences])
      : preferences = preferences ?? AppPreferencesRepository();
  final AppPreferencesRepository preferences;
  final IsarDatabaseService database;
  final UserGoalsRepository goals;
  static const channel = MethodChannel('smart_fitness/local_documents');

  Future<bool> export() async {
    final savedGoals = await goals.load();
    final settings = await preferences.load();
    final waterPresets = await WaterPresetsRepository().load();
    final doc = await database.isar.txn(() async => BackupDocument(
        goals: savedGoals,
        language: settings.language,
        waterPresets: waterPresets,
        theme: settings.theme,
        reminders: settings.reminders,
        products: await database.isar.foodProducts.where().findAll(),
        entries: await database.isar.foodLogEntries.where().findAll(),
        measurements: await database.getBodyMeasurementHistory(),
        water: await database.isar.waterLogEntries.where().findAll()));
    final json = doc.encode();
    BackupDocument.decode(json); // An exported file must satisfy import limits.
    final data = utf8.encode(json);
    if (data.length > BackupDocument.maxBytes) {
      throw const FormatException('Копия больше 10 МБ');
    }
    return await channel.invokeMethod<bool>(
            'export', Uint8List.fromList(data)) ??
        false;
  }

  Future<BackupDocument?> chooseImport() async {
    final bytes = await channel.invokeMethod<Uint8List>('import');
    if (bytes == null) return null;
    if (bytes.length > BackupDocument.maxBytes) {
      throw const FormatException('Файл больше 10 МБ');
    }
    return BackupDocument.decode(utf8.decode(bytes));
  }

  Future<void> restore(BackupDocument document) async {
    // Revalidate even when called outside the file picker.
    final valid = BackupDocument.decode(document.encode());
    final previousGoals = await goals.load();
    final previousSettings = await preferences.load();
    final previousWaterPresets = await WaterPresetsRepository().load();
    try {
      await database.isar.writeTxn(() async {
        await database.isar.foodProducts.clear();
        await database.isar.foodLogEntries.clear();
        await database.isar.bodyMeasurements.clear();
        await database.isar.waterLogEntries.clear();
        await database.isar.foodProducts.putAll(valid.products);
        await database.isar.foodLogEntries.putAll(valid.entries);
        await database.isar.bodyMeasurements.putAll(valid.measurements);
        await database.isar.waterLogEntries.putAll(valid.water);
        await goals.save(valid.goals);
        await WaterPresetsRepository().save(valid.waterPresets);
        await preferences.save(
            theme: valid.theme,
            reminders: valid.reminders,
            language: valid.language);
      });
    } catch (_) {
      await goals.save(previousGoals);
      await WaterPresetsRepository().save(previousWaterPresets);
      await preferences.save(
          theme: previousSettings.theme,
          reminders: previousSettings.reminders,
          language: previousSettings.language);
      rethrow;
    } finally {
      await HomeWidgets.refresh();
    }
  }
}
