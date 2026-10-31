import 'package:flutter/material.dart';

/// A persistent label above an input, never intersecting its outline.
class LabeledField extends StatelessWidget {
  const LabeledField({required this.label, required this.child, super.key});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          child,
        ],
      );
}
