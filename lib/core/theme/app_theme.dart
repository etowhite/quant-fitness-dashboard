import 'package:flutter/material.dart';
import '../../features/settings/domain/theme_settings.dart';

// Brand colors are reserved for the logo; UI colors come from ColorScheme.
abstract final class AppColors {
  static const background = Color(0xFF121212);
  static const card = Color(0xFF1E1E1E);
  static const green = Color(0xFF00FF87);
  static const cyan = Color(0xFF00E5FF);
  static const text = Color(0xFFF5F5F5);
  static const muted = Color(0xFFB0B0B0);
}

abstract final class AppTheme {
  static ThemeData get dark => build(const ThemeSettings(), Brightness.dark);
  static ThemeData build(ThemeSettings settings, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final palette = settings.palette;
    final primary = dark
        ? palette.primary
        : switch (palette) {
            AccentPalette.cyberNeon => const Color(0xFF00884B),
            AccentPalette.electricViolet => const Color(0xFF6D28D9),
            AccentPalette.sunsetCoral => const Color(0xFFC73647),
            AccentPalette.mintOcean => const Color(0xFF047857),
            AccentPalette.rose => const Color(0xFFA33462),
            AccentPalette.lavender => const Color(0xFF7053A2),
            AccentPalette.sage => const Color(0xFF3F6C4B),
            AccentPalette.ocean => const Color(0xFF0369A1),
            AccentPalette.amber => const Color(0xFF975700),
          };
    final secondary = dark
        ? palette.secondary
        : switch (palette) {
            AccentPalette.cyberNeon => const Color(0xFF007C91),
            AccentPalette.electricViolet => const Color(0xFF0E7490),
            AccentPalette.sunsetCoral => const Color(0xFFA15C00),
            AccentPalette.mintOcean => const Color(0xFF1D4ED8),
            AccentPalette.rose => const Color(0xFF813C79),
            AccentPalette.lavender => const Color(0xFF67568B),
            AccentPalette.sage => const Color(0xFF336D5A),
            AccentPalette.ocean => const Color(0xFF1D4ED8),
            AccentPalette.amber => const Color(0xFFB54708),
          };
    final background = dark
        ? (settings.amoled ? Colors.black : AppColors.background)
        : const Color(0xFFF8FAFC);
    final scheme =
        ColorScheme.fromSeed(seedColor: palette.primary, brightness: brightness)
            .copyWith(
      primary: primary,
      secondary: secondary,
      onPrimary:
          ThemeData.estimateBrightnessForColor(primary) == Brightness.light
              ? const Color(0xFF102118)
              : Colors.white,
      onSecondary:
          ThemeData.estimateBrightnessForColor(secondary) == Brightness.light
              ? const Color(0xFF102118)
              : Colors.white,
      surface: dark ? AppColors.card : Colors.white,
      onSurface: dark ? AppColors.text : const Color(0xFF17212D),
      onSurfaceVariant:
          dark ? const Color(0xFFB9C2CC) : const Color(0xFF4B5868),
      surfaceTint: Colors.transparent,
    );
    final base =
        ThemeData(useMaterial3: true, colorScheme: scheme, fontFamily: 'Inter');
    final text = base.textTheme;
    return base.copyWith(
      scaffoldBackgroundColor: background,
      textTheme: text.copyWith(
          headlineMedium: text.headlineMedium
              ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.6),
          titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
      appBarTheme: AppBarTheme(
          backgroundColor: background,
          foregroundColor: scheme.onSurface,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false),
      cardTheme: base.cardTheme.copyWith(
          color: scheme.surface,
          elevation: 0,
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
      inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: scheme.surfaceContainerHighest.withAlpha(dark ? 90 : 120),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none)),
      navigationBarTheme: NavigationBarThemeData(
          backgroundColor: scheme.surface,
          elevation: 0,
          indicatorColor: primary.withAlpha(35),
          iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
              color: s.contains(WidgetState.selected)
                  ? primary
                  : scheme.onSurfaceVariant))),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: scheme.surface,
          selectedItemColor: primary,
          unselectedItemColor: scheme.onSurfaceVariant,
          type: BottomNavigationBarType.fixed),
      bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: scheme.surface,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)))),
    );
  }
}
