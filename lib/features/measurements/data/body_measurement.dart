import 'package:isar_community/isar.dart';

part 'body_measurement.g.dart';

@collection
class BodyMeasurement {
  // Isar 3 recognizes Id as the primary key; no @id annotation exists.
  Id? id;

  // Normalized to local midnight by the service: one record per day.
  @Index(unique: true, replace: true)
  late DateTime date;

  double? weight;
  double? bodyFat;
  double? chest;
  double? waist;
  double? hips;
  double? biceps;
  String? note;
}
