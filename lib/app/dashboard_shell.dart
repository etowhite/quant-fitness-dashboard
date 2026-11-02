import '../core/home_widgets/home_widgets.dart';
import 'dart:ui';
import '../shared/widgets/scroll_island.dart';
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

class _DashboardShellState extends ConsumerState<DashboardShell> {
  @override
  void initState() {
    super.initState();
    HomeWidgets.route.addListener(_openWidgetRoute);
    WidgetsBinding.instance.addPostFrameCallback((_) => _openWidgetRoute());
  }

  void _openWidgetRoute() {
    if (!mounted) return;
    final route = HomeWidgets.route.value;
    if (route == null) return;
    ref.read(selectedTabProvider.notifier).select(
        route == 'nutrition' || route == 'water'
            ? AppTab.nutrition
            : AppTab.dashboard);
  }

  @override
  void dispose() {
    HomeWidgets.route.removeListener(_openWidgetRoute);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(selectedTabProvider);
    ref.listen(selectedTabProvider, (old, next) {
      if (old != next) {
        ref.read(navigationVisibleProvider.notifier).setVisible(true);
      }
    });
    final visible = ref.watch(navigationVisibleProvider);
    return Scaffold(
      extendBody: true,
      body: Stack(children: [
        Positioned.fill(
            child: ScrollIslandListener(
          onVisibilityChanged: (v) =>
              ref.read(navigationVisibleProvider.notifier).setVisible(v),
          child: SafeArea(
              bottom: false,
              child: RetainedTabView(index: tab.index, children: const [
                DashboardScreen(),
                NutritionScreen(),
                MeasurementsScreen(),
                SettingsScreen()
              ])),
        )),
        Positioned(
            left: 16,
            right: 16,
            bottom: 16 + MediaQuery.paddingOf(context).bottom,
            child: IgnorePointer(
                ignoring: !visible,
                child: AnimatedSlide(
                    offset: visible ? Offset.zero : const Offset(0, 1.5),
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeInOutCubicEmphasized,
                    // Keep the backdrop outside opacity/saveLayer composition.
                    child: FloatingBottomBar(
                        selected: tab,
                        onSelected: (tab) => ref
                            .read(selectedTabProvider.notifier)
                            .select(tab))))),
      ]),
    );
  }
}

/// Retains every tab's State and scroll position but paints exactly one opaque
/// page. No outgoing pages or full-screen transformed opacity layers accumulate
/// when the user changes tabs before a previous transition finishes.
class RetainedTabView extends StatelessWidget {
  const RetainedTabView(
      {required this.index, required this.children, super.key});
  final int index;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) =>
      IndexedStack(index: index, sizing: StackFit.expand, children: [
        for (var i = 0; i < children.length; i++)
          TickerMode(
              enabled: index == i,
              child: RepaintBoundary(
                  child: ColoredBox(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      child: children[i])))
      ]);
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
    return ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh.withValues(alpha: .88),
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
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Icon(icons[tab.index],
                                                            color: selected ==
                                                                    tab
                                                                ? scheme
                                                                    .onPrimaryContainer
                                                                : scheme
                                                                    .onSurfaceVariant),
                                                        if (selected ==
                                                            tab) ...[
                                                          const SizedBox(
                                                              width: 6),
                                                          Flexible(
                                                              child: FittedBox(
                                                                  fit: BoxFit
                                                                      .scaleDown,
                                                                  child: QText(
                                                                      labels[tab
                                                                          .index],
                                                                      maxLines:
                                                                          1,
                                                                      softWrap:
                                                                          false,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                      style: TextStyle(
                                                                          color: scheme
                                                                              .onPrimaryContainer,
                                                                          fontWeight:
                                                                              FontWeight.w600))))
                                                        ],
                                                      ]))))))),
                      ])),
            )));
  }
}
