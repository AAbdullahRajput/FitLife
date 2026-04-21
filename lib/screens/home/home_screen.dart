import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/helpers.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/data/app_data.dart';
import '../../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../workout/workout_screen.dart';
import '../meals/meals_screen.dart';
import '../progress/progress_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  int _selectedTab = 0;
  String _webSection = 'Dashboard';
  bool _isLoggedIn = false;
  bool _isLoadingData = false;

  // ── Sidebar collapsed/expanded ──────────────────────────────────────────────
  bool _sidebarExpanded = false;

  // ── Profile dropdown ─────────────────────────────────────────────────────────
  bool _showProfileDropdown = false;
  OverlayEntry? _profileDropdownOverlay;

  // ── Hover states (instant — plain setState, no AnimatedContainer) ────────────
  String? _hoveredSidebarItem;
  String? _hoveredNavLink;

  // ── Tooltip overlay ──────────────────────────────────────────────────────────
  OverlayEntry? _tooltipOverlay;

  late List<Map<String, dynamic>> _todayWorkouts;
  late List<Map<String, dynamic>> _todayMeals;

  String get userName => AppData.userName;
  double get userWeight => AppData.userWeight;
  double get userHeight => AppData.userHeight;
  int get userAge => AppData.userAge;
  String get userGoal => AppData.userGoal;

  int get completedWorkouts =>
      _todayWorkouts.where((w) => w['done'] == true).length;

  int get totalCalories =>
      _todayMeals.fold(0, (sum, m) => sum + (m['calories'] as int));

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

  // ── Profile dropdown ─────────────────────────────────────────────────────────
  void _toggleProfileDropdown(BuildContext context) {
    if (_showProfileDropdown) {
      _removeProfileDropdown();
      setState(() => _showProfileDropdown = false);
    } else {
      setState(() => _showProfileDropdown = true);
      _openProfileDropdown(context);
    }
  }

  void _openProfileDropdown(BuildContext context) {
    final overlay = Overlay.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);

    _profileDropdownOverlay = OverlayEntry(
      builder: (ctx) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          _removeProfileDropdown();
          setState(() => _showProfileDropdown = false);
        },
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
                  builder: (c, v, child) =>
                      Transform.scale(scale: v, alignment: Alignment.topRight, child: child),
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
                        // Header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary.withOpacity(0.15),
                                  border: Border.all(
                                      color: AppColors.primary.withOpacity(0.4)),
                                ),
                                child: const Center(
                                    child: Icon(Icons.person_rounded,
                                        size: 20, color: AppColors.primary)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(userName,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: textPrimary)),
                                    Text(
                                      _isLoggedIn ? 'Member' : 'Guest',
                                      style: const TextStyle(
                                          fontSize: 11, color: AppColors.primary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(height: 1, color: borderColor),
                        _DropdownItemHover(
                          icon: Icons.person_outline_rounded,
                          label: 'Profile',
                          textColor: textPrimary,
                          isDestructive: false,
                          onTap: () {
                            _removeProfileDropdown();
                            setState(() {
                              _showProfileDropdown = false;
                              _webSection = 'Profile';
                            });
                          },
                        ),
                        _DropdownItemHover(
                          icon: Icons.settings_outlined,
                          label: 'Settings',
                          textColor: textPrimary,
                          isDestructive: false,
                          onTap: () {
                            _removeProfileDropdown();
                            setState(() {
                              _showProfileDropdown = false;
                              _webSection = 'Settings';
                            });
                          },
                        ),
                        Divider(height: 1, color: borderColor),
                        _DropdownItemHover(
                          icon: Icons.logout_rounded,
                          label: 'Logout',
                          textColor: const Color(0xFFFF4444),
                          isDestructive: true,
                          onTap: () async {
                            _removeProfileDropdown();
                            setState(() => _showProfileDropdown = false);
                            await Supabase.instance.client.auth.signOut();
                            if (mounted) {
                              Navigator.pushReplacementNamed(context, '/login');
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
    overlay.insert(_profileDropdownOverlay!);
  }

  void _removeProfileDropdown() {
    _profileDropdownOverlay?.remove();
    _profileDropdownOverlay = null;
  }

  // ── Tooltip ──────────────────────────────────────────────────────────────────
  void _showTooltip(BuildContext context, String title, String message,
      IconData icon, Color color) {
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
                      BoxShadow(color: color.withOpacity(0.2), blurRadius: 20),
                      const BoxShadow(
                          color: Colors.black54,
                          blurRadius: 12,
                          offset: Offset(0, 4)),
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
                                color: color.withOpacity(0.15)),
                            child: Icon(icon, size: 14, color: color),
                          ),
                          const SizedBox(width: 8),
                          Text(title,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: color)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 12, color: Colors.white.withOpacity(0.5)),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(message,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.8),
                                    height: 1.4)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: color.withOpacity(0.12),
                          border: Border.all(color: color.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.touch_app_rounded,
                                size: 10, color: color),
                            const SizedBox(width: 4),
                            Text('Long press to toggle complete',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: color,
                                    fontWeight: FontWeight.w600)),
                          ],
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
    _removeProfileDropdown();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (kIsWeb) return _buildWebLayout(isDark);
    return _buildMobileLayout(isDark);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WEB LAYOUT
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildWebLayout(bool isDark) {
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final textSecondary =
        isDark ? const Color(0xFFB0B0B0) : const Color(0xFF555555);
    final bgColor = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF0F2F5);
    final cardColor = isDark ? const Color(0xFF141414) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);
    final sidebarColor =
        isDark ? const Color(0xFF0D0D0D) : const Color(0xFF1A1A2E);

    return Scaffold(
      backgroundColor: bgColor,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Column(
          children: [
            _buildWebTopNav(isDark, textPrimary, cardColor, borderColor),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_sidebarExpanded) _buildWebSidebar(isDark, sidebarColor),
                  Expanded(
                    child: _buildWebContent(
                        isDark, textPrimary, textSecondary, cardColor, borderColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebContent(bool isDark, Color textPrimary, Color textSecondary,
      Color cardColor, Color borderColor) {
    switch (_webSection) {
      case 'Workouts':
        return WorkoutScreen(userTier: _userTier);
      case 'Diet Plan':
        return MealsScreen(userTier: _userTier);
      case 'Progress':
        return const ProgressScreen();
      case 'Profile':
        return const ProfileScreen();
      case 'Settings':
      return const SettingsScreen();
      default:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWebWelcomeBanner(
                      isDark, textPrimary, textSecondary, cardColor, borderColor),
                  const SizedBox(height: 24),
                  _buildWebStatsGrid(isDark, textPrimary, cardColor),
                  const SizedBox(height: 24),
                  if (!_isLoggedIn) ...[
                    _buildWebUnlockBanner(isDark, textPrimary, textSecondary),
                    const SizedBox(height: 24),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildWebWorkoutCard(
                            isDark, textPrimary, textSecondary, cardColor, borderColor),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 2,
                        child: _buildWebDietCard(
                            isDark, textPrimary, textSecondary, cardColor, borderColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (!_isLoggedIn)
                    _buildWebLockedSection(
                        isDark, textPrimary, textSecondary, cardColor, borderColor),
                ],
              ),
            ),
          ),
        );
    }
  }

  // ── TOP NAV ──────────────────────────────────────────────────────────────────
  Widget _buildWebTopNav(
      bool isDark, Color textPrimary, Color cardColor, Color borderColor) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          // ── Hamburger ─────────────────────────────────────────────────────
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => setState(() => _sidebarExpanded = !_sidebarExpanded),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.primary.withOpacity(0.08),
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                      _sidebarExpanded
                          ? Icons.close_rounded
                          : Icons.menu_rounded,
                      key: ValueKey(_sidebarExpanded),
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // ── Logo → Dashboard ──────────────────────────────────────────────
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => setState(() => _webSection = 'Dashboard'),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(0.15),
                      border:
                          Border.all(color: AppColors.primary.withOpacity(0.4)),
                    ),
                    child: const Center(
                        child: Icon(Icons.fitness_center_rounded,
                            size: 16, color: AppColors.primary)),
                  ),
                  const SizedBox(width: 10),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF5EFC82), Color(0xFF00C853)],
                    ).createShader(bounds),
                    child: const Text(
                      'FitLife',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          // ── Nav links ─────────────────────────────────────────────────────
          if (_isLoggedIn) ...[
            _buildNavLink('Dashboard', _webSection == 'Dashboard', textPrimary),
            const SizedBox(width: 4),
            _buildNavLink('Workouts', _webSection == 'Workouts', textPrimary),
            const SizedBox(width: 4),
            _buildNavLink('Diet', _webSection == 'Diet Plan', textPrimary),
            const SizedBox(width: 4),
            _buildNavLink('Progress', _webSection == 'Progress', textPrimary),
            const SizedBox(width: 16),
          ],
          // ── Theme toggle ──────────────────────────────────────────────────
          Consumer<ThemeProvider>(
            builder: (context, theme, _) => MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () =>
                    Provider.of<ThemeProvider>(context, listen: false)
                        .toggleTheme(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withOpacity(0.1),
                    border:
                        Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Center(
                    child: Icon(
                      theme.isDark
                          ? Icons.wb_sunny_rounded
                          : Icons.dark_mode_rounded,
                      size: 17,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          if (!_isLoggedIn) ...[
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/login'),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.primary.withOpacity(0.4)),
                  ),
                  child: const Text('Sign In',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/register'),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: const LinearGradient(
                        colors: [Color(0xFF5EFC82), Color(0xFF00C853)]),
                  ),
                  child: const Text('Get Started Free',
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ] else ...[
            // ── Profile avatar → dropdown ────────────────────────────────────
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => _toggleProfileDropdown(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _showProfileDropdown
                        ? AppColors.primary.withOpacity(0.28)
                        : AppColors.primary.withOpacity(0.15),
                    border: Border.all(
                      color: _showProfileDropdown
                          ? AppColors.primary
                          : AppColors.primary.withOpacity(0.4),
                      width: _showProfileDropdown ? 2 : 1.5,
                    ),
                  ),
                  child: const Center(
                      child: Icon(Icons.person_rounded,
                          size: 18, color: AppColors.primary)),
                ),
              ),
            ),
          ],
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  // ── Nav link — NO AnimatedContainer, instant color change ───────────────────
  Widget _buildNavLink(String label, bool isActive, Color textPrimary) {
    final isHovered = _hoveredNavLink == label;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoveredNavLink = label),
      onExit: (_) => setState(() => _hoveredNavLink = null),
      child: GestureDetector(
        onTap: () => setState(() {
          if (label == 'Dashboard') _webSection = 'Dashboard';
          else if (label == 'Workouts') _webSection = 'Workouts';
          else if (label == 'Diet') _webSection = 'Diet Plan';
          else if (label == 'Progress') _webSection = 'Progress';
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isActive
                ? AppColors.primary.withOpacity(0.15)
                : isHovered
                    ? AppColors.primary.withOpacity(0.09)
                    : Colors.transparent,
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive || isHovered
                      ? AppColors.primary
                      : textPrimary.withOpacity(0.6))),
        ),
      ),
    );
  }

  // ── COLLAPSIBLE SIDEBAR — 60px icons-only / 220px full ──────────────────────
  Widget _buildWebSidebar(bool isDark, Color sidebarColor) {
    final items = _isLoggedIn
        ? [
            {'icon': Icons.dashboard_rounded, 'label': 'Dashboard', 'locked': false},
            {'icon': Icons.fitness_center_rounded, 'label': 'Workouts', 'locked': false},
            {'icon': Icons.restaurant_rounded, 'label': 'Diet Plan', 'locked': false},
            {'icon': Icons.bar_chart_rounded, 'label': 'Progress', 'locked': false},
            {'icon': Icons.notifications_rounded, 'label': 'Reminders', 'locked': false},
            {'icon': Icons.person_rounded, 'label': 'Profile', 'locked': false},
            {'icon': Icons.settings_rounded, 'label': 'Settings', 'locked': false},
          ]
        : [
            {'icon': Icons.dashboard_rounded, 'label': 'Dashboard', 'locked': false},
            {'icon': Icons.lock_rounded, 'label': 'Workouts', 'locked': true},
            {'icon': Icons.lock_rounded, 'label': 'Diet Plan', 'locked': true},
            {'icon': Icons.lock_rounded, 'label': 'Progress', 'locked': true},
          ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      width: 220,
      color: sidebarColor,
      child: Column(
        children: [
          const SizedBox(height: 18),
          // ── User avatar ────────────────────────────────────────────────────
          Padding(
  padding: const EdgeInsets.symmetric(horizontal: 14),
  child: Row(
    children: [
      Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary.withOpacity(0.2),
          border: Border.all(
              color: AppColors.primary.withOpacity(0.5)),
        ),
        child: const Center(
            child: Icon(Icons.person_rounded,
                size: 17, color: AppColors.primary)),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(userName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            Row(
              children: [
                Icon(
                  _isLoggedIn
                      ? Icons.verified_rounded
                      : Icons.person_outline_rounded,
                  size: 10,
                  color: _isLoggedIn
                      ? AppColors.primary
                      : Colors.white.withOpacity(0.4),
                ),
                const SizedBox(width: 3),
                Text(
                  _isLoggedIn ? 'Member' : 'Guest',
                  style: TextStyle(
                      fontSize: 10,
                      color: _isLoggedIn
                          ? AppColors.primary
                          : Colors.white.withOpacity(0.4)),
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  ),
),
          const SizedBox(height: 14),
          Divider(color: Colors.white.withOpacity(0.08), height: 1),
          const SizedBox(height: 10),
          // ── Items ──────────────────────────────────────────────────────────
          ...items.map((item) {
            final label = item['label'] as String;
            final isLocked = item['locked'] as bool;
            final isActive = label == _webSection;
            final isHovered = _hoveredSidebarItem == label && !isLocked;

            final iconColor = isActive
                ? AppColors.primary
                : isHovered
                    ? AppColors.primary.withOpacity(0.85)
                    : isLocked
                        ? Colors.white.withOpacity(0.18)
                        : Colors.white.withOpacity(0.5);

            final textColor = isActive
                ? AppColors.primary
                : isHovered
                    ? AppColors.primary.withOpacity(0.9)
                    : isLocked
                        ? Colors.white.withOpacity(0.18)
                        : Colors.white.withOpacity(0.6);

            final bgColor = isActive
                ? AppColors.primary.withOpacity(0.18)
                : isHovered
                    ? AppColors.primary.withOpacity(0.10)
                    : Colors.transparent;

            return Tooltip(
              // Show label as tooltip when collapsed
              message: _sidebarExpanded ? '' : label,
              preferBelow: false,
              waitDuration: Duration.zero,
              decoration: BoxDecoration(
                color: const Color(0xFF222222),
                borderRadius: BorderRadius.circular(6),
              ),
              textStyle:
                  const TextStyle(color: Colors.white, fontSize: 12),
              child: MouseRegion(
                // Immediate cursor + hover
                cursor: isLocked
                    ? SystemMouseCursors.forbidden
                    : SystemMouseCursors.click,
                onEnter: (_) {
                  if (!isLocked) setState(() => _hoveredSidebarItem = label);
                },
                onExit: (_) => setState(() => _hoveredSidebarItem = null),
                child: GestureDetector(
                  onTap: isLocked
                      ? null
                      : () => setState(() => _webSection = label),
                  child: Container(
                    // Plain Container — color is instant (no AnimatedContainer)
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: bgColor,
                    ),
                    child: Row(
  children: [
    const SizedBox(width: 2),
    Icon(item['icon'] as IconData,
        size: 18, color: iconColor),
    const SizedBox(width: 12),
    Expanded(
      child: Text(label,
          style: TextStyle(
              fontSize: 13,
              fontWeight: isActive
                  ? FontWeight.w700
                  : FontWeight.w400,
              color: textColor)),
    ),
    if (isLocked)
      Icon(Icons.lock_outline_rounded,
          size: 13,
          color: Colors.white.withOpacity(0.2)),
    if (isActive && !isLocked)
      Container(
        width: 5,
        height: 5,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary,
        ),
      ),
  ],
),
                  ),
                ),
              ),
            );
          }),
          const Spacer(),
          if (!_isLoggedIn && _sidebarExpanded)
            Padding(
              padding: const EdgeInsets.all(12),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/register'),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: const LinearGradient(
                          colors: [Color(0xFF5EFC82), Color(0xFF00C853)]),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.auto_awesome_rounded,
                            size: 14, color: Colors.black),
                        SizedBox(width: 6),
                        Text('Join Free',
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 13,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── remaining widget builders (unchanged from previous version) ──────────────

  Widget _buildWebWelcomeBanner(bool isDark, Color textPrimary,
      Color textSecondary, Color cardColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF0D2010), const Color(0xFF0A1A0A)]
              : [const Color(0xFFE8F5E9), const Color(0xFFF1F8E9)],
        ),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${Helpers.getGreeting()}, $userName!',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: textPrimary)),
                const SizedBox(height: 6),
                Text("Here's your fitness overview for today",
                    style: TextStyle(fontSize: 14, color: textSecondary)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildWebBadge(
                        userGoal, Icons.flag_rounded, AppColors.primary),
                    _buildWebBadge(
                      'BMI ${Helpers.calculateBMI(userWeight, userHeight).toStringAsFixed(1)} · ${Helpers.getBMICategory(Helpers.calculateBMI(userWeight, userHeight))}',
                      Icons.monitor_heart_rounded,
                      const Color(0xFF2979FF),
                    ),
                    _buildWebBadge(
                      '$completedWorkouts/${_todayWorkouts.length} workouts done',
                      Icons.check_circle_rounded,
                      const Color(0xFFFF6D00),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.1),
              border: Border.all(
                  color: AppColors.primary.withOpacity(0.3), width: 2),
            ),
            child: const Center(
                child: Icon(Icons.fitness_center_rounded,
                    size: 36, color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildWebBadge(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withOpacity(0.12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 5),
          Text(text,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildWebStatsGrid(bool isDark, Color textPrimary, Color cardColor) {
    final stats = [
      {'label': 'Weight', 'value': '${userWeight}kg', 'icon': Icons.monitor_weight_rounded, 'color': const Color(0xFF2979FF)},
      {'label': 'Height', 'value': '${userHeight}cm', 'icon': Icons.height_rounded, 'color': const Color(0xFFFF6D00)},
      {'label': 'Age', 'value': '$userAge yrs', 'icon': Icons.cake_rounded, 'color': const Color(0xFFAA00FF)},
      {'label': 'Daily Calories', 'value': '$totalCalories kcal', 'icon': Icons.local_fire_department_rounded, 'color': const Color(0xFFFFD600)},
      {'label': 'BMI', 'value': Helpers.calculateBMI(userWeight, userHeight).toStringAsFixed(1), 'icon': Icons.analytics_rounded, 'color': AppColors.primary},
      {'label': 'Workouts', 'value': '$completedWorkouts/${_todayWorkouts.length}', 'icon': Icons.fitness_center_rounded, 'color': const Color(0xFF00C853)},
    ];
    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.2,
      children: stats.map((stat) {
        final color = stat['color'] as Color;
        final icon = stat['icon'] as IconData;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: cardColor,
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    shape: BoxShape.circle, color: color.withOpacity(0.1)),
                child: Center(child: Icon(icon, size: 20, color: color)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(stat['value'] as String,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: color)),
                    Text(stat['label'] as String,
                        style: TextStyle(
                            fontSize: 11,
                            color: textPrimary.withOpacity(0.5))),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWebUnlockBanner(
      bool isDark, Color textPrimary, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0D1F0D), const Color(0xFF111A11)]
              : [const Color(0xFFE8F5E9), const Color(0xFFF1F8E9)],
        ),
        border: Border.all(
            color: AppColors.primary.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('FREE PLAN',
                          style: TextStyle(
                              fontSize: 10,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1)),
                    ),
                    const SizedBox(width: 10),
                    Row(
                      children: [
                        const Icon(Icons.lock_open_rounded,
                            size: 14, color: AppColors.primary),
                        const SizedBox(width: 5),
                        Text("You're using the free plan — unlock more!",
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: textPrimary)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 16,
                  children: [
                    _buildWebFeatureChip('Cloud sync', textSecondary),
                    _buildWebFeatureChip('50+ exercises', textSecondary),
                    _buildWebFeatureChip('Advanced diet', textSecondary),
                    _buildWebFeatureChip('Analytics', textSecondary),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Row(
            children: [
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/login'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.primary.withOpacity(0.4)),
                    ),
                    child: const Text('Sign In',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/register'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: const LinearGradient(
                          colors: [Color(0xFF5EFC82), Color(0xFF00C853)]),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.auto_awesome_rounded,
                            size: 14, color: Colors.black),
                        SizedBox(width: 6),
                        Text('Create Free Account',
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 13,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWebFeatureChip(String text, Color textSecondary) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle_rounded,
            size: 13, color: AppColors.primary),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: textSecondary)),
      ],
    );
  }

  Widget _buildWebWorkoutCard(bool isDark, Color textPrimary,
      Color textSecondary, Color cardColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: cardColor,
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.fitness_center_rounded,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text("Today's Workout",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textPrimary)),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: AppColors.primary.withOpacity(0.1),
                ),
                child: Text('$completedWorkouts/${_todayWorkouts.length} done',
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(Helpers.formatDate(DateTime.now()),
              style: TextStyle(fontSize: 12, color: textSecondary)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: AppColors.primary.withOpacity(0.06),
              border:
                  Border.all(color: AppColors.primary.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                Icon(Icons.touch_app_rounded,
                    size: 13, color: AppColors.primary.withOpacity(0.7)),
                const SizedBox(width: 6),
                Text(
                  'Tap to view details · Long press to mark as complete ✓',
                  style: TextStyle(
                      fontSize: 11,
                      color: textSecondary,
                      fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ..._todayWorkouts.asMap().entries.map((entry) {
            final index = entry.key;
            final workout = entry.value;
            final color = workout['color'] as Color;
            final isDone = workout['done'] as bool;
            final icon =
                workout['icon'] as IconData? ?? Icons.fitness_center_rounded;
            return MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/exercise-detail',
                    arguments: workout),
                onLongPress: () {
                  setState(() => _todayWorkouts[index]['done'] = !isDone);
                  _showTooltip(
                    context,
                    isDone ? 'Marked Incomplete' : 'Workout Complete! 🎉',
                    isDone
                        ? '${workout['name']} has been unchecked.'
                        : '${workout['name']} marked as done. Great job!',
                    isDone
                        ? Icons.remove_circle_outline_rounded
                        : Icons.check_circle_rounded,
                    color,
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isDone
                        ? color.withOpacity(0.08)
                        : (isDark
                            ? const Color(0xFF1A1A1A)
                            : const Color(0xFFF8F8F8)),
                    border: Border.all(
                        color:
                            isDone ? color.withOpacity(0.4) : borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color.withOpacity(0.12)),
                        child: Center(
                            child: Icon(icon, size: 18, color: color)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(workout['name'] as String,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isDone ? color : textPrimary,
                                    decoration: isDone
                                        ? TextDecoration.lineThrough
                                        : null)),
                            Text(
                                '${workout['sets']} sets × ${workout['reps']} reps • Rest ${workout['rest']}',
                                style: TextStyle(
                                    fontSize: 11, color: textSecondary)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: color.withOpacity(0.1)),
                        child: Text(workout['muscle'] as String,
                            style: TextStyle(
                                fontSize: 10,
                                color: color,
                                fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 10),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDone ? color : Colors.transparent,
                          border: Border.all(
                              color: isDone ? color : borderColor, width: 2),
                        ),
                        child: isDone
                            ? const Icon(Icons.check,
                                size: 12, color: Colors.white)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWebDietCard(bool isDark, Color textPrimary,
      Color textSecondary, Color cardColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: cardColor,
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.restaurant_rounded,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text("Today's Meals",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textPrimary)),
                ],
              ),
              Text('$totalCalories kcal',
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Daily nutrition plan',
              style: TextStyle(fontSize: 12, color: textSecondary)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Calories consumed',
                  style: TextStyle(fontSize: 11, color: textSecondary)),
              Text('$totalCalories / 2000 kcal',
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: totalCalories / 2000,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 16),
          ..._todayMeals.map((meal) {
            final color = meal['color'] as Color;
            final icon =
                meal['icon'] as IconData? ?? Icons.restaurant_rounded;
            return MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/meal-detail',
                    arguments: meal),
                onLongPress: () => _showTooltip(
                  context,
                  meal['meal'] as String,
                  '${meal['items']} · ${meal['calories']} kcal · ${meal['time']}',
                  icon,
                  color,
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isDark
                        ? const Color(0xFF1A1A1A)
                        : const Color(0xFFF8F8F8),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color.withOpacity(0.12)),
                        child: Center(
                            child: Icon(icon, size: 16, color: color)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(meal['meal'] as String,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary)),
                            Text(meal['items'] as String,
                                style: TextStyle(
                                    fontSize: 10, color: textSecondary)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${meal['calories']} kcal',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: color)),
                          Text(meal['time'] as String,
                              style: TextStyle(
                                  fontSize: 10, color: textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWebLockedSection(bool isDark, Color textPrimary,
      Color textSecondary, Color cardColor, Color borderColor) {
    final features = [
      {'icon': Icons.fitness_center_rounded, 'title': 'Full Exercise Library', 'desc': '200+ exercises with video demos', 'color': const Color(0xFF2979FF)},
      {'icon': Icons.restaurant_menu_rounded, 'title': 'Advanced Diet Plans', 'desc': 'AI-generated meal plans', 'color': const Color(0xFF00C853)},
      {'icon': Icons.insights_rounded, 'title': 'Progress Analytics', 'desc': 'Charts and insights over time', 'color': const Color(0xFFFF6D00)},
      {'icon': Icons.cloud_sync_rounded, 'title': 'Cloud Backup', 'desc': 'Never lose your data', 'color': const Color(0xFFAA00FF)},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.lock_rounded,
                size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text('Unlock Premium Features',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textPrimary)),
          ],
        ),
        const SizedBox(height: 4),
        Text('Create a free account to unlock these features',
            style: TextStyle(fontSize: 13, color: textSecondary)),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 4,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.6,
          children: features.map((f) {
            final color = f['color'] as Color;
            final icon = f['icon'] as IconData;
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: cardColor,
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(9),
                        color: color.withOpacity(0.12)),
                    child:
                        Center(child: Icon(icon, size: 18, color: color)),
                  ),
                  const SizedBox(height: 8),
                  Text(f['title'] as String,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: textPrimary)),
                  Text(f['desc'] as String,
                      style: TextStyle(fontSize: 10, color: textSecondary)),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Center(
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/register'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 40, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                      colors: [Color(0xFF5EFC82), Color(0xFF00C853)]),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8))
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.rocket_launch_rounded,
                        size: 16, color: Colors.black),
                    SizedBox(width: 8),
                    Text('Create Your Free Account Now',
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MOBILE LAYOUT
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildMobileDashboard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final textSecondary =
        isDark ? const Color(0xFFB0B0B0) : const Color(0xFF555555);
    final cardColor = isDark ? const Color(0xFF141414) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMobileHeader(isDark, textPrimary, textSecondary),
          const SizedBox(height: 20),
          _buildMobileStatsRow(textPrimary),
          const SizedBox(height: 16),
          if (!_isLoggedIn) ...[
            _buildMobileUnlockBanner(isDark, textPrimary, textSecondary),
            const SizedBox(height: 20),
          ],
          if (_isLoadingData)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(
                    color: AppColors.primary, strokeWidth: 2.5),
              ),
            )
          else ...[
            _buildSectionTitle(
                "Today's Workout",
                "$completedWorkouts/${_todayWorkouts.length} done",
                textPrimary,
                Icons.fitness_center_rounded),
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: AppColors.primary.withOpacity(0.06),
                border:
                    Border.all(color: AppColors.primary.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  Icon(Icons.touch_app_rounded,
                      size: 13, color: AppColors.primary.withOpacity(0.7)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Long press any workout to mark it as complete ✓',
                      style: TextStyle(
                          fontSize: 11,
                          color: textSecondary,
                          fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildMobileWorkoutList(
                cardColor, borderColor, textPrimary, textSecondary),
            const SizedBox(height: 20),
            _buildSectionTitle("Today's Meals", "$totalCalories kcal",
                textPrimary, Icons.restaurant_rounded),
            const SizedBox(height: 12),
            _buildMobileMealList(
                cardColor, borderColor, textPrimary, textSecondary),
            if (!_isLoggedIn) ...[
              const SizedBox(height: 20),
              _buildMobileLockedSection(isDark, textPrimary, textSecondary),
            ],
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  Widget _buildMobileLayout(bool isDark) {
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final bgColor =
        isDark ? const Color(0xFF050A05) : const Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: bgColor,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: IndexedStack(
                  index: _selectedTab,
                  children: [
                    _buildMobileDashboard(),
                    WorkoutScreen(userTier: _userTier),
                    MealsScreen(userTier: _userTier),
                    const ProgressScreen(),
                    const ProfileScreen(),
                  ],
                ),
              ),
              _buildMobileBottomNav(isDark, textPrimary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileHeader(
      bool isDark, Color textPrimary, Color textSecondary) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(Helpers.getGreeting(),
                  style: TextStyle(fontSize: 13, color: textSecondary)),
              const SizedBox(height: 4),
              Text(userName,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: textPrimary)),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: AppColors.primary.withOpacity(0.12),
                  border:
                      Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.flag_rounded,
                        size: 11, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(userGoal,
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.15),
                border: Border.all(
                    color: AppColors.primary.withOpacity(0.4), width: 2),
              ),
              child: const Center(
                  child: Icon(Icons.person_rounded,
                      size: 22, color: AppColors.primary)),
            ),
            const SizedBox(height: 4),
            Text(
              'BMI ${Helpers.calculateBMI(userWeight, userHeight).toStringAsFixed(1)}',
              style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(width: 8),
        Consumer<ThemeProvider>(
          builder: (context, theme, _) => GestureDetector(
            onTap: () => Provider.of<ThemeProvider>(context, listen: false)
                .toggleTheme(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.12),
                border:
                    Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Center(
                child: Icon(
                  theme.isDark
                      ? Icons.wb_sunny_rounded
                      : Icons.dark_mode_rounded,
                  size: 17,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileStatsRow(Color textPrimary) {
    final stats = [
      {'label': 'Weight', 'value': '${userWeight}kg', 'icon': Icons.monitor_weight_rounded, 'color': const Color(0xFF2979FF)},
      {'label': 'Height', 'value': '${userHeight}cm', 'icon': Icons.height_rounded, 'color': const Color(0xFFFF6D00)},
      {'label': 'Age', 'value': '${userAge}yrs', 'icon': Icons.cake_rounded, 'color': const Color(0xFFAA00FF)},
      {'label': 'Calories', 'value': '$totalCalories', 'icon': Icons.local_fire_department_rounded, 'color': const Color(0xFFFFD600)},
    ];
    return Row(
      children: stats.asMap().entries.map((entry) {
        final i = entry.key;
        final stat = entry.value;
        final color = stat['color'] as Color;
        final icon = stat['icon'] as IconData;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < stats.length - 1 ? 8 : 0),
            padding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: color.withOpacity(0.08),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(height: 4),
                Text(stat['value'] as String,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: color)),
                const SizedBox(height: 2),
                Text(stat['label'] as String,
                    style: TextStyle(
                        fontSize: 9, color: textPrimary.withOpacity(0.4))),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMobileUnlockBanner(
      bool isDark, Color textPrimary, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? const Color(0xFF0D1F0D) : const Color(0xFFE8F5E9),
        border: Border.all(
            color: AppColors.primary.withOpacity(0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('FREE PLAN',
                    style: TextStyle(
                        fontSize: 10,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1)),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  const Icon(Icons.lock_open_rounded,
                      size: 13, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text('Unlock More',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: textPrimary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _buildFeatureChip('Cloud sync', textSecondary),
              _buildFeatureChip('50+ exercises', textSecondary),
              _buildFeatureChip('Diet plans', textSecondary),
              _buildFeatureChip('Analytics', textSecondary),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Flexible(
                flex: 3,
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/register'),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: const LinearGradient(
                          colors: [Color(0xFF5EFC82), Color(0xFF00C853)]),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.auto_awesome_rounded,
                            size: 14, color: Colors.black),
                        SizedBox(width: 6),
                        Text('Create Free Account',
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 13,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/login'),
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.primary.withOpacity(0.5)),
                  ),
                  child: const Center(
                      child: Text('Sign In',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600))),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(String text, Color textSecondary) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle_rounded,
            size: 12, color: AppColors.primary),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 11, color: textSecondary)),
      ],
    );
  }

  Widget _buildMobileLockedSection(
      bool isDark, Color textPrimary, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? const Color(0xFF141414) : Colors.white,
        border: Border.all(
            color: isDark
                ? const Color(0xFF2A2A2A)
                : const Color(0xFFE0E0E0)),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: AppColors.primary.withOpacity(0.1),
            ),
            child: const Center(
                child: Icon(Icons.lock_rounded,
                    size: 24, color: AppColors.primary)),
          ),
          const SizedBox(height: 10),
          Text('More Features Locked',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textPrimary)),
          const SizedBox(height: 6),
          Text(
            'Create a free account to unlock full workout plans, advanced diet tracking and more.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
      String title, String subtitle, Color textPrimary, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(title,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textPrimary)),
          ],
        ),
        Text(subtitle,
            style: const TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildMobileWorkoutList(Color cardColor, Color borderColor,
      Color textPrimary, Color textSecondary) {
    return Column(
      children: _todayWorkouts.asMap().entries.map((entry) {
        final index = entry.key;
        final workout = entry.value;
        final color = workout['color'] as Color;
        final isDone = workout['done'] as bool;
        final icon =
            workout['icon'] as IconData? ?? Icons.fitness_center_rounded;
        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/exercise-detail',
              arguments: workout),
          onLongPress: () {
            setState(() => _todayWorkouts[index]['done'] = !isDone);
            _showTooltip(
              context,
              isDone ? 'Marked Incomplete' : 'Workout Complete! 🎉',
              isDone
                  ? '${workout['name']} has been unchecked.'
                  : '${workout['name']} marked as done!\n${workout['sets']} sets × ${workout['reps']} reps finished.',
              isDone
                  ? Icons.remove_circle_outline_rounded
                  : Icons.check_circle_rounded,
              color,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: isDone ? color.withOpacity(0.08) : cardColor,
              border: Border.all(
                  color: isDone ? color.withOpacity(0.4) : borderColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withOpacity(isDone ? 0.2 : 0.1)),
                  child: Center(child: Icon(icon, size: 20, color: color)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(workout['name'] as String,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDone ? color : textPrimary,
                              decoration: isDone
                                  ? TextDecoration.lineThrough
                                  : null)),
                      Text(
                          '${workout['sets']} sets × ${workout['reps']} reps • Rest ${workout['rest']}',
                          style:
                              TextStyle(fontSize: 11, color: textSecondary)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: color.withOpacity(0.12)),
                      child: Text(workout['muscle'] as String,
                          style: TextStyle(
                              fontSize: 9,
                              color: color,
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 6),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone ? color : Colors.transparent,
                        border: Border.all(
                            color: isDone ? color : borderColor, width: 2),
                      ),
                      child: isDone
                          ? const Icon(Icons.check,
                              size: 11, color: Colors.white)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMobileMealList(Color cardColor, Color borderColor,
      Color textPrimary, Color textSecondary) {
    return Column(
      children: _todayMeals.map((meal) {
        final color = meal['color'] as Color;
        final icon =
            meal['icon'] as IconData? ?? Icons.restaurant_rounded;
        return GestureDetector(
          onTap: () =>
              Navigator.pushNamed(context, '/meal-detail', arguments: meal),
          onLongPress: () => _showTooltip(
            context,
            meal['meal'] as String,
            '${meal['items']} · ${meal['calories']} kcal · ${meal['time']}',
            icon,
            color,
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: cardColor,
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withOpacity(0.12)),
                  child: Center(child: Icon(icon, size: 20, color: color)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(meal['meal'] as String,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: textPrimary)),
                      Text(meal['items'] as String,
                          style:
                              TextStyle(fontSize: 11, color: textSecondary)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${meal['calories']} kcal',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: color)),
                    Text(meal['time'] as String,
                        style:
                            TextStyle(fontSize: 10, color: textSecondary)),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMobileBottomNav(bool isDark, Color textPrimary) {
    final navBg = isDark ? const Color(0xFF141414) : Colors.white;
    final navBorder =
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);

    if (!_isLoggedIn) {
      return Container(
        padding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        decoration: BoxDecoration(
          color: navBg,
          border: Border(top: BorderSide(color: navBorder)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.home_rounded,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 6),
                Text('Home',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textPrimary)),
              ],
            ),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/register'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                      colors: [Color(0xFF5EFC82), Color(0xFF00C853)]),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.auto_awesome_rounded,
                        size: 13, color: Colors.black),
                    SizedBox(width: 4),
                    Text('Join Free',
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final tabs = [
      {'icon': Icons.home_rounded, 'label': 'Home'},
      {'icon': Icons.fitness_center_rounded, 'label': 'Workout'},
      {'icon': Icons.restaurant_rounded, 'label': 'Diet'},
      {'icon': Icons.bar_chart_rounded, 'label': 'Progress'},
      {'icon': Icons.person_rounded, 'label': 'Profile'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: navBg,
        border: Border(top: BorderSide(color: navBorder)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isSelected = _selectedTab == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedTab = index),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isSelected
                    ? AppColors.primary.withOpacity(0.15)
                    : Colors.transparent,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(tab['icon'] as IconData,
                      color: isSelected
                          ? AppColors.primary
                          : textPrimary.withOpacity(0.35),
                      size: isSelected ? 24 : 22),
                  const SizedBox(height: 3),
                  Text(tab['label'] as String,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: isSelected
                              ? AppColors.primary
                              : textPrimary.withOpacity(0.35))),
                  const SizedBox(height: 3),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: isSelected ? 4 : 0,
                    height: isSelected ? 4 : 0,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Stateful hover widget for dropdown items ─────────────────────────────────
class _DropdownItemHover extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color textColor;
  final bool isDestructive;
  final VoidCallback onTap;

  const _DropdownItemHover({
    required this.icon,
    required this.label,
    required this.textColor,
    required this.isDestructive,
    required this.onTap,
  });

  @override
  State<_DropdownItemHover> createState() => _DropdownItemHoverState();
}

class _DropdownItemHoverState extends State<_DropdownItemHover> {
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
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          color: _hovered
              ? (widget.isDestructive
                  ? const Color(0xFFFF4444).withOpacity(0.09)
                  : AppColors.primary.withOpacity(0.07))
              : Colors.transparent,
          child: Row(
            children: [
              Icon(widget.icon, size: 16, color: widget.textColor),
              const SizedBox(width: 10),
              Text(widget.label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: widget.textColor)),
            ],
          ),
        ),
      ),
    );
  }
}