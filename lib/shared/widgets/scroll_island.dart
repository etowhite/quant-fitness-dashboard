import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final navigationVisibleProvider =
    NotifierProvider<NavigationVisibility, bool>(NavigationVisibility.new);

class NavigationVisibility extends Notifier<bool> {
  @override
  bool build() => true;
  void setVisible(bool value) {
    if (state != value) state = value;
  }
}

/// Only user-driven vertical scrolling controls the island, never horizontal
/// charts, programmatic date jumps or offstage tabs.
class ScrollIslandListener extends StatefulWidget {
  const ScrollIslandListener(
      {required this.child, required this.onVisibilityChanged, super.key});
  final Widget child;
  final ValueChanged<bool> onVisibilityChanged;
  @override
  State<ScrollIslandListener> createState() => _ScrollIslandListenerState();
}

class _ScrollIslandListenerState extends State<ScrollIslandListener> {
  bool _dragging = false;
  double _downward = 0;
  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.depth != 0 ||
                notification.metrics.axis != Axis.vertical) {
              return false;
            }
            if (notification is ScrollStartNotification) {
              _dragging = notification.dragDetails != null;
              _downward = 0;
            }
            if (notification is ScrollUpdateNotification) {
              if (notification.metrics.pixels <= 0) {
                _downward = 0;
                widget.onVisibilityChanged(true);
              } else if (_dragging) {
                final delta = notification.scrollDelta ?? 0;
                if (delta < 0) {
                  _downward = 0;
                  widget.onVisibilityChanged(true);
                } else {
                  _downward += delta;
                  if (_downward > 10) widget.onVisibilityChanged(false);
                }
              }
            }
            if (notification is ScrollEndNotification) _dragging = false;
            return false;
          },
          child: widget.child);
}

/// Matches the island's visibility; hidden controls cannot intercept touches.
class IslandAwareFab extends ConsumerWidget {
  const IslandAwareFab({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible = ref.watch(navigationVisibleProvider);
    return AnimatedPadding(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOutCubicEmphasized,
      padding: EdgeInsets.only(bottom: visible ? 88 : 0),
      child: IgnorePointer(
          ignoring: !visible,
          child: AnimatedOpacity(
              opacity: visible ? 1 : 0,
              duration: const Duration(milliseconds: 280),
              child: child)),
    );
  }
}
