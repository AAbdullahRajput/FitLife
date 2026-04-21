// lib/core/theme/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Accent palette ────────────────────────────────────────────────────────────
const List<Color> kAccentColors = [
  Color(0xFF00C853), // Green (default)
  Color(0xFF2979FF), // Blue
  Color(0xFFFF6D00), // Orange
  Color(0xFFAA00FF), // Purple
  Color(0xFFFF1744), // Red
  Color(0xFF00BCD4), // Cyan
  Color(0xFFFFD600), // Yellow
  Color(0xFFE91E63), // Pink
  Color(0xFF009688), // Teal
  Color(0xFFB76E79), // Rose Gold
];

// ── Gradient pairs per accent ─────────────────────────────────────────────────
const Map<int, List<Color>> kAccentGradients = {
  0: [Color(0xFF5EFC82), Color(0xFF00C853)], // Green
  1: [Color(0xFF64B5F6), Color(0xFF1565C0)], // Blue
  2: [Color(0xFFFFB74D), Color(0xFFE65100)], // Orange
  3: [Color(0xFFCE93D8), Color(0xFF6A1B9A)], // Purple
  4: [Color(0xFFFF6B6B), Color(0xFFD50000)], // Red
  5: [Color(0xFF80DEEA), Color(0xFF00838F)], // Cyan
  6: [Color(0xFFFFF176), Color(0xFFF9A825)], // Yellow
  7: [Color(0xFFF48FB1), Color(0xFFAD1457)], // Pink
  8: [Color(0xFF80CBC4), Color(0xFF00695C)], // Teal
  9: [Color(0xFFE8A0A8), Color(0xFF8B4A52)], // Rose Gold
};

class ThemeProvider extends ChangeNotifier {
  bool _isDark = true;
  int _accentIndex = 0;

  bool get isDark => _isDark;
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  Color get accentColor => kAccentColors[_accentIndex];
  int get accentIndex => _accentIndex;
  List<Color> get accentGradient =>
      kAccentGradients[_accentIndex] ?? kAccentGradients[0]!;

  /// Returns a darker shade of accent for light-mode legibility on
  /// problematic colors (yellow, cyan).
  Color get safeAccent {
    if (!_isDark && (_accentIndex == 6 || _accentIndex == 5)) {
      // Yellow → darker gold | Cyan → deeper teal
      return _accentIndex == 6
          ? const Color(0xFFF9A825)
          : const Color(0xFF00838F);
    }
    return accentColor;
  }

  /// Text/icon color that sits ON TOP of the accent (contrast-safe).
  Color get onAccent {
    final brightness = ThemeData.estimateBrightnessForColor(accentColor);
    return brightness == Brightness.light ? Colors.black : Colors.white;
  }

  ThemeProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool('isDark') ?? true;
    _accentIndex = prefs.getInt('accentIndex') ?? 0;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDark = !_isDark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', _isDark);
  }

  Future<void> setAccent(int index) async {
    if (index < 0 || index >= kAccentColors.length) return;
    _accentIndex = index;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('accentIndex', index);
  }
}