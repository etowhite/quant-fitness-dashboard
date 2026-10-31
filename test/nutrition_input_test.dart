import 'package:flutter_test/flutter_test.dart';
import 'package:smart_fitness_dashboard/features/nutrition/presentation/nutrition_input.dart';

void main() {
  test('accepts decimal comma, dot and zero macros', () {
    expect(parseNutritionNumber(' 150,5 ', positive: true), 150.5);
    expect(parseNutritionNumber('2.5'), 2.5);
    expect(validateNutritionNumber('0'), isNull);
  });
  test('rejects finite values exceeding a configured bound', () {
    expect(validateNutritionNumber('1001', max: 1000), isNotNull);
    expect(validateNutritionNumber('1000', max: 1000), isNull);
  });
  test('rejects zero portions, negative, missing and non-finite values', () {
    expect(validateNutritionNumber('0', positive: true), isNotNull);
    for (final value in ['', '-1', 'NaN', 'Infinity', '1e999', 'еда']) {
      expect(validateNutritionNumber(value), isNotNull, reason: value);
    }
  });
}
