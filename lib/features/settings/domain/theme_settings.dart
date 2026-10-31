import 'package:flutter/material.dart';

enum AccentPalette {
  cyberNeon('Cyber Neon', Color(0xFF00FF87), Color(0xFF00E5FF)),
  electricViolet('Electric Violet', Color(0xFF8B5CF6), Color(0xFF06B6D4)),
  sunsetCoral('Sunset Coral', Color(0xFFFF6B6B), Color(0xFFFFB800)),
  mintOcean('Mint & Ocean', Color(0xFF10B981), Color(0xFF3B82F6));

  const AccentPalette(this.label, this.primary, this.secondary);
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
