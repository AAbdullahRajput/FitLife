// lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';

class AppColors {
  // ── Static fallback (used in const contexts) ──────────────────────────────
  static const Color primary = Color(0xFF00C853);
  static const Color primaryDark = Color(0xFF009624);
  static const Color primaryLight = Color(0xFF5EFC82);

  // ── Background ─────────────────────────────────────────────────────────────
  static const Color background = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF141414);
  static const Color surfaceLight = Color(0xFF1E1E1E);

  // ── Text ───────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textHint = Color(0xFF606060);

  // ── Accent ─────────────────────────────────────────────────────────────────
  static const Color accent = Color(0xFFFF6D00);
  static const Color accentBlue = Color(0xFF2979FF);

  // ── Status ─────────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF00C853);
  static const Color warning = Color(0xFFFFD600);
  static const Color error = Color(0xFFFF1744);

  // ── Border ─────────────────────────────────────────────────────────────────
  static const Color border = Color(0xFF2A2A2A);
  static const Color borderLight = Color(0xFF3A3A3A);

  // ── Dynamic helpers ────────────────────────────────────────────────────────

  /// Returns the currently selected accent color from ThemeProvider.
  /// Use this everywhere instead of [AppColors.primary] so color changes
  /// propagate app-wide.
  static Color of(BuildContext context, {bool listen = true}) {
    return Provider.of<ThemeProvider>(context, listen: listen).safeAccent;
  }

  /// Gradient pair for the current accent.
  static List<Color> gradientOf(BuildContext context, {bool listen = true}) {
    return Provider.of<ThemeProvider>(context, listen: listen).accentGradient;
  }

  /// Returns black or white depending on accent brightness — safe for text
  /// that sits directly on the accent color.
  static Color onAccentOf(BuildContext context, {bool listen = true}) {
    return Provider.of<ThemeProvider>(context, listen: listen).onAccent;
  }

  /// Sidebar tint: very subtle accent wash on the dark sidebar background.
  static Color sidebarOf(BuildContext context, {bool listen = true}) {
    final accent =
        Provider.of<ThemeProvider>(context, listen: listen).accentColor;
    return Color.lerp(const Color(0xFF0D0D0D), accent, 0.06)!;
  }
}