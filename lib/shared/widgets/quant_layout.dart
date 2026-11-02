import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/localization/app_strings.dart';

abstract final class QuantInsets {
  /// Space for the 68dp island and, where present, the FAB above it.
  static EdgeInsets page(BuildContext context, {bool fab = false}) =>
      EdgeInsets.fromLTRB(
          AppSpacing.section,
          AppSpacing.actionGap,
          AppSpacing.section,
          (fab ? 192 : 120) + MediaQuery.viewPaddingOf(context).bottom);
  static EdgeInsets form(BuildContext context) => EdgeInsets.fromLTRB(
      AppSpacing.section,
      AppSpacing.actionGap,
      AppSpacing.section,
      24 + MediaQuery.viewPaddingOf(context).bottom);
}

/// Keep the full accessible label when an extended FAB cannot fit large type.
class QuantFab extends StatelessWidget {
  const QuantFab(
      {required this.label,
      required this.onPressed,
      this.icon = Icons.add,
      super.key});
  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    final text = TextPainter(
        text: TextSpan(
            text: context.tr(label),
            style: Theme.of(context).textTheme.labelLarge),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context))
      ..layout();
    final compact = text.width + 80 > MediaQuery.sizeOf(context).width - 32;
    text.dispose();
    if (compact) {
      return FloatingActionButton(
          onPressed: onPressed, tooltip: context.tr(label), child: Icon(icon));
    }
    return FloatingActionButton.extended(
        onPressed: onPressed, icon: Icon(icon), label: QText(label));
  }
}

/// App bars grow with large system type instead of clipping a wrapped title.
class QuantAppBar extends AppBar {
  QuantAppBar(
      {required BuildContext context,
      required Widget title,
      super.actions,
      super.key})
      : super(
            title: DefaultTextStyle.merge(
                softWrap: true, maxLines: 10, child: title),
            toolbarHeight: _height(context, title, actions?.length ?? 0));

  static double _height(BuildContext context, Widget title, int actions) {
    final label = title is QText
        ? context.tr(title.data)
        : title is Text
            ? title.data ?? ''
            : '';
    final leading = Navigator.of(context).canPop() ? 56 : 0;
    final width = math.max(
        64.0, MediaQuery.sizeOf(context).width - 32 - leading - 48 * actions);
    final painter = TextPainter(
        text: TextSpan(
            text: label, style: Theme.of(context).textTheme.titleLarge),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context))
      ..layout(maxWidth: width);
    final height = math.max(kToolbarHeight, painter.height + 16);
    painter.dispose();
    return height;
  }
}
