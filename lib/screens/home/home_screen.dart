import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/helpers.dart';
import 'package:provider/provider.dart';
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

  // Dummy user data
  final String userName = 'Abdullah';
  final double userWeight = 75.0;
  final double userHeight = 175.0;
  final int userAge = 24;
  final String userGoal = 'Build Muscle';

  // Dummy today's workout
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
    {
      'name': 'Deadlift',
      'sets': 4,
      'reps': 8,
      'rest': '90s',
      'muscle': 'Back + Legs',
      'emoji': '🔥',
      'color': const Color(0xFFAA00FF),
      'done': false,
    },
  ];

  // Dummy today's meals
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
    {
      'meal': 'Snack',
      'time': '4:00 PM',
      'items': 'Banana + Protein Shake',
      'calories': 280,
      'emoji': '🍌',
      'color': const Color(0xFFFF6D00),
    },
    {
      'meal': 'Dinner',
      'time': '8:00 PM',
      'items': 'Fish + Vegetables + Rice',
      'calories': 520,
      'emoji': '🐟',
      'color': const Color(0xFF2979FF),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Column(
            children: [
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppConstants.paddingLG),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      _buildHeader(),
                      const SizedBox(height: 24),

                      // Stats row
                      _buildStatsRow(),
                      const SizedBox(height: 28),

                      // After _buildStatsRow() and its SizedBox:
                      _buildUnlockBanner(),
                      const SizedBox(height: 28),

                      // Today's workout
                      _buildSectionTitle(
                          "Today's Workout 💪", "${completedWorkouts}/${todayWorkouts.length} done"),
                      const SizedBox(height: 14),
                      _buildWorkoutList(),
                      const SizedBox(height: 28),

                      // Today's diet
                      _buildSectionTitle(
                          "Today's Meals 🥗", "$totalCalories kcal"),
                      const SizedBox(height: 14),
                      _buildMealList(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Bottom nav
              _buildBottomNav(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final bmi = Helpers.calculateBMI(userWeight, userHeight);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${Helpers.getGreeting()} 👋',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                userName,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF0D1F0D)
                      : const Color(0xFFE8F5E9),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.4),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  '🎯 $userGoal',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Avatar + BMI
        Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.15),
                border: Border.all(
                    color: AppColors.primary.withOpacity(0.4), width: 2),
              ),
              child: const Center(
                child: Text('👤', style: TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'BMI ${Helpers.calculateBMI(userWeight, userHeight).toStringAsFixed(1)}',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        // Add this inside the header Row, after the avatar Column:
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
          },
          child: Consumer<ThemeProvider>(
            builder: (context, theme, _) {
              return Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.12),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                  ),
                ),
                child: Center(
                  child: Text(
                    theme.isDark ? '☀️' : '🌙',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    final stats = [
      {
        'label': 'Weight',
        'value': '${userWeight}kg',
        'emoji': '⚖️',
        'color': const Color(0xFF2979FF)
      },
      {
        'label': 'Height',
        'value': '${userHeight}cm',
        'emoji': '📏',
        'color': const Color(0xFFFF6D00)
      },
      {
        'label': 'Age',
        'value': '${userAge}yrs',
        'emoji': '🎂',
        'color': const Color(0xFFAA00FF)
      },
      {
        'label': 'Calories',
        'value': '${totalCalories}',
        'emoji': '🔥',
        'color': const Color(0xFFFFD600)
      },
    ];

    return Row(
      children: stats.map((stat) {
        final color = stat['color'] as Color;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
              right: stat != stats.last ? 8 : 0,
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: color.withOpacity(0.08),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Text(stat['emoji'] as String,
                    style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 6),
                Text(
                  stat['value'] as String,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stat['label'] as String,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textHint.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildUnlockBanner() {
  // Hide if already logged in
  if (StorageService.isLoggedIn()) return const SizedBox.shrink();

  return Container(
    margin: const EdgeInsets.only(top: 8),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF1A1A2E),
          AppColors.primary.withOpacity(0.15),
        ],
      ),
      border: Border.all(
        color: AppColors.primary.withOpacity(0.3),
        width: 1.5,
      ),
    ),
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
            const Text(
              '🔓 Unlock More Features',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Feature list
        _buildUnlockFeature('☁️ Save progress to cloud'),
        _buildUnlockFeature('💪 50+ more exercises'),
        _buildUnlockFeature('🥗 Advanced diet plans'),
        _buildUnlockFeature('📊 Detailed analytics'),

        const SizedBox(height: 12),

        Row(
          children: [
            Flexible(
              flex: 3,
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/register');
                },
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF5EFC82),
                        Color(0xFF00C853),
                      ],
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
              onTap: () {
                Navigator.pushNamed(context, '/login');
              },
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.4),
                  ),
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

Widget _buildUnlockFeature(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        const Icon(Icons.check_circle,
            size: 14, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary.withOpacity(0.8),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildSectionTitle(String title, String subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
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

  Widget _buildWorkoutList() {
    return Column(
      children: todayWorkouts.asMap().entries.map((entry) {
        final index = entry.key;
        final workout = entry.value;
        final color = workout['color'] as Color;
        final isDone = workout['done'] as bool;

        return GestureDetector(
          onTap: () {
            setState(() {
              todayWorkouts[index]['done'] = !isDone;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: isDone
                  ? color.withOpacity(0.08)
                  : AppColors.surface,
              border: Border.all(
                color: isDone ? color.withOpacity(0.4) : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                // Emoji
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(isDone ? 0.2 : 0.1),
                  ),
                  child: Center(
                    child: Text(
                      workout['emoji'] as String,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workout['name'] as String,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDone
                              ? color
                              : AppColors.textPrimary,
                          decoration: isDone
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${workout['sets']} sets × ${workout['reps']} reps • Rest ${workout['rest']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textHint.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),

                // Muscle tag + check
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: color.withOpacity(0.12),
                      ),
                      child: Text(
                        workout['muscle'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone ? color : Colors.transparent,
                        border: Border.all(
                          color: isDone ? color : AppColors.borderLight,
                          width: 2,
                        ),
                      ),
                      child: isDone
                          ? const Icon(Icons.check,
                              size: 12, color: Colors.white)
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

  Widget _buildMealList() {
    return Column(
      children: todayMeals.map((meal) {
        final color = meal['color'] as Color;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.12),
                ),
                child: Center(
                  child: Text(
                    meal['emoji'] as String,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal['meal'] as String,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      meal['items'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint.withOpacity(0.6),
                      ),
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
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    meal['time'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomNav() {
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
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textHint,
                    size: 22,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    tab['label'] as String,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textHint,
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