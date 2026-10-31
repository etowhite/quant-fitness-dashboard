import 'package:flutter/widgets.dart';
import '../../../core/localization/app_strings.dart';

double? parseNutritionNumber(String text, {bool positive = false}) {
  final value = double.tryParse(text.trim().replaceAll(',', '.'));
  if (value == null || !value.isFinite || (positive ? value <= 0 : value < 0)) {
    return null;
  }
  return value;
}

String? validateNutritionNumber(String? text,
    {bool positive = false, double? max}) {
  final value = parseNutritionNumber(text ?? '', positive: positive);
  if (value == null) {
    return positive ? 'Введите число больше нуля' : 'Введите число от нуля';
  }
  if (max != null && value > max) return 'Максимум: ${max.toStringAsFixed(0)}';
  return null;
}

String? validateLocalizedNumber(BuildContext context, String? text,
    {bool positive = false, double? max}) {
  final error = validateNutritionNumber(text, positive: positive, max: max);
  return error == null ? null : context.tr(error);
}
