import 'dart:convert';
import 'dart:io';
import 'package:smart_fitness_dashboard/features/nutrition/domain/hydration.dart';

void main() {
  final file = File('assets/data/ru_base_foods.json');
  final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  for (final row in data['foods'] as List) {
    row['waterPercentage'] = Hydration.detect(row['name'] as String);
  }
  file.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(data)}\n');
}
