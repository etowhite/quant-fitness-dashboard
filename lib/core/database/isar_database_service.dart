import 'dart:async';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/measurements/data/body_measurement.dart';
import '../../features/nutrition/data/food_log_entry.dart';
import '../../features/nutrition/data/food_product.dart';
import 'food_seed.dart';
import 'local_day.dart';
import 'widget_operation.dart';
import '../validation/input_limits.dart';
import '../../features/water/data/water_log_entry.dart';

class IsarDatabaseService {
  IsarDatabaseService._(this.isar);
  final Isar isar;

  // Call once through the provider. Optional directory/name isolate test DBs.
  static Future<IsarDatabaseService> init(
      {String? directory, String name = 'smart_fitness'}) async {
    final path = directory ?? (await getApplicationDocumentsDirectory()).path;
    final isar = await Isar.open(
      [
        BodyMeasurementSchema,
        FoodProductSchema,
        FoodLogEntrySchema,
        WaterLogEntrySchema,
        WidgetOperationSchema,
      ],
      directory: path,
      name: name,
      inspector: false,
    );
    final service = IsarDatabaseService._(isar);
    try {
      final catalogue = await loadBaseFoodProducts();
      await isar.writeTxn(() async {
        final existing = await isar.foodProducts.where().findAll();
        final keys =
            existing.map((p) => p.catalogueKey).whereType<String>().toSet();
        final names = existing.map((p) => p.name.toLowerCase()).toSet();
        for (final product in catalogue) {
          // Additive migration: never overwrite custom or previously edited rows.
          if (!keys.contains(product.catalogueKey) &&
              !names.contains(product.name.toLowerCase())) {
            await isar.foodProducts.put(product);
            names.add(product.name.toLowerCase());
          }
        }
      });
      return service;
    } catch (_) {
      await isar.close();
      rethrow;
    }
  }

  static const mealTypes = {'Завтрак', 'Обед', 'Ужин', 'Перекус'};

  Future<Id> addFoodLogEntry(FoodLogEntry entry) async {
    if (!mealTypes.contains(entry.mealType)) {
      throw ArgumentError.value(entry.mealType, 'mealType');
    }
    _name(entry.productName);
    _positive(entry.weightGrams, 'weightGrams');
    if (entry.weightGrams > InputLimits.portionGrams) {
      throw ArgumentError('Слишком большая порция');
    }
    _macros(entry.calories, entry.proteins, entry.fats, entry.carbs);
    if ([entry.calories, entry.proteins, entry.fats, entry.carbs]
        .any((v) => v > 100000)) {
      throw ArgumentError('Превышен предел значений порции');
    }
    if (entry.id != null) {
      throw ArgumentError('Для новой записи id должен быть null');
    }
    entry.productName = entry.productName.trim();
    entry.date = entry.date.toLocal();
    return isar.writeTxn(() => isar.foodLogEntries.put(entry));
  }

  // Builds a snapshot: later edits to the catalog cannot change past totals.
  Future<Id> addProductToDiary(
      {required FoodProduct product,
      required DateTime date,
      required String mealType,
      required double weightGrams}) {
    final factor = weightGrams / 100;
    return addFoodLogEntry(FoodLogEntry()
      ..date = date
      ..mealType = mealType
      ..productName = product.name
      ..weightGrams = weightGrams
      ..calories = product.calories * factor
      ..proteins = product.proteins * factor
      ..fats = product.fats * factor
      ..carbs = product.carbs * factor);
  }

  Future<bool> deleteFoodLogEntry(Id id) =>
      isar.writeTxn(() => isar.foodLogEntries.delete(id));

  QueryBuilder<FoodLogEntry, FoodLogEntry, QAfterWhereClause> _dayQuery(
          DateTime date) =>
      isar.foodLogEntries
          .where()
          .dateBetween(localDay(date), nextLocalDay(date), includeUpper: false);

  Future<List<FoodLogEntry>> getFoodLogEntriesForDay(DateTime date) =>
      _dayQuery(date).findAll();

  Stream<List<FoodLogEntry>> watchFoodLogEntriesForDay(DateTime date) =>
      _dayQuery(date).watch(fireImmediately: true);

  Future<List<FoodProduct>> searchProducts(String query, {int limit = 20}) {
    if (limit <= 0) throw ArgumentError.value(limit, 'limit');
    final prefix = query.trim();
    // Value index, case-insensitive prefix autocomplete, not a full scan.
    return isar.foodProducts
        .where()
        .nameStartsWith(prefix)
        .limit(limit)
        .findAll();
  }

  Stream<List<FoodProduct>> watchProducts(String query, {int limit = 30}) {
    if (limit <= 0) throw ArgumentError.value(limit, 'limit');
    return isar.foodProducts
        .where()
        .nameStartsWith(query.trim())
        .limit(limit)
        .watch(fireImmediately: true);
  }

  Future<Id> saveCustomProduct(FoodProduct product) {
    _name(product.name);
    _macros(product.calories, product.proteins, product.fats, product.carbs);
    if (product.calories > InputLimits.caloriesPer100g ||
        [product.proteins, product.fats, product.carbs]
            .any((v) => v > InputLimits.macroPer100g)) {
      throw ArgumentError('Превышен предел КБЖУ на 100 г');
    }
    product.name = product.name.trim();
    return isar.writeTxn(() => isar.foodProducts.put(product));
  }

  Future<Id> saveBodyMeasurement(BodyMeasurement measurement) async {
    for (final value in [
      measurement.chest,
      measurement.waist,
      measurement.hips,
      measurement.biceps
    ]) {
      if (value != null) {
        _positive(value, 'measurement');
        if (value > InputLimits.circumferenceCm) {
          throw ArgumentError('Слишком большой объем');
        }
      }
    }
    if ((measurement.note?.length ?? 0) > InputLimits.note) {
      throw ArgumentError('Слишком длинная заметка');
    }
    measurement.date = localDay(measurement.date);
    return isar.writeTxn(() async {
      final existing = await isar.bodyMeasurements
          .where()
          .dateEqualTo(measurement.date)
          .findFirst();
      // The day, rather than an incoming object's id, determines the record.
      measurement.id = existing?.id;
      return isar.bodyMeasurements.put(measurement);
    });
  }

  Future<List<BodyMeasurement>> getBodyMeasurementHistory() =>
      isar.bodyMeasurements.where(sort: Sort.desc).anyDate().findAll();

  Future<BodyMeasurement?> getLatestBodyMeasurement() =>
      isar.bodyMeasurements.where(sort: Sort.desc).anyDate().findFirst();

  Future<bool> deleteBodyMeasurement(Id id) =>
      isar.writeTxn(() => isar.bodyMeasurements.delete(id));

  Future<BodyMeasurement?> getBodyMeasurementForDay(DateTime date) =>
      isar.bodyMeasurements.where().dateEqualTo(localDay(date)).findFirst();

  Stream<List<BodyMeasurement>> watchBodyMeasurementHistory() =>
      isar.bodyMeasurements
          .where(sort: Sort.desc)
          .anyDate()
          .watch(fireImmediately: true);

  Future<bool> close() => isar.close();

  Future<void> applyWidgetWater(String requestId, int? volume,
      {DateTime? now}) async {
    if (requestId.isEmpty ||
        requestId.length > 100 ||
        (volume != null && ![100, 250, 500].contains(volume))) {
      throw ArgumentError('Invalid widget operation');
    }
    final timestamp = now ?? DateTime.now();
    final day = localDay(timestamp);
    await isar.writeTxn(() async {
      if (await isar.widgetOperations
              .where()
              .requestIdEqualTo(requestId)
              .findFirst() !=
          null) {
        return;
      }
      if (volume != null) {
        final rows =
            await isar.waterLogEntries.where().dateEqualTo(day).findAll();
        if (rows.fold<int>(0, (sum, r) => sum + r.volumeMl) + volume >
            InputLimits.waterDailyMl) {
          throw ArgumentError('Daily water limit exceeded');
        }
        await isar.waterLogEntries.put(WaterLogEntry()
          ..date = day
          ..volumeMl = volume
          ..recordedAt = timestamp);
      } else {
        final rows =
            await isar.waterLogEntries.where().dateEqualTo(day).findAll();
        rows.sort((a, b) {
          final time = a.recordedAt.compareTo(b.recordedAt);
          return time == 0 ? (a.id ?? 0).compareTo(b.id ?? 0) : time;
        });
        if (rows.isNotEmpty) await isar.waterLogEntries.delete(rows.last.id!);
      }
      await isar.widgetOperations.put(WidgetOperation()
        ..requestId = requestId
        ..recordedAt = timestamp);
    });
  }

  /// Read both collections in one snapshot. Normalize timestamps to local days.
  Future<Set<DateTime>> getRecordedDiaryDates() => isar.txn(() async => {
        ...await isar.foodLogEntries.where().dateProperty().findAll(),
        ...await isar.waterLogEntries.where().dateProperty().findAll(),
      }.map(localDay).toSet());

  Stream<Set<DateTime>> watchRecordedDiaryDates() {
    late StreamController<Set<DateTime>> output;
    StreamSubscription<void>? food;
    StreamSubscription<void>? water;
    var active = true;
    var pending = Future<void>.value();
    void refresh([void _]) {
      pending = pending.then((_) async {
        if (!active) return;
        try {
          final dates = await getRecordedDiaryDates();
          if (active) output.add(dates);
        } catch (error, stack) {
          if (active) output.addError(error, stack);
        }
      });
    }

    output = StreamController<Set<DateTime>>(
      onListen: () {
        food = isar.foodLogEntries
            .watchLazy()
            .listen(refresh, onError: output.addError);
        water = isar.waterLogEntries
            .watchLazy()
            .listen(refresh, onError: output.addError);
        refresh();
      },
      onCancel: () async {
        active = false;
        await food?.cancel();
        await water?.cancel();
      },
    );
    return output.stream;
  }

  Stream<List<WaterLogEntry>> watchWater(DateTime date) => isar.waterLogEntries
      .where()
      .dateEqualTo(localDay(date))
      .watch(fireImmediately: true);

  Future<Id> addWater(DateTime date, int volumeMl) => isar.writeTxn(() async {
        if (volumeMl <= 0 || volumeMl > InputLimits.waterPortionMl) {
          throw ArgumentError(
              'Порция воды должна быть от 1 до ${InputLimits.waterPortionMl} мл');
        }
        final day = localDay(date);
        final rows =
            await isar.waterLogEntries.where().dateEqualTo(day).findAll();
        final total = rows.fold<int>(0, (sum, row) => sum + row.volumeMl);
        if (total + volumeMl > InputLimits.waterDailyMl) {
          throw ArgumentError('Превышен предел записей за день');
        }
        return isar.waterLogEntries.put(WaterLogEntry()
          ..date = day
          ..volumeMl = volumeMl
          ..recordedAt = DateTime.now());
      });

  Future<bool> undoWater(DateTime date) => isar.writeTxn(() async {
        final rows = await isar.waterLogEntries
            .where()
            .dateEqualTo(localDay(date))
            .findAll();
        rows.sort((a, b) {
          final time = a.recordedAt.compareTo(b.recordedAt);
          return time != 0 ? time : a.id!.compareTo(b.id!);
        });
        return rows.isNotEmpty &&
            await isar.waterLogEntries.delete(rows.last.id!);
      });

  Future<FoodProduct> cacheOnlineProduct(FoodProduct product) async {
    final code = product.barcode;
    if (code == null || !RegExp(r'^\d{8,14}$').hasMatch(code)) {
      throw ArgumentError('Некорректный штрихкод');
    }
    return isar.writeTxn(() async {
      final existing =
          await isar.foodProducts.where().barcodeEqualTo(code).findFirst();
      if (existing != null) return existing;
      _name(product.name);
      _macros(product.calories, product.proteins, product.fats, product.carbs);
      if (product.calories > InputLimits.caloriesPer100g ||
          [product.proteins, product.fats, product.carbs]
              .any((n) => n > InputLimits.macroPer100g)) {
        throw ArgumentError('Недопустимое КБЖУ');
      }
      await isar.foodProducts.put(product);
      return product;
    });
  }

  static void _positive(double value, String name) {
    if (!value.isFinite || value <= 0) throw ArgumentError.value(value, name);
  }

  static void _name(String name) {
    if (name.trim().isEmpty || name.trim().length > InputLimits.productName) {
      throw ArgumentError(
          'Название должно содержать 1–${InputLimits.productName} символов');
    }
  }

  static void _macros(
      double calories, double proteins, double fats, double carbs) {
    for (final value in [calories, proteins, fats, carbs]) {
      if (!value.isFinite || value < 0) {
        throw ArgumentError('Некорректное КБЖУ');
      }
    }
  }
}
