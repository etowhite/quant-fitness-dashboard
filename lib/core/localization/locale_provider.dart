import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/settings/application/theme_settings_provider.dart';
import '../../features/settings/application/reminder_settings_provider.dart';
import 'app_language.dart';

final localeProvider =
    AsyncNotifierProvider<LocaleNotifier, AppLanguage>(LocaleNotifier.new);

class LocaleNotifier extends AsyncNotifier<AppLanguage> {
  @override
  Future<AppLanguage> build() async =>
      (await ref.watch(appPreferencesRepositoryProvider).load()).language;
  Future<void> save(AppLanguage language) async {
    await ref.read(appPreferencesRepositoryProvider).save(language: language);
    state = AsyncData(language);
    ref.invalidate(reminderSettingsProvider);
  }
}
