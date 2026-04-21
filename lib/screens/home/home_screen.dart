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
            'emoji': _muscleEmoji(ex['muscle'] ?? ''),
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
                'emoji': _mealEmoji(match['type'] ?? ''),
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

  String _muscleEmoji(String muscle) {
    const map = {
      'Chest': '🏋️', 'Back': '💪', 'Shoulders': '⚡',
      'Legs': '🦵', 'Arms': '💪', 'Core': '🔥', 'Full Body': '🏃',
    };
    return map[muscle] ?? '💪';
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

  String _mealEmoji(String type) {
    const map = {
      'breakfast': '🥣',
      'lunch': '🍗',
      'snack': '🍌',
      'dinner': '🐟',
    };
    return map[type] ?? '🍽️';
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

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (kIsWeb) return _buildWebLayout(isDark);
    return _buildMobileLayout(isDark);
  }

  // ═══════════════════════════════════════
  // WEB LAYOUT
  // ═══════════════════════════════════════
  Widget _buildWebLayout(bool isDark) {
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final textSecondary =
        isDark ? const Color(0xFFB0B0B0) : const Color(0xFF555555);
    final bgColor =
        isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF0F2F5);
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
                  _buildWebSidebar(isDark, sidebarColor),
                  Expanded(
                    child: _buildWebContent(isDark, textPrimary,
                        textSecondary, cardColor, borderColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Web Content Area (switches based on _webSection) ──
  Widget _buildWebContent(bool isDark, Color textPrimary, Color textSecondary,
      Color cardColor, Color borderColor) {
    switch (_webSection) {
      case 'Workouts':
      case 'Workouts 🔒':
        return WorkoutScreen(userTier: _userTier);
      case 'Diet Plan':
      case 'Diet Plan 🔒':
        return MealsScreen(userTier: _userTier);
      case 'Progress':
      case 'Progress 🔒':
        return const ProgressScreen();
      case 'Profile':
        return const ProfileScreen();
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
                        child: _buildWebWorkoutCard(isDark, textPrimary,
                            textSecondary, cardColor, borderColor),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 2,
                        child: _buildWebDietCard(isDark, textPrimary,
                            textSecondary, cardColor, borderColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (!_isLoggedIn)
                    _buildWebLockedSection(isDark, textPrimary,
                        textSecondary, cardColor, borderColor),
                ],
              ),
            ),
          ),
        );
    }
  }

  Widget _buildWebTopNav(bool isDark, Color textPrimary, Color cardColor,
      Color borderColor) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.15),
                  border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                ),
                child: const Center(
                    child: Text('🏋️', style: TextStyle(fontSize: 16))),
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
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          if (_isLoggedIn) ...[
            _buildNavLink('Dashboard', _webSection == 'Dashboard', textPrimary),
            const SizedBox(width: 4),
            _buildNavLink('Workouts', _webSection == 'Workouts', textPrimary),
            const SizedBox(width: 4),
            _buildNavLink('Diet', _webSection == 'Diet Plan', textPrimary),
            const SizedBox(width: 4),
            _buildNavLink('Progress', _webSection == 'Progress', textPrimary),
            const SizedBox(width: 20),
          ],
          Consumer<ThemeProvider>(
            builder: (context, theme, _) => GestureDetector(
              onTap: () => Provider.of<ThemeProvider>(context, listen: false)
                  .toggleTheme(),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.1),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Center(
                  child: Text(theme.isDark ? '☀️' : '🌙',
                      style: const TextStyle(fontSize: 16)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (!_isLoggedIn) ...[
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/login'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                ),
                child: const Text('Sign In',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/register'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          ] else ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.15),
                border: Border.all(color: AppColors.primary.withOpacity(0.4)),
              ),
              child: const Center(
                  child: Text('👤', style: TextStyle(fontSize: 18))),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavLink(String label, bool isActive, Color textPrimary) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (label == 'Dashboard') _webSection = 'Dashboard';
          else if (label == 'Workouts') _webSection = 'Workouts';
          else if (label == 'Diet') _webSection = 'Diet Plan';
          else if (label == 'Progress') _webSection = 'Progress';
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isActive ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? AppColors.primary : textPrimary.withOpacity(0.6),
            )),
      ),
    );
  }

  Widget _buildWebSidebar(bool isDark, Color sidebarColor) {
    final items = _isLoggedIn
        ? [
            {'icon': Icons.dashboard_rounded, 'label': 'Dashboard'},
            {'icon': Icons.fitness_center_rounded, 'label': 'Workouts'},
            {'icon': Icons.restaurant_rounded, 'label': 'Diet Plan'},
            {'icon': Icons.bar_chart_rounded, 'label': 'Progress'},
            {'icon': Icons.notifications_rounded, 'label': 'Reminders'},
            {'icon': Icons.person_rounded, 'label': 'Profile'},
            {'icon': Icons.settings_rounded, 'label': 'Settings'},
          ]
        : [
            {'icon': Icons.dashboard_rounded, 'label': 'Dashboard'},
            {'icon': Icons.lock_rounded, 'label': 'Workouts 🔒'},
            {'icon': Icons.lock_rounded, 'label': 'Diet Plan 🔒'},
            {'icon': Icons.lock_rounded, 'label': 'Progress 🔒'},
          ];

    return Container(
      width: 220,
      color: sidebarColor,
      child: Column(
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withOpacity(0.2),
                    border:
                        Border.all(color: AppColors.primary.withOpacity(0.5)),
                  ),
                  child: const Center(
                      child: Text('👤', style: TextStyle(fontSize: 18))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(userName,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      Text(
                        _isLoggedIn ? '✅ Member' : '👤 Guest',
                        style: TextStyle(
                          fontSize: 11,
                          color: _isLoggedIn
                              ? AppColors.primary
                              : Colors.white.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Divider(color: Colors.white.withOpacity(0.08), height: 1),
          const SizedBox(height: 16),
          ...items.map((item) {
            final label = item['label'] as String;
            final isActive = label == _webSection ||
                (label == 'Dashboard' && _webSection == 'Dashboard');
            final isLocked = label.contains('🔒');
            return GestureDetector(
              onTap: () => setState(() => _webSection = label),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: isActive
                      ? AppColors.primary.withOpacity(0.15)
                      : Colors.transparent,
                ),
                child: ListTile(
                  dense: true,
                  leading: Icon(item['icon'] as IconData,
                      size: 18,
                      color: isActive
                          ? AppColors.primary
                          : isLocked
                              ? Colors.white.withOpacity(0.2)
                              : Colors.white.withOpacity(0.5)),
                  title: Text(label,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isActive ? FontWeight.w700 : FontWeight.w400,
                          color: isActive
                              ? AppColors.primary
                              : isLocked
                                  ? Colors.white.withOpacity(0.2)
                                  : Colors.white.withOpacity(0.6))),
                ),
              ),
            );
          }),
          const Spacer(),
          if (!_isLoggedIn)
            Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/register'),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                        colors: [Color(0xFF5EFC82), Color(0xFF00C853)]),
                  ),
                  child: const Center(
                      child: Text('✨ Join Free',
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 13,
                              fontWeight: FontWeight.w700))),
                ),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

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
                Text('${Helpers.getGreeting()}, $userName! 👋',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: textPrimary)),
                const SizedBox(height: 6),
                Text("Here's your fitness overview for today",
                    style: TextStyle(fontSize: 14, color: textSecondary)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildWebBadge('🎯 $userGoal', AppColors.primary),
                    const SizedBox(width: 8),
                    _buildWebBadge(
                      'BMI ${Helpers.calculateBMI(userWeight, userHeight).toStringAsFixed(1)} • ${Helpers.getBMICategory(Helpers.calculateBMI(userWeight, userHeight))}',
                      const Color(0xFF2979FF),
                    ),
                    const SizedBox(width: 8),
                    _buildWebBadge(
                      '$completedWorkouts/${_todayWorkouts.length} workouts done',
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
              border:
                  Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
            ),
            child: const Center(
                child: Text('🏋️', style: TextStyle(fontSize: 38))),
          ),
        ],
      ),
    );
  }

  Widget _buildWebBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withOpacity(0.12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildWebStatsGrid(bool isDark, Color textPrimary, Color cardColor) {
    final stats = [
      {'label': 'Weight', 'value': '${userWeight}kg', 'emoji': '⚖️', 'color': const Color(0xFF2979FF)},
      {'label': 'Height', 'value': '${userHeight}cm', 'emoji': '📏', 'color': const Color(0xFFFF6D00)},
      {'label': 'Age', 'value': '$userAge yrs', 'emoji': '🎂', 'color': const Color(0xFFAA00FF)},
      {'label': 'Daily Calories', 'value': '$totalCalories kcal', 'emoji': '🔥', 'color': const Color(0xFFFFD600)},
      {'label': 'BMI', 'value': Helpers.calculateBMI(userWeight, userHeight).toStringAsFixed(1), 'emoji': '📊', 'color': AppColors.primary},
      {'label': 'Workouts', 'value': '$completedWorkouts/${_todayWorkouts.length}', 'emoji': '💪', 'color': const Color(0xFF00C853)},
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
                child: Center(
                    child: Text(stat['emoji'] as String,
                        style: const TextStyle(fontSize: 20))),
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
                    Text("🔓 You're using the free plan — unlock more!",
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: textPrimary)),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 16,
                  children: [
                    _buildWebFeatureChip('☁️ Cloud sync', textSecondary),
                    _buildWebFeatureChip('💪 50+ exercises', textSecondary),
                    _buildWebFeatureChip('🥗 Advanced diet', textSecondary),
                    _buildWebFeatureChip('📊 Analytics', textSecondary),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Row(
            children: [
              GestureDetector(
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
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/register'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: const LinearGradient(
                        colors: [Color(0xFF5EFC82), Color(0xFF00C853)]),
                  ),
                  child: const Text('✨ Create Free Account',
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
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
        const Icon(Icons.check_circle, size: 13, color: AppColors.primary),
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
              Text("Today's Workout 💪",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textPrimary)),
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
          const SizedBox(height: 16),
          ..._todayWorkouts.asMap().entries.map((entry) {
            final index = entry.key;
            final workout = entry.value;
            final color = workout['color'] as Color;
            final isDone = workout['done'] as bool;

            return GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/exercise-detail',
                  arguments: workout),
              onLongPress: () =>
                  setState(() => _todayWorkouts[index]['done'] = !isDone),
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
                      color: isDone ? color.withOpacity(0.4) : borderColor),
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
                          child: Text(workout['emoji'] as String,
                              style: const TextStyle(fontSize: 18))),
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
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWebDietCard(bool isDark, Color textPrimary, Color textSecondary,
      Color cardColor, Color borderColor) {
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
              Text("Today's Meals 🥗",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textPrimary)),
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
            return GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/meal-detail',
                  arguments: meal),
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
                          child: Text(meal['emoji'] as String,
                              style: const TextStyle(fontSize: 16))),
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
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWebLockedSection(bool isDark, Color textPrimary,
      Color textSecondary, Color cardColor, Color borderColor) {
    final features = [
      {'emoji': '💪', 'title': 'Full Exercise Library', 'desc': '200+ exercises with video demos', 'color': const Color(0xFF2979FF)},
      {'emoji': '🥗', 'title': 'Advanced Diet Plans', 'desc': 'AI-generated meal plans', 'color': const Color(0xFF00C853)},
      {'emoji': '📊', 'title': 'Progress Analytics', 'desc': 'Charts and insights over time', 'color': const Color(0xFFFF6D00)},
      {'emoji': '☁️', 'title': 'Cloud Backup', 'desc': 'Never lose your data', 'color': const Color(0xFFAA00FF)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('🔒 Unlock Premium Features',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textPrimary)),
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
                  Text(f['emoji'] as String,
                      style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 6),
                  Text(f['title'] as String,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: textPrimary)),
                  Text(f['desc'] as String,
                      style:
                          TextStyle(fontSize: 10, color: textSecondary)),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Center(
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/register'),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
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
              child: const Text('🚀 Create Your Free Account Now',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.w800)),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════
  // MOBILE LAYOUT
  // ═══════════════════════════════════════

  // ── Dashboard content for tab index 0 ──
  Widget _buildMobileDashboard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final textSecondary =
        isDark ? const Color(0xFFB0B0B0) : const Color(0xFF555555);
    final bgColor =
        isDark ? const Color(0xFF050A05) : const Color(0xFFF5F5F5);
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
          if (_isLoadingData) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(
                    color: AppColors.primary, strokeWidth: 2.5),
              ),
            ),
          ] else ...[
            _buildSectionTitle(
                "Today's Workout 💪",
                "$completedWorkouts/${_todayWorkouts.length} done",
                textPrimary),
            const SizedBox(height: 12),
            _buildMobileWorkoutList(
                cardColor, borderColor, textPrimary, textSecondary),
            const SizedBox(height: 20),
            _buildSectionTitle(
                "Today's Meals 🥗", "$totalCalories kcal", textPrimary),
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
              Text('${Helpers.getGreeting()} 👋',
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
                child: Text('🎯 $userGoal',
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600)),
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
                  child: Text('👤', style: TextStyle(fontSize: 20))),
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
                  child: Text(theme.isDark ? '☀️' : '🌙',
                      style: const TextStyle(fontSize: 16))),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileStatsRow(Color textPrimary) {
    final stats = [
      {'label': 'Weight', 'value': '${userWeight}kg', 'emoji': '⚖️', 'color': const Color(0xFF2979FF)},
      {'label': 'Height', 'value': '${userHeight}cm', 'emoji': '📏', 'color': const Color(0xFFFF6D00)},
      {'label': 'Age', 'value': '${userAge}yrs', 'emoji': '🎂', 'color': const Color(0xFFAA00FF)},
      {'label': 'Calories', 'value': '$totalCalories', 'emoji': '🔥', 'color': const Color(0xFFFFD600)},
    ];

    return Row(
      children: stats.asMap().entries.map((entry) {
        final i = entry.key;
        final stat = entry.value;
        final color = stat['color'] as Color;
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
                Text(stat['emoji'] as String,
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 4),
                Text(stat['value'] as String,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: color)),
                const SizedBox(height: 2),
                Text(stat['label'] as String,
                    style: TextStyle(
                        fontSize: 9,
                        color: textPrimary.withOpacity(0.4))),
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
              Text('🔓 Unlock More',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textPrimary)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _buildFeatureChip('☁️ Cloud sync', textSecondary),
              _buildFeatureChip('💪 50+ exercises', textSecondary),
              _buildFeatureChip('🥗 Diet plans', textSecondary),
              _buildFeatureChip('📊 Analytics', textSecondary),
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
                    child: const Center(
                        child: Text('Create Free Account',
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 13,
                                fontWeight: FontWeight.w700))),
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
        const Icon(Icons.check_circle, size: 12, color: AppColors.primary),
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
          const Text('🔒', style: TextStyle(fontSize: 32)),
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
      String title, String subtitle, Color textPrimary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textPrimary)),
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

        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/exercise-detail',
              arguments: workout),
          onLongPress: () =>
              setState(() => _todayWorkouts[index]['done'] = !isDone),
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
                  child: Center(
                      child: Text(workout['emoji'] as String,
                          style: const TextStyle(fontSize: 18))),
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
        return GestureDetector(
          onTap: () =>
              Navigator.pushNamed(context, '/meal-detail', arguments: meal),
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
                  child: Center(
                      child: Text(meal['emoji'] as String,
                          style: const TextStyle(fontSize: 18))),
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
                child: const Text('✨ Join Free',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
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
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isSelected = _selectedTab == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedTab = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isSelected
                    ? AppColors.primary.withOpacity(0.12)
                    : Colors.transparent,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(tab['icon'] as IconData,
                      color: isSelected
                          ? AppColors.primary
                          : textPrimary.withOpacity(0.4),
                      size: 22),
                  const SizedBox(height: 3),
                  Text(tab['label'] as String,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: isSelected
                              ? AppColors.primary
                              : textPrimary.withOpacity(0.4))),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}