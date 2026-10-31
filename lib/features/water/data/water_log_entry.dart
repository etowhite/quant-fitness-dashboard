import 'package:isar_community/isar.dart';

part 'water_log_entry.g.dart';

@Collection(accessor: 'waterLogEntries')
class WaterLogEntry {
  Id? id;
  @Index()
  late DateTime date;
  late int volumeMl;
  late DateTime recordedAt;
}
