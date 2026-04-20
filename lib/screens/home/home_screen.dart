import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/helpers.dart';
import '../../core/theme/theme_provider.dart';
import '../../services/storage_service.dart';

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
  bool _isLoggedIn = false;

  final String userName = 'Abdullah';
  final double userWeight = 75.0;
  final double userHeight = 175.0;
  final int userAge = 24;
  final String userGoal = 'Build Muscle';

  final List<Map<String, dynamic>> todayWorkouts = [
    {
      'name': 'Bench Press',
      'sets': 4,
      'reps': 10,
      'rest': '60s',
      'muscle': 'Chest',
      'emoji': '🏋️',
      'color': const Color(0xFF2979FF),
      'done': false,
    },
    {
      'name': 'Pull Ups',
      'sets': 3,
      'reps': 12,
      'rest': '60s',
      'muscle': 'Back',
      'emoji': '💪',
      'color': const Color(0xFF00C853),
      'done': false,
    },
    {
      'name': 'Shoulder Press',
      'sets': 3,
      'reps': 10,
      'rest': '45s',
      'muscle': 'Shoulders',
      'emoji': '⚡',
      'color': const Color(0xFFFF6D00),
      'done': false,
    },
  ];

  final List<Map<String, dynamic>> todayMeals = [
    {
      'meal': 'Breakfast',
      'time': '8:00 AM',
      'items': 'Oats + Eggs + Milk',
      'calories': 450,
      'emoji': '🥣',
      'color': const Color(0xFFFFD600),
    },
    {
      'meal': 'Lunch',
      'time': '1:00 PM',
      'items': 'Chicken Rice + Salad',
      'calories': 650,
      'emoji': '🍗',
      'color': const Color(0xFF00C853),
    },
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );
    _animController.forward();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final loggedIn = await StorageService.isLoggedIn();
    setState(() => _isLoggedIn = loggedIn);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  int get completedWorkouts =>
      todayWorkouts.where((w) => w['done'] == true).length;

  int get totalCalories =>
      todayMeals.fold(0, (sum, m) => sum + (m['calories'] as int));

  // Responsive wrapper — centers content on web
  Widget _responsiveWrapper(Widget child) {
    if (kIsWeb) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: child,
        ),
      );
    }
    return child;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final textSecondary = isDark ? const Color(0xFFB0B0B0) : const Color(0xFF444444);
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = isDark ? const Color(0xFF141414) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);

    return Scaffold(
      backgroundColor: bgColor,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: _responsiveWrapper(
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(AppConstants.paddingLG),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(textPrimary, textSecondary),
                        const SizedBox(height: 20),
                        _buildStatsRow(textPrimary),
                        const SizedBox(height: 16),
                        _buildUnlockBanner(isDark, textPrimary, textSecondary),
                        const SizedBox(height: 24),
                        _buildSectionTitle(
                          "Today's Workout 💪",
                          "$completedWorkouts/${todayWorkouts.length} done",
                          textPrimary,
                        ),
                        const SizedBox(height: 12),
                        _buildWorkoutList(cardColor, borderColor, textPrimary, textSecondary),
                        const SizedBox(height: 24),
                        _buildSectionTitle(
                          "Today's Meals 🥗",
                          "$totalCalories kcal",
                          textPrimary,
                        ),
                        const SizedBox(height: 12),
                        _buildMealList(cardColor, borderColor, textPrimary, textSecondary),
                        if (!_isLoggedIn) ...[
                          const SizedBox(height: 24),
                          _buildLockedSection(isDark, textPrimary, textSecondary),
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
              _responsiveWrapper(_buildBottomNav(isDark, textPrimary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color textPrimary, Color textSecondary) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${Helpers.getGreeting()} 👋',
                style: TextStyle(fontSize: 13, color: textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                userName,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: AppColors.primary.withOpacity(0.12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Text(
                  '🎯 $userGoal',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Avatar
        Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.15),
                border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 2),
              ),
              child: const Center(child: Text('👤', style: TextStyle(fontSize: 22))),
            ),
            const SizedBox(height: 4),
            Text(
              'BMI ${Helpers.calculateBMI(userWeight, userHeight).toStringAsFixed(1)}',
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(width: 8),

        // Theme toggle
        GestureDetector(
          onTap: () =>
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme(),
          child: Consumer<ThemeProvider>(
            builder: (context, theme, _) => Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Center(
                child: Text(
                  theme.isDark ? '☀️' : '🌙',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(Color textPrimary) {
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
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: color.withOpacity(0.08),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Text(stat['emoji'] as String, style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 4),
                Text(
                  stat['value'] as String,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  stat['label'] as String,
                  style: TextStyle(fontSize: 9, color: textPrimary.withOpacity(0.4)),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildUnlockBanner(bool isDark, Color textPrimary, Color textSecondary) {
    if (_isLoggedIn) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? const Color(0xFF0D1F0D) : const Color(0xFFE8F5E9),
        border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'FREE PLAN',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '🔓 Unlock More Features',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildFeatureRow('☁️ Save progress to cloud', textSecondary),
          _buildFeatureRow('💪 50+ more exercises', textSecondary),
          _buildFeatureRow('🥗 Advanced diet plans', textSecondary),
          _buildFeatureRow('📊 Detailed analytics', textSecondary),
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
                        colors: [Color(0xFF5EFC82), Color(0xFF00C853)],
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'Create Free Account',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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
                    border: Border.all(color: AppColors.primary.withOpacity(0.5)),
                  ),
                  child: const Center(
                    child: Text(
                      'Sign In',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildFeatureRow(String text, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 13, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 12, color: textSecondary)),
        ],
      ),
    );
  }

  Widget _buildLockedSection(bool isDark, Color textPrimary, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? const Color(0xFF141414) : Colors.white,
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
        ),
      ),
      child: Column(
        children: [
          const Text('🔒', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 12),
          Text(
            'More Features Locked',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Create a free account to unlock full workout plans, advanced diet tracking, progress charts and more.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle, Color textPrimary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildWorkoutList(Color cardColor, Color borderColor, Color textPrimary, Color textSecondary) {
    return Column(
      children: todayWorkouts.asMap().entries.map((entry) {
        final index = entry.key;
        final workout = entry.value;
        final color = workout['color'] as Color;
        final isDone = workout['done'] as bool;

        return GestureDetector(
          onTap: () => setState(() => todayWorkouts[index]['done'] = !isDone),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: isDone ? color.withOpacity(0.08) : cardColor,
              border: Border.all(
                color: isDone ? color.withOpacity(0.4) : borderColor,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(isDone ? 0.2 : 0.1),
                  ),
                  child: Center(
                    child: Text(workout['emoji'] as String,
                        style: const TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workout['name'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDone ? color : textPrimary,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${workout['sets']} sets × ${workout['reps']} reps • Rest ${workout['rest']}',
                        style: TextStyle(fontSize: 11, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: color.withOpacity(0.12),
                      ),
                      child: Text(
                        workout['muscle'] as String,
                        style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600),
                      ),
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
                          color: isDone ? color : borderColor,
                          width: 2,
                        ),
                      ),
                      child: isDone
                          ? const Icon(Icons.check, size: 11, color: Colors.white)
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

  Widget _buildMealList(Color cardColor, Color borderColor, Color textPrimary, Color textSecondary) {
    return Column(
      children: todayMeals.map((meal) {
        final color = meal['color'] as Color;
        return Container(
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
                  color: color.withOpacity(0.12),
                ),
                child: Center(
                  child: Text(meal['emoji'] as String,
                      style: const TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal['meal'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      meal['items'] as String,
                      style: TextStyle(fontSize: 11, color: textSecondary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${meal['calories']} kcal',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meal['time'] as String,
                    style: TextStyle(fontSize: 10, color: textSecondary),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomNav(bool isDark, Color textPrimary) {
    // Guest user — only Home tab
    if (!_isLoggedIn) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141414) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.home_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 6),
                Text(
                  'Home',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/register'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5EFC82), Color(0xFF00C853)],
                  ),
                ),
                child: const Text(
                  '✨ Join Free',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Logged in user — full bottom nav
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
        color: isDark ? const Color(0xFF141414) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
          ),
        ),
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
                  Icon(
                    tab['icon'] as IconData,
                    color: isSelected ? AppColors.primary : textPrimary.withOpacity(0.4),
                    size: 22,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    tab['label'] as String,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                      color: isSelected ? AppColors.primary : textPrimary.withOpacity(0.4),
                    ),
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