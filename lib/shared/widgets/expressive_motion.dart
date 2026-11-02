import 'package:flutter/material.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/localization/app_strings.dart';

const expressiveDuration = Duration(milliseconds: 420);

/// Equal-width capsules whose column count follows translated, scaled labels.
class ResponsiveChoices extends StatelessWidget {
  const ResponsiveChoices(
      {required this.labels,
      required this.children,
      this.leadingWidth = 0,
      super.key});
  final List<String> labels;
  final List<Widget> children;
  final double leadingWidth;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        var widest = 64.0;
        for (final label in labels) {
          final painter = TextPainter(
              text: TextSpan(
                  text: context.tr(label),
                  style: Theme.of(context).textTheme.labelLarge),
              textDirection: Directionality.of(context),
              textScaler: MediaQuery.textScalerOf(context))
            ..layout();
          final width = painter.width + 32 + leadingWidth;
          if (width > widest) widest = width;
          painter.dispose();
        }
        final columns =
            ((box.maxWidth + AppSpacing.small) / (widest + AppSpacing.small))
                .floor()
                .clamp(1, children.length);
        final width =
            (box.maxWidth - AppSpacing.small * (columns - 1)) / columns;
        return Wrap(
            spacing: AppSpacing.small,
            runSpacing: AppSpacing.small,
            children: [
              for (final child in children) SizedBox(width: width, child: child)
            ]);
      });
}

class CapsuleChoice extends StatelessWidget {
  const CapsuleChoice(
      {required this.label,
      required this.selected,
      required this.onPressed,
      this.compact = false,
      this.color,
      super.key});
  final String label;
  final bool selected;
  final VoidCallback? onPressed;
  final Color? color;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
        selected: selected,
        child: AnimatedContainer(
          duration: expressiveDuration,
          curve: Curves.easeOutExpo,
          decoration: ShapeDecoration(
              shape:
                  StadiumBorder(side: BorderSide(color: scheme.outlineVariant)),
              color: selected ? scheme.primary : scheme.surface),
          child: TextButton(
              onPressed: onPressed,
              style: TextButton.styleFrom(
                  minimumSize: const Size(64, 48),
                  shape: const StadiumBorder(),
                  side: BorderSide.none,
                  foregroundColor:
                      selected ? scheme.onPrimary : scheme.onSurface,
                  textStyle:
                      compact ? Theme.of(context).textTheme.labelSmall : null,
                  padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 16)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (color != null) ...[
                  CircleAvatar(radius: 6, backgroundColor: color),
                  const SizedBox(width: 8)
                ],
                Flexible(
                    child: QText(label,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis)),
              ])),
        ));
  }
}

class AnimatedMetric extends StatelessWidget {
  const AnimatedMetric(
      {required this.value, required this.format, this.style, super.key});
  final double value;
  final String Function(double) format;
  final TextStyle? style;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
      tween: Tween(end: value),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : expressiveDuration,
      curve: Curves.easeOutExpo,
      builder: (context, value, _) => QText(format(value), style: style));
}

class AnimatedProgress extends StatelessWidget {
  const AnimatedProgress(
      {required this.value,
      this.color,
      this.backgroundColor,
      this.minHeight = 6,
      this.semanticsLabel,
      super.key});
  final double value, minHeight;
  final Color? color, backgroundColor;
  final String? semanticsLabel;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
      tween: Tween(end: value.clamp(0, 1)),
      duration: expressiveDuration,
      curve: Curves.easeOutExpo,
      builder: (context, progress, __) => LinearProgressIndicator(
          value: progress,
          color: color,
          backgroundColor: backgroundColor,
          minHeight: minHeight,
          semanticsLabel:
              semanticsLabel == null ? null : context.tr(semanticsLabel!),
          borderRadius: BorderRadius.circular(12)));
}
