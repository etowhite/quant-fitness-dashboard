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

class DashboardShell extends ConsumerStatefulWidget {
  const DashboardShell({super.key});
  @override
  ConsumerState<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends ConsumerState<DashboardShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 420), value: 1);
  late final Animation<double> _curve =
      CurvedAnimation(parent: _motion, curve: Curves.easeOutExpo);
  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(selectedTabProvider);
    ref.listen(selectedTabProvider, (old, next) {
      if (old != next) _motion.forward(from: 0);
    });
    return Scaffold(
      body: SafeArea(
          child: FadeTransition(
              opacity: Tween<double>(begin: .35, end: 1).animate(_curve),
              child: ScaleTransition(
                  scale: Tween<double>(begin: .98, end: 1).animate(_curve),
                  child: SlideTransition(
                      position: Tween<Offset>(
                              begin: const Offset(0, .015), end: Offset.zero)
                          .animate(_curve),
                      child: IndexedStack(index: tab.index, children: const [
                        DashboardScreen(),
                        NutritionScreen(),
                        MeasurementsScreen(),
                        SettingsScreen()
                      ]))))),
      bottomNavigationBar: FloatingBottomBar(
          selected: tab,
          onSelected: (tab) =>
              ref.read(selectedTabProvider.notifier).select(tab)),
    );
  }
}

class FloatingBottomBar extends StatelessWidget {
  const FloatingBottomBar(
      {required this.selected, required this.onSelected, super.key});
  final AppTab selected;
  final ValueChanged<AppTab> onSelected;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const labels = ['Дашборд', 'Питание', 'Замеры', 'Настройки'];
    const icons = [
      Icons.dashboard_outlined,
      Icons.restaurant_outlined,
      Icons.monitor_weight_outlined,
      Icons.settings_outlined
    ];
    return SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: scheme.outlineVariant),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 20,
                    offset: const Offset(0, 4))
              ]),
          child: LayoutBuilder(
              builder: (context, constraints) => Row(children: [
                    for (final tab in AppTab.values)
                      AnimatedContainer(
                          duration: const Duration(milliseconds: 420),
                          curve: Curves.easeOutExpo,
                          width: constraints.maxWidth *
                              (selected == tab ? .46 : .18),
                          child: Semantics(
                              selected: selected == tab,
                              button: true,
                              label: context.tr(labels[tab.index]),
                              child: Tooltip(
                                  message: context.tr(labels[tab.index]),
                                  child: Material(
                                      color: selected == tab
                                          ? scheme.primaryContainer
                                          : Colors.transparent,
                                      shape: StadiumBorder(
                                          side: BorderSide(
                                              color: scheme.outlineVariant,
                                              width: 1)),
                                      clipBehavior: Clip.antiAlias,
                                      child: InkWell(
                                          key: ValueKey('tab-${tab.name}'),
                                          onTap: () => onSelected(tab),
                                          child: SizedBox(
                                              height: 56,
                                              child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(icons[tab.index],
                                                        color: selected == tab
                                                            ? scheme
                                                                .onPrimaryContainer
                                                            : scheme
                                                                .onSurfaceVariant),
                                                    if (selected == tab) ...[
                                                      const SizedBox(width: 6),
                                                      Flexible(
                                                          child: QText(
                                                              labels[tab.index],
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style: TextStyle(
                                                                  color: scheme
                                                                      .onPrimaryContainer,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600)))
                                                    ],
                                                  ]))))))),
                  ])),
        ));
  }
}
