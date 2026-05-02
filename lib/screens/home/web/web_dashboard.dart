import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/data/app_data.dart';
import '../../../services/storage_service.dart';
import 'web_cursor_effects.dart';

class WebDashboard extends StatefulWidget {

  final bool isLoggedIn;
  final bool isLoadingData;
  final List<Map<String, dynamic>> todayWorkouts;
  final List<Map<String, dynamic>> todayMeals;
  final void Function(String section) onNavigate;
  final void Function(int index) onWorkoutToggle;
  final void Function(BuildContext, String, String, IconData, Color)
      onShowTooltip;

  const WebDashboard({
    super.key,
    required this.isLoggedIn,
    required this.isLoadingData,
    required this.todayWorkouts,
    required this.todayMeals,
    required this.onNavigate,
    required this.onWorkoutToggle,
    required this.onShowTooltip,
  });

 @override
  State<WebDashboard> createState() => _WebDashboardState();
}

class _WebDashboardState extends State<WebDashboard> {
  String? _homeBannerPath;

  String get userName => AppData.userName;
  double get userWeight => AppData.userWeight;
  double get userHeight => AppData.userHeight;
  int get userAge => AppData.userAge;
  String get userGoal => AppData.userGoal;

  int get completedWorkouts =>
      widget.todayWorkouts.where((w) => w['done'] == true).length;
  int get totalCalories =>
      widget.todayMeals.fold(0, (sum, m) => sum + (m['calories'] as int));

  @override
  void initState() {
    super.initState();
    _loadBanner();
  }

  Future<void> _loadBanner() async {
    final path = await StorageService.getHomeBanner();
    if (mounted) setState(() => _homeBannerPath = path);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppColors.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Welcome hero banner ──────────────────────────────────
              _WelcomeBanner(
                homeBannerPath: _homeBannerPath,
                userName: userName,
                userGoal: userGoal,
                userWeight: userWeight,
                userHeight: userHeight,
                completedWorkouts: completedWorkouts,
                totalWorkouts: widget.todayWorkouts.length,
                isLoggedIn: widget.isLoggedIn,
                isDark: isDark,
                accent: accent,
                onNavigate: widget.onNavigate,
              ),
              const SizedBox(height: 24),

              // ── Stats grid ───────────────────────────────────────────
              _StatsGrid(
                userWeight: userWeight,
                userHeight: userHeight,
                userAge: userAge,
                totalCalories: totalCalories,
                completedWorkouts: completedWorkouts,
                totalWorkouts: widget.todayWorkouts.length,
                isDark: isDark,
                accent: accent,
              ),
              const SizedBox(height: 24),

              // ── Guest unlock banner ──────────────────────────────────
              if (!widget.isLoggedIn) ...[
                _GuestBanner(isDark: isDark, accent: accent),
                const SizedBox(height: 24),
              ],

              // ── Workout + Meals row ──────────────────────────────────
              if (widget.isLoadingData)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: CircularProgressIndicator(
                        color: accent, strokeWidth: 2),
                  ),
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _WorkoutCard(
                        todayWorkouts: widget.todayWorkouts,
                        completedWorkouts: completedWorkouts,
                        isDark: isDark,
                        accent: accent,
                        onToggle: widget.onWorkoutToggle,
                        onShowTooltip: widget.onShowTooltip,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 2,
                      child: _MealsCard(
                        todayMeals: widget.todayMeals,
                        totalCalories: totalCalories,
                        isDark: isDark,
                        accent: accent,
                        onShowTooltip: widget.onShowTooltip,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 24),

              // ── Locked features ──────────────────────────────────────
              if (!widget.isLoggedIn)
                _LockedSection(isDark: isDark, accent: accent),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// IMAGE URLS
// ═══════════════════════════════════════════════════════════════════════════
class _Imgs {
  // Welcome banner
  static const welcomeBg =
      'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b'
      '?w=1200&q=80&auto=format&fit=crop';
  static const welcomeAthlete =
      'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61'
      '?w=400&q=80&auto=format&fit=crop';

  // Stat card backgrounds — bright, clearly identifiable, well-centered images
  static const statWeight =
      'https://images.unsplash.com/photo-1526506118085-60ce8714f8c5'
      '?w=400&q=80&auto=format&fit=crop'; // dumbbells close-up, bright
  static const statHeight =
      'https://images.unsplash.com/photo-1552674605-db6ffd4facb5'
      '?w=400&q=80&auto=format&fit=crop'; // runner legs / silhouette
  static const statAge =
      'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61'
      '?w=400&q=80&auto=format&fit=crop'; // athlete upper body
  static const statCalories =
      'https://images.unsplash.com/photo-1512621776951-a57141f2eefd'
      '?w=400&q=80&auto=format&fit=crop'; // colourful healthy food bowl
  static const statBmi =
      'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b'
      '?w=400&q=80&auto=format&fit=crop'; // gym floor / equipment
  static const statWorkouts =
      'https://images.unsplash.com/photo-1534438327276-14e5300c3a48'
      '?w=400&q=80&auto=format&fit=crop'; // gym weights rack, well-lit

  // Workout card banner
  static const workoutBanner =
      'https://images.unsplash.com/photo-1534438327276-14e5300c3a48'
      '?w=800&q=80&auto=format&fit=crop';

  // Exercise thumbnails (muscle group based)
  static const exerciseChest =
      'https://images.unsplash.com/photo-1534367610401-9f5ed68180aa'
      '?w=120&q=80&auto=format&fit=crop';
  static const exerciseBack =
      'https://images.unsplash.com/photo-1603287681836-b174ce5074c2'
      '?w=120&q=80&auto=format&fit=crop';
  static const exerciseLegs =
      'https://images.unsplash.com/photo-1566241142559-40e1dab266c6'
      '?w=120&q=80&auto=format&fit=crop';
  static const exerciseShoulders =
      'https://images.unsplash.com/photo-1598971639058-fab3c3109a00'
      '?w=120&q=80&auto=format&fit=crop';
  static const exerciseArms =
      'https://images.unsplash.com/photo-1581009137042-c552e485697a'
      '?w=120&q=80&auto=format&fit=crop';
  static const exerciseCore =
      'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b'
      '?w=120&q=80&auto=format&fit=crop';
  static const exerciseDefault =
      'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e'
      '?w=120&q=80&auto=format&fit=crop';

  // Meal card banner
  static const mealBanner =
      'https://images.unsplash.com/photo-1547592180-85f173990554'
      '?w=800&q=80&auto=format&fit=crop';

  // Food thumbnails per meal type
  static const foodBreakfast =
      'https://images.unsplash.com/photo-1533089860892-a7c6f0a88666'
      '?w=120&q=80&auto=format&fit=crop';
  static const foodLunch =
      'https://images.unsplash.com/photo-1512621776951-a57141f2eefd'
      '?w=120&q=80&auto=format&fit=crop';
  static const foodSnack =
      'https://images.unsplash.com/photo-1568702846914-96b305d2aaeb'
      '?w=120&q=80&auto=format&fit=crop';
  static const foodDinner =
      'https://images.unsplash.com/photo-1467003909585-2f8a72700288'
      '?w=120&q=80&auto=format&fit=crop';
  static const foodDefault =
      'https://images.unsplash.com/photo-1490645935967-10de6ba17061'
      '?w=120&q=80&auto=format&fit=crop';

  // Locked feature images
  static const featureExercise =
      'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e'
      '?w=300&q=70&auto=format&fit=crop';
  static const featureDiet =
      'https://images.unsplash.com/photo-1490645935967-10de6ba17061'
      '?w=300&q=70&auto=format&fit=crop';
  static const featureAnalytics =
      'https://images.unsplash.com/photo-1549576490-b0b4831ef60a'
      '?w=300&q=70&auto=format&fit=crop';
  static const featureCloud =
      'https://images.unsplash.com/photo-1534438327276-14e5300c3a48'
      '?w=300&q=70&auto=format&fit=crop';

  // Helper: get exercise image by muscle group
  static String exerciseByMuscle(String muscle) {
    switch (muscle.toLowerCase()) {
      case 'chest':
        return exerciseChest;
      case 'back':
        return exerciseBack;
      case 'legs':
        return exerciseLegs;
      case 'shoulders':
        return exerciseShoulders;
      case 'arms':
        return exerciseArms;
      case 'core':
        return exerciseCore;
      default:
        return exerciseDefault;
    }
  }

  // Helper: get food image by meal type
  static String foodByMealType(String mealName) {
    final lower = mealName.toLowerCase();
    if (lower.contains('breakfast')) return foodBreakfast;
    if (lower.contains('lunch')) return foodLunch;
    if (lower.contains('snack')) return foodSnack;
    if (lower.contains('dinner')) return foodDinner;
    return foodDefault;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// GLASS CARD BASE
// ═══════════════════════════════════════════════════════════════════════════
class _GlassCard extends StatelessWidget {
  final Widget child;
  final Color accent;
  final bool isDark;
  final EdgeInsets? padding;
  final double? borderOpacity;
  final List<BoxShadow>? extraShadows;

  const _GlassCard({
    required this.child,
    required this.accent,
    required this.isDark,
    this.padding,
    this.borderOpacity,
    this.extraShadows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark
            ? Colors.black.withOpacity(0.55)
            : Colors.white.withOpacity(0.85),
        border: Border.all(
          color: accent.withOpacity(borderOpacity ?? 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          if (isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ...?extraShadows,
        ],
      ),
      child: child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WELCOME BANNER
// ═══════════════════════════════════════════════════════════════════════════
class _WelcomeBanner extends StatelessWidget {
  final String userName;
  final String userGoal;
  final double userWeight;
  final double userHeight;
  final int completedWorkouts;
  final int totalWorkouts;
  final bool isLoggedIn;
  final bool isDark;
  final Color accent;
  final void Function(String) onNavigate;
  final String? homeBannerPath;

  const _WelcomeBanner({
    required this.userName,
    required this.userGoal,
    required this.userWeight,
    required this.userHeight,
    required this.completedWorkouts,
    required this.totalWorkouts,
    required this.isLoggedIn,
    required this.isDark,
    required this.accent,
    required this.onNavigate,
    this.homeBannerPath,
  });

  @override
  Widget build(BuildContext context) {
    final bmi = Helpers.calculateBMI(userWeight, userHeight);
    return Consumer<ThemeProvider>(
      builder: (context, theme, _) => TiltCard(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            width: double.infinity,
            child: Stack(
              children: [
                // ── Real gym photo background ──────────────────────
                Positioned.fill(
                  child: homeBannerPath != null
                      ? Image.network(
                          homeBannerPath!,
                          fit: BoxFit.cover,
                          alignment: const Alignment(0, -0.3),
                          errorBuilder: (_, __, ___) => Image.network(
                            _Imgs.welcomeBg,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Image.network(
                          _Imgs.welcomeBg,
                          fit: BoxFit.cover,
                          alignment: const Alignment(0, -0.3),
                          errorBuilder: (_, __, ___) => Container(
                            color: accent.withOpacity(0.08),
                          ),
                        ),
                ),

                // ── Dark gradient overlay ──────────────────────────
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.88),
                          Colors.black.withOpacity(0.65),
                          Colors.black.withOpacity(0.25),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),

                // ── Accent border ──────────────────────────────────
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: accent.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                // ── Content ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(28),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              Helpers.getGreeting().toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                color: accent.withOpacity(0.9),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: theme.accentGradient,
                              ).createShader(bounds),
                              child: Text(
                                userName,
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _GlowBadge(
                                  label: userGoal,
                                  icon: Icons.flag_rounded,
                                  color: accent,
                                ),
                                _GlowBadge(
                                  label:
                                      'BMI ${bmi.toStringAsFixed(1)} · ${Helpers.getBMICategory(bmi)}',
                                  icon: Icons.monitor_heart_rounded,
                                  color: const Color(0xFF2979FF),
                                ),
                                _GlowBadge(
                                  label:
                                      '$completedWorkouts/$totalWorkouts workouts',
                                  icon: Icons.check_circle_rounded,
                                  color: const Color(0xFF00C853),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                _ActionButton(
                                  label: 'Start Workout',
                                  icon: Icons.play_arrow_rounded,
                                  accent: accent,
                                  theme: theme,
                                  onTap: () => onNavigate('Workouts'),
                                ),
                                const SizedBox(width: 12),
                                _OutlineButton(
                                  label: 'Diet Plan',
                                  icon: Icons.restaurant_rounded,
                                  accent: accent,
                                  onTap: () => onNavigate('Diet Plan'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),

                      // ── Athlete photo + streak chip ────────────────
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              _Imgs.welcomeAthlete,
                              width: 120,
                              height: 140,
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                              errorBuilder: (_, __, ___) => Container(
                                width: 120,
                                height: 140,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    colors: theme.accentGradient,
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.fitness_center_rounded,
                                    size: 44,
                                    color: theme.onAccent,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Glow border around athlete photo
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: accent.withOpacity(0.4),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                          // Streak chip
                          Positioned(
                            bottom: -10,
                            right: -10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.85),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: accent.withOpacity(0.4), width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: accent.withOpacity(0.3),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '47',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: accent,
                                      height: 1,
                                    ),
                                  ),
                                  Text(
                                    'Day Streak',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.white.withOpacity(0.5),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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
// STATS GRID
// ═══════════════════════════════════════════════════════════════════════════
class _StatsGrid extends StatelessWidget {
  final double userWeight;
  final double userHeight;
  final int userAge;
  final int totalCalories;
  final int completedWorkouts;
  final int totalWorkouts;
  final bool isDark;
  final Color accent;

  const _StatsGrid({
    required this.userWeight,
    required this.userHeight,
    required this.userAge,
    required this.totalCalories,
    required this.completedWorkouts,
    required this.totalWorkouts,
    required this.isDark,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final bmi = Helpers.calculateBMI(userWeight, userHeight);

    final stats = [
      {
        'label': 'Weight',
        'value': '${userWeight}kg',
        'color': const Color(0xFF2979FF),
        'bgImage': _Imgs.statWeight,
        'icon': Icons.monitor_weight_rounded,
      },
      {
        'label': 'Height',
        'value': '${userHeight}cm',
        'color': const Color(0xFFFF6D00),
        'bgImage': _Imgs.statHeight,
        'icon': Icons.height_rounded,
      },
      {
        'label': 'Age',
        'value': '$userAge yrs',
        'color': const Color(0xFFAA00FF),
        'bgImage': _Imgs.statAge,
        'icon': Icons.cake_rounded,
      },
      {
        'label': 'Calories',
        'value': '$totalCalories kcal',
        'color': const Color(0xFFFFD600),
        'bgImage': _Imgs.statCalories,
        'icon': Icons.local_fire_department_rounded,
      },
      {
        'label': 'BMI',
        'value': bmi.toStringAsFixed(1),
        'color': accent,
        'bgImage': _Imgs.statBmi,
        'icon': Icons.analytics_rounded,
      },
      {
        'label': 'Workouts',
        'value': '$completedWorkouts/$totalWorkouts',
        'color': const Color(0xFF00C853),
        'bgImage': _Imgs.statWorkouts,
        'icon': Icons.fitness_center_rounded,
      },
    ];

    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.4,
      children: stats.map((stat) {
        final color = stat['color'] as Color;
        final bgImage = stat['bgImage'] as String;
        final icon = stat['icon'] as IconData;

        return TiltCard(
          maxTilt: 5,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // ── Real photo background ──────────────────────────
                Positioned.fill(
                  child: Image.network(
                    bgImage,
                    fit: BoxFit.cover,
                    // Center crop so the subject is always visible
                    alignment: Alignment.center,
                    errorBuilder: (_, __, ___) => Container(
                      color: color.withOpacity(0.08),
                    ),
                  ),
                ),

                // ── Dark overlay — stronger so text is always readable ──
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.black.withOpacity(0.55),
                          Colors.black.withOpacity(0.78),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Accent border ──────────────────────────────────
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: color.withOpacity(0.25),
                        width: 1,
                      ),
                    ),
                  ),
                ),

                // ── Card content ───────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Frosted icon circle with glow
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withOpacity(0.15),
                          border: Border.all(
                              color: color.withOpacity(0.45), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.4),
                              blurRadius: 14,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                bgImage,
                                fit: BoxFit.cover,
                                alignment: Alignment.center,
                                errorBuilder: (_, __, ___) => Container(
                                  color: color.withOpacity(0.2),
                                  child: Center(
                                    child: Icon(
                                      icon,
                                      size: 20,
                                      color: color,
                                    ),
                                  ),
                                ),
                              ),
                              // Tint overlay so the icon colour reads clearly
                              Container(
                                color: color.withOpacity(0.2),
                              ),
                              // The icon on top of the photo
                              Center(
                                child: Icon(
                                  icon,
                                  size: 20,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: color.withOpacity(0.8),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [color, color.withOpacity(0.7)],
                              ).createShader(bounds),
                              child: Text(
                                stat['value'] as String,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Text(
                              stat['label'] as String,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.5),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WORKOUT CARD
// ═══════════════════════════════════════════════════════════════════════════
class _WorkoutCard extends StatelessWidget {
  final List<Map<String, dynamic>> todayWorkouts;
  final int completedWorkouts;
  final bool isDark;
  final Color accent;
  final void Function(int) onToggle;
  final void Function(BuildContext, String, String, IconData, Color)
      onShowTooltip;

  const _WorkoutCard({
    required this.todayWorkouts,
    required this.completedWorkouts,
    required this.isDark,
    required this.accent,
    required this.onToggle,
    required this.onShowTooltip,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? Colors.black.withOpacity(0.55)
              : Colors.white.withOpacity(0.85),
          border: Border.all(color: accent.withOpacity(0.15), width: 1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Banner image ─────────────────────────────────────────
            SizedBox(
              height: 90,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    _Imgs.workoutBanner,
                    fit: BoxFit.cover,
                    alignment: const Alignment(0, -0.2),
                    errorBuilder: (_, __, ___) => Container(
                      color: accent.withOpacity(0.08),
                    ),
                  ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.8),
                          Colors.black.withOpacity(0.4),
                          Colors.black.withOpacity(0.1),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                  // Banner content
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: accent.withOpacity(0.2),
                                border: Border.all(
                                    color: accent.withOpacity(0.4), width: 1),
                              ),
                              child: Icon(Icons.fitness_center_rounded,
                                  size: 16, color: accent),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Today's Workout",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  Helpers.formatDate(DateTime.now()),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: accent.withOpacity(0.15),
                            border: Border.all(
                                color: accent.withOpacity(0.4), width: 1),
                          ),
                          child: Text(
                            '$completedWorkouts/${todayWorkouts.length} done',
                            style: TextStyle(
                              fontSize: 11,
                              color: accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Workout items ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: todayWorkouts.asMap().entries.map((entry) {
                  final index = entry.key;
                  final workout = entry.value;
                  final color = workout['color'] as Color;
                  final isDone = workout['done'] as bool;
                  final muscle = workout['muscle'] as String? ?? '';
                  final icon = workout['icon'] as IconData? ??
                      Icons.fitness_center_rounded;
                  return _WorkoutItem(
                    workout: workout,
                    index: index,
                    color: color,
                    isDone: isDone,
                    icon: icon,
                    muscle: muscle,
                    isDark: isDark,
                    accent: accent,
                    onToggle: () => onToggle(index),
                    onShowTooltip: (title, msg) => onShowTooltip(
                      context,
                      title,
                      msg,
                      isDone
                          ? Icons.remove_circle_outline_rounded
                          : Icons.check_circle_rounded,
                      color,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutItem extends StatefulWidget {
  final Map<String, dynamic> workout;
  final int index;
  final Color color;
  final bool isDone;
  final IconData icon;
  final String muscle;
  final bool isDark;
  final Color accent;
  final VoidCallback onToggle;
  final void Function(String, String) onShowTooltip;

  const _WorkoutItem({
    required this.workout,
    required this.index,
    required this.color,
    required this.isDone,
    required this.icon,
    required this.muscle,
    required this.isDark,
    required this.accent,
    required this.onToggle,
    required this.onShowTooltip,
  });

  @override
  State<_WorkoutItem> createState() => _WorkoutItemState();
}

class _WorkoutItemState extends State<_WorkoutItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final exerciseImage = _Imgs.exerciseByMuscle(widget.muscle);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(
            context, '/exercise-detail',
            arguments: widget.workout),
        onLongPress: () {
          widget.onToggle();
          widget.onShowTooltip(
            widget.isDone ? 'Marked Incomplete' : 'Workout Complete! 🎉',
            widget.isDone
                ? '${widget.workout['name']} unchecked.'
                : '${widget.workout['name']} marked done!',
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: widget.isDone
                ? widget.color.withOpacity(0.1)
                : _hovered
                    ? widget.color.withOpacity(0.06)
                    : widget.isDark
                        ? Colors.white.withOpacity(0.04)
                        : Colors.black.withOpacity(0.03),
            border: Border.all(
              color: widget.isDone
                  ? widget.color.withOpacity(0.4)
                  : _hovered
                      ? widget.color.withOpacity(0.25)
                      : widget.isDark
                          ? Colors.white.withOpacity(0.08)
                          : Colors.black.withOpacity(0.08),
              width: 1,
            ),
            boxShadow: widget.isDone || _hovered
                ? [
                    BoxShadow(
                      color: widget.color.withOpacity(0.12),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // ── Real exercise photo thumbnail ──────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  children: [
                    Image.network(
                      exerciseImage,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: widget.color.withOpacity(0.15),
                        ),
                        child: Center(
                          child: Icon(widget.icon,
                              size: 20, color: widget.color),
                        ),
                      ),
                    ),
                    if (widget.isDone)
                      Positioned.fill(
                        child: Container(
                          color: widget.color.withOpacity(0.35),
                          child: const Center(
                            child: Icon(Icons.check_rounded,
                                size: 20, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.workout['name'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: widget.isDone
                            ? widget.color
                            : widget.isDark
                                ? Colors.white
                                : const Color(0xFF0A0A0A),
                        decoration: widget.isDone
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    Text(
                      '${widget.workout['sets']} sets × ${widget.workout['reps']} reps • Rest ${widget.workout['rest']}',
                      style: TextStyle(
                        fontSize: 11,
                        color: widget.isDark
                            ? Colors.white.withOpacity(0.4)
                            : Colors.black.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: widget.color.withOpacity(0.1),
                  border: Border.all(
                      color: widget.color.withOpacity(0.3), width: 1),
                ),
                child: Text(
                  widget.muscle,
                  style: TextStyle(
                    fontSize: 10,
                    color: widget.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isDone
                      ? widget.color
                      : Colors.transparent,
                  border: Border.all(
                    color: widget.isDone
                        ? widget.color
                        : widget.isDark
                            ? Colors.white.withOpacity(0.2)
                            : Colors.black.withOpacity(0.2),
                    width: 2,
                  ),
                  boxShadow: widget.isDone
                      ? [
                          BoxShadow(
                            color: widget.color.withOpacity(0.4),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
                child: widget.isDone
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MEALS CARD
// ═══════════════════════════════════════════════════════════════════════════
class _MealsCard extends StatelessWidget {
  final List<Map<String, dynamic>> todayMeals;
  final int totalCalories;
  final bool isDark;
  final Color accent;
  final void Function(BuildContext, String, String, IconData, Color)
      onShowTooltip;

  const _MealsCard({
    required this.todayMeals,
    required this.totalCalories,
    required this.isDark,
    required this.accent,
    required this.onShowTooltip,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? Colors.black.withOpacity(0.55)
              : Colors.white.withOpacity(0.85),
          border: Border.all(color: accent.withOpacity(0.15), width: 1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Banner image ─────────────────────────────────────────
            SizedBox(
              height: 90,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    _Imgs.mealBanner,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    errorBuilder: (_, __, ___) => Container(
                      color: accent.withOpacity(0.08),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.8),
                          Colors.black.withOpacity(0.35),
                          Colors.black.withOpacity(0.1),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: accent.withOpacity(0.2),
                                border: Border.all(
                                    color: accent.withOpacity(0.4), width: 1),
                              ),
                              child: Icon(Icons.restaurant_rounded,
                                  size: 16, color: accent),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Today's Meals",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Daily nutrition plan',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Text(
                          '$totalCalories kcal',
                          style: TextStyle(
                            fontSize: 15,
                            color: accent,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Meal body ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Progress bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Calories consumed',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? Colors.white.withOpacity(0.4)
                              : Colors.black.withOpacity(0.4),
                        ),
                      ),
                      Text(
                        '$totalCalories / 2000 kcal',
                        style: TextStyle(
                          fontSize: 11,
                          color: accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Stack(
                    children: [
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: accent.withOpacity(0.1),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor:
                            (totalCalories / 2000).clamp(0.0, 1.0),
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            gradient: LinearGradient(
                              colors: AppColors.gradientOf(context),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: accent.withOpacity(0.5),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Meal items
                  ...todayMeals.map((meal) {
                    final color = meal['color'] as Color;
                    final icon = meal['icon'] as IconData? ??
                        Icons.restaurant_rounded;
                    final mealName = meal['meal'] as String;
                    return _MealItem(
                      meal: meal,
                      color: color,
                      icon: icon,
                      mealName: mealName,
                      isDark: isDark,
                      onShowTooltip: () => onShowTooltip(
                        context,
                        mealName,
                        '${meal['items']} · ${meal['calories']} kcal',
                        icon,
                        color,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealItem extends StatefulWidget {
  final Map<String, dynamic> meal;
  final Color color;
  final IconData icon;
  final String mealName;
  final bool isDark;
  final VoidCallback onShowTooltip;

  const _MealItem({
    required this.meal,
    required this.color,
    required this.icon,
    required this.mealName,
    required this.isDark,
    required this.onShowTooltip,
  });

  @override
  State<_MealItem> createState() => _MealItemState();
}

class _MealItemState extends State<_MealItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final foodImage = _Imgs.foodByMealType(widget.mealName);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/meal-detail',
            arguments: widget.meal),
        onLongPress: widget.onShowTooltip,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: _hovered
                ? widget.color.withOpacity(0.08)
                : widget.isDark
                    ? Colors.white.withOpacity(0.04)
                    : Colors.black.withOpacity(0.03),
            border: Border.all(
              color: _hovered
                  ? widget.color.withOpacity(0.3)
                  : widget.isDark
                      ? Colors.white.withOpacity(0.07)
                      : Colors.black.withOpacity(0.07),
              width: 1,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: widget.color.withOpacity(0.1),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // ── Real food photo thumbnail ──────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  foodImage,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: widget.color.withOpacity(0.12),
                      border: Border.all(
                          color: widget.color.withOpacity(0.3), width: 1),
                    ),
                    child: Center(
                      child: Icon(widget.icon,
                          size: 18, color: widget.color),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.mealName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: widget.isDark
                            ? Colors.white
                            : const Color(0xFF0A0A0A),
                      ),
                    ),
                    Text(
                      widget.meal['items'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        color: widget.isDark
                            ? Colors.white.withOpacity(0.4)
                            : Colors.black.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${widget.meal['calories']} kcal',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: widget.color,
                    ),
                  ),
                  Text(
                    widget.meal['time'] as String,
                    style: TextStyle(
                      fontSize: 10,
                      color: widget.isDark
                          ? Colors.white.withOpacity(0.35)
                          : Colors.black.withOpacity(0.35),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// GUEST BANNER
// ═══════════════════════════════════════════════════════════════════════════
class _GuestBanner extends StatelessWidget {
  final bool isDark;
  final Color accent;

  const _GuestBanner({required this.isDark, required this.accent});

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      accent: accent,
      isDark: isDark,
      borderOpacity: 0.3,
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
                        color: accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: accent.withOpacity(0.3), width: 1),
                      ),
                      child: Text(
                        'FREE PLAN',
                        style: TextStyle(
                          fontSize: 10,
                          color: accent,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Unlock the full FitLife experience',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF0A0A0A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 16,
                  children: [
                    _FeatureChip('Cloud sync', accent),
                    _FeatureChip('50+ exercises', accent),
                    _FeatureChip('Advanced diet', accent),
                    _FeatureChip('Analytics', accent),
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
                        horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: accent.withOpacity(0.4), width: 1.5),
                      color: accent.withOpacity(0.06),
                    ),
                    child: Text(
                      'Sign In',
                      style: TextStyle(
                        color: accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/register'),
                  child: Consumer<ThemeProvider>(
                    builder: (context, theme, _) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient:
                            LinearGradient(colors: theme.accentGradient),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withOpacity(0.4),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.auto_awesome_rounded,
                              size: 14, color: theme.onAccent),
                          const SizedBox(width: 6),
                          Text(
                            'Create Free Account',
                            style: TextStyle(
                              color: theme.onAccent,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
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
}

// ═══════════════════════════════════════════════════════════════════════════
// LOCKED SECTION
// ═══════════════════════════════════════════════════════════════════════════
class _LockedSection extends StatelessWidget {
  final bool isDark;
  final Color accent;

  const _LockedSection({required this.isDark, required this.accent});

  @override
  Widget build(BuildContext context) {
    final features = [
      {
        'icon': Icons.fitness_center_rounded,
        'title': 'Full Exercise Library',
        'desc': '200+ exercises with video demos',
        'color': const Color(0xFF2979FF),
        'image': _Imgs.featureExercise,
      },
      {
        'icon': Icons.restaurant_menu_rounded,
        'title': 'Advanced Diet Plans',
        'desc': 'AI-generated meal plans',
        'color': const Color(0xFF00C853),
        'image': _Imgs.featureDiet,
      },
      {
        'icon': Icons.insights_rounded,
        'title': 'Progress Analytics',
        'desc': 'Charts and insights over time',
        'color': const Color(0xFFFF6D00),
        'image': _Imgs.featureAnalytics,
      },
      {
        'icon': Icons.cloud_sync_rounded,
        'title': 'Cloud Backup',
        'desc': 'Never lose your data',
        'color': const Color(0xFFAA00FF),
        'image': _Imgs.featureCloud,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.lock_rounded, size: 18, color: accent),
            const SizedBox(width: 8),
            Text(
              'Unlock Premium Features',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0A0A0A),
              ),
            ),
          ],
        ),
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
            final image = f['image'] as String;

            return TiltCard(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    // Real photo background
                    Positioned.fill(
                      child: Image.network(
                        image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(color: color.withOpacity(0.08)),
                      ),
                    ),
                    // Dark overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.5),
                              Colors.black.withOpacity(0.85),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Border
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: color.withOpacity(0.2), width: 1),
                        ),
                      ),
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: color.withOpacity(0.2),
                              border: Border.all(
                                  color: color.withOpacity(0.4), width: 1),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(0.3),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Center(
                                child: Icon(icon, size: 18, color: color)),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            f['title'] as String,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            f['desc'] as String,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Center(
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/register'),
              child: Consumer<ThemeProvider>(
                builder: (context, theme, _) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient:
                        LinearGradient(colors: theme.accentGradient),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withOpacity(0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.rocket_launch_rounded,
                          size: 18, color: theme.onAccent),
                      const SizedBox(width: 10),
                      Text(
                        'Create Your Free Account Now',
                        style: TextStyle(
                          color: theme.onAccent,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SMALL REUSABLE WIDGETS
// ═══════════════════════════════════════════════════════════════════════════
class _GlowBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _GlowBadge({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withOpacity(0.12),
        border: Border.all(color: color.withOpacity(0.35), width: 1),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.15), blurRadius: 8),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accent;
  final ThemeProvider theme;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.accent,
    required this.theme,
    required this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient:
                LinearGradient(colors: widget.theme.accentGradient),
            boxShadow: [
              BoxShadow(
                color: widget.accent
                    .withOpacity(_hovered ? 0.55 : 0.35),
                blurRadius: _hovered ? 20 : 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 16, color: widget.theme.onAccent),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.theme.onAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutlineButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  const _OutlineButton({
    required this.label,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  @override
  State<_OutlineButton> createState() => _OutlineButtonState();
}

class _OutlineButtonState extends State<_OutlineButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: _hovered
                ? widget.accent.withOpacity(0.12)
                : widget.accent.withOpacity(0.06),
            border: Border.all(
              color: _hovered
                  ? widget.accent.withOpacity(0.5)
                  : widget.accent.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 16, color: widget.accent),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final String text;
  final Color accent;
  const _FeatureChip(this.text, this.accent);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle_rounded, size: 13, color: accent),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: accent.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}