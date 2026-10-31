import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/nutrition/data/food_product.dart';
import '../../features/nutrition/data/food_log_entry.dart';
import '../../features/measurements/data/body_measurement.dart';
import '../../features/water/data/water_log_entry.dart';
import '../../features/settings/data/app_preferences_repository.dart';
import '../../features/settings/domain/theme_settings.dart';
import '../../features/settings/domain/reminder_settings.dart';
import '../../features/goals/data/user_goals_repository.dart';
import '../../features/goals/domain/user_goals.dart';
import '../notifications/notification_service.dart';
import 'isar_database_service.dart';
import 'food_seed.dart';
import '../home_widgets/home_widgets.dart';
import '../../features/water/application/water_presets_provider.dart';

enum ResetCategory { diary, products, measurements, preferences }

class DataResetService {
  DataResetService(
      this.database, this.goals, this.preferences, this.notifications);
  final IsarDatabaseService database;
  final UserGoalsRepository goals;
  final AppPreferencesRepository preferences;
  final NotificationService notifications;
  Future<Map<ResetCategory, int>> counts() async => {
        ResetCategory.diary: await database.isar.foodLogEntries.count() +
            await database.isar.waterLogEntries.count(),
        ResetCategory.products: await database.isar.foodProducts
            .filter()
            .catalogueKeyIsNull()
            .count(),
        ResetCategory.measurements:
            await database.isar.bodyMeasurements.count(),
        ResetCategory.preferences: 3,
      };
  Future<void> clear(Set<ResetCategory> categories,
      {bool factory = false}) async {
    final selected = factory ? ResetCategory.values.toSet() : categories;
    if (selected.isEmpty) return;
    // Read/validate bundled seed before changing any data.
    final seeds = selected.contains(ResetCategory.products)
        ? await loadBaseFoodProducts()
        : <FoodProduct>[];
    if (selected.contains(ResetCategory.preferences)) {
      await notifications.cancelAll();
    }
    // All collection changes and reseeding form one atomic Isar transaction.
    // SharedPreferences is a separate store; interruptions require retrying reset.
    await database.isar.writeTxn(() async {
      if (selected.contains(ResetCategory.diary)) {
        await database.isar.foodLogEntries.clear();
        await database.isar.waterLogEntries.clear();
      }
      if (selected.contains(ResetCategory.measurements)) {
        await database.isar.bodyMeasurements.clear();
      }
      if (selected.contains(ResetCategory.products)) {
        await database.isar.foodProducts.clear();
        await database.isar.foodProducts.putAll(seeds);
      }
    });
    if (factory) {
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.clear()) throw StateError('Could not clear preferences');
    } else if (selected.contains(ResetCategory.preferences)) {
      await WaterPresetsRepository().save([]);
      await goals.save(const UserGoals());
      await preferences.save(
          theme: const ThemeSettings(), reminders: const ReminderSettings());
    }
    await HomeWidgets.refresh();
  }
}
