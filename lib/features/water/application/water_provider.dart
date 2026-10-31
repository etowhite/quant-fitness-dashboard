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
