import 'package:flutter/material.dart';

class DashboardCard extends StatelessWidget {
  const DashboardCard({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(padding: const EdgeInsets.all(20), child: child),
      );
}
