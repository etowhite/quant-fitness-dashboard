import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/localization/locale_provider.dart';
import 'features/onboarding/application/onboarding_provider.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';
import 'core/localization/app_strings.dart';
import 'features/settings/application/theme_settings_provider.dart';
import 'features/settings/application/reminder_settings_provider.dart';
import 'features/settings/domain/theme_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app/dashboard_shell.dart';
import 'core/theme/app_theme.dart';
import 'core/database/database_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  await initializeDateFormatting();
  runApp(const ProviderScope(child: SmartFitnessApp()));
}

class SmartFitnessApp extends ConsumerStatefulWidget {
  const SmartFitnessApp({super.key});

  @override
  ConsumerState<SmartFitnessApp> createState() => _SmartFitnessAppState();
}

class _SmartFitnessAppState extends ConsumerState<SmartFitnessApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(reminderSettingsProvider.notifier).refreshSchedule();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings =
        ref.watch(themeSettingsProvider).valueOrNull ?? const ThemeSettings();
    ref.watch(reminderSettingsProvider);
    final onboarding = ref.watch(onboardingProvider);
    final language = ref.watch(localeProvider).valueOrNull;
    return MaterialApp(
      title: 'quant',
      locale: language?.locale,
      supportedLocales: AppStrings.supportedLocales,
      localizationsDelegates: const [
        AppStrings.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(settings, Brightness.light),
      darkTheme: AppTheme.build(settings, Brightness.dark),
      themeMode: settings.mode,
      themeAnimationDuration: const Duration(milliseconds: 350),
      themeAnimationCurve: Curves.easeInOutCubic,
      home: ref.watch(databaseServiceProvider).when(
            data: (_) => onboarding.isLoading
                ? const Scaffold(
                    body: Center(child: CircularProgressIndicator()))
                : onboarding.valueOrNull == true
                    ? const DashboardShell()
                    : const OnboardingScreen(),
            loading: () => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => Scaffold(
              body: Center(
                  child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const QText('Не удалось открыть локальную базу данных.'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => ref.invalidate(databaseServiceProvider),
                    child: const QText('Повторить'),
                  ),
                ]),
              )),
            ),
          ),
    );
  }
}
