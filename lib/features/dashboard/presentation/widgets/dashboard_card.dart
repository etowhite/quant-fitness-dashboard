import 'package:smart_fitness_dashboard/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class DashboardCard extends StatelessWidget {
  const DashboardCard({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
            padding: const EdgeInsets.all(AppSpacing.cardInset), child: child),
      );
}
