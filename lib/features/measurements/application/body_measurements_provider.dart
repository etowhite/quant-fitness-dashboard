import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/database/isar_database_service.dart';
import '../data/body_measurement.dart';

// Watchers also cover writes performed outside this feature's UI.
final bodyMeasurementHistoryProvider =
    StreamProvider.autoDispose<List<BodyMeasurement>>((ref) async* {
  final service = await ref.watch(databaseServiceProvider.future);
  yield* service.watchBodyMeasurementHistory();
});

final latestBodyMeasurementProvider =
    Provider.autoDispose<AsyncValue<BodyMeasurement?>>(
        (ref) => ref.watch(bodyMeasurementHistoryProvider).whenData(
              (history) => history.isEmpty ? null : history.first,
            ));

final bodyMeasurementActionsProvider = Provider((ref) =>
    BodyMeasurementActions(() => ref.read(databaseServiceProvider.future)));

class BodyMeasurementActions {
  BodyMeasurementActions(this._database);
  final Future<IsarDatabaseService> Function() _database;

  Future<void> save(BodyMeasurement measurement) async {
    final service = await _database();
    await service.saveBodyMeasurement(measurement);
  }

  Future<void> delete(int id) async {
    final service = await _database();
    await service.deleteBodyMeasurement(id);
  }
}
