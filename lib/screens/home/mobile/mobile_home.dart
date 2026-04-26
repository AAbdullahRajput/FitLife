import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
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

  int  _selectedTab   = 0;
  bool _isLoggedIn    = false;
  bool _isLoadingData = false;

  OverlayEntry? _profileOverlay;

  late List<Map<String, dynamic>> _todayWorkouts;
  late List<Map<String, dynamic>> _todayMeals;

  String get userName => AppData.userName;

  String get _userTier {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return 'guest';
    return 'free';
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _todayWorkouts = AppData.getTodayWorkouts();
    _todayMeals    = AppData.getTodayMeals();

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

  @override
  void dispose() {
    _removeProfileOverlay();
    _animController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  // ── Auth ──────────────────────────────────────────────────────────────────
  Future<void> _checkLoginStatus() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (mounted) setState(() => _isLoggedIn = session != null);
  }

  // ── Supabase data ─────────────────────────────────────────────────────────
  Future<void> _loadFromSupabase() async {
    if (mounted) setState(() => _isLoadingData = true);
    try {
      final exercises = await SupabaseService.getExercises(tier: 'guest');
      final meals     = await SupabaseService.getMeals(tier: 'guest');
      if (!mounted) return;
      setState(() {
        if (exercises.isNotEmpty) {
          _todayWorkouts = exercises.take(4).map((ex) => {
            'name':   ex['name']   ?? '',
            'sets':   3,
            'reps':   10,
            'rest':   '60s',
            'muscle': ex['muscle'] ?? '',
            'icon':   _muscleIcon(ex['muscle']  ?? ''),
            'color':  _muscleColor(ex['muscle'] ?? ''),
            'done':   false,
            'id':     ex['id'],
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
                'meal':     _capitalize(match['type'] ?? ''),
                'time':     _mealTime(match['type']   ?? ''),
                'items':    match['name']     ?? '',
                'calories': match['calories'] ?? 0,
                'icon':     _mealIcon(match['type']  ?? ''),
                'color':    _mealColor(match['type'] ?? ''),
                'id':       match['id'],
              });
            }
          }
        }
        _isLoadingData = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  // ── Workout toggle ────────────────────────────────────────────────────────
  void _onToggleWorkout(int index, int _) {
    setState(() {
      _todayWorkouts[index]['done'] =
          !(_todayWorkouts[index]['done'] as bool);
    });
  }

  // ── Profile dropdown overlay ──────────────────────────────────────────────
  void _openProfileDropdown() {
    _removeProfileOverlay();
    final overlay  = Overlay.of(context);
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final accent   = AppColors.of(context, listen: false);
    final cardColor    = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor  = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);
    final textPrimary  = isDark ? Colors.white : const Color(0xFF0A0A0A);

    _profileOverlay = OverlayEntry(
      builder: (ctx) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _removeProfileOverlay,
        child: Stack(
          children: [
            Positioned.fill(child: Container(color: Colors.transparent)),
            Positioned(
              // Bottom-right anchored (above bottom nav)
              bottom: MediaQuery.of(ctx).padding.bottom + 70,
              right: 12,
              child: Material(
                color: Colors.transparent,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.85, end: 1.0),
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  builder: (c, v, child) => Transform.scale(
                    scale: v,
                    alignment: Alignment.bottomRight,
                    child: child,
                  ),
                  child: Container(
                    width: 210,
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // User header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: accent.withOpacity(0.15),
                                  border: Border.all(
                                      color: accent.withOpacity(0.4)),
                                ),
                                child: Center(
                                  child: Icon(Icons.person_rounded,
                                      size: 20, color: accent),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      userName,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: textPrimary,
                                      ),
                                    ),
                                    Text(
                                      _isLoggedIn ? 'Member' : 'Guest',
                                      style: TextStyle(
                                          fontSize: 11, color: accent),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(height: 1, color: borderColor),
                        _DropdownItem(
                          icon: Icons.person_outline_rounded,
                          label: 'Profile',
                          textColor: textPrimary,
                          isDestructive: false,
                          accent: accent,
                          onTap: () {
                            _removeProfileOverlay();
                            setState(() => _selectedTab = 4);
                          },
                        ),
                        Divider(height: 1, color: borderColor),
                        _DropdownItem(
                          icon: Icons.logout_rounded,
                          label: 'Logout',
                          textColor: const Color(0xFFFF4444),
                          isDestructive: true,
                          accent: accent,
                          onTap: () async {
                            _removeProfileOverlay();
                            await Supabase.instance.client.auth.signOut();
                            if (mounted) {
                              Navigator.pushReplacementNamed(
                                  context, '/login');
                            }
                          },
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    overlay.insert(_profileOverlay!);
  }

  void _removeProfileOverlay() {
    _profileOverlay?.remove();
    _profileOverlay = null;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  IconData _muscleIcon(String muscle) {
    const map = {
      'Chest':     Icons.fitness_center_rounded,
      'Back':      Icons.accessibility_new_rounded,
      'Shoulders': Icons.sports_gymnastics_rounded,
      'Legs':      Icons.directions_run_rounded,
      'Arms':      Icons.sports_handball_rounded,
      'Core':      Icons.self_improvement_rounded,
      'Full Body': Icons.sports_martial_arts_rounded,
    };
    return map[muscle] ?? Icons.fitness_center_rounded;
  }

  Color _muscleColor(String muscle) {
    const map = {
      'Chest':     Color(0xFF2979FF),
      'Back':      Color(0xFF00C853),
      'Shoulders': Color(0xFFFF6D00),
      'Legs':      Color(0xFFAA00FF),
      'Arms':      Color(0xFFFFD600),
      'Core':      Color(0xFFFF1744),
      'Full Body': Color(0xFF00BCD4),
    };
    return map[muscle] ?? const Color(0xFF2979FF);
  }

  String _mealTime(String type) {
    const map = {
      'breakfast': '8:00 AM',
      'lunch':     '1:00 PM',
      'snack':     '4:00 PM',
      'dinner':    '8:00 PM',
    };
    return map[type] ?? '12:00 PM';
  }

  IconData _mealIcon(String type) {
    const map = {
      'breakfast': Icons.free_breakfast_rounded,
      'lunch':     Icons.lunch_dining_rounded,
      'snack':     Icons.apple_rounded,
      'dinner':    Icons.dinner_dining_rounded,
    };
    return map[type] ?? Icons.restaurant_rounded;
  }

  Color _mealColor(String type) {
    const map = {
      'breakfast': Color(0xFFFFD600),
      'lunch':     Color(0xFF00C853),
      'snack':     Color(0xFFFF6D00),
      'dinner':    Color(0xFF2979FF),
    };
    return map[type] ?? const Color(0xFF00C853);
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppColors.of(context);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF050A05) : const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          // ── Animated background (dark mode only) ─────────────────────
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

          // ── Main content ──────────────────────────────────────────────
          FadeTransition(
            opacity: _fadeAnim,
            child: SafeArea(
              child: Column(
                children: [
                  // ── Content area ────────────────────────────────────
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

                  // ── Bottom nav ───────────────────────────────────────
                  MobileBottomNav(
                    selectedTab: _selectedTab,
                    isLoggedIn: _isLoggedIn,
                    onTabTap: (i) {
                      // Profile tab long-press opens dropdown
                      setState(() => _selectedTab = i);
                    },
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

// ═══════════════════════════════════════════════════════════════════════════
// PROFILE DROPDOWN ITEM
// ═══════════════════════════════════════════════════════════════════════════
class _DropdownItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color textColor;
  final bool isDestructive;
  final Color accent;
  final VoidCallback onTap;

  const _DropdownItem({
    required this.icon,
    required this.label,
    required this.textColor,
    required this.isDestructive,
    required this.accent,
    required this.onTap,
  });

  @override
  State<_DropdownItem> createState() => _DropdownItemState();
}

class _DropdownItemState extends State<_DropdownItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        color: _pressed
            ? (widget.isDestructive
                ? const Color(0xFFFF4444).withOpacity(0.09)
                : widget.accent.withOpacity(0.07))
            : Colors.transparent,
        child: Row(
          children: [
            Icon(widget.icon, size: 16, color: widget.textColor),
            const SizedBox(width: 10),
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: widget.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ANIMATED MOBILE BACKGROUND PAINTER
// ═══════════════════════════════════════════════════════════════════════════
class _MobileBackgroundPainter extends CustomPainter {
  final Color accent;
  final double progress;

  _MobileBackgroundPainter({
    required this.accent,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Deep dark base
    final bgPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        colors: const [Color(0xFF0D1A0D), Color(0xFF050A05)],
        radius: 1.2,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Animated top-left accent glow
    final glowOffset1 = Offset(
      size.width  * 0.15 + sin(progress * 2 * pi) * 20,
      size.height * 0.10 + cos(progress * 2 * pi) * 15,
    );
    _drawGlow(canvas, glowOffset1, accent, 180, 0.12);

    // Animated bottom-right purple glow
    final glowOffset2 = Offset(
      size.width  * 0.85 + cos(progress * 2 * pi) * 25,
      size.height * 0.80 + sin(progress * 2 * pi) * 20,
    );
    _drawGlow(canvas, glowOffset2, const Color(0xFFAA00FF), 200, 0.09);

    // Subtle grid
    final gridPaint = Paint()
      ..color       = accent.withOpacity(0.03)
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
      ..color       = Colors.white.withOpacity(0.012)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  void _drawGlow(Canvas canvas, Offset center, Color color,
      double radius, double opacity) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withOpacity(opacity),
          color.withOpacity(opacity * 0.4),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(
          Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_MobileBackgroundPainter old) =>
      old.progress != progress || old.accent != accent;
}