import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_provider.dart';
import '../localization/locale_provider.dart';
import '../../app/dashboard_shell.dart';
import '../../features/goals/application/user_goals_provider.dart';
import '../../features/settings/application/theme_settings_provider.dart';
import '../../features/settings/application/reminder_settings_provider.dart';
import '../../features/onboarding/application/onboarding_provider.dart';
import 'data_reset_service.dart';

final dataResetServiceProvider = FutureProvider<DataResetService>((ref) async =>
    DataResetService(
        await ref.watch(databaseServiceProvider.future),
        ref.watch(userGoalsRepositoryProvider),
        ref.watch(appPreferencesRepositoryProvider),
        ref.watch(notificationServiceProvider)));
void invalidatePreferences(WidgetRef ref, {bool factory = false}) {
  ref.invalidate(userGoalsProvider);
  ref.invalidate(themeSettingsProvider);
  ref.invalidate(localeProvider);
  ref.invalidate(reminderSettingsProvider);
  if (factory) {
    ref.invalidate(selectedTabProvider);
    ref.invalidate(onboardingProvider);
  }
}
