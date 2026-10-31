import 'package:isar_community/isar.dart';

part 'food_log_entry.g.dart';

@Collection(accessor: 'foodLogEntries')
class FoodLogEntry {
  Id? id;

  @Index()
  late DateTime date;

  late String mealType;
  // Snapshot, intentionally independent of future product edits/deletions.
  late String productName;
  late double weightGrams;
  // Totals for this portion, not per 100 g.
  late double calories;
  late double proteins;
  late double fats;
  late double carbs;
}
