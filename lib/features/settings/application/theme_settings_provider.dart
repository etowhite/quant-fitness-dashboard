import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/app_preferences_repository.dart';
import '../domain/theme_settings.dart';

final appPreferencesRepositoryProvider =
    Provider((ref) => AppPreferencesRepository());
final themeSettingsProvider =
    AsyncNotifierProvider<ThemeSettingsNotifier, ThemeSettings>(
        ThemeSettingsNotifier.new);

class ThemeSettingsNotifier extends AsyncNotifier<ThemeSettings> {
  bool _saving = false;
  @override
  Future<ThemeSettings> build() async =>
      (await ref.watch(appPreferencesRepositoryProvider).load()).theme;
  Future<void> save(ThemeSettings settings) async {
    if (_saving) return;
    _saving = true;
    try {
      if (state.isLoading) await future;
      await ref.read(appPreferencesRepositoryProvider).save(theme: settings);
      state = AsyncData(settings);
    } finally {
      _saving = false;
    }
  }
}
