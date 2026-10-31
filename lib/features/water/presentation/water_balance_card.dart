import '../../../core/localization/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_provider.dart';
import '../../goals/application/user_goals_provider.dart';
import '../application/water_provider.dart';

class WaterBalanceCard extends ConsumerStatefulWidget {
  const WaterBalanceCard({required this.date, super.key});
  final DateTime date;
  @override
  ConsumerState<WaterBalanceCard> createState() => _WaterBalanceCardState();
}

class _WaterBalanceCardState extends ConsumerState<WaterBalanceCard> {
  bool _busy = false;
  String? _error;
  Future<void> _change(int? volume) async {
    if (_busy) return;
    final date = widget.date;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final db = await ref.read(databaseServiceProvider.future);
      if (volume == null) {
        await db.undoWater(date);
      } else {
        await db.addWater(date, volume);
      }
    } catch (_) {
      if (mounted) {
        setState(
            () => _error = 'Не удалось сохранить воду. Повторите попытку.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final water = ref.watch(waterProvider(widget.date));
    final goal = ref.watch(effectiveUserGoalsProvider).waterMl;
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(20),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.water_drop_outlined,
                    color: Theme.of(context).colorScheme.secondary),
                const SizedBox(width: 8),
                QText('Водный баланс',
                    style: Theme.of(context).textTheme.titleMedium)
              ]),
              const SizedBox(height: 12),
              water.when(
                  data: (rows) {
                    final total =
                        rows.fold<int>(0, (sum, r) => sum + r.volumeMl);
                    return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          QText('$total / $goal мл',
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 10),
                          LinearProgressIndicator(
                              value: (total / goal).clamp(0.0, 1.0),
                              color: Theme.of(context).colorScheme.secondary,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .secondary
                                  .withAlpha(26),
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(8)),
                          const SizedBox(height: 12),
                          Wrap(spacing: 8, children: [
                            for (final volume in [150, 250, 500])
                              OutlinedButton(
                                  onPressed:
                                      _busy ? null : () => _change(volume),
                                  child: QText('+$volume мл')),
                            IconButton(
                                onPressed: _busy || rows.isEmpty
                                    ? null
                                    : () => _change(null),
                                tooltip:
                                    context.tr('Отменить последнюю порцию'),
                                icon: Icon(Icons.remove_circle_outline,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondary)),
                          ]),
                        ]);
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => TextButton(
                      onPressed: () =>
                          ref.invalidate(waterProvider(widget.date)),
                      child: const QText('Повторить загрузку воды'))),
              if (_error != null) QText(_error!),
            ])));
  }
}
