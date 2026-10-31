import '../core/localization/app_strings.dart';
import '../features/settings/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/measurements/presentation/measurements_screen.dart';
import '../features/nutrition/presentation/nutrition_screen.dart';

enum AppTab { dashboard, nutrition, measurements, settings }

final selectedTabProvider =
    NotifierProvider<SelectedTab, AppTab>(SelectedTab.new);

class SelectedTab extends Notifier<AppTab> {
  @override
  AppTab build() => AppTab.dashboard;

  void select(AppTab tab) => state = tab;
}

class DashboardShell extends ConsumerWidget {
  const DashboardShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(selectedTabProvider);
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: tab.index,
          children: const [
            DashboardScreen(),
            NutritionScreen(),
            MeasurementsScreen(),
            SettingsScreen()
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab.index,
        onDestinationSelected: (index) =>
            ref.read(selectedTabProvider.notifier).select(AppTab.values[index]),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            label: context.tr('Дашборд'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.restaurant_outlined),
            selectedIcon: const Icon(Icons.restaurant),
            label: context.tr('Питание'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.monitor_weight_outlined),
            selectedIcon: const Icon(Icons.monitor_weight),
            label: context.tr('Замеры'),
          ),
          NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings),
              label: context.tr('Настройки')),
        ],
      ),
    );
  }
}
