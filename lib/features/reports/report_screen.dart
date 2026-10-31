import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/database/database_provider.dart';
import '../../core/database/local_day.dart';
import '../../core/localization/app_strings.dart';
import '../../shared/widgets/quant_logo.dart';
import '../dashboard/application/daily_health_provider.dart';
import '../dashboard/presentation/widgets/weight_chart_card.dart';
import '../goals/application/user_goals_provider.dart';
import '../nutrition/data/food_log_entry.dart';
import '../water/data/water_log_entry.dart';
import 'report_data.dart';

const reportChannel = MethodChannel('quant/report_image');

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});
  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  final captureKey = GlobalKey();
  int days = 7;
  bool busy = false;
  String? error;
  ReportData? report;
  @override
  void initState() {
    super.initState();
    Future.microtask(load);
  }

  Future<void> load() async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
      report = null;
    });
    try {
      final end = DateTime.now();
      final start = localDay(DateTime(end.year, end.month, end.day - days + 1));
      final db = await ref.read(databaseServiceProvider.future);
      final goals = await ref.read(userGoalsProvider.future);
      final food = await db.isar.foodLogEntries
          .filter()
          .dateBetween(start, end)
          .findAll();
      final water = await db.isar.waterLogEntries
          .filter()
          .dateBetween(start, localDay(end))
          .findAll();
      final health = await ref
          .read(healthConnectServiceProvider)
          .fetchReportHistory(start, end);
      final data = ReportData(
          start: start,
          end: end,
          weights: health.weights,
          food: food,
          water: water,
          steps: health.steps,
          waterGoal: goals.waterMl,
          stepGoal: goals.steps,
          healthIncomplete: health.incomplete);
      if (mounted) setState(() => report = data);
    } catch (_) {
      if (mounted) {
        setState(
            () => error = 'Не удалось сформировать отчёт. Повторите попытку.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> export(bool share) async {
    if (busy || report == null) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await WidgetsBinding.instance.endOfFrame;
      final boundary = captureKey.currentContext!.findRenderObject()!
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (bytes == null || bytes.lengthInBytes > 25 * 1024 * 1024) {
        throw StateError('Image too large');
      }
      if (!share) {
        final sdk = await reportChannel.invokeMethod<int>('sdk');
        if (sdk != null &&
            sdk <= 28 &&
            !await Permission.storage.request().isGranted) {
          throw StateError('Storage permission');
        }
      }
      final result = await reportChannel.invokeMethod<bool>(
          share ? 'share' : 'save', bytes.buffer.asUint8List());
      if (result == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: QText(share
                ? 'Открыто меню «Поделиться»'
                : 'Изображение сохранено в галерею')));
      }
    } catch (_) {
      if (mounted) {
        setState(() => error =
            'Не удалось сохранить или отправить изображение. Проверьте доступ и свободное место.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const QText('Экспорт отчёта')),
      body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Wrap(spacing: 12, runSpacing: 8, children: [
              for (final n in [7, 30])
                ChoiceChip(
                    label: QText(
                        n == 7 ? 'Последние 7 дней' : 'Последние 30 дней'),
                    selected: days == n,
                    onSelected: busy
                        ? null
                        : (_) {
                            setState(() => days = n);
                            load();
                          })
            ]),
            const SizedBox(height: 16),
            if (busy) const LinearProgressIndicator(),
            if (error != null) ...[
              QText(error!),
              TextButton(
                  onPressed: busy ? null : load,
                  child: const QText('Повторить'))
            ],
            if (report != null) ...[
              RepaintBoundary(
                  key: captureKey, child: ReportImage(data: report!)),
              const SizedBox(height: 16),
              FilledButton.icon(
                  onPressed: busy ? null : () => export(false),
                  icon: const Icon(Icons.save_alt),
                  label: const QText('Сохранить изображение')),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                  onPressed: busy ? null : () => export(true),
                  icon: const Icon(Icons.share_outlined),
                  label: const QText('Поделиться')),
            ]
          ])));
}

class ReportImage extends StatelessWidget {
  const ReportImage({required this.data, super.key});
  final ReportData data;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final locale = context.languageCode;
    String num(double? v, {int digits = 0}) => v == null
        ? context.tr('Нет данных')
        : NumberFormat.decimalPatternDigits(
                locale: locale, decimalDigits: digits)
            .format(v);
    String date(DateTime d) => DateFormat('d MMM yyyy', locale).format(d);
    Widget average(String title, ReportAverage a, String unit,
            {String? footnote}) =>
        Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      QText(title, style: t.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(
                          '${num(a.mean)} ${a.mean == null ? '' : context.tr(unit)}',
                          style: t.textTheme.headlineSmall),
                      Text('${context.tr('Дней с данными')}: ${a.days}'),
                      if (footnote != null) Text(footnote)
                    ])));
    return DefaultTextStyle(
        style: t.textTheme.bodyMedium!,
        child: ColoredBox(
            color: t.scaffoldBackgroundColor,
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Wrap(
                          spacing: 12,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const QuantLogo(size: 44),
                            Text('quant', style: t.textTheme.headlineLarge)
                          ]),
                      const SizedBox(height: 8),
                      QText('Отчёт за период', style: t.textTheme.titleLarge),
                      Text('${date(data.start)} — ${date(data.end)}'),
                      const SizedBox(height: 16),
                      WeightChartCard(
                          history: data.weights,
                          subtitle:
                              '${date(data.start)} — ${date(data.end)} · ${context.tr('кг')}'),
                      const SizedBox(height: 12),
                      Card(
                          child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (data.weights.isEmpty)
                                      const QText(
                                          'Нет измерений веса за период')
                                    else ...[
                                      Text(
                                          '${context.tr('Первое измерение')}: ${num(data.weights.first.value, digits: 1)} ${context.tr('кг')} · ${date(data.weights.first.date)}'),
                                      if (data.weights.length > 1) ...[
                                        Text(
                                            '${context.tr('Последнее измерение')}: ${num(data.weights.last.value, digits: 1)} ${context.tr('кг')} · ${date(data.weights.last.date)}'),
                                        Text(
                                            '${context.tr('Изменение веса')}: ${num(data.weightChange, digits: 1)} ${context.tr('кг')}')
                                      ] else
                                        const QText(
                                            'Одно измерение — изменение не рассчитывается'),
                                    ]
                                  ]))),
                      const SizedBox(height: 12),
                      average(
                          'Средние записанные калории', data.nutrition, 'ккал'),
                      average(
                          'Средний записанный объём воды', data.hydration, 'мл',
                          footnote:
                              '${context.tr('Дней достижения цели')}: ${data.waterGoalDays} / ${data.hydration.days}'),
                      average('Средние шаги', data.activity, 'шагов',
                          footnote:
                              '${context.tr('Дней достижения цели')}: ${data.stepGoalDays} / ${data.activity.days}'),
                      const SizedBox(height: 12),
                      Text(
                          '${context.tr('Сравнение с текущими целями (история целей не ведётся)')}: ${data.waterGoal} ${context.tr('мл')}, ${data.stepGoal} ${context.tr('шагов')}.'),
                      const SizedBox(height: 8),
                      const QText(
                          'Вода отражает только записанный объём. Дни без записей не включены в средние. Отсутствие данных не означает ноль.'),
                      if (data.healthIncomplete) ...[
                        const SizedBox(height: 8),
                        const QText(
                            'Данные Health Connect могут быть неполными: проверьте разрешения и синхронизацию в приложении.')
                      ],
                    ]))));
  }
}
