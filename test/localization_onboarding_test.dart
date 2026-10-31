import 'package:smart_fitness_dashboard/core/database/data_reset_provider.dart';
import 'package:smart_fitness_dashboard/core/database/data_reset_service.dart';
import 'package:smart_fitness_dashboard/features/settings/presentation/widgets/data_management_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_fitness_dashboard/core/localization/app_strings.dart';
import 'package:smart_fitness_dashboard/core/localization/app_language.dart';
import 'package:smart_fitness_dashboard/core/localization/locale_provider.dart';
import 'package:smart_fitness_dashboard/core/localization/translations.dart';
import 'package:smart_fitness_dashboard/core/notifications/notification_service.dart';
import 'package:smart_fitness_dashboard/features/settings/application/theme_settings_provider.dart';
import 'package:smart_fitness_dashboard/features/settings/application/reminder_settings_provider.dart';
import 'package:smart_fitness_dashboard/features/settings/domain/reminder_settings.dart';
import 'package:smart_fitness_dashboard/features/settings/presentation/settings_screen.dart';
import 'package:smart_fitness_dashboard/features/onboarding/application/onboarding_provider.dart';
import 'package:smart_fitness_dashboard/features/onboarding/presentation/onboarding_screen.dart';
import 'package:smart_fitness_dashboard/features/goals/application/user_goals_provider.dart';
import 'package:smart_fitness_dashboard/core/backup/backup_document.dart';
import 'package:smart_fitness_dashboard/features/goals/domain/user_goals.dart';

class LocalNotifications extends NotificationService {
  @override
  Future<bool> apply(ReminderSettings s,
          {bool requestPermission = false}) async =>
      true;
}

class LocalizedHarness extends ConsumerWidget {
  const LocalizedHarness({this.settings = false, super.key});
  final bool settings;
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp(
      locale:
          ref.watch(localeProvider).valueOrNull?.locale ?? const Locale('ru'),
      supportedLocales: AppStrings.supportedLocales,
      localizationsDelegates: const [
        AppStrings.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      home: settings
          ? const SettingsScreen()
          : ref.watch(onboardingProvider).valueOrNull == true
              ? const Scaffold(body: Text('dashboard sentinel'))
              : const OnboardingScreen());
}

class FakeReset implements DataResetService {
  Set<ResetCategory>? selected;
  bool factory = false;
  @override
  Future<Map<ResetCategory, int>> counts() async =>
      {for (final c in ResetCategory.values) c: 5};
  @override
  Future<void> clear(Set<ResetCategory> categories,
      {bool factory = false}) async {
    selected = categories;
    this.factory = factory;
    if (factory) await (await SharedPreferences.getInstance()).clear();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  Future<ProviderContainer> prepare() async {
    final c = ProviderContainer(overrides: [
      notificationServiceProvider.overrideWithValue(LocalNotifications())
    ]);
    await c.read(localeProvider.future);
    await c.read(themeSettingsProvider.future);
    await c.read(userGoalsProvider.future);
    await c.read(onboardingProvider.future);
    await c.read(reminderSettingsProvider.future);
    addTearDown(c.dispose);
    return c;
  }

  test(
      'all translation keys, units and dynamic labels translate without Cyrillic',
      () {
    const strings = AppStrings(Locale('en'));
    for (final entry in english.entries) {
      expect(strings.text(entry.key), entry.value);
      expect(RegExp('[А-Яа-яЁё]').hasMatch(entry.value), isFalse,
          reason: entry.key);
    }
    expect(strings.text('Шаг 2 из 3'), 'Step 2 of 3');
    expect(strings.text('Вода: 2000 мл'), 'Water: 2000 ml');
    expect(
        strings.text('Б 12.3 · Ж 4.5 · У 33.0 г'), 'P 12.3 · F 4.5 · C 33.0 g');
    expect(strings.text('Авторская заметка'), 'Авторская заметка');
  });
  test(
      'language persists across restart and JSON v4 roundtrip; old versions use Auto',
      () async {
    final c = await prepare();
    await c.read(localeProvider.notifier).save(AppLanguage.en);
    final second = ProviderContainer();
    addTearDown(second.dispose);
    expect(await second.read(localeProvider.future), AppLanguage.en);
    final doc = BackupDocument(
        goals: const UserGoals(),
        products: [],
        entries: [],
        measurements: [],
        language: AppLanguage.en);
    expect(BackupDocument.decode(doc.encode()).language, AppLanguage.en);
  });
  testWidgets('RU/EN changes onboarding immediately; skip persists completion',
      (tester) async {
    final c = await prepare();
    await tester.pumpWidget(UncontrolledProviderScope(
        container: c, child: const LocalizedHarness()));
    await tester.pumpAndSettle();
    expect(find.text('Знакомство с quant'), findsOneWidget);
    await tester.ensureVisible(find.text('EN'));
    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to quant'), findsOneWidget);
    expect(find.text('Знакомство с quant'), findsNothing);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.text('dashboard sentinel'), findsOneWidget);
    expect(
        (await SharedPreferences.getInstance()).getBool(OnboardingNotifier.key),
        isTrue);
  });
  testWidgets(
      'three onboarding steps persist goals and allow continuing without permission',
      (tester) async {
    final c = await prepare();
    await c.read(localeProvider.notifier).save(AppLanguage.en);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: c, child: const LocalizedHarness()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Your daily goals'), findsOneWidget);
    expect(
        tester
            .widgetList<ActionChip>(find.byType(ActionChip))
            .map((chip) => chip.shape),
        everyElement(isA<StadiumBorder>()));
    final presets =
        find.ancestor(of: find.text('Cut'), matching: find.byType(Wrap)).first;
    expect(tester.widget<Wrap>(presets).alignment, WrapAlignment.center);
    await tester.tap(find.byTooltip('Increase').first);
    await tester.pumpAndSettle();
    expect(c.read(effectiveUserGoalsProvider).calories, 2250);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Connect & Start'), findsOneWidget);
    await tester.tap(find.text('Continue without connecting'));
    await tester.pumpAndSettle();
    expect(find.text('dashboard sentinel'), findsOneWidget);
  });
  testWidgets('Settings language switch renders English labels without restart',
      (tester) async {
    final c = await prepare();
    await tester.pumpWidget(UncontrolledProviderScope(
        container: c, child: const LocalizedHarness(settings: true)));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<AppLanguage>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English').last);
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Replay Onboarding'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Data Management & Reset'), 300,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(find.text('Factory Reset'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('selective reset requires a category and confirmation',
      (tester) async {
    final fake = FakeReset();
    final c = ProviderContainer(overrides: [
      dataResetServiceProvider.overrideWith((ref) async => fake),
      notificationServiceProvider.overrideWithValue(LocalNotifications())
    ]);
    addTearDown(c.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: const MaterialApp(home: Scaffold(body: DataManagementCard()))));
    await tester.tap(find.text('Выборочная очистка данных'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(
        tester
            .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Очистить выбранное'))
            .onPressed,
        isNull);
    await tester.tap(find.text('История дневника питания и воды'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Очистить выбранное'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(fake.selected, isNull);
    await tester.tap(find.text('Очистить выбранное'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(fake.selected, {ResetCategory.diary});
    expect(fake.factory, isFalse);
  });
  testWidgets(
      'factory reset has backup option and clears onboarding flag only after confirmation',
      (tester) async {
    await (await SharedPreferences.getInstance())
        .setBool(OnboardingNotifier.key, true);
    final fake = FakeReset();
    final c = ProviderContainer(overrides: [
      dataResetServiceProvider.overrideWith((ref) async => fake),
      notificationServiceProvider.overrideWithValue(LocalNotifications())
    ]);
    addTearDown(c.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: const MaterialApp(home: Scaffold(body: DataManagementCard()))));
    await tester.tap(find.text('Полный сброс приложения'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Сначала экспортировать JSON'), findsOneWidget);
    expect(fake.selected, isNull);
    await tester.tap(find.text('Сбросить приложение'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(fake.factory, isTrue);
    expect(
        (await SharedPreferences.getInstance()).getBool(OnboardingNotifier.key),
        isNull);
    expect(await c.read(onboardingProvider.future), isFalse);
  });
}
