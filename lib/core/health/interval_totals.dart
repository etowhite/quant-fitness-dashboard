import 'dart:math' as math;
import 'package:health/health.dart';

/// Raw fallback estimate: partition overlapping intervals and take the largest
/// rate in each partition, never add competing devices for the same time span.
/// Health Connect's user-prioritized aggregate remains the preferred value.
double nonOverlappingTotal(
    List<HealthDataPoint> points, DateTime start, DateTime end,
    {required double maxValue}) {
  final intervals = <({int from, int to, double rate})>[];
  final instants = <int, double>{};
  for (final p in points) {
    if (p.value is! NumericHealthValue) continue;
    final value = (p.value as NumericHealthValue).numericValue.toDouble();
    if (!value.isFinite || value < 0 || value > maxValue) continue;
    final from = p.dateFrom.microsecondsSinceEpoch;
    final to = p.dateTo.microsecondsSinceEpoch;
    if (to < from || p.dateTo.isBefore(start) || p.dateFrom.isAfter(end)) {
      continue;
    }
    if (from == to) {
      instants[from] = math.max(instants[from] ?? 0, value);
      continue;
    }
    final clippedFrom = math.max(from, start.microsecondsSinceEpoch);
    final clippedTo = math.min(to, end.microsecondsSinceEpoch);
    if (clippedTo > clippedFrom) {
      intervals
          .add((from: clippedFrom, to: clippedTo, rate: value / (to - from)));
    }
  }
  // Event sweep avoids quadratic work for high-frequency tracker records.
  final events = <int, List<({double rate, bool add})>>{};
  for (final i in intervals) {
    (events[i.from] ??= []).add((rate: i.rate, add: true));
    (events[i.to] ??= []).add((rate: i.rate, add: false));
  }
  final times = events.keys.toList()..sort();
  final rates = <double, int>{};
  var total = instants.values.fold(0.0, (a, b) => a + b);
  int? previous;
  for (final time in times) {
    if (previous != null && rates.isNotEmpty) {
      total += (time - previous) * rates.keys.reduce(math.max);
    }
    for (final event in events[time]!) {
      final count = (rates[event.rate] ?? 0) + (event.add ? 1 : -1);
      if (count <= 0) {
        rates.remove(event.rate);
      } else {
        rates[event.rate] = count;
      }
    }
    previous = time;
  }
  return total.clamp(0, maxValue).toDouble();
}
