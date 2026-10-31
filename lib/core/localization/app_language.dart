import 'package:flutter/material.dart';

enum AppLanguage {
  system,
  ru,
  en;

  Locale? get locale => this == system ? null : Locale(name);
  static AppLanguage parse(Object? value) {
    if (value == null) return AppLanguage.system;
    return values.firstWhere((v) => v.name == value,
        orElse: () => throw const FormatException('Invalid language'));
  }
}
