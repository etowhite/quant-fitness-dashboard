import 'dart:io';

import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../features/dashboard/domain/daily_health_metrics.dart';

enum HealthAccess { granted, denied, unavailable, updateRequired }

// Resolve only coincident records; distinct measurements remain distinct.
// Overlapping intervals with different boundaries cannot safely be summed away.
List<HealthDataPoint> prioritizeHealthSources(List<HealthDataPoint> points) {
  int priority(HealthDataPoint p) {
    // DataOrigin package identity, never an app's editable display label.
    final source = p.sourceId.toLowerCase();
    bool package(String name) => source == name || source.startsWith('$name.');
    final body = p.type == HealthDataType.WEIGHT ||
        p.type == HealthDataType.BODY_FAT_PERCENTAGE;
    if (body && package('com.picooc')) {
      return 2;
    }
    if (!body && package('com.xiaomi.wearable')) {
      return 2;
    }
    return 0;
  }

  final sorted = [...points]..sort((a, b) {
      final rank = priority(b).compareTo(priority(a));
      return rank != 0 ? rank : a.uuid.compareTo(b.uuid);
    });
  final selected = <String, HealthDataPoint>{};
  for (final p in sorted) {
    final key = '${p.type.name}:${p.dateFrom.microsecondsSinceEpoch}:'
        '${p.type == HealthDataType.ACTIVE_ENERGY_BURNED ? p.dateTo.microsecondsSinceEpoch : ''}';
    selected.putIfAbsent(key, () => p);
  }
  return selected.values.toList();
}

DateTime? _lastTimestamp(List<HealthDataPoint> points, DateTime now) {
  DateTime? last;
  for (final p in points) {
    final date = p.dateTo.toLocal();
    if (!date.isAfter(now) && (last == null || date.isAfter(last))) last = date;
  }
  return last;
}

class HealthAccessException implements Exception {
  const HealthAccessException(this.access);
  final HealthAccess access;
}

class HealthConnectService {
  HealthConnectService({Health? health, DateTime Function()? clock})
      : _health = health ?? Health(),
        _clock = clock ?? DateTime.now;

  final Health _health;
  final DateTime Function() _clock;
  Future<void>? _configuration;

  static const types = [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.WEIGHT,
    HealthDataType.BODY_FAT_PERCENTAGE,
  ];
  static final _permissions = List.filled(types.length, HealthDataAccess.READ);

  Future<void> configure() async {
    if (!Platform.isAndroid) {
      throw const HealthAccessException(HealthAccess.unavailable);
    }
    try {
      await (_configuration ??= _health.configure());
    } catch (_) {
      _configuration = null;
      rethrow;
    }
  }

  Future<HealthAccess> checkAccess() async {
    if (!Platform.isAndroid) return HealthAccess.unavailable;
    await configure();
    final status = await _health.getHealthConnectSdkStatus();
    if (status == HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired) {
      return HealthAccess.updateRequired;
    }
    if (status != HealthConnectSdkStatus.sdkAvailable) {
      return HealthAccess.unavailable;
    }
    return await Permission.activityRecognition.isGranted &&
            await _health.hasPermissions(types, permissions: _permissions) ==
                true
        ? HealthAccess.granted
        : HealthAccess.denied;
  }

  Future<HealthAccess> requestPermissions() async {
    final access = await checkAccess();
    if (access == HealthAccess.unavailable ||
        access == HealthAccess.updateRequired) {
      return access;
    }
    if (!await Permission.activityRecognition.isGranted &&
        !await Permission.activityRecognition.request().isGranted) {
      return HealthAccess.denied;
    }
    if (access == HealthAccess.denied) {
      await _health.requestAuthorization(types, permissions: _permissions);
    }
    if (await _health.isHealthDataHistoryAvailable() &&
        !await _health.isHealthDataHistoryAuthorized()) {
      await _health.requestHealthDataHistoryAuthorization();
    }
    // Recheck all four permissions: partial authorization is not full access.
    return checkAccess();
  }

  Future<DailyHealthMetrics> fetchTodayMetrics() async {
    final access = await checkAccess();
    if (access != HealthAccess.granted) throw HealthAccessException(access);
    final now = _clock().toLocal();
    final midnight = DateTime(now.year, now.month, now.day);
    final since = now.subtract(const Duration(days: 30));
    final historyAvailable = await _health.isHealthDataHistoryAvailable();
    final historyAuthorized =
        historyAvailable && await _health.isHealthDataHistoryAuthorized();
    final measurementStart = historyAuthorized ? DateTime(1970) : since;
    var steps = await _health.getTotalStepsInInterval(midnight, now);
    if (steps != null && (steps < 0 || steps > 1000000)) steps = null;
    // The aggregate may return zero for an interval with no records.
    final samples = await _health.getHealthDataFromTypes(
      types: [HealthDataType.STEPS],
      startTime: midnight,
      endTime: now,
    );
    if (steps == 0 && samples.isEmpty) steps = null;
    final calories = await _health.getHealthDataFromTypes(
      types: [HealthDataType.ACTIVE_ENERGY_BURNED],
      startTime: midnight,
      endTime: now,
    );
    final measurements = await _health.getHealthDataFromTypes(
      types: [HealthDataType.WEIGHT, HealthDataType.BODY_FAT_PERCENTAGE],
      startTime: measurementStart,
      endTime: now,
    );
    final energy = prioritizeHealthSources(_health.removeDuplicates(calories));
    final unique =
        prioritizeHealthSources(_health.removeDuplicates(measurements));
    final weights =
        _points(unique, HealthDataType.WEIGHT, measurementStart, now);
    final fat = _points(
        unique, HealthDataType.BODY_FAT_PERCENTAGE, measurementStart, now);
    double? totalCalories;
    for (final point in energy) {
      final value = point.value;
      if (value is! NumericHealthValue) continue;
      if (point.unit != HealthDataUnit.KILOCALORIE) {
        throw StateError('Unexpected energy unit: ${point.unit}');
      }
      final numeric = value.numericValue.toDouble();
      if (!numeric.isFinite || numeric < 0 || numeric > 100000) continue;
      final total = (totalCalories ?? 0) + numeric;
      if (!total.isFinite || total > 100000) {
        throw StateError('Invalid daily energy total');
      }
      totalCalories = total;
    }
    return DailyHealthMetrics(
      fetchedAt: now,
      activityDataAt: _lastTimestamp([...samples, ...energy], now),
      bodyDataAt: _lastTimestamp(unique, now),
      historyAuthorized: historyAuthorized,
      historyAvailable: historyAvailable,
      stepsToday: steps,
      activeCaloriesToday: totalCalories,
      latestWeight: weights.isEmpty ? null : weights.last,
      latestBodyFat: fat.isEmpty ? null : fat.last,
      weightHistory: weights.where((p) => !p.date.isBefore(since)).toList(),
    );
  }

  List<HealthValuePoint> _points(List<HealthDataPoint> points,
      HealthDataType type, DateTime since, DateTime now) {
    final result = <HealthValuePoint>[];
    for (final point in points.where((p) => p.type == type)) {
      final value = point.value;
      final date = point.dateFrom.toLocal();
      if (value is! NumericHealthValue ||
          date.isBefore(since) ||
          date.isAfter(now)) {
        continue;
      }
      final expected = type == HealthDataType.WEIGHT
          ? HealthDataUnit.KILOGRAM
          : HealthDataUnit.PERCENT;
      if (point.unit != expected) {
        throw StateError('Unexpected unit: ${point.unit}');
      }
      final numeric = value.numericValue.toDouble();
      final valid = numeric.isFinite &&
          (type == HealthDataType.WEIGHT
              ? numeric > 0 && numeric <= 1000
              : numeric >= 0 && numeric <= 100);
      if (valid) result.add(HealthValuePoint(date: date, value: numeric));
    }
    result.sort((a, b) => a.date.compareTo(b.date));
    return result;
  }
}
