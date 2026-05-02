import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/data/app_data.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../services/storage_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
// IMAGE URLS  (mirrors web _Imgs class)
// ═══════════════════════════════════════════════════════════════════════════
class _Imgs {
  static const welcomeBg =
      'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b'
      '?w=900&q=80&auto=format&fit=crop';
  static const welcomeAthlete =
      'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61'
      '?w=300&q=80&auto=format&fit=crop';

  static const statWeight =
      'https://images.unsplash.com/photo-1526506118085-60ce8714f8c5'
      '?w=300&q=80&auto=format&fit=crop';
  static const statHeight =
      'https://images.unsplash.com/photo-1552674605-db6ffd4facb5'
      '?w=300&q=80&auto=format&fit=crop';
  static const statAge =
      'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61'
      '?w=300&q=80&auto=format&fit=crop';
  static const statCalories =
      'https://images.unsplash.com/photo-1512621776951-a57141f2eefd'
      '?w=300&q=80&auto=format&fit=crop';

  static const workoutBanner =
      'https://images.unsplash.com/photo-1534438327276-14e5300c3a48'
      '?w=800&q=80&auto=format&fit=crop';
  static const mealBanner =
      'https://images.unsplash.com/photo-1547592180-85f173990554'
      '?w=800&q=80&auto=format&fit=crop';

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

  static String exerciseByMuscle(String muscle) {
    switch (muscle.toLowerCase()) {
      case 'chest':      return exerciseChest;
      case 'back':       return exerciseBack;
      case 'legs':       return exerciseLegs;
      case 'shoulders':  return exerciseShoulders;
      case 'arms':       return exerciseArms;
      case 'core':       return exerciseCore;
      default:           return exerciseDefault;
    }
  }

  static String foodByMealType(String mealName) {
    final lower = mealName.toLowerCase();
    if (lower.contains('breakfast')) return foodBreakfast;
    if (lower.contains('lunch'))     return foodLunch;
    if (lower.contains('snack'))     return foodSnack;
    if (lower.contains('dinner'))    return foodDinner;
    return foodDefault;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MOBILE DASHBOARD
// ═══════════════════════════════════════════════════════════════════════════
class MobileDashboard extends StatefulWidget {
  final bool isLoggedIn;
  final bool isLoadingData;
  final List<Map<String, dynamic>> todayWorkouts;
  final List<Map<String, dynamic>> todayMeals;
  final void Function(int index, int workoutIndex) onToggleWorkout;

  const MobileDashboard({
    super.key,
    required this.isLoggedIn,
    required this.isLoadingData,
    required this.todayWorkouts,
    required this.todayMeals,
    required this.onToggleWorkout,
  });

  @override
  State<MobileDashboard> createState() => _MobileDashboardState();
}

class _MobileDashboardState extends State<MobileDashboard>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _tooltipOverlay;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  String? _homeBannerPath;
  String? _profilePhotoPath;

  String get userName     => AppData.userName;
  double get userWeight   => AppData.userWeight;
  double get userHeight   => AppData.userHeight;
  int    get userAge      => AppData.userAge;
  String get userGoal     => AppData.userGoal;

  int get completedWorkouts =>
      widget.todayWorkouts.where((w) => w['done'] == true).length;
  int get totalCalories =>
      widget.todayMeals.fold(0, (sum, m) => sum + (m['calories'] as int));
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _loadSavedImages();
  }

  Future<void> _loadSavedImages() async {
    final banner = await StorageService.getHomeBanner();
    final photo = await StorageService.getProfilePhoto();
    if (mounted) {
      setState(() {
        _homeBannerPath = banner;
        _profilePhotoPath = photo;
      });
    }
  }

  @override
  void dispose() {
    _tooltipOverlay?.remove();
    _pulseController.dispose();
    super.dispose();
  }

  void _showTooltip(BuildContext context, String title, String message,
      IconData icon, Color color) {
    _tooltipOverlay?.remove();
    _tooltipOverlay = null;
    final overlay = Overlay.of(context);
    _tooltipOverlay = OverlayEntry(
      builder: (ctx) => Positioned(
        left: 0,
        right: 0,
        top: MediaQuery.of(ctx).size.height * 0.35,
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
                          color: color.withOpacity(0.3), blurRadius: 20),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(icon, size: 14, color: color),
                        const SizedBox(width: 8),
                        Text(title,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: color)),
                      ]),
                      const SizedBox(height: 6),
                      Text(message,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.8))),
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
    Future.delayed(const Duration(milliseconds: 2500),
        () => _tooltipOverlay?.remove());
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final accent  = AppColors.of(context);
    final textPrimary   = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final textSecondary =
        isDark ? const Color(0xFFB0B0B0) : const Color(0xFF555555);
    final borderColor =
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────
          _buildHeader(isDark, accent, textPrimary, textSecondary),
          const SizedBox(height: 16),

          // ── Hero banner (with real gym photo + athlete) ──────────────
          _buildHeroBanner(isDark, accent, textPrimary),
          const SizedBox(height: 16),

          // ── 2 × 2 Stats grid ────────────────────────────────────────
          _buildStatsGrid(isDark, accent),
          const SizedBox(height: 16),

          // ── Guest banner ─────────────────────────────────────────────
          if (!widget.isLoggedIn) ...[
            _buildGuestBanner(isDark, accent, textPrimary, textSecondary),
            const SizedBox(height: 20),
          ],

          // ── Workouts ─────────────────────────────────────────────────
          if (widget.isLoadingData)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(
                    color: accent, strokeWidth: 2.5),
              ),
            )
          else ...[
            _buildSectionTitle(
              "Today's Workout",
              "$completedWorkouts/${widget.todayWorkouts.length} done",
              textPrimary,
              Icons.fitness_center_rounded,
              accent,
            ),
            const SizedBox(height: 8),
            _buildHintBanner(isDark, accent, textSecondary),
            const SizedBox(height: 10),

            // Workout banner image strip
            _buildBannerStrip(_Imgs.workoutBanner, accent),
            const SizedBox(height: 10),

            ...widget.todayWorkouts.asMap().entries.map((e) =>
                _WorkoutCard(
                  index: e.key,
                  workout: e.value,
                  isDark: isDark,
                  accent: accent,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  borderColor: borderColor,
                  onToggle: () {
                    widget.onToggleWorkout(e.key, e.key);
                    final isDone = e.value['done'] as bool;
                    _showTooltip(
                      context,
                      isDone ? 'Marked Incomplete' : 'Workout Complete! 🎉',
                      isDone
                          ? '${e.value['name']} has been unchecked.'
                          : '${e.value['name']} marked as done!',
                      isDone
                          ? Icons.remove_circle_outline_rounded
                          : Icons.check_circle_rounded,
                      e.value['color'] as Color,
                    );
                  },
                )),
            const SizedBox(height: 20),

            // ── Meals ────────────────────────────────────────────────
            _buildSectionTitle(
              "Today's Meals",
              "$totalCalories kcal",
              textPrimary,
              Icons.restaurant_rounded,
              accent,
            ),
            const SizedBox(height: 8),
            _buildCalorieProgress(isDark, accent, textSecondary),

            // Meal banner image strip
            _buildBannerStrip(_Imgs.mealBanner, accent),
            const SizedBox(height: 10),

            ...widget.todayMeals.map((meal) => _MealCard(
                  meal: meal,
                  isDark: isDark,
                  accent: accent,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  borderColor: borderColor,
                )),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────
  Widget _buildHeader(bool isDark, Color accent, Color textPrimary,
      Color textSecondary) {
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
                  color: accent.withOpacity(0.12),
                  border: Border.all(color: accent.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.flag_rounded, size: 11, color: accent),
                    const SizedBox(width: 4),
                    Text(userGoal,
                        style: TextStyle(
                            fontSize: 11,
                            color: accent,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Animated avatar
        // Animated avatar
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) => Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withOpacity(0.15),
              border: Border.all(
                  color: accent.withOpacity(0.4 * _pulseAnim.value), width: 2),
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(0.2 * _pulseAnim.value),
                  blurRadius: 12 * _pulseAnim.value,
                  spreadRadius: 2 * _pulseAnim.value,
                ),
              ],
            ),
            child: ClipOval(
              child: _profilePhotoPath != null
                  ? (_profilePhotoPath!.startsWith('http')
                      ? Image.network(
                          _profilePhotoPath!,
                          key: ValueKey(_profilePhotoPath),
                          fit: BoxFit.cover,
                          width: 46,
                          height: 46,
                          errorBuilder: (_, __, ___) => Center(
                            child: Icon(Icons.person_rounded,
                                size: 22, color: accent)),
                        )
                      : Image.file(
                          File(_profilePhotoPath!),
                          fit: BoxFit.cover,
                          width: 46,
                          height: 46,
                        ))
                  : Center(
                      child: Icon(Icons.person_rounded,
                          size: 22, color: accent)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Column(children: [
          Text(
            'BMI ${Helpers.calculateBMI(userWeight, userHeight).toStringAsFixed(1)}',
            style: TextStyle(
                fontSize: 10, color: accent, fontWeight: FontWeight.w600),
          ),
        ]),
        const SizedBox(width: 8),
        Consumer<ThemeProvider>(
          builder: (context, theme, _) => GestureDetector(
            onTap: () =>
                Provider.of<ThemeProvider>(context, listen: false)
                    .toggleTheme(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withOpacity(0.12),
                border: Border.all(color: accent.withOpacity(0.3)),
              ),
              child: Center(
                child: Icon(
                  theme.isDark
                      ? Icons.wb_sunny_rounded
                      : Icons.dark_mode_rounded,
                  size: 17,
                  color: accent,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Hero banner — gym photo bg + athlete photo + streak chip ───────────
  Widget _buildHeroBanner(bool isDark, Color accent, Color textPrimary) {
    final bmi = Helpers.calculateBMI(userWeight, userHeight);
    return Consumer<ThemeProvider>(
      builder: (context, theme, _) => GestureDetector(
        onLongPress: () async {
          final picker = ImagePicker();
          final picked = await picker.pickImage(
              source: ImageSource.gallery, imageQuality: 85);
          if (picked != null) {
            await StorageService.saveHomeBanner(picked.path);
            if (mounted) setState(() => _homeBannerPath = picked.path);
          }
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
          width: double.infinity,
          child: Stack(
            children: [
              // Real gym photo background
              // Real gym photo background
              Positioned.fill(
                child: _homeBannerPath != null
                    ? Image.file(
                        File(_homeBannerPath!),
                        fit: BoxFit.cover,
                        alignment: const Alignment(0, -0.3),
                      )
                    : Image.network(
                        _Imgs.welcomeBg,
                        fit: BoxFit.cover,
                        alignment: const Alignment(0, -0.3),
                        errorBuilder: (_, __, ___) =>
                            Container(color: accent.withOpacity(0.08)),
                      ),
              ),
              // Dark gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.88),
                        Colors.black.withOpacity(0.60),
                        Colors.black.withOpacity(0.20),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
              // Accent border
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: accent.withOpacity(0.3), width: 1.5),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Badges
                          Wrap(
                            spacing: 5,
                            runSpacing: 5,
                            children: [
                              _glowBadge(userGoal, Icons.flag_rounded, accent),
                              _glowBadge(
                                'BMI ${bmi.toStringAsFixed(1)}',
                                Icons.monitor_heart_rounded,
                                const Color(0xFF2979FF),
                              ),
                              _glowBadge(
                                '$completedWorkouts/${widget.todayWorkouts.length} done',
                                Icons.check_circle_rounded,
                                const Color(0xFF00C853),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Action buttons — Wrap so they stack if needed
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _actionButton('Start Workout',
                                  Icons.play_arrow_rounded, accent, theme, context),
                              _outlineButton('Diet Plan',
                                  Icons.restaurant_rounded, accent, context),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // ── Athlete photo + streak chip ──────────────────
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            _Imgs.welcomeAthlete,
                            width: 90,
                            height: 110,
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                            errorBuilder: (_, __, ___) => Container(
                              width: 90,
                              height: 110,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: LinearGradient(
                                    colors: theme.accentGradient),
                              ),
                              child: Center(
                                child: Icon(Icons.fitness_center_rounded,
                                    size: 34, color: theme.onAccent),
                              ),
                            ),
                          ),
                        ),
                        // Glow border on athlete photo
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: accent.withOpacity(0.4), width: 1.5),
                            ),
                          ),
                        ),
                        // Streak chip
                        Positioned(
                          bottom: -10,
                          right: -10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: accent.withOpacity(0.4), width: 1),
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withOpacity(0.35),
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
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: accent,
                                    height: 1,
                                  ),
                                ),
                                Text(
                                  'Day Streak',
                                  style: TextStyle(
                                    fontSize: 8,
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

  // ── 2 × 2 Stats grid ────────────────────────────────────────────────────
  Widget _buildStatsGrid(bool isDark, Color accent) {
    final stats = [
      {
        'label':   'Weight',
        'value':   '${userWeight}kg',
        'color':   const Color(0xFF2979FF),
        'bgImage': _Imgs.statWeight,
        'icon':    Icons.monitor_weight_rounded,
      },
      {
        'label':   'Height',
        'value':   '${userHeight}cm',
        'color':   const Color(0xFFFF6D00),
        'bgImage': _Imgs.statHeight,
        'icon':    Icons.height_rounded,
      },
      {
        'label':   'Age',
        'value':   '$userAge yrs',
        'color':   const Color(0xFFAA00FF),
        'bgImage': _Imgs.statAge,
        'icon':    Icons.cake_rounded,
      },
      {
        'label':   'Calories',
        'value':   '$totalCalories kcal',
        'color':   const Color(0xFFFFD600),
        'bgImage': _Imgs.statCalories,
        'icon':    Icons.local_fire_department_rounded,
      },
    ];

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.0,
      children: stats.map((stat) {
        final color   = stat['color']   as Color;
        final bgImage = stat['bgImage'] as String;
        final icon    = stat['icon']    as IconData;

        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Real photo background
              Positioned.fill(
                child: Image.network(
                  bgImage,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  errorBuilder: (_, __, ___) =>
                      Container(color: color.withOpacity(0.08)),
                ),
              ),
              // Dark overlay
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
              // Accent border
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: color.withOpacity(0.25), width: 1),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Icon circle with photo inside
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: color.withOpacity(0.45), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.4),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(bgImage,
                                fit: BoxFit.cover,
                                alignment: Alignment.center,
                                errorBuilder: (_, __, ___) => Container(
                                    color: color.withOpacity(0.2))),
                            Container(color: color.withOpacity(0.2)),
                            Center(
                              child: Icon(icon,
                                  size: 18,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                        color: color.withOpacity(0.8),
                                        blurRadius: 6)
                                  ]),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
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
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Text(
                            stat['label'] as String,
                            style: TextStyle(
                              fontSize: 10,
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
        );
      }).toList(),
    );
  }

  // ── Section title ────────────────────────────────────────────────────────
  Widget _buildSectionTitle(String title, String subtitle, Color textPrimary,
      IconData icon, Color accent) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withOpacity(0.12),
              boxShadow: [
                BoxShadow(color: accent.withOpacity(0.25), blurRadius: 8),
              ],
            ),
            child: Icon(icon, size: 14, color: accent),
          ),
          const SizedBox(width: 8),
          Text(title,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textPrimary)),
        ]),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: accent.withOpacity(0.12),
            border: Border.all(color: accent.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(color: accent.withOpacity(0.15), blurRadius: 6),
            ],
          ),
          child: Text(subtitle,
              style: TextStyle(
                  fontSize: 11,
                  color: accent,
                  fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  // ── Banner image strip (for workout / meal sections) ────────────────────
  Widget _buildBannerStrip(String imageUrl, Color accent) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: double.infinity,
        height: 72,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              alignment: const Alignment(0, -0.3),
              errorBuilder: (_, __, ___) =>
                  Container(color: accent.withOpacity(0.08)),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.black.withOpacity(0.2),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
            // Left accent bar
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      accent.withOpacity(0.1),
                      accent,
                      accent.withOpacity(0.1),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Hint banner ──────────────────────────────────────────────────────────
  Widget _buildHintBanner(bool isDark, Color accent, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: accent.withOpacity(0.06),
        border: Border.all(color: accent.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.touch_app_rounded,
              size: 13, color: accent.withOpacity(0.7)),
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
    );
  }

  // ── Calorie progress ─────────────────────────────────────────────────────
  Widget _buildCalorieProgress(
      bool isDark, Color accent, Color textSecondary) {
    return Consumer<ThemeProvider>(
      builder: (context, theme, _) => Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Calories consumed',
                  style: TextStyle(fontSize: 11, color: textSecondary)),
              Text('$totalCalories / 2000 kcal',
                  style: TextStyle(
                      fontSize: 11,
                      color: accent,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          Stack(
            children: [
              Container(
                height: 5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: accent.withOpacity(0.1),
                ),
              ),
              FractionallySizedBox(
                widthFactor: (totalCalories / 2000).clamp(0.0, 1.0),
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    gradient: LinearGradient(colors: theme.accentGradient),
                    boxShadow: [
                      BoxShadow(
                          color: accent.withOpacity(0.5), blurRadius: 4),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // ── Guest banner ─────────────────────────────────────────────────────────
  Widget _buildGuestBanner(bool isDark, Color accent, Color textPrimary,
      Color textSecondary) {
    return Consumer<ThemeProvider>(
      builder: (context, theme, _) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isDark
              ? Colors.white.withOpacity(0.04)
              : Colors.white.withOpacity(0.85),
          border: Border.all(color: accent.withOpacity(0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(isDark ? 0.15 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border:
                      Border.all(color: accent.withOpacity(0.3), width: 1),
                ),
                child: Text('FREE PLAN',
                    style: TextStyle(
                        fontSize: 9,
                        color: accent,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1)),
              ),
              const SizedBox(width: 8),
              Icon(Icons.lock_open_rounded, size: 13, color: accent),
              const SizedBox(width: 5),
              Text('Unlock More Features',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textPrimary)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Flexible(
                flex: 3,
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/register'),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient:
                          LinearGradient(colors: theme.accentGradient),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_awesome_rounded,
                              size: 13, color: theme.onAccent),
                          const SizedBox(width: 5),
                          Text('Create Free Account',
                              style: TextStyle(
                                  color: theme.onAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                        ],
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
                    border: Border.all(color: accent.withOpacity(0.5)),
                  ),
                  child: Center(
                      child: Text('Sign In',
                          style: TextStyle(
                              color: accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600))),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  // ── Small helpers ─────────────────────────────────────────────────────────
  Widget _glowBadge(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withOpacity(0.12),
        border: Border.all(color: color.withOpacity(0.35), width: 1),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.15), blurRadius: 6),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _actionButton(String label, IconData icon, Color accent,
      ThemeProvider theme, BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/workout'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(colors: theme.accentGradient),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: theme.onAccent),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    color: theme.onAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _outlineButton(String label, IconData icon, Color accent,
      BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/diet'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: accent.withOpacity(0.08),
          border: Border.all(color: accent.withOpacity(0.35), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: accent),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WORKOUT CARD  (extracted widget with photo thumbnail)
// ═══════════════════════════════════════════════════════════════════════════
class _WorkoutCard extends StatelessWidget {
  final int index;
  final Map<String, dynamic> workout;
  final bool isDark;
  final Color accent;
  final Color textPrimary;
  final Color textSecondary;
  final Color borderColor;
  final VoidCallback onToggle;

  const _WorkoutCard({
    required this.index,
    required this.workout,
    required this.isDark,
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
    required this.borderColor,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final color  = workout['color']  as Color;
    final isDone = workout['done']   as bool;
    final icon   = workout['icon']   as IconData? ?? Icons.fitness_center_rounded;
    final muscle = workout['muscle'] as String?  ?? '';
    final exerciseImage = _Imgs.exerciseByMuscle(muscle);

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/exercise-detail',
          arguments: workout),
      onLongPress: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isDone
              ? color.withOpacity(0.1)
              : isDark
                  ? Colors.white.withOpacity(0.04)
                  : Colors.white.withOpacity(0.85),
          border: Border.all(
              color: isDone ? color.withOpacity(0.4) : borderColor),
          boxShadow: isDone
              ? [
                  BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ]
              : [
                  BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
        ),
        child: Row(
          children: [
            // ── Real exercise photo thumbnail ───────────────────────
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
                        color: color.withOpacity(0.15),
                      ),
                      child: Center(
                          child: Icon(icon, size: 20, color: color)),
                    ),
                  ),
                  if (isDone)
                    Positioned.fill(
                      child: Container(
                        color: color.withOpacity(0.35),
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
                  Text(workout['name'] as String,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDone ? color : textPrimary,
                          decoration:
                              isDone ? TextDecoration.lineThrough : null)),
                  Text(
                      '${workout['sets']} sets × ${workout['reps']} reps • Rest ${workout['rest']}',
                      style:
                          TextStyle(fontSize: 11, color: textSecondary)),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: color.withOpacity(0.1),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Text(muscle,
                  style: TextStyle(
                      fontSize: 9,
                      color: color,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone ? color : Colors.transparent,
                border: Border.all(
                    color: isDone ? color : borderColor, width: 2),
                boxShadow: isDone
                    ? [
                        BoxShadow(
                            color: color.withOpacity(0.4), blurRadius: 6)
                      ]
                    : null,
              ),
              child: isDone
                  ? const Icon(Icons.check, size: 11, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MEAL CARD  (extracted widget with food photo thumbnail)
// ═══════════════════════════════════════════════════════════════════════════
class _MealCard extends StatelessWidget {
  final Map<String, dynamic> meal;
  final bool isDark;
  final Color accent;
  final Color textPrimary;
  final Color textSecondary;
  final Color borderColor;

  const _MealCard({
    required this.meal,
    required this.isDark,
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final color    = meal['color'] as Color;
    final icon     = meal['icon']  as IconData? ?? Icons.restaurant_rounded;
    final mealName = meal['meal']  as String;
    final foodImage = _Imgs.foodByMealType(mealName);

    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, '/meal-detail', arguments: meal),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isDark
              ? Colors.white.withOpacity(0.04)
              : Colors.white.withOpacity(0.85),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(isDark ? 0.08 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Real food photo thumbnail ───────────────────────────
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
                    color: color.withOpacity(0.12),
                    border:
                        Border.all(color: color.withOpacity(0.3), width: 1),
                  ),
                  child: Center(
                      child: Icon(icon, size: 18, color: color)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(mealName,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textPrimary)),
                  Text(meal['items'] as String,
                      style: TextStyle(
                          fontSize: 11, color: textSecondary)),
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
  }
}