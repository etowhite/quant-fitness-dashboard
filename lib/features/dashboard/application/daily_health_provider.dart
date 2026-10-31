import '../../../core/home_widgets/home_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/health/health_connect_service.dart';
import '../domain/daily_health_metrics.dart';

final healthConnectServiceProvider = Provider((ref) => HealthConnectService());

class DailyHealthState {
  const DailyHealthState({required this.access, this.metrics});
  final HealthAccess access;
  final DailyHealthMetrics? metrics;
  bool get isEmpty => metrics?.isEmpty ?? true;
}

final dailyHealthProvider =
    AsyncNotifierProvider<DailyHealthNotifier, DailyHealthState>(
        DailyHealthNotifier.new);

class DailyHealthNotifier extends AsyncNotifier<DailyHealthState> {
  bool _busy = false;

  @override
  Future<DailyHealthState> build() async {
    _busy = true;
    try {
      return await _load(request: false);
    } finally {
      _busy = false;
    }
  }

  Future<DailyHealthState> _load({required bool request}) async {
    final service = ref.read(healthConnectServiceProvider);
    final access = request
        ? await service.requestPermissions()
        : await service.checkAccess();
    if (access != HealthAccess.granted) {
      await HomeWidgets.saveActivity(null, DateTime.now());
      return DailyHealthState(access: access);
    }
    try {
      final metrics = await service.fetchTodayMetrics();
      await HomeWidgets.saveActivity(metrics.stepsToday, metrics.fetchedAt);
      return DailyHealthState(access: access, metrics: metrics);
    } on HealthAccessException catch (error) {
      return DailyHealthState(access: error.access);
    }
  }

  Future<void> refresh({bool requestPermissions = false}) async {
    if (_busy) {
      try {
        await future;
      } catch (_) {/* An explicit grant can recover an initial error. */}
      if (!requestPermissions) return;
    }
    _busy = true;
    final previous = state;
    state = const AsyncLoading<DailyHealthState>().copyWithPrevious(previous);
    try {
      state = (await AsyncValue.guard(() => _load(request: requestPermissions)))
          .copyWithPrevious(previous);
    } finally {
      _busy = false;
    }
  }
}
