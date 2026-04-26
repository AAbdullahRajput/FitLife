import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/app_data.dart';
import '../../../services/supabase_service.dart';
import '../../workout/workout_screen.dart';
import '../../meals/meals_screen.dart';
import '../../progress/progress_screen.dart';
import '../../profile/profile_screen.dart';
import 'mobile_dashboard.dart';
import 'mobile_bottom_nav.dart';

class MobileHome extends StatefulWidget {
  const MobileHome({super.key});

  @override
  State<MobileHome> createState() => _MobileHomeState();
}

class _MobileHomeState extends State<MobileHome>
    with TickerProviderStateMixin {
  late AnimationController _animController;
  late AnimationController _bgController;
  late Animation<double> _fadeAnim;

  int _selectedTab = 0;
  bool _isLoggedIn = false;
  bool _isLoadingData = false;

  late List<Map<String, dynamic>> _todayWorkouts;
  late List<Map<String, dynamic>> _todayMeals;

  String get _userTier {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return 'guest';
    return 'free';
  }

  @override
  void initState() {
    super.initState();
    _todayWorkouts = AppData.getTodayWorkouts();
    _todayMeals = AppData.getTodayMeals();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _animController.forward();
    _checkLoginStatus();
    _loadFromSupabase();
  }

  Future<void> _checkLoginStatus() async {
    final session = Supabase.instance.client.auth.currentSession;
    setState(() => _isLoggedIn = session != null);
  }

  Future<void> _loadFromSupabase() async {
    setState(() => _isLoadingData = true);
    try {
      final exercises = await SupabaseService.getExercises(tier: 'guest');
      final meals = await SupabaseService.getMeals(tier: 'guest');
      if (!mounted) return;
      setState(() {
        if (exercises.isNotEmpty) {
          _todayWorkouts = exercises.take(4).map((ex) => {
            'name': ex['name'] ?? '',
            'sets': 3,
            'reps': 10,
            'rest': '60s',
            'muscle': ex['muscle'] ?? '',
            'icon': _muscleIcon(ex['muscle'] ?? ''),
            'color': _muscleColor(ex['muscle'] ?? ''),
            'done': false,
            'id': ex['id'],
          }).toList();
        }
        if (meals.isNotEmpty) {
          _todayMeals = [];
          for (final type in ['breakfast', 'lunch', 'snack', 'dinner']) {
            final match = meals.firstWhere(
              (m) => m['type'] == type,
              orElse: () => {},
            );
            if (match.isNotEmpty) {
              _todayMeals.add({
                'meal': _capitalize(match['type'] ?? ''),
                'time': _mealTime(match['type'] ?? ''),
                'items': match['name'] ?? '',
                'calories': match['calories'] ?? 0,
                'icon': _mealIcon(match['type'] ?? ''),
                'color': _mealColor(match['type'] ?? ''),
                'id': match['id'],
              });
            }
          }
        }
        _isLoadingData = false;
      });
    } catch (_) {
      setState(() => _isLoadingData = false);
    }
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  IconData _muscleIcon(String muscle) {
    const map = {
      'Chest': Icons.fitness_center_rounded,
      'Back': Icons.accessibility_new_rounded,
      'Shoulders': Icons.sports_gymnastics_rounded,
      'Legs': Icons.directions_run_rounded,
      'Arms': Icons.sports_handball_rounded,
      'Core': Icons.self_improvement_rounded,
      'Full Body': Icons.sports_martial_arts_rounded,
    };
    return map[muscle] ?? Icons.fitness_center_rounded;
  }

  Color _muscleColor(String muscle) {
    const map = {
      'Chest': Color(0xFF2979FF),
      'Back': Color(0xFF00C853),
      'Shoulders': Color(0xFFFF6D00),
      'Legs': Color(0xFFAA00FF),
      'Arms': Color(0xFFFFD600),
      'Core': Color(0xFFFF1744),
      'Full Body': Color(0xFF00BCD4),
    };
    return map[muscle] ?? const Color(0xFF2979FF);
  }

  String _mealTime(String type) {
    const map = {
      'breakfast': '8:00 AM',
      'lunch': '1:00 PM',
      'snack': '4:00 PM',
      'dinner': '8:00 PM',
    };
    return map[type] ?? '12:00 PM';
  }

  IconData _mealIcon(String type) {
    const map = {
      'breakfast': Icons.free_breakfast_rounded,
      'lunch': Icons.lunch_dining_rounded,
      'snack': Icons.apple_rounded,
      'dinner': Icons.dinner_dining_rounded,
    };
    return map[type] ?? Icons.restaurant_rounded;
  }

  Color _mealColor(String type) {
    const map = {
      'breakfast': Color(0xFFFFD600),
      'lunch': Color(0xFF00C853),
      'snack': Color(0xFFFF6D00),
      'dinner': Color(0xFF2979FF),
    };
    return map[type] ?? const Color(0xFF00C853);
  }

  void _onToggleWorkout(int index, int _) {
    setState(() {
      _todayWorkouts[index]['done'] = !(_todayWorkouts[index]['done'] as bool);
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppColors.of(context);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF050A05) : const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          // ── Animated background (dark mode only) ──────────────────────
          if (isDark)
            AnimatedBuilder(
              animation: _bgController,
              builder: (_, __) => CustomPaint(
                size: MediaQuery.of(context).size,
                painter: _MobileBackgroundPainter(
                  accent: accent,
                  progress: _bgController.value,
                ),
              ),
            ),

          // ── Main content ───────────────────────────────────────────────
          FadeTransition(
            opacity: _fadeAnim,
            child: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: IndexedStack(
                      index: _selectedTab,
                      children: [
                        MobileDashboard(
                          isLoggedIn: _isLoggedIn,
                          isLoadingData: _isLoadingData,
                          todayWorkouts: _todayWorkouts,
                          todayMeals: _todayMeals,
                          onToggleWorkout: _onToggleWorkout,
                        ),
                        WorkoutScreen(userTier: _userTier),
                        MealsScreen(userTier: _userTier),
                        const ProgressScreen(),
                        const ProfileScreen(),
                      ],
                    ),
                  ),
                  MobileBottomNav(
                    selectedTab: _selectedTab,
                    isLoggedIn: _isLoggedIn,
                    onTabTap: (i) => setState(() => _selectedTab = i),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Animated mobile background painter ────────────────────────────────────────
class _MobileBackgroundPainter extends CustomPainter {
  final Color accent;
  final double progress;

  _MobileBackgroundPainter({required this.accent, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Deep dark base
    final bgPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        colors: const [Color(0xFF0D1A0D), Color(0xFF050A05)],
        radius: 1.2,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Animated top-left glow
    final glowOffset1 = Offset(
      size.width * 0.15 + sin(progress * 2 * pi) * 20,
      size.height * 0.1 + cos(progress * 2 * pi) * 15,
    );
    _drawGlow(canvas, glowOffset1, accent, 180, 0.12);

    // Animated bottom-right glow
    final glowOffset2 = Offset(
      size.width * 0.85 + cos(progress * 2 * pi) * 25,
      size.height * 0.8 + sin(progress * 2 * pi) * 20,
    );
    _drawGlow(canvas, glowOffset2, const Color(0xFFAA00FF), 200, 0.09);

    // Subtle grid
    final gridPaint = Paint()
      ..color = accent.withOpacity(0.03)
      ..strokeWidth = 0.6;
    for (int i = 0; i <= 12; i++) {
      final x = size.width * i / 12;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (int i = 0; i <= 20; i++) {
      final y = size.height * i / 20;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Scan lines
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.012)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  void _drawGlow(Canvas canvas, Offset center, Color color, double radius, double opacity) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withOpacity(opacity),
          color.withOpacity(opacity * 0.4),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_MobileBackgroundPainter old) =>
      old.progress != progress || old.accent != accent;
}