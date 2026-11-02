import 'package:flutter/material.dart';
import '../../core/theme/app_spacing.dart';

/// Scrolls long content above the keyboard; stacked actions keep a real gap.
class QuantDialog extends StatelessWidget {
  const QuantDialog({this.title, this.content, this.actions, super.key});
  final Widget? title, content;
  final List<Widget>? actions;
  @override
  Widget build(BuildContext context) => AlertDialog(
      scrollable: true,
      insetPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.section, vertical: AppSpacing.cardInset),
      titlePadding: const EdgeInsets.fromLTRB(
          AppSpacing.cardInset, AppSpacing.cardInset, AppSpacing.cardInset, 0),
      contentPadding: const EdgeInsets.all(AppSpacing.cardInset),
      actionsPadding: const EdgeInsets.fromLTRB(
          AppSpacing.cardInset, 0, AppSpacing.cardInset, AppSpacing.cardInset),
      actionsOverflowButtonSpacing: AppSpacing.actionGap,
      title: title,
      content: content,
      actions: actions
          ?.map((action) => DefaultTextStyle.merge(
              textAlign: TextAlign.center, child: action))
          .toList());
}
