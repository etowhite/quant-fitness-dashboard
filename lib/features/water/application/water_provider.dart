import '../../nutrition/application/food_diary_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/local_day.dart';
import '../data/water_log_entry.dart';

final _waterFamily = StreamProvider.autoDispose
    .family<List<WaterLogEntry>, DateTime>((ref, day) async* {
  final db = await ref.watch(databaseServiceProvider.future);
  yield* db.watchWater(day);
});
AutoDisposeStreamProvider<List<WaterLogEntry>> waterProvider(DateTime day) =>
    _waterFamily(localDay(day));

class DailyHydration {
  const DailyHydration({required this.manualMl, required this.foodMl});
  final int manualMl;
  final double foodMl;
  double get totalMl => manualMl + foodMl;
}

final _hydrationFamily = Provider.autoDispose
    .family<AsyncValue<DailyHydration>, DateTime>((ref, day) {
  final water = ref.watch(waterProvider(day));
  final food = ref.watch(foodDiaryProvider(day));
  if (water.hasError) return AsyncError(water.error!, water.stackTrace!);
  if (food.hasError) return AsyncError(food.error!, food.stackTrace!);
  final rows = water.valueOrNull;
  final diary = food.valueOrNull;
  if (rows == null || diary == null) return const AsyncLoading();
  return AsyncData(DailyHydration(
      manualMl: rows.fold<int>(0, (sum, row) => sum + row.volumeMl),
      foodMl: diary.waterMl));
});
AutoDisposeProvider<AsyncValue<DailyHydration>> dailyHydrationProvider(
        DateTime day) =>
    _hydrationFamily(localDay(day));
