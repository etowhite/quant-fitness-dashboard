import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_fitness_dashboard/core/theme/app_theme.dart';
import 'package:smart_fitness_dashboard/core/backup/backup_document.dart';
import 'package:smart_fitness_dashboard/core/notifications/notification_service.dart';
import 'package:smart_fitness_dashboard/features/goals/domain/user_goals.dart';
import 'package:smart_fitness_dashboard/features/settings/domain/theme_settings.dart';
import 'package:smart_fitness_dashboard/features/settings/domain/reminder_settings.dart';
import 'package:smart_fitness_dashboard/features/settings/data/app_preferences_repository.dart';
import 'package:smart_fitness_dashboard/features/settings/application/theme_settings_provider.dart';
import 'package:smart_fitness_dashboard/features/settings/application/reminder_settings_provider.dart';
import 'package:smart_fitness_dashboard/features/settings/presentation/settings_screen.dart';
import 'package:smart_fitness_dashboard/shared/widgets/quant_logo.dart';
import 'package:smart_fitness_dashboard/features/dashboard/presentation/widgets/dashboard_header.dart';
import 'package:intl/date_symbol_data_local.dart';

class FakeNotifications extends NotificationService {
  final applied = <ReminderSettings>[];
  bool permission = true;
  @override
  Future<bool> apply(ReminderSettings settings,
      {bool requestPermission = false}) async {
    applied.add(settings);
    return permission;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('theme and reminder saves merge and survive provider restart', () async {
    final repository = AppPreferencesRepository();
    const theme = ThemeSettings(
        mode: ThemeMode.light,
        palette: AccentPalette.electricViolet,
        amoled: true);
    const reminders = ReminderSettings(
        water: true,
        waterInterval: 90,
        weekday: 3,
        measurements: MealReminder(enabled: true, minute: 480));
    await Future.wait(
        [repository.save(theme: theme), repository.save(reminders: reminders)]);
    final first = ProviderContainer(overrides: [
      notificationServiceProvider.overrideWithValue(FakeNotifications())
    ]);
    expect((await first.read(themeSettingsProvider.future)).toJson(),
        theme.toJson());
    expect((await first.read(reminderSettingsProvider.future)).toJson(),
        reminders.toJson());
    first.dispose();
    final second = ProviderContainer();
    addTearDown(second.dispose);
    expect((await second.read(themeSettingsProvider.future)).palette,
        AccentPalette.electricViolet);
  });
  test('denied notification permission preserves confirmed settings', () async {
    final fake = FakeNotifications();
    final container = ProviderContainer(
        overrides: [notificationServiceProvider.overrideWithValue(fake)]);
    addTearDown(container.dispose);
    await container.read(reminderSettingsProvider.future);
    fake.permission = false;
    await expectLater(
        container
            .read(reminderSettingsProvider.notifier)
            .save(const ReminderSettings(water: true)),
        throwsStateError);
    expect(
        container.read(reminderSettingsProvider).requireValue.water, isFalse);
    expect((await AppPreferencesRepository().load()).reminders.water, isFalse);
    expect(fake.applied.last.water, isFalse);
  });
  test('all palettes adapt contrast, light surfaces and AMOLED', () {
    for (final palette in AccentPalette.values) {
      final settings = ThemeSettings(palette: palette, amoled: true);
      final light = AppTheme.build(settings, Brightness.light),
          dark = AppTheme.build(settings, Brightness.dark);
      expect(light.scaffoldBackgroundColor, const Color(0xFFF8FAFC));
      expect(light.cardTheme.color, Colors.white);
      expect(dark.scaffoldBackgroundColor, Colors.black);
      expect(dark.colorScheme.primary, palette.primary);
      expect(light.colorScheme.primary, isNot(palette.primary));
      final a = light.colorScheme.primary.computeLuminance(),
          b = light.colorScheme.onPrimary.computeLuminance();
      expect((a > b ? (a + .05) / (b + .05) : (b + .05) / (a + .05)),
          greaterThan(4.5));
    }
  });
  test('water slots respect active window and weekdays; IDs unique', () {
    const settings = ReminderSettings(
        water: true,
        waterInterval: 90,
        breakfast: MealReminder(enabled: true, minute: 540),
        measurements: MealReminder(enabled: true, minute: 480),
        weekday: 7);
    final slots = buildReminderSlots(settings);
    final water = slots.where((s) => s.id < 200);
    expect(water.map((s) => s.minute),
        [540, 630, 720, 810, 900, 990, 1080, 1170, 1260]);
    expect(slots.map((s) => s.id).toSet().length, slots.length);
    expect(slots.last.weekday, 7);
    expect(buildReminderSlots(const ReminderSettings()), isEmpty);
    for (final invalid in [
      settings.copyWith(waterInterval: 0),
      settings.copyWith(waterStart: 1300),
      settings.copyWith(weekday: 8)
    ]) {
      expect(() => buildReminderSlots(invalid), throwsFormatException);
    }
  });
  test(
      'backup v3 preserves appearance and scheduling; v2 migrates; rejects bad settings',
      () {
    final doc = BackupDocument(
        goals: const UserGoals(),
        products: [],
        entries: [],
        measurements: [],
        theme: const ThemeSettings(
            mode: ThemeMode.system,
            palette: AccentPalette.sunsetCoral,
            amoled: true),
        reminders: const ReminderSettings(water: true));
    final restored = BackupDocument.decode(doc.encode());
    expect(restored.theme.toJson(), doc.theme.toJson());
    expect(restored.reminders.toJson(), doc.reminders.toJson());
    final old = jsonDecode(doc.encode()) as Map<String, dynamic>;
    old['version'] = 2;
    old.remove('theme');
    old.remove('reminders');
    expect(BackupDocument.decode(jsonEncode(old)).theme.mode, ThemeMode.dark);
    old['version'] = 3;
    expect(() => BackupDocument.decode(jsonEncode(old)), throwsFormatException);
  });
  testWidgets(
      'quant header renders vector logo and lowercase brand in both themes',
      (tester) async {
    await initializeDateFormatting('ru');
    for (final brightness in Brightness.values) {
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.build(const ThemeSettings(), brightness),
          home: Scaffold(
              body: DashboardHeader(
                  date: DateTime(2026, 10, 31),
                  syncing: false,
                  onSync: () {}))));
      expect(find.text('quant'), findsOneWidget);
      expect(find.byType(QuantLogo), findsOneWidget);
      expect(
          find.byWidgetPredicate(
              (w) => w is CustomPaint && w.painter is QuantLogoPainter),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets('settings changes persist selected light mode and palette',
      (tester) async {
    final container = ProviderContainer(overrides: [
      notificationServiceProvider.overrideWithValue(FakeNotifications())
    ]);
    addTearDown(container.dispose);
    await container.read(themeSettingsProvider.future);
    await container.read(reminderSettingsProvider.future);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child:
            MaterialApp(theme: AppTheme.dark, home: const SettingsScreen())));
    await tester.pumpAndSettle();
    expect(find.text('Оформление'), findsOneWidget);
    await tester.ensureVisible(find.text('Светлая'));
    await tester.tap(find.text('Светлая'));
    await tester.pumpAndSettle();
    expect(container.read(themeSettingsProvider).requireValue.mode,
        ThemeMode.light);
    await tester.ensureVisible(find.byTooltip('Sunset Coral'));
    await tester.tap(find.byTooltip('Sunset Coral'));
    await tester.pumpAndSettle();
    expect(container.read(themeSettingsProvider).requireValue.palette,
        AccentPalette.sunsetCoral);
    expect(tester.takeException(), isNull);
  });
}
