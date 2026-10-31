import '../../../../core/localization/app_strings.dart';
import '../../../../shared/widgets/quant_logo.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader(
      {required this.date,
      required this.syncing,
      required this.onSync,
      super.key});
  final DateTime date;
  final bool syncing;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final formatted =
        DateFormat('EEEE, d MMM', context.languageCode).format(date);
    return Row(children: [
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const QuantLogo(size: 42),
          const SizedBox(width: 12),
          QText('quant', style: Theme.of(context).textTheme.headlineMedium)
        ]),
        const SizedBox(height: 4),
        QText('${formatted[0].toUpperCase()}${formatted.substring(1)}',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ])),
      if (syncing)
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.secondary,
                  semanticsLabel: context.tr('Синхронизация Health Connect'))),
        )
      else
        IconButton(
            onPressed: onSync,
            tooltip: context.tr('Синхронизировать Health Connect'),
            icon: Icon(Icons.sync,
                color: Theme.of(context).colorScheme.secondary)),
    ]);
  }
}
