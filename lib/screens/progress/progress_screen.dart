// ══════════════════════════════════════════════════════════════════════════════
// lib/screens/progress/progress_screen.dart
// ══════════════════════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../core/data/app_data.dart';
import '../../core/utils/helpers.dart';
import '../../services/supabase_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoading = true;
  bool _isLoggedIn = false;

  // ── Summary stats ──────────────────────────────────────────────────────────
  int _totalWorkoutsThisWeek = 0;
  int _totalMealsThisWeek = 0;
  int _currentStreak = 0;
  double _weeklyCalories = 0;

  // ── Chart data ─────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _weeklyWorkouts = []; // {day, count}
  List<Map<String, dynamic>> _weeklyMeals = [];    // {day, calories}
  Map<String, int> _muscleBreakdown = {};           // {muscle: count}
  List<Map<String, dynamic>> _weightHistory = [];   // {date, weight}

  // ── Weight log ─────────────────────────────────────────────────────────────
  final _weightController = TextEditingController();
  bool _isSavingWeight = false;

  // ── Profile ────────────────────────────────────────────────────────────────
  double _currentWeight = AppData.userWeight;
  double _userHeight = AppData.userHeight;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkLoginAndLoad();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _checkLoginAndLoad() async {
    final session = Supabase.instance.client.auth.currentSession;
    setState(() => _isLoggedIn = session != null);
    await _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _loadWeeklyWorkouts(),
        _loadWeeklyMeals(),
        _loadMuscleBreakdown(),
        if (_isLoggedIn) _loadWeightHistory(),
        if (_isLoggedIn) _loadProfile(),
      ]);
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  // ── Last 7 days dates ──────────────────────────────────────────────────────
  List<DateTime> get _last7Days {
    final now = DateTime.now();
    return List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
  }

  String _toDateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _dayLabel(DateTime d) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[d.weekday - 1];
  }

  Future<void> _loadWeeklyWorkouts() async {
    final client = Supabase.instance.client;
    final days = _last7Days;
    final startDate = _toDateStr(days.first);
    final endDate = _toDateStr(days.last);

    List<Map<String, dynamic>> rows = [];

    if (_isLoggedIn) {
      try {
        final res = await client
            .from('user_workouts')
            .select('date, completed')
            .eq('user_id', client.auth.currentUser!.id)
            .gte('date', startDate)
            .lte('date', endDate);
        rows = List<Map<String, dynamic>>.from(res);
      } catch (_) {}
    }

    // Build per-day counts
    final weeklyData = days.map((day) {
      final dateStr = _toDateStr(day);
      final count = rows.where((r) => r['date'] == dateStr).length;
      return {'day': _dayLabel(day), 'count': count, 'date': dateStr};
    }).toList();

    _totalWorkoutsThisWeek = rows.length;
    _currentStreak = _calculateStreak(rows);
    _weeklyWorkouts = weeklyData;
  }

  Future<void> _loadWeeklyMeals() async {
    final client = Supabase.instance.client;
    final days = _last7Days;
    final startDate = _toDateStr(days.first);
    final endDate = _toDateStr(days.last);

    List<Map<String, dynamic>> rows = [];

    if (_isLoggedIn) {
      try {
        // Join user_meals with meals to get calories
        final res = await client
            .from('user_meals')
            .select('date, meal_id, meals(calories)')
            .eq('user_id', client.auth.currentUser!.id)
            .gte('date', startDate)
            .lte('date', endDate);
        rows = List<Map<String, dynamic>>.from(res);
      } catch (_) {}
    }

    double totalCal = 0;
    final weeklyData = days.map((day) {
      final dateStr = _toDateStr(day);
      final dayRows = rows.where((r) => r['date'] == dateStr);
      int dayCal = 0;
      for (final r in dayRows) {
        final meal = r['meals'];
        if (meal != null && meal['calories'] != null) {
          dayCal += (meal['calories'] as num).toInt();
        }
      }
      totalCal += dayCal;
      return {'day': _dayLabel(day), 'calories': dayCal, 'date': dateStr};
    }).toList();

    _totalMealsThisWeek = rows.length;
    _weeklyCalories = totalCal;
    _weeklyMeals = weeklyData;

    // ── FIX: Sample fallback data for guests so chart isn't blank ─────────────
    if (rows.isEmpty && !_isLoggedIn) {
      final sampleCals = [1800, 2100, 1950, 0, 2200, 1750, 2000];
      _weeklyMeals = days.asMap().entries.map((e) {
        return {
          'day': _dayLabel(e.value),
          'calories': sampleCals[e.key],
          'date': _toDateStr(e.value),
        };
      }).toList();
      _weeklyCalories = _weeklyMeals.fold(
          0.0, (sum, m) => sum + (m['calories'] as int));
      _totalMealsThisWeek =
          _weeklyMeals.where((m) => (m['calories'] as int) > 0).length;
    }
  }

  Future<void> _loadMuscleBreakdown() async {
    final client = Supabase.instance.client;
    final days = _last7Days;
    final startDate = _toDateStr(days.first);
    final endDate = _toDateStr(days.last);

    Map<String, int> breakdown = {};

    if (_isLoggedIn) {
      try {
        final res = await client
            .from('user_workouts')
            .select('exercise_id, exercises(muscle)')
            .eq('user_id', client.auth.currentUser!.id)
            .gte('date', startDate)
            .lte('date', endDate);

        for (final row in res) {
          final exercise = row['exercises'];
          if (exercise != null && exercise['muscle'] != null) {
            final muscle = exercise['muscle'] as String;
            breakdown[muscle] = (breakdown[muscle] ?? 0) + 1;
          }
        }
      } catch (_) {}
    }

    // Fallback sample data for guests
    if (breakdown.isEmpty) {
      breakdown = {
        'Chest': 3,
        'Back': 2,
        'Legs': 2,
        'Shoulders': 1,
        'Core': 1,
      };
    }

    _muscleBreakdown = breakdown;
  }

  Future<void> _loadWeightHistory() async {
    try {
      final client = Supabase.instance.client;
      final res = await client
          .from('body_metrics')
          .select('weight, date')
          .eq('user_id', client.auth.currentUser!.id)
          .order('date', ascending: true)
          .limit(30);
      _weightHistory = List<Map<String, dynamic>>.from(res);
    } catch (_) {
      _weightHistory = [];
    }
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await SupabaseService.getProfile();
      if (profile != null && mounted) {
        setState(() {
          _currentWeight = (profile['weight'] as num?)?.toDouble() ?? AppData.userWeight;
          _userHeight = (profile['height'] as num?)?.toDouble() ?? AppData.userHeight;
        });
      }
    } catch (_) {}
  }

  int _calculateStreak(List<Map<String, dynamic>> workouts) {
    if (workouts.isEmpty) return 0;
    final dates = workouts
        .map((w) => w['date'] as String?)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();

    int streak = 0;
    DateTime check = DateTime.now();
    for (int i = dates.length - 1; i >= 0; i--) {
      final d = DateTime.tryParse(dates[i]);
      if (d == null) break;
      final diff = check.difference(d).inDays;
      if (diff <= 1) {
        streak++;
        check = d.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  Future<void> _saveWeight() async {
    final val = double.tryParse(_weightController.text.trim());
    if (val == null || val < 20 || val > 300) {
      _showSnack('Enter a valid weight (20–300 kg)', isError: true);
      return;
    }
    setState(() => _isSavingWeight = true);
    try {
      await Supabase.instance.client.from('body_metrics').insert({
        'user_id': Supabase.instance.client.auth.currentUser!.id,
        'weight': val,
        'date': _toDateStr(DateTime.now()),
      });
      _weightController.clear();
      await _loadWeightHistory();
      _showSnack('Weight logged! 💪');
    } catch (_) {
      _showSnack('Failed to save. Try again.', isError: true);
    }
    if (mounted) setState(() => _isSavingWeight = false);
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? const Color(0xFFFF1744) : AppColors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ════════════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (kIsWeb) return _buildWebLayout(isDark);
    return _buildMobileLayout(isDark);
  }

  // ════════════════════════════════════════════════════════════════════════════
  // WEB LAYOUT
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildWebLayout(bool isDark) {
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final textSecondary = isDark ? const Color(0xFFB0B0B0) : const Color(0xFF555555);
    final cardColor = isDark ? const Color(0xFF141414) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);
    final bgColor = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF0F2F5);

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
      );
    }

    return Container(
      color: bgColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────────────
                _buildWebHeader(textPrimary, textSecondary),
                const SizedBox(height: 24),

                // ── Guest banner ─────────────────────────────────────────────
                if (!_isLoggedIn) ...[
                  _buildGuestBanner(isDark, textPrimary, textSecondary),
                  const SizedBox(height: 24),
                ],

                // ── Stats row ────────────────────────────────────────────────
                _buildStatsRow(isDark, textPrimary, cardColor, borderColor),
                const SizedBox(height: 24),

                // ── Charts row ───────────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildWorkoutBarChart(
                          isDark, textPrimary, textSecondary, cardColor, borderColor),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 2,
                      child: _buildMuscleDonut(
                          isDark, textPrimary, textSecondary, cardColor, borderColor),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── FIX: Calorie + Nutrition Summary + Weight row ─────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          _buildCalorieLineChart(
                              isDark, textPrimary, textSecondary, cardColor, borderColor),
                          const SizedBox(height: 20),
                          _buildNutritionSummaryCard(
                              isDark, textPrimary, textSecondary, cardColor, borderColor),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 2,
                      child: _buildWeightCard(
                          isDark, textPrimary, textSecondary, cardColor, borderColor),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWebHeader(Color textPrimary, Color textSecondary) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Progress',
                style: TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w800, color: textPrimary)),
            const SizedBox(height: 4),
            Text('Your fitness journey this week',
                style: TextStyle(fontSize: 14, color: textSecondary)),
          ],
        ),
        const Spacer(),
        // Refresh button
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: _loadAllData,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: AppColors.primary.withOpacity(0.1),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.refresh_rounded, size: 15, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text('Refresh',
                      style: TextStyle(
                          fontSize: 13,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // MOBILE LAYOUT
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildMobileLayout(bool isDark) {
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final textSecondary = isDark ? const Color(0xFFB0B0B0) : const Color(0xFF555555);
    final cardColor = isDark ? const Color(0xFF141414) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);
    final bgColor = isDark ? const Color(0xFF050A05) : const Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        // ── FIX: Only show back button if there is a route to pop to ──────────
        leading: Navigator.canPop(context)
            ? GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cardColor,
                    border: Border.all(color: borderColor),
                  ),
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      size: 16, color: textPrimary),
                ),
              )
            : null,
        title: Text('Progress',
            style: TextStyle(
                color: textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
        actions: [
          GestureDetector(
            onTap: _loadAllData,
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.1),
              ),
              child: const Icon(Icons.refresh_rounded,
                  size: 18, color: AppColors.primary),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: textSecondary,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Workouts'),
            Tab(text: 'Nutrition'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 2.5))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMobileOverviewTab(
                    isDark, textPrimary, textSecondary, cardColor, borderColor),
                _buildMobileWorkoutTab(
                    isDark, textPrimary, textSecondary, cardColor, borderColor),
                _buildMobileNutritionTab(
                    isDark, textPrimary, textSecondary, cardColor, borderColor),
              ],
            ),
    );
  }

  Widget _buildMobileOverviewTab(bool isDark, Color textPrimary,
    Color textSecondary, Color cardColor, Color borderColor) {
  return RefreshIndicator(
    onRefresh: _loadAllData,
    color: AppColors.primary,
    backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
    child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (!_isLoggedIn) ...[
            _buildGuestBanner(isDark, textPrimary, textSecondary),
            const SizedBox(height: 16),
          ],
          _buildStatsRow(isDark, textPrimary, cardColor, borderColor),
          const SizedBox(height: 16),
          _buildMuscleDonut(
              isDark, textPrimary, textSecondary, cardColor, borderColor),
          const SizedBox(height: 16),
          _buildWeightCard(
              isDark, textPrimary, textSecondary, cardColor, borderColor),
        ],
      ),
      ),
    );
  }

  Widget _buildMobileWorkoutTab(bool isDark, Color textPrimary,
      Color textSecondary, Color cardColor, Color borderColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildWorkoutBarChart(
              isDark, textPrimary, textSecondary, cardColor, borderColor),
          const SizedBox(height: 16),
          _buildWorkoutActivityList(
              isDark, textPrimary, textSecondary, cardColor, borderColor),
        ],
      ),
    );
  }

  Widget _buildMobileNutritionTab(bool isDark, Color textPrimary,
      Color textSecondary, Color cardColor, Color borderColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCalorieLineChart(
              isDark, textPrimary, textSecondary, cardColor, borderColor),
          const SizedBox(height: 16),
          _buildNutritionSummaryCard(
              isDark, textPrimary, textSecondary, cardColor, borderColor),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // SHARED WIDGETS
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildGuestBanner(
      bool isDark, Color textPrimary, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isDark ? const Color(0xFF0D1F0D) : const Color(0xFFE8F5E9),
        border: Border.all(
            color: AppColors.primary.withOpacity(0.4), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.15),
            ),
            child: const Center(
              child: Icon(Icons.lock_open_rounded,
                  size: 20, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sign in to track progress',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textPrimary)),
                const SizedBox(height: 2),
                Text(
                    'Showing sample data. Log in to see your real stats.',
                    style: TextStyle(fontSize: 11, color: textSecondary)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/login'),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(
                    colors: [Color(0xFF5EFC82), Color(0xFF00C853)]),
              ),
              child: const Text('Sign In',
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

  Widget _buildStatsRow(bool isDark, Color textPrimary, Color cardColor,
      Color borderColor) {
    final bmi = Helpers.calculateBMI(_currentWeight, _userHeight);
    final stats = [
      {
        'label': 'Workouts',
        'value': '$_totalWorkoutsThisWeek',
        'sub': 'this week',
        'icon': Icons.fitness_center_rounded,
        'color': const Color(0xFF2979FF),
      },
      {
        'label': 'Streak',
        'value': '$_currentStreak',
        'sub': 'days',
        'icon': Icons.local_fire_department_rounded,
        'color': const Color(0xFFFF6D00),
      },
      {
        'label': 'Meals',
        'value': '$_totalMealsThisWeek',
        'sub': 'this week',
        'icon': Icons.restaurant_rounded,
        'color': const Color(0xFF00C853),
      },
      {
        'label': 'BMI',
        'value': bmi.toStringAsFixed(1),
        'sub': Helpers.getBMICategory(bmi),
        'icon': Icons.monitor_heart_rounded,
        'color': const Color(0xFFAA00FF),
      },
    ];

    return kIsWeb
        ? Row(
            children: stats.asMap().entries.map((e) {
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                      right: e.key < stats.length - 1 ? 16 : 0),
                  child: _buildStatCard(
                      e.value, isDark, textPrimary, cardColor, borderColor),
                ),
              );
            }).toList(),
          )
        : GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.6,
            children: stats
                .map((s) => _buildStatCard(
                    s, isDark, textPrimary, cardColor, borderColor))
                .toList(),
          );
  }

  Widget _buildStatCard(Map<String, dynamic> stat, bool isDark,
      Color textPrimary, Color cardColor, Color borderColor) {
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.1)),
            child: Center(
                child: Icon(stat['icon'] as IconData,
                    size: 20, color: color)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(stat['value'] as String,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: color)),
                Text(stat['label'] as String,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: textPrimary)),
                Text(stat['sub'] as String,
                    style: TextStyle(
                        fontSize: 10,
                        color: textPrimary.withOpacity(0.4))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Workout Bar Chart ────────────────────────────────────────────────────────
  Widget _buildWorkoutBarChart(bool isDark, Color textPrimary,
      Color textSecondary, Color cardColor, Color borderColor) {
    final maxY = (_weeklyWorkouts
                .map((w) => w['count'] as int)
                .fold(0, (a, b) => a > b ? a : b) +
            1)
        .toDouble();

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
          _buildCardHeader(
              'Workouts This Week',
              Icons.fitness_center_rounded,
              '$_totalWorkoutsThisWeek total',
              textPrimary,
              textSecondary),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: _weeklyWorkouts.isEmpty
                ? _buildEmptyChart(textSecondary)
                : BarChart(
                    BarChartData(
                      maxY: maxY < 2 ? 3 : maxY,
                      minY: 0,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 1,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: borderColor,
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            reservedSize: 28,
                            getTitlesWidget: (v, _) => Text(
                              v.toInt().toString(),
                              style: TextStyle(
                                  fontSize: 10, color: textSecondary),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, _) {
                              final idx = v.toInt();
                              if (idx < 0 ||
                                  idx >= _weeklyWorkouts.length)
                                return const SizedBox();
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  _weeklyWorkouts[idx]['day'] as String,
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: textSecondary),
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                            sideTitles:
                                SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles:
                                SideTitles(showTitles: false)),
                      ),
                      barGroups:
                          _weeklyWorkouts.asMap().entries.map((e) {
                        final count =
                            (e.value['count'] as int).toDouble();
                        final isToday = e.value['date'] ==
                            _toDateStr(DateTime.now());
                        return BarChartGroupData(
                          x: e.key,
                          barRods: [
                            BarChartRodData(
                              toY: count == 0 ? 0.05 : count,
                              width: 22,
                              borderRadius: BorderRadius.circular(6),
                              color: isToday
                                  ? AppColors.primary
                                  : count > 0
                                      ? AppColors.primary
                                          .withOpacity(0.5)
                                      : borderColor,
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Calorie Line Chart ───────────────────────────────────────────────────────
  Widget _buildCalorieLineChart(bool isDark, Color textPrimary,
      Color textSecondary, Color cardColor, Color borderColor) {
    final spots = _weeklyMeals.asMap().entries.map((e) {
      return FlSpot(
          e.key.toDouble(), (e.value['calories'] as int).toDouble());
    }).toList();

    final maxCal = _weeklyMeals
        .map((m) => m['calories'] as int)
        .fold(0, (a, b) => a > b ? a : b);

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
          _buildCardHeader(
              'Calories This Week',
              Icons.local_fire_department_rounded,
              '${_weeklyCalories.toInt()} total kcal',
              textPrimary,
              textSecondary),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: spots.every((s) => s.y == 0)
                ? _buildEmptyChart(textSecondary)
                : LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: maxCal < 100 ? 500 : (maxCal * 1.3),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) =>
                            FlLine(color: borderColor, strokeWidth: 1),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (v, _) => Text(
                              '${(v / 1000).toStringAsFixed(1)}k',
                              style: TextStyle(
                                  fontSize: 9, color: textSecondary),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, _) {
                              final idx = v.toInt();
                              if (idx < 0 ||
                                  idx >= _weeklyMeals.length)
                                return const SizedBox();
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  _weeklyMeals[idx]['day'] as String,
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: textSecondary),
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                            sideTitles:
                                SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles:
                                SideTitles(showTitles: false)),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          curveSmoothness: 0.3,
                          color: const Color(0xFFFF6D00),
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, _, __, ___) =>
                                FlDotCirclePainter(
                              radius: 4,
                              color: const Color(0xFFFF6D00),
                              strokeWidth: 2,
                              strokeColor: cardColor,
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                const Color(0xFFFF6D00).withOpacity(0.3),
                                const Color(0xFFFF6D00).withOpacity(0.0),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Muscle Donut Chart ───────────────────────────────────────────────────────
  Widget _buildMuscleDonut(bool isDark, Color textPrimary,
      Color textSecondary, Color cardColor, Color borderColor) {
    const muscleColors = {
      'Chest': Color(0xFF2979FF),
      'Back': Color(0xFF00C853),
      'Shoulders': Color(0xFFFF6D00),
      'Legs': Color(0xFFAA00FF),
      'Arms': Color(0xFFFFD600),
      'Core': Color(0xFFFF1744),
      'Full Body': Color(0xFF00BCD4),
    };

    final total =
        _muscleBreakdown.values.fold(0, (a, b) => a + b);
    final sections = _muscleBreakdown.entries.map((e) {
      final color = muscleColors[e.key] ?? AppColors.primary;
      final pct = total > 0 ? (e.value / total * 100) : 0;
      return PieChartSectionData(
        value: e.value.toDouble(),
        color: color,
        radius: 52,
        title: pct >= 10 ? '${pct.toInt()}%' : '',
        titleStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.white),
      );
    }).toList();

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
          _buildCardHeader('Muscle Focus',
              Icons.sports_gymnastics_rounded, 'This week', textPrimary, textSecondary),
          const SizedBox(height: 16),
          _muscleBreakdown.isEmpty
              ? _buildEmptyChart(textSecondary)
              : Row(
                  children: [
                    SizedBox(
                      height: 140,
                      width: 140,
                      child: PieChart(
                        PieChartData(
                          sections: sections,
                          centerSpaceRadius: 36,
                          sectionsSpace: 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:
                            _muscleBreakdown.entries.map((e) {
                          final color =
                              muscleColors[e.key] ?? AppColors.primary;
                          final pct = total > 0
                              ? (e.value / total * 100).toInt()
                              : 0;
                          return Padding(
                            padding:
                                const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: color),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(e.key,
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: textPrimary)),
                                ),
                                Text('$pct%',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: color,
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  // ── Weight Card ──────────────────────────────────────────────────────────────
  Widget _buildWeightCard(bool isDark, Color textPrimary,
      Color textSecondary, Color cardColor, Color borderColor) {
    final bmi = Helpers.calculateBMI(_currentWeight, _userHeight);
    final bmiCat = Helpers.getBMICategory(bmi);
    final bmiColor = bmi < 18.5
        ? const Color(0xFF2979FF)
        : bmi < 25
            ? AppColors.primary
            : bmi < 30
                ? const Color(0xFFFFD600)
                : const Color(0xFFFF1744);

    // Build weight spots for mini chart
    List<FlSpot> weightSpots = [];
    if (_weightHistory.isNotEmpty) {
      for (int i = 0; i < _weightHistory.length; i++) {
        final w = (_weightHistory[i]['weight'] as num).toDouble();
        weightSpots.add(FlSpot(i.toDouble(), w));
      }
    }

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
          _buildCardHeader('Body Metrics',
              Icons.monitor_weight_rounded, '', textPrimary, textSecondary),
          const SizedBox(height: 16),

          // Current weight + BMI
          Row(
            children: [
              Expanded(
                child: _buildMetricPill(
                  '${_currentWeight.toStringAsFixed(1)} kg',
                  'Current Weight',
                  Icons.monitor_weight_rounded,
                  const Color(0xFF2979FF),
                  textPrimary,
                  cardColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricPill(
                  bmi.toStringAsFixed(1),
                  bmiCat,
                  Icons.analytics_rounded,
                  bmiColor,
                  textPrimary,
                  cardColor,
                ),
              ),
            ],
          ),

          // Weight history mini chart
          if (weightSpots.length > 1) ...[
            const SizedBox(height: 16),
            Text('Weight History',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textPrimary)),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: const FlTitlesData(
                    leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: weightSpots,
                      isCurved: true,
                      color: const Color(0xFF2979FF),
                      barWidth: 2.5,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF2979FF).withOpacity(0.25),
                            const Color(0xFF2979FF).withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Log weight input (only if logged in)
          if (_isLoggedIn) ...[
            const SizedBox(height: 16),
            Divider(color: borderColor, height: 1),
            const SizedBox(height: 14),
            Text('Log Today\'s Weight',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textPrimary)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    style:
                        TextStyle(fontSize: 14, color: textPrimary),
                    decoration: InputDecoration(
                      hintText: 'e.g. 74.5',
                      hintStyle: TextStyle(
                          color: textPrimary.withOpacity(0.35),
                          fontSize: 13),
                      suffixText: 'kg',
                      suffixStyle: TextStyle(
                          color: textPrimary.withOpacity(0.5),
                          fontSize: 13),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF1A1A1A)
                          : const Color(0xFFF8F8F8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _isSavingWeight ? null : _saveWeight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 11),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: const LinearGradient(colors: [
                        Color(0xFF5EFC82),
                        Color(0xFF00C853)
                      ]),
                    ),
                    child: _isSavingWeight
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                color: Colors.black, strokeWidth: 2),
                          )
                        : const Text('Log',
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 13,
                                fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: AppColors.primary.withOpacity(0.06),
                border: Border.all(
                    color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Text(
                '🔒 Sign in to log your weight and track progress over time',
                style: TextStyle(fontSize: 11, color: textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricPill(String value, String label, IconData icon,
      Color color, Color textPrimary, Color cardColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withOpacity(0.08),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: color)),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: textPrimary.withOpacity(0.5))),
        ],
      ),
    );
  }

  // ── Workout Activity List (mobile workout tab) ──────────────────────────────
  Widget _buildWorkoutActivityList(bool isDark, Color textPrimary,
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
          Text('Weekly Activity',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textPrimary)),
          const SizedBox(height: 14),
          ..._weeklyWorkouts.map((day) {
            final count = day['count'] as int;
            final isToday =
                day['date'] == _toDateStr(DateTime.now());
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: count > 0
                          ? AppColors.primary.withOpacity(0.15)
                          : borderColor.withOpacity(0.5),
                      border: isToday
                          ? Border.all(
                              color: AppColors.primary, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: Text(day['day'] as String,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: count > 0
                                  ? AppColors.primary
                                  : textSecondary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                                count > 0
                                    ? '$count workout${count > 1 ? 's' : ''}'
                                    : 'Rest day',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: count > 0
                                        ? textPrimary
                                        : textSecondary)),
                            if (count > 0)
                              const Icon(Icons.check_circle_rounded,
                                  size: 16, color: AppColors.primary),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: count > 0
                                ? (count / 5).clamp(0.0, 1.0)
                                : 0,
                            backgroundColor: borderColor,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                count > 0
                                    ? AppColors.primary
                                    : borderColor),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Nutrition Summary Card ──────────────────────────────────────────────────
  Widget _buildNutritionSummaryCard(bool isDark, Color textPrimary,
      Color textSecondary, Color cardColor, Color borderColor) {
    final avgCal =
        _weeklyCalories > 0 ? (_weeklyCalories / 7).toInt() : 0;

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
          Text('Nutrition Summary',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textPrimary)),
          const SizedBox(height: 16),
          _buildNutritionRow(
              'Total Calories',
              '${_weeklyCalories.toInt()} kcal',
              Icons.local_fire_department_rounded,
              const Color(0xFFFF6D00),
              textPrimary,
              textSecondary),
          _buildNutritionRow(
              'Daily Average',
              '$avgCal kcal/day',
              Icons.trending_up_rounded,
              const Color(0xFF2979FF),
              textPrimary,
              textSecondary),
          _buildNutritionRow(
              'Meals Logged',
              '$_totalMealsThisWeek meals',
              Icons.restaurant_rounded,
              AppColors.primary,
              textPrimary,
              textSecondary),
          _buildNutritionRow(
              'Goal Calories',
              '2000 kcal/day',
              Icons.flag_rounded,
              const Color(0xFFAA00FF),
              textPrimary,
              textSecondary),
          const SizedBox(height: 8),
          Divider(color: borderColor, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Weekly Progress',
                        style:
                            TextStyle(fontSize: 12, color: textSecondary)),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (_weeklyCalories / (2000 * 7))
                            .clamp(0.0, 1.0),
                        backgroundColor: borderColor,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFFF6D00)),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Text(
                '${((_weeklyCalories / (2000 * 7)) * 100).clamp(0, 100).toInt()}%',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFFF6D00)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionRow(String label, String value, IconData icon,
      Color color, Color textPrimary, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.1)),
            child:
                Center(child: Icon(icon, size: 15, color: color)),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label,
                  style:
                      TextStyle(fontSize: 13, color: textSecondary))),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textPrimary)),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────
  Widget _buildCardHeader(String title, IconData icon, String subtitle,
      Color textPrimary, Color textSecondary) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(title,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textPrimary)),
        ),
        if (subtitle.isNotEmpty)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppColors.primary.withOpacity(0.1),
            ),
            child: Text(subtitle,
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }

  Widget _buildEmptyChart(Color textSecondary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_rounded,
              size: 36, color: textSecondary.withOpacity(0.3)),
          const SizedBox(height: 8),
          Text(
            _isLoggedIn
                ? 'No data yet — start logging!'
                : 'Sign in to see your data',
            style: TextStyle(fontSize: 12, color: textSecondary),
          ),
        ],
      ),
    );
  }
}