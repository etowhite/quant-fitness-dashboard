import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('offline catalogue has 300+ unique traceable records and all categories',
      () {
    final data =
        jsonDecode(File('assets/data/ru_base_foods.json').readAsStringSync())
            as Map<String, dynamic>;
    final rows = (data['foods'] as List).cast<Map<String, dynamic>>();
    expect(rows.length, greaterThanOrEqualTo(300));
    expect(rows.map((r) => r['id']).toSet().length, rows.length);
    expect(rows.map((r) => r['name']).toSet().length, rows.length);
    expect(rows.map((r) => r['category']).toSet().length,
        greaterThanOrEqualTo(15));
    for (final r in rows) {
      expect((r['name'] as String).length, inInclusiveRange(1, 120));
      expect(r['source'], isNotEmpty);
      for (final key in ['calories', 'proteins', 'fats', 'carbs']) {
        final n = r[key] as num;
        expect(n.isFinite, isTrue);
        expect(n, inInclusiveRange(0, key == 'calories' ? 1000 : 100));
      }
      expect(r['sourceId'] != null || r['ingredients'] is List, isTrue);
    }
  });
}
