import 'dart:io';
import 'package:flutter/services.dart';

import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'interval_totals.dart';

import '../../features/dashboard/domain/daily_health_metrics.dart';

enum HealthSourceMode { platform, localFallback }

enum HealthAccess { granted, denied, unavailable, updateRequired }

// Resolve only coincident records; distinct measurements remain distinct.
// Overlapping intervals with different boundaries cannot safely be summed away.
List<HealthDataPoint> prioritizeHealthSources(List<HealthDataPoint> points) {
  final sorted = [...points]..sort((a, b) {
      final source = a.sourceId.compareTo(b.sourceId);
      return source != 0 ? source : a.uuid.compareTo(b.uuid);
    });
  final selected = <String, HealthDataPoint>{};
  for (final p in sorted) {
    final key = '${p.type.name}:${p.dateFrom.microsecondsSinceEpoch}:'
        '${p.dateTo.microsecondsSinceEpoch}';
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
  HealthConnectService({Health? health, DateTime Function()? clock, bool? iOS})
      : _health = health ?? Health(),
        _clock = clock ?? DateTime.now,
        _isIOS = iOS ?? Platform.isIOS;

  final bool _isIOS;
  final Health _health;
  final DateTime Function() _clock;
  Future<void>? _configuration;
  HealthSourceMode sourceMode = HealthSourceMode.platform;
  bool get isSupportedPlatform => Platform.isAndroid || _isIOS;
  static const _capabilities = MethodChannel('quant/health_capabilities');
  List<HealthDataType> get platformTypes => types
      .where((t) => !_isIOS || t != HealthDataType.TOTAL_CALORIES_BURNED)
      .toList();
  Future<bool> _iosAvailable() async {
    if (!_isIOS) return true;
    if (!const bool.fromEnvironment('QUANT_HEALTHKIT', defaultValue: false)) {
      sourceMode = HealthSourceMode.localFallback;
      return false;
    }
    try {
      final available = await _capabilities
              .invokeMethod<bool>('healthKitAvailable')
              .timeout(const Duration(seconds: 5)) ==
          true;
      if (!available) sourceMode = HealthSourceMode.localFallback;
      return available;
    } on Object {
      sourceMode = HealthSourceMode.localFallback;
      return false;
    }
  }

  Future<bool> activityPermissionGranted() =>
      _isIOS ? Future.value(true) : Permission.activityRecognition.isGranted;

  static const types = [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.TOTAL_CALORIES_BURNED,
    HealthDataType.WEIGHT,
    HealthDataType.BODY_FAT_PERCENTAGE,
  ];
  static final _permissions = List.filled(types.length, HealthDataAccess.READ);

  Future<void> configure() async {
    if (!isSupportedPlatform || !await _iosAvailable()) {
      throw const HealthAccessException(HealthAccess.unavailable);
    }
    try {
      await (_configuration ??= _health.configure())
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      _configuration = null;
      rethrow;
    }
  }

  Future<HealthAccess> checkAccess() async {
    if (!isSupportedPlatform) return HealthAccess.unavailable;
    if (!await _iosAvailable()) return HealthAccess.unavailable;
    try {
      await configure();
      if (_isIOS) return HealthAccess.granted;
      return await _androidAccess();
    } on Object {
      if (!_isIOS) rethrow;
      sourceMode = HealthSourceMode.localFallback;
      return HealthAccess.unavailable;
    }
  }

  Future<HealthAccess> _androidAccess() async {
    final status = await _health.getHealthConnectSdkStatus();
    if (status == HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired) {
      return HealthAccess.updateRequired;
    }
    if (status != HealthConnectSdkStatus.sdkAvailable) {
      return HealthAccess.unavailable;
    }
    // Partial access still permits useful weight/energy data.
    for (final type in types) {
      if (await _canRead(type)) return HealthAccess.granted;
    }
    return HealthAccess.denied;
  }

  Future<bool> _canRead(HealthDataType type) async =>
      await _health
          .hasPermissions([type], permissions: [HealthDataAccess.READ]) ==
      true;

  Future<List<HealthDataPoint>> _read(
      HealthDataType type, DateTime start, DateTime end) async {
    if (_isIOS && (!await _iosAvailable() || !platformTypes.contains(type))) {
      return [];
    }
    if (!_isIOS && !await _canRead(type)) return [];
    return _health.removeDuplicates(await _health
        .getHealthDataFromTypes(types: [type], startTime: start, endTime: end));
  }

  Future<HealthAccess> requestPermissions() async {
    try {
      return await _requestPermissions();
    } on Object {
      if (!_isIOS) rethrow;
      sourceMode = HealthSourceMode.localFallback;
      return HealthAccess.unavailable;
    }
  }

  Future<HealthAccess> _requestPermissions() async {
    final access = await checkAccess();
    if (access == HealthAccess.unavailable ||
        access == HealthAccess.updateRequired) {
      return access;
    }
    if (Platform.isAndroid && !await Permission.activityRecognition.isGranted) {
      await Permission.activityRecognition.request();
    }
    if (_isIOS ||
        await _health.hasPermissions(types, permissions: _permissions) !=
            true) {
      await _health.requestAuthorization(platformTypes,
          permissions:
              List.filled(platformTypes.length, HealthDataAccess.READ));
    }
    if (Platform.isAndroid &&
        await _health.isHealthDataHistoryAvailable() &&
        !await _health.isHealthDataHistoryAuthorized()) {
      await _health.requestHealthDataHistoryAuthorization();
    }
    // Recheck after the dialog; optional denials do not hide granted data.
    return checkAccess();
  }

  Future<DailyHealthMetrics> fetchTodayMetrics() async {
    try {
      return await _fetchTodayMetrics();
    } on Object {
      if (!_isIOS) rethrow;
      sourceMode = HealthSourceMode.localFallback;
      throw const HealthAccessException(HealthAccess.unavailable);
    }
  }

  Future<DailyHealthMetrics> _fetchTodayMetrics() async {
    final access = await checkAccess();
    if (access != HealthAccess.granted) throw HealthAccessException(access);
    final now = _clock().toLocal();
    final midnight = DateTime(now.year, now.month, now.day);
    final since = now.subtract(const Duration(days: 30));
    final historyAvailable =
        Platform.isAndroid && await _health.isHealthDataHistoryAvailable();
    final historyAuthorized =
        historyAvailable && await _health.isHealthDataHistoryAuthorized();
    final measurementStart = historyAuthorized ? DateTime(1970) : since;
    int? steps;
    if ((_isIOS || await _canRead(HealthDataType.STEPS)) &&
        await activityPermissionGranted()) {
      try {
        steps = await _health.getTotalStepsInInterval(midnight, now);
      } catch (_) {
        /* Some providers cannot aggregate; use read-only raw samples. */
      }
    }
    if (steps != null && (steps < 0 || steps > 1000000)) steps = null;
    // The aggregate may return zero for an interval with no records.
    final samples = await _read(HealthDataType.STEPS, midnight, now);
    if ((steps ?? 0) == 0 && samples.isNotEmpty) {
      steps = nonOverlappingTotal(
              samples.where((p) => p.unit == HealthDataUnit.COUNT).toList(),
              midnight,
              now,
              maxValue: 1000000)
          .round();
    }
    if (steps == 0 && samples.isEmpty) steps = null;
    var energy =
        await _read(HealthDataType.ACTIVE_ENERGY_BURNED, midnight, now);
    double energyTotal(List<HealthDataPoint> points) => nonOverlappingTotal(
        points.where((p) => p.unit == HealthDataUnit.KILOCALORIE).toList(),
        midnight,
        now,
        maxValue: 100000);
    var totalCalories = energyTotal(energy);
    var caloriesAreTotal = false;
    if (totalCalories == 0 && !_isIOS) {
      final fallback =
          await _read(HealthDataType.TOTAL_CALORIES_BURNED, midnight, now);
      if (fallback.isNotEmpty) {
        energy = fallback;
        totalCalories = energyTotal(fallback);
        caloriesAreTotal = true;
      }
    }
    final measurements = [
      ...await _read(HealthDataType.WEIGHT, measurementStart, now),
      ...await _read(HealthDataType.BODY_FAT_PERCENTAGE, measurementStart, now),
    ];
    final unique =
        prioritizeHealthSources(_health.removeDuplicates(measurements));
    final weights =
        _points(unique, HealthDataType.WEIGHT, measurementStart, now);
    final fat = _points(
        unique, HealthDataType.BODY_FAT_PERCENTAGE, measurementStart, now);
    return DailyHealthMetrics(
      fetchedAt: now,
      activityDataAt: _lastTimestamp([...samples, ...energy], now),
      bodyDataAt: _lastTimestamp(unique, now),
      historyAuthorized: historyAuthorized,
      historyAvailable: historyAvailable,
      stepsToday: steps,
      activeCaloriesToday: energy.isEmpty ? null : totalCalories,
      caloriesAreTotal: caloriesAreTotal,
      latestWeight: weights.isEmpty ? null : weights.last,
      latestBodyFat: fat.isEmpty ? null : fat.last,
      weightHistory: weights.where((p) => !p.date.isBefore(since)).toList(),
    );
  }

  /// Explicit report read; never opens a permission dialog. Missing days stay absent.
  Future<
      ({
        List<HealthValuePoint> weights,
        Map<DateTime, int> steps,
        bool incomplete
      })> fetchReportHistory(DateTime start, DateTime end) async {
    final weights = <HealthValuePoint>[];
    final steps = <DateTime, int>{};
    var incomplete = false;
    try {
      if (await checkAccess() != HealthAccess.granted) {
        return (weights: weights, steps: steps, incomplete: true);
      }
      try {
        if (_isIOS || await _canRead(HealthDataType.WEIGHT)) {
          weights.addAll(_points(
              prioritizeHealthSources(
                  await _read(HealthDataType.WEIGHT, start, end)),
              HealthDataType.WEIGHT,
              start,
              end));
        } else {
          incomplete = true;
        }
      } catch (_) {
        incomplete = true;
      }
      if ((_isIOS || await _canRead(HealthDataType.STEPS)) &&
          await activityPermissionGranted()) {
        for (var day = DateTime(start.year, start.month, start.day);
            day.isBefore(end);
            day = DateTime(day.year, day.month, day.day + 1)) {
          final next = DateTime(day.year, day.month, day.day + 1);
          final until = next.isAfter(end) ? end : next;
          try {
            final samples = await _read(HealthDataType.STEPS, day, until);
            int? count;
            try {
              count = await _health.getTotalStepsInInterval(day, until);
            } catch (_) {
              incomplete = true;
            }
            if (count == null || count <= 0) {
              if (samples.isEmpty) {
                continue;
              }
              count = nonOverlappingTotal(
                      samples
                          .where((p) => p.unit == HealthDataUnit.COUNT)
                          .toList(),
                      day,
                      until,
                      maxValue: 1000000)
                  .round();
            }
            if (count >= 0 && count <= 1000000) steps[day] = count;
          } catch (_) {
            incomplete = true;
          }
        }
      } else {
        incomplete = true;
      }
    } catch (_) {
      incomplete = true;
    }
    return (weights: weights, steps: steps, incomplete: incomplete);
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
