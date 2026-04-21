// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  /// Call this from MaterialApp passing the current accent color so that
  /// Material widgets (Switch, Slider, LinearProgressIndicator, etc.) all
  /// pick up the chosen accent automatically.
  static ThemeData darkTheme({Color accent = AppColors.primary}) {
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.dark,
    ).copyWith(
      primary: accent,
      secondary: accent,
      surface: AppColors.surface,
      error: AppColors.error,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF050A05),
      primaryColor: accent,
      // Switches, sliders, checkboxes inherit from colorScheme.primary ✓
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF050A05),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: AppColors.textPrimary, fontSize: 16),
        bodyMedium: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        bodySmall: TextStyle(color: AppColors.textHint, fontSize: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: _onColor(accent),
          minimumSize: const Size(double.infinity, 54),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: const TextStyle(color: AppColors.textHint),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent, width: 2),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: accent,
        unselectedItemColor: AppColors.textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: accent),
      sliderTheme: SliderThemeData(
        activeTrackColor: accent,
        thumbColor: accent,
        overlayColor: accent.withOpacity(0.15),
        inactiveTrackColor: accent.withOpacity(0.2),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? accent : null),
        trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? accent.withOpacity(0.4)
                : null),
      ),
    );
  }

  static ThemeData lightTheme({Color accent = AppColors.primary}) {
    // For light-mode legibility, darken yellow/cyan.
    final safeAccent = _safeAccentForLight(accent);

    final scheme = ColorScheme.fromSeed(
      seedColor: safeAccent,
      brightness: Brightness.light,
    ).copyWith(
      primary: safeAccent,
      secondary: safeAccent,
      surface: Colors.white,
      error: AppColors.error,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      primaryColor: safeAccent,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF5F5F5),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Color(0xFF0A0A0A),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: Color(0xFF0A0A0A)),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
            color: Color(0xFF0A0A0A),
            fontSize: 28,
            fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(
            color: Color(0xFF0A0A0A),
            fontSize: 22,
            fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(
            color: Color(0xFF0A0A0A),
            fontSize: 18,
            fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: Color(0xFF0A0A0A), fontSize: 16),
        bodyMedium: TextStyle(color: Color(0xFF444444), fontSize: 14),
        bodySmall: TextStyle(color: Color(0xFF888888), fontSize: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: safeAccent,
          foregroundColor: _onColor(safeAccent),
          minimumSize: const Size(double.infinity, 54),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(color: Color(0xFF888888)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: safeAccent, width: 2),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: safeAccent,
        unselectedItemColor: const Color(0xFF888888),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: safeAccent),
      sliderTheme: SliderThemeData(
        activeTrackColor: safeAccent,
        thumbColor: safeAccent,
        overlayColor: safeAccent.withOpacity(0.15),
        inactiveTrackColor: safeAccent.withOpacity(0.2),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? safeAccent : null),
        trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? safeAccent.withOpacity(0.4)
                : null),
      ),
    );
  }

  // ── Internal helpers ────────────────────────────────────────────────────────

  /// Returns black or white depending on the brightness of [color].
  static Color _onColor(Color color) {
    return ThemeData.estimateBrightnessForColor(color) == Brightness.light
        ? Colors.black
        : Colors.white;
  }

  /// In light mode, yellow and cyan are hard to read — darken them.
  static Color _safeAccentForLight(Color color) {
    if (color == const Color(0xFFFFD600)) return const Color(0xFFF9A825);
    if (color == const Color(0xFF00BCD4)) return const Color(0xFF00838F);
    return color;
  }
}