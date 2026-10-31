import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/notifications/notification_service.dart';
import '../domain/reminder_settings.dart';
import 'theme_settings_provider.dart';

final notificationServiceProvider = Provider((ref) => NotificationService());
final notificationStatusProvider = StateProvider<String?>((ref) => null);
final reminderSettingsProvider =
    AsyncNotifierProvider<ReminderSettingsNotifier, ReminderSettings>(
        ReminderSettingsNotifier.new);

class ReminderSettingsNotifier extends AsyncNotifier<ReminderSettings> {
  bool _busy = false;
  @override
  Future<ReminderSettings> build() async {
    final settings =
        (await ref.watch(appPreferencesRepositoryProvider).load()).reminders;
    // No permission dialogs on launch or import. Explicit settings edits request consent.
    try {
      final applied =
          await ref.read(notificationServiceProvider).apply(settings);
      ref.read(notificationStatusProvider.notifier).state =
          applied ? null : 'Уведомления отключены в настройках Android.';
    } catch (_) {
      ref.read(notificationStatusProvider.notifier).state =
          'Не удалось восстановить расписание. Повторите в настройках.';
    }
    return settings;
  }

  Future<void> save(ReminderSettings settings) async {
    if (_busy) return;
    settings.validate();
    _busy = true;
    final previous = state.valueOrNull ?? const ReminderSettings();
    try {
      if (state.isLoading) await future;
      final applied = await ref
          .read(notificationServiceProvider)
          .apply(settings, requestPermission: true);
      if (!applied) {
        throw StateError('Разрешите уведомления в настройках Android');
      }
      await ref
          .read(appPreferencesRepositoryProvider)
          .save(reminders: settings);
      state = AsyncData(settings);
      ref.read(notificationStatusProvider.notifier).state = null;
    } catch (_) {
      try {
        await ref.read(notificationServiceProvider).apply(previous);
      } catch (_) {}
      rethrow;
    } finally {
      _busy = false;
    }
  }

  Future<void> refreshSchedule() async {
    try {
      final settings = await future;
      final applied =
          await ref.read(notificationServiceProvider).apply(settings);
      ref.read(notificationStatusProvider.notifier).state =
          applied ? null : 'Уведомления отключены в настройках Android.';
    } catch (_) {
      ref.read(notificationStatusProvider.notifier).state =
          'Не удалось обновить расписание.';
    }
  }
}
