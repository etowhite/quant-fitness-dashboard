import 'package:flutter/material.dart';

enum AccentPalette {
  cyberNeon('Неон', Color(0xFF00FF87), Color(0xFF00E5FF)),
  electricViolet('Electric Violet', Color(0xFF8B5CF6), Color(0xFF06B6D4)),
  sunsetCoral('Sunset Coral', Color(0xFFFF6B6B), Color(0xFFFFB800)),
  mintOcean('Mint & Ocean', Color(0xFF10B981), Color(0xFF3B82F6)),
  rose('Роза', Color(0xFFEE8BAA), Color(0xFFCC6699)),
  lavender('Лаванда', Color(0xFFB4A0E5), Color(0xFF8B7AB8)),
  sage('Шалфей', Color(0xFF9DBB9B), Color(0xFF568D78)),
  ocean('Океан', Color(0xFF38BDF8), Color(0xFF2563EB)),
  amber('Янтарь', Color(0xFFFBBF24), Color(0xFFF97316));

  const AccentPalette(this.label, this.primary, this.secondary);
  // Legacy enum names remain readable in existing backups.
  static const presets = [cyberNeon, rose, lavender, sage, ocean, amber];
  final String label;
  final Color primary, secondary;
}

class ThemeSettings {
  const ThemeSettings(
      {this.mode = ThemeMode.dark,
      this.palette = AccentPalette.cyberNeon,
      this.amoled = false});
  final ThemeMode mode;
  final AccentPalette palette;
  final bool amoled;
  ThemeSettings copyWith(
          {ThemeMode? mode, AccentPalette? palette, bool? amoled}) =>
      ThemeSettings(
          mode: mode ?? this.mode,
          palette: palette ?? this.palette,
          amoled: amoled ?? this.amoled);
  Map<String, dynamic> toJson() =>
      {'mode': mode.name, 'palette': palette.name, 'amoled': amoled};
  factory ThemeSettings.fromJson(Map<String, dynamic> json) {
    final modes = ThemeMode.values.where((v) => v.name == json['mode']);
    final palettes =
        AccentPalette.values.where((v) => v.name == json['palette']);
    if (modes.isEmpty || palettes.isEmpty || json['amoled'] is! bool) {
      throw const FormatException('Некорректное оформление');
    }
    return ThemeSettings(
        mode: modes.first,
        palette: palettes.first,
        amoled: json['amoled'] as bool);
  }
}
