import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/database/local_day.dart';
import '../../../../core/localization/app_strings.dart';

class DiaryCalendarSheet extends ConsumerStatefulWidget {
  const DiaryCalendarSheet({required this.selected, super.key});
  final DateTime selected;
  @override
  ConsumerState<DiaryCalendarSheet> createState() => _DiaryCalendarSheetState();
}

class _DiaryCalendarSheetState extends ConsumerState<DiaryCalendarSheet> {
  late DateTime _month = DateTime(widget.selected.year, widget.selected.month);
  void _move(int offset) =>
      setState(() => _month = DateTime(_month.year, _month.month + offset));
  @override
  Widget build(BuildContext context) {
    final records = ref.watch(recordedDiaryDatesProvider);
    final dates = records.valueOrNull ?? <DateTime>{};
    final scheme = Theme.of(context).colorScheme;
    final firstWeekday = MaterialLocalizations.of(context).firstDayOfWeekIndex;
    final blanks = (_month.weekday % 7 - firstWeekday + 7) % 7;
    final count = DateTime(_month.year, _month.month + 1, 0).day;
    final cells = ((blanks + count + 6) ~/ 7) * 7;
    return SafeArea(
        child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                Expanded(
                    child: QText('Выберите дату',
                        style: Theme.of(context).textTheme.titleLarge)),
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    tooltip: context.tr('Закрыть'),
                    icon: const Icon(Icons.close)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                IconButton(
                    key: const ValueKey('calendar-previous'),
                    onPressed:
                        _month.isAfter(DateTime(1900)) ? () => _move(-1) : null,
                    tooltip: context.tr('Предыдущий месяц'),
                    icon: const Icon(Icons.chevron_left)),
                Expanded(
                    child: Text(
                        DateFormat.yMMMM(context.languageCode).format(_month),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium)),
                IconButton(
                    key: const ValueKey('calendar-next'),
                    onPressed: _month.isBefore(DateTime(2100, 12))
                        ? () => _move(1)
                        : null,
                    tooltip: context.tr('Следующий месяц'),
                    icon: const Icon(Icons.chevron_right)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                      child: Text(
                          MaterialLocalizations.of(context)
                              .narrowWeekdays[(firstWeekday + i) % 7],
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelMedium))
              ]),
              const SizedBox(height: 8),
              if (records.isLoading) const LinearProgressIndicator(),
              if (records.hasError)
                TextButton(
                    onPressed: () => ref.invalidate(recordedDiaryDatesProvider),
                    child:
                        const QText('Не удалось загрузить отметки. Повторить')),
              GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisExtent: 52,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4),
                  itemCount: cells,
                  itemBuilder: (context, index) {
                    final number = index - blanks + 1;
                    if (number < 1 || number > count) {
                      return const SizedBox.shrink();
                    }
                    final date = DateTime(_month.year, _month.month, number);
                    final selected = date == localDay(widget.selected);
                    final recorded = dates.contains(date);
                    return Semantics(
                        selected: selected,
                        button: true,
                        label:
                            '${DateFormat.yMMMMd(context.languageCode).format(date)}${recorded ? ', ${context.tr('Есть записи')}' : ''}',
                        child: Material(
                            color: selected
                                ? scheme.primaryContainer
                                : scheme.surface,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: scheme.outlineVariant)),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                                key: ValueKey('calendar-day-$number'),
                                onTap: () => Navigator.pop(context, date),
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('$number',
                                          style: TextStyle(
                                              color: selected
                                                  ? scheme.onPrimaryContainer
                                                  : scheme.onSurface)),
                                      const SizedBox(height: 4),
                                      if (recorded)
                                        Container(
                                            key: ValueKey(
                                                'calendar-dot-$number'),
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: scheme.primary))
                                      else
                                        const SizedBox(height: 6),
                                    ]))));
                  }),
            ])));
  }
}
