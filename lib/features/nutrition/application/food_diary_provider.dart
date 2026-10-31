import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/database/local_day.dart';
import '../data/food_log_entry.dart';
import '../data/food_product.dart';
import 'daily_food_diary.dart';

final _foodDiaryFamily = AsyncNotifierProvider.autoDispose
    .family<FoodDiaryNotifier, DailyFoodDiary, DateTime>(FoodDiaryNotifier.new);

// All timestamps belonging to one local day share one family instance.
AutoDisposeFamilyAsyncNotifierProvider<FoodDiaryNotifier, DailyFoodDiary,
    DateTime> foodDiaryProvider(
        DateTime date) =>
    _foodDiaryFamily(localDay(date));

class FoodDiaryNotifier
    extends AutoDisposeFamilyAsyncNotifier<DailyFoodDiary, DateTime> {
  @override
  Future<DailyFoodDiary> build(DateTime arg) async {
    final first = Completer<DailyFoodDiary>();
    var active = true;
    StreamSubscription<List<FoodLogEntry>>? subscription;
    ref.onDispose(() {
      active = false;
      final current = subscription;
      if (current != null) unawaited(current.cancel());
    });
    final service = await ref.watch(databaseServiceProvider.future);
    if (!active) {
      throw StateError('Diary provider disposed during initialization');
    }
    subscription = service.watchFoodLogEntriesForDay(arg).listen((entries) {
      if (!active) return;
      final diary = DailyFoodDiary(entries);
      if (!first.isCompleted) {
        first.complete(diary);
      } else {
        state = AsyncData(diary);
      }
    }, onError: (Object error, StackTrace stack) {
      if (!active) return;
      if (!first.isCompleted) {
        first.completeError(error, stack);
      } else {
        state = AsyncError(error, stack);
      }
    });
    return first.future;
  }

  Future<void> addEntry(FoodLogEntry entry) async {
    if (localDay(entry.date) != localDay(arg)) {
      throw ArgumentError('Дата записи не совпадает с датой дневника');
    }
    final service = await ref.read(databaseServiceProvider.future);
    await service.addFoodLogEntry(entry);
  }

  Future<void> addProduct(
      FoodProduct product, double weightGrams, String mealType) async {
    final service = await ref.read(databaseServiceProvider.future);
    await service.addProductToDiary(
        product: product,
        date: arg,
        mealType: mealType,
        weightGrams: weightGrams);
  }

  Future<void> deleteEntry(int id) async {
    final service = await ref.read(databaseServiceProvider.future);
    await service.deleteFoodLogEntry(id);
  }
}
