import 'package:flutter/material.dart';

import '../../features/ordering/models/branding.dart';

/// Turns whatever [Branding] the Dashboard provides into light and dark
/// ThemeData. The same screens/widgets render correctly for any set of
/// brand colors and either brightness — only the seed color and a handful
/// of surface tones change.
class AppTheme {
  static ThemeData light(Branding branding) => _build(
        branding: branding,
        brightness: Brightness.light,
        scaffoldBackground: branding.backgroundColor,
        cardColor: Colors.white,
        dividerColor: Colors.black12,
        appBarForeground: Colors.black87,
        secondaryTextColor: Colors.black54,
      );

  static ThemeData dark(Branding branding) => _build(
        branding: branding,
        brightness: Brightness.dark,
        scaffoldBackground: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        dividerColor: Colors.white24,
        appBarForeground: Colors.white,
        secondaryTextColor: Colors.white70,
      );

  static ThemeData _build({
    required Branding branding,
    required Brightness brightness,
    required Color scaffoldBackground,
    required Color cardColor,
    required Color dividerColor,
    required Color appBarForeground,
    required Color secondaryTextColor,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: branding.primaryColor,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackground,
      cardColor: cardColor,
      dividerColor: dividerColor,
      fontFamily: branding.fontFamily,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBackground,
        foregroundColor: appBarForeground,
        elevation: 0,
        centerTitle: false,
      ),
      textTheme: TextTheme(
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: colorScheme.onSurface,
        ),
        titleLarge: TextStyle(fontWeight: FontWeight.w700, color: colorScheme.onSurface),
        bodyMedium: TextStyle(color: secondaryTextColor, height: 1.4),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? colorScheme.primary : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? colorScheme.primary.withValues(alpha: 0.5) : null,
        ),
      ),
    );
  }
}
