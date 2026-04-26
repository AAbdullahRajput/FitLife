import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/data/app_data.dart';

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
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
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
                      BoxShadow(color: color.withOpacity(0.3), blurRadius: 20),
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
    Future.delayed(
        const Duration(milliseconds: 2500), () => _tooltipOverlay?.remove());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppColors.of(context);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final textSecondary =
        isDark ? const Color(0xFFB0B0B0) : const Color(0xFF555555);
    final cardColor = isDark
        ? Colors.white.withOpacity(0.04)
        : Colors.white.withOpacity(0.85);
    final borderColor =
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────
          _buildHeader(isDark, accent, textPrimary, textSecondary),
          const SizedBox(height: 20),

          // ── Hero banner ───────────────────────────────────────────────
          _buildHeroBanner(isDark, accent, textPrimary),
          const SizedBox(height: 16),

          // ── Stats row ─────────────────────────────────────────────────
          _buildStatsRow(isDark, accent, textPrimary),
          const SizedBox(height: 16),

          // ── Guest banner ──────────────────────────────────────────────
          if (!widget.isLoggedIn) ...[
            _buildGuestBanner(isDark, accent, textPrimary, textSecondary),
            const SizedBox(height: 20),
          ],

          // ── Workouts ──────────────────────────────────────────────────
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
                accent),
            const SizedBox(height: 8),
            _buildHintBanner(isDark, accent, textSecondary),
            const SizedBox(height: 12),
            ...widget.todayWorkouts.asMap().entries.map((entry) =>
                _buildWorkoutCard(
                    entry.key, entry.value, isDark, accent,
                    textPrimary, textSecondary, cardColor, borderColor)),
            const SizedBox(height: 20),

            // ── Meals ──────────────────────────────────────────────────
            _buildSectionTitle("Today's Meals", "$totalCalories kcal",
                textPrimary, Icons.restaurant_rounded, accent),
            const SizedBox(height: 8),
            // Calorie progress bar
            _buildCalorieProgress(isDark, accent, textSecondary),
            const SizedBox(height: 12),
            ...widget.todayMeals.map((meal) =>
                _buildMealCard(meal, isDark, accent, textPrimary,
                    textSecondary, cardColor, borderColor)),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
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
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) => Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withOpacity(0.15),
              border: Border.all(
                  color: accent.withOpacity(0.4 * _pulseAnim.value),
                  width: 2),
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(0.2 * _pulseAnim.value),
                  blurRadius: 12 * _pulseAnim.value,
                  spreadRadius: 2 * _pulseAnim.value,
                ),
              ],
            ),
            child: Center(
                child: Icon(Icons.person_rounded, size: 22, color: accent)),
          ),
        ),
        const SizedBox(width: 8),
        // BMI badge
        Column(
          children: [
            Text(
              'BMI ${Helpers.calculateBMI(userWeight, userHeight).toStringAsFixed(1)}',
              style: TextStyle(
                  fontSize: 10,
                  color: accent,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
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

  // ── Hero banner ────────────────────────────────────────────────────────────
  Widget _buildHeroBanner(bool isDark, Color accent, Color textPrimary) {
    final bmi = Helpers.calculateBMI(userWeight, userHeight);
    return Consumer<ThemeProvider>(
      builder: (context, theme, _) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: isDark
                ? [
                    accent.withOpacity(0.25),
                    accent.withOpacity(0.08),
                    const Color(0xFF0A0A0F).withOpacity(0.6),
                  ]
                : [
                    accent.withOpacity(0.18),
                    accent.withOpacity(0.06),
                    Colors.white.withOpacity(0.8),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
              color: accent.withOpacity(0.35), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(isDark ? 0.2 : 0.1),
              blurRadius: 24,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges row
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _glowBadge(userGoal, Icons.flag_rounded, accent),
                      _glowBadge(
                          'BMI ${bmi.toStringAsFixed(1)} · ${Helpers.getBMICategory(bmi)}',
                          Icons.monitor_heart_rounded,
                          const Color(0xFF2979FF)),
                      _glowBadge(
                          '$completedWorkouts/${widget.todayWorkouts.length} workouts',
                          Icons.check_circle_rounded,
                          const Color(0xFF00C853)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Action buttons
                  Row(
                    children: [
                      _actionButton('Start Workout',
                          Icons.play_arrow_rounded, accent, theme, context),
                      const SizedBox(width: 10),
                      _outlineButton('Diet Plan',
                          Icons.restaurant_rounded, accent, context),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Glowing fitness icon
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: theme.accentGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withOpacity(0.5 * _pulseAnim.value),
                      blurRadius: 20 * _pulseAnim.value,
                      spreadRadius: 2 * _pulseAnim.value,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(Icons.fitness_center_rounded,
                      size: 28, color: theme.onAccent),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(colors: theme.accentGradient),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: theme.onAccent),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: theme.onAccent,
                    fontSize: 12,
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: accent.withOpacity(0.08),
          border: Border.all(color: accent.withOpacity(0.35), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: accent),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ── Stats row ──────────────────────────────────────────────────────────────
  Widget _buildStatsRow(bool isDark, Color accent, Color textPrimary) {
    return Row(
      children: [
        _statCard('Weight', '${userWeight}kg',
            Icons.monitor_weight_rounded, const Color(0xFF2979FF),
            textPrimary, isDark),
        const SizedBox(width: 8),
        _statCard('Height', '${userHeight}cm',
            Icons.height_rounded, const Color(0xFFFF6D00),
            textPrimary, isDark),
        const SizedBox(width: 8),
        _statCard('Age', '${userAge}yrs', Icons.cake_rounded,
            const Color(0xFFAA00FF), textPrimary, isDark),
        const SizedBox(width: 8),
        _statCard('Calories', '$totalCalories',
            Icons.local_fire_department_rounded,
            const Color(0xFFFFD600), textPrimary, isDark),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color,
      Color textPrimary, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isDark ? Colors.white.withOpacity(0.04) : Colors.white.withOpacity(0.85),
          border: Border.all(color: color.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(isDark ? 0.15 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.12),
                border: Border.all(color: color.withOpacity(0.3), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.25),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Center(child: Icon(icon, size: 16, color: color)),
            ),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 9, color: textPrimary.withOpacity(0.4))),
          ],
        ),
      ),
    );
  }

  // ── Section title ──────────────────────────────────────────────────────────
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

  // ── Hint banner ────────────────────────────────────────────────────────────
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

  // ── Workout card ───────────────────────────────────────────────────────────
  Widget _buildWorkoutCard(int index, Map<String, dynamic> workout,
      bool isDark, Color accent, Color textPrimary, Color textSecondary,
      Color cardColor, Color borderColor) {
    final color = workout['color'] as Color;
    final isDone = workout['done'] as bool;
    final icon =
        workout['icon'] as IconData? ?? Icons.fitness_center_rounded;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/exercise-detail',
          arguments: workout),
      onLongPress: () {
        widget.onToggleWorkout(index, index);
        _showTooltip(
          context,
          isDone ? 'Marked Incomplete' : 'Workout Complete! 🎉',
          isDone
              ? '${workout['name']} has been unchecked.'
              : '${workout['name']} marked as done!',
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
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(isDone ? 0.2 : 0.1),
                boxShadow: isDone
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
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
                          decoration:
                              isDone ? TextDecoration.lineThrough : null)),
                  Text(
                      '${workout['sets']} sets × ${workout['reps']} reps • Rest ${workout['rest']}',
                      style: TextStyle(
                          fontSize: 11, color: textSecondary)),
                ],
              ),
            ),
            // Muscle tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: color.withOpacity(0.1),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Text(
                workout['muscle'] as String? ?? '',
                style:
                    TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w700),
              ),
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
                          color: color.withOpacity(0.4),
                          blurRadius: 6,
                        ),
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

  // ── Calorie progress ───────────────────────────────────────────────────────
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
                    gradient: LinearGradient(
                      colors: theme.accentGradient,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withOpacity(0.5),
                        blurRadius: 4,
                      ),
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

  // ── Meal card ──────────────────────────────────────────────────────────────
  Widget _buildMealCard(Map<String, dynamic> meal, bool isDark, Color accent,
      Color textPrimary, Color textSecondary, Color cardColor,
      Color borderColor) {
    final color = meal['color'] as Color;
    final icon = meal['icon'] as IconData? ?? Icons.restaurant_rounded;

    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, '/meal-detail', arguments: meal),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
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
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.12),
                border: Border.all(color: color.withOpacity(0.3), width: 1),
                boxShadow: [
                  BoxShadow(color: color.withOpacity(0.2), blurRadius: 8),
                ],
              ),
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

  // ── Guest banner ───────────────────────────────────────────────────────────
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
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: accent.withOpacity(0.5)),
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
}