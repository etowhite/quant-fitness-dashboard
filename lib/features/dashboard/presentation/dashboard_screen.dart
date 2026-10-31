import '../../../core/localization/app_strings.dart';
import '../../../core/home_widgets/home_widgets.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/local_day.dart';
import '../../../core/health/health_connect_service.dart';
import '../../nutrition/application/food_diary_provider.dart';
import '../../goals/application/user_goals_provider.dart';
import '../application/daily_health_provider.dart';
import '../domain/daily_health_metrics.dart';
import 'widgets/dashboard_card.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/health_access_banner.dart';
import 'widgets/health_metrics_grid.dart';
import 'widgets/nutrition_summary_card.dart';
import 'widgets/weight_chart_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with WidgetsBindingObserver {
  late DateTime _day;
  Timer? _midnightTimer;
  bool _refreshing = false;
  final _activityKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _day = localDay(DateTime.now());
    WidgetsBinding.instance.addObserver(this);
    HomeWidgets.route.addListener(_jumpToActivity);
    _scheduleMidnight();
  }

  void _jumpToActivity() {
    if (HomeWidgets.route.value != 'activity') return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || HomeWidgets.route.value != 'activity') return;
      final target = _activityKey.currentContext;
      if (target != null) {
        HomeWidgets.route.value = null;
        Scrollable.ensureVisible(target,
            duration: const Duration(milliseconds: 350), alignment: .1);
      }
    });
  }

  void _scheduleMidnight() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    _midnightTimer = Timer(
        nextLocalDay(now).difference(now) + const Duration(milliseconds: 100),
        () {
      if (!mounted) return;
      _updateDay();
      unawaited(_sync());
      _scheduleMidnight();
    });
  }

  void _updateDay() {
    final today = localDay(DateTime.now());
    if (today != _day) setState(() => _day = today);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateDay();
      _scheduleMidnight();
      unawaited(_sync());
    }
  }

  Future<void> _sync({bool requestPermissions = false}) async {
    if (_refreshing) return;
    _updateDay();
    setState(() => _refreshing = true);
    try {
      await Future.wait<void>([
        ref
            .read(dailyHealthProvider.notifier)
            .refresh(requestPermissions: requestPermissions),
        ref.refresh(foodDiaryProvider(_day).future).then<void>((_) {}),
      ]);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  QText('Не удалось обновить все данные. Попробуйте еще раз.')),
        );
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    HomeWidgets.route.removeListener(_jumpToActivity);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _jumpToActivity();
    final health = ref.watch(dailyHealthProvider);
    final diary = ref.watch(foodDiaryProvider(_day));
    final goals = ref.watch(effectiveUserGoalsProvider);
    final healthState = health.valueOrNull;
    final stored = healthState?.metrics;
    // Never show yesterday's daily activity under today's heading after midnight.
    final metrics = stored == null || localDay(stored.fetchedAt) == _day
        ? stored
        : DailyHealthMetrics(
            fetchedAt: stored.fetchedAt,
            stepsToday: null,
            activeCaloriesToday: null,
            latestWeight: stored.latestWeight,
            latestBodyFat: stored.latestBodyFat,
            bodyDataAt: stored.bodyDataAt,
            historyAuthorized: stored.historyAuthorized,
            historyAvailable: stored.historyAvailable,
            weightHistory: stored.weightHistory);
    final busy = health.isLoading || _refreshing;

    return RefreshIndicator(
      onRefresh: () => _sync(requestPermissions: true),
      color: Theme.of(context).colorScheme.secondary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        children: [
          DashboardHeader(
              date: _day,
              syncing: busy,
              onSync: () => _sync(requestPermissions: true)),
          const SizedBox(height: 24),
          if (metrics?.historyAvailable == true &&
              !metrics!.historyAuthorized) ...[
            DashboardCard(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const QText(
                      'Для старых взвешиваний разрешите чтение истории Health Connect.'),
                  TextButton(
                      onPressed:
                          busy ? null : () => _sync(requestPermissions: true),
                      child: const QText('Разрешить историю')),
                ])),
            const SizedBox(height: 16),
          ],
          if (healthState != null &&
              healthState.access != HealthAccess.granted) ...[
            HealthAccessBanner(
                access: healthState.access,
                busy: busy,
                onConnect: () => _sync(
                    requestPermissions:
                        healthState.access == HealthAccess.denied)),
            const SizedBox(height: 16),
          ],
          if (health.hasError) ...[
            const DashboardCard(
                child: QText('Не удалось синхронизировать Health Connect. '
                    'Проверьте доступ и повторите обновление. Сохраненные на экране показатели могут быть устаревшими.')),
            const SizedBox(height: 16),
          ],
          diary.when(
            data: (day) =>
                NutritionSummaryCard(totals: day.totals, goals: goals),
            loading: () => const DashboardCard(
                child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()))),
            error: (error, stack) => DashboardCard(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const QText('Не удалось прочитать дневник питания.'),
                TextButton(
                    onPressed: () => ref.invalidate(foodDiaryProvider(_day)),
                    child: const QText('Повторить')),
              ],
            )),
          ),
          const SizedBox(height: 16),
          HealthMetricsGrid(
              key: _activityKey,
              metrics: metrics,
              loading: health.isLoading,
              stepGoal: goals.steps),
          const SizedBox(height: 16),
          WeightChartCard(history: metrics?.weightHistory ?? []),
          if (stored != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: QText(
                  'Health Connect · обновлено ${DateFormat('d MMM, HH:mm', context.languageCode).format(stored.fetchedAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ),
        ],
      ),
    );
  }
}
