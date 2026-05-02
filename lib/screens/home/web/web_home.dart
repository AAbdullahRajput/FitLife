import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/app_data.dart';
import '../../../services/supabase_service.dart';
import '../../workout/workout_screen.dart';
import '../../meals/meals_screen.dart';
import '../../progress/progress_screen.dart';
import '../../profile/profile_screen.dart';
import '../../settings/settings_screen.dart';
import '../../workout/exercises/chest/chest_screen.dart';
import 'web_top_nav.dart';
import 'web_sidebar.dart';
import 'web_dashboard.dart';
import 'web_background.dart';
import 'web_cursor_effects.dart';
import '../../../services/storage_service.dart';

class WebHome extends StatefulWidget {
  const WebHome({super.key});

  @override
  State<WebHome> createState() => _WebHomeState();
}

class _WebHomeState extends State<WebHome>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  String _webSection = 'Dashboard';
  bool _isLoggedIn = false;
  bool _isLoadingData = false;
  bool _sidebarExpanded = false;
  Widget? _activeExerciseScreen;
  Offset _cursorPosition = const Offset(0.5, 0.5);

  OverlayEntry? _tooltipOverlay;

  late List<Map<String, dynamic>> _todayWorkouts;
  late List<Map<String, dynamic>> _todayMeals;

  String get userName => AppData.userName;
  String? _profilePhotoUrl;

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
    _animController.forward();
    _checkLoginStatus();
    _loadFromSupabase();
    _loadProfilePhoto();
  }

  Future<void> _loadProfilePhoto() async {
    try {
      final url = await StorageService.getProfilePhoto();
      if (mounted) setState(() => _profilePhotoUrl = url);
    } catch (_) {}
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

  // ── Helpers ─────────────────────────────────────────────────────────────
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

  // ── Profile dropdown ─────────────────────────────────────────────────────
  void _openProfileDropdown() {
    final overlay = Overlay.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final accent = AppColors.of(context, listen: false);

    OverlayEntry? entry;
    entry = OverlayEntry(
      builder: (ctx) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => entry?.remove(),
        child: Stack(
          children: [
            Positioned.fill(child: Container(color: Colors.transparent)),
            Positioned(
              top: 68,
              right: 12,
              child: Material(
                color: Colors.transparent,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.85, end: 1.0),
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeOut,
                  builder: (c, v, child) => Transform.scale(
                    scale: v,
                    alignment: Alignment.topRight,
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
                        // ── User header ──────────────────────────────
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(14, 14, 14, 10),
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
                                child: ClipOval(
                                  child: _profilePhotoUrl != null
                                      ? Image.network(
                                          _profilePhotoUrl!,
                                          fit: BoxFit.cover,
                                          width: 38,
                                          height: 38,
                                          errorBuilder: (_, __, ___) => Center(
                                            child: Icon(Icons.person_rounded,
                                                size: 20, color: accent),
                                          ),
                                        )
                                      : Center(
                                          child: Icon(Icons.person_rounded,
                                              size: 20, color: accent),
                                        ),
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
                            entry?.remove();
                            setState(() => _webSection = 'Profile');
                          },
                        ),
                        _DropdownItem(
                          icon: Icons.settings_outlined,
                          label: 'Settings',
                          textColor: textPrimary,
                          isDestructive: false,
                          accent: accent,
                          onTap: () {
                            entry?.remove();
                            setState(() => _webSection = 'Settings');
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
                            entry?.remove();
                            await Supabase.instance.client.auth.signOut();
                            if (context.mounted) {
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
    overlay.insert(entry);
  }

  // ── Tooltip ──────────────────────────────────────────────────────────────
  void _showTooltip(
    BuildContext context,
    String title,
    String message,
    IconData icon,
    Color color,
  ) {
    _removeTooltip();
    final overlay = Overlay.of(context);
    _tooltipOverlay = OverlayEntry(
      builder: (context) => Positioned(
        left: 0,
        right: 0,
        top: MediaQuery.of(context).size.height * 0.35,
        child: IgnorePointer(
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutBack,
                builder: (c, v, child) =>
                    Transform.scale(scale: v, child: child),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 280),
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withOpacity(0.4)),
                    boxShadow: [
                      BoxShadow(
                          color: color.withOpacity(0.2), blurRadius: 20),
                      const BoxShadow(
                        color: Colors.black54,
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color.withOpacity(0.15),
                            ),
                            child: Icon(icon, size: 14, color: color),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        message,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(_tooltipOverlay!);
    Future.delayed(const Duration(milliseconds: 2500), _removeTooltip);
  }

  void _removeTooltip() {
    _tooltipOverlay?.remove();
    _tooltipOverlay = null;
  }

  @override
  void dispose() {
    _removeTooltip();
    _animController.dispose();
    super.dispose();
  }

  // ── Section content ──────────────────────────────────────────────────────
  Widget _buildContent() {
    switch (_webSection) {
      case 'Workouts':
        return WorkoutScreen(
          userTier: _userTier,
          onNavigateToSection: (s) => setState(() => _webSection = s),
        );
      case 'Chest':
        return ChestScreen(
          userTier: _userTier,
          onBack: () => setState(() => _webSection = 'Workouts'),
          onNavigateTo: (screen) => setState(() {
            _activeExerciseScreen = screen;
            _webSection = 'ExerciseDetail';
          }),
        );
      case 'ExerciseDetail':
        return _activeExerciseScreen ?? const SizedBox();
      case 'Diet Plan':
        return MealsScreen(userTier: _userTier);
      case 'Progress':
        return const ProgressScreen();
      case 'Profile':
        return const ProfileScreen();
      case 'Settings':
        return const SettingsScreen();
      default:
        return WebDashboard(
          isLoggedIn: _isLoggedIn,
          isLoadingData: _isLoadingData,
          todayWorkouts: _todayWorkouts,
          todayMeals: _todayMeals,
          onNavigate: (s) => setState(() => _webSection = s),
          onWorkoutToggle: (index) => setState(
            () => _todayWorkouts[index]['done'] =
                !(_todayWorkouts[index]['done'] as bool),
          ),
          onShowTooltip: _showTooltip,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF0F2F5);

    return Scaffold(
      backgroundColor: bgColor,
      body: Listener(
        onPointerHover: (e) {
          final size = MediaQuery.of(context).size;
          setState(() => _cursorPosition = Offset(
                e.localPosition.dx / size.width,
                e.localPosition.dy / size.height,
              ));
        },
        child: WebCursorEffects(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Stack(
              children: [
                // ── Dark animated background ─────────────────────────
                if (isDark) WebBackground(cursor: _cursorPosition),

                // ── Main layout ──────────────────────────────────────
                Column(
                  children: [
                    // ── Top nav ──────────────────────────────────────
                    WebTopNav(
                      isLoggedIn: _isLoggedIn,
                      profilePhotoUrl: _profilePhotoUrl,
                      sidebarExpanded: _sidebarExpanded,
                      webSection: _webSection,
                      onNavigate: (s) => setState(() => _webSection = s),
                      onToggleSidebar: () => setState(
                          () => _sidebarExpanded = !_sidebarExpanded),
                      onToggleTheme: () {
                        // Wire to your ThemeProvider toggle here
                        // e.g. context.read<ThemeProvider>().toggleTheme();
                      },
                      onLogin: () =>
                          Navigator.pushNamed(context, '/login'),
                      onLogout: _openProfileDropdown,
                    ),

                    // ── Body row ─────────────────────────────────────
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Sidebar ──────────────────────────────
                          if (_sidebarExpanded)
                            WebSidebar(
                            isLoggedIn: _isLoggedIn,
                            webSection: _webSection,
                            userName: userName,
                            profilePhotoUrl: _profilePhotoUrl,
                            onSectionTap: (s) =>
                                setState(() => _webSection = s),
                            onJoinFreeTap: () => Navigator.pushNamed(
                                context, '/register'),
                          ),

                          // ── Main content ─────────────────────────
                          Expanded(child: _buildContent()),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DROPDOWN ITEM
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
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          color: _hovered
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
      ),
    );
  }
}