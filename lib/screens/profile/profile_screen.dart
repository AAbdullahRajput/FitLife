// lib/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/data/app_data.dart';
import '../../core/utils/helpers.dart';
import '../../services/storage_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final _supabase = Supabase.instance.client;
  bool get _isLoggedIn => _supabase.auth.currentSession != null;
  String get _userEmail =>
      _supabase.auth.currentUser?.email ?? 'guest@fitlife.app';

  String get _userName => AppData.userName;
  double get _userWeight => AppData.userWeight;
  double get _userHeight => AppData.userHeight;
  int get _userAge => AppData.userAge;
  String get _userGoal => AppData.userGoal;

  double get _bmi => Helpers.calculateBMI(_userWeight, _userHeight);
  String get _bmiCategory => Helpers.getBMICategory(_bmi);

  bool _isLoggingOut = false;

  final List<Map<String, dynamic>> _achievements = [
    {
      'icon': '🔥',
      'title': 'First Workout',
      'desc': 'Completed your first session',
      'unlocked': true,
    },
    {
      'icon': '💧',
      'title': 'Hydration Hero',
      'desc': 'Hit water goal 7 days straight',
      'unlocked': true,
    },
    {
      'icon': '🏋️',
      'title': 'Iron Will',
      'desc': 'Logged 10 workouts',
      'unlocked': false,
    },
    {
      'icon': '🥗',
      'title': 'Clean Eater',
      'desc': 'Logged meals for 5 days',
      'unlocked': false,
    },
    {
      'icon': '📈',
      'title': 'On Track',
      'desc': 'Reached your weekly goal',
      'unlocked': false,
    },
    {
      'icon': '⚡',
      'title': 'Streak Master',
      'desc': '30-day streak',
      'unlocked': false,
    },
  ];

  final List<Map<String, dynamic>> _bodyStats = [
    {
      'label': 'Chest',
      'value': '94 cm',
      'icon': Icons.straighten_rounded,
      'color': const Color(0xFF2979FF),
    },
    {
      'label': 'Waist',
      'value': '80 cm',
      'icon': Icons.straighten_rounded,
      'color': const Color(0xFFFF6D00),
    },
    {
      'label': 'Hips',
      'value': '96 cm',
      'icon': Icons.straighten_rounded,
      'color': const Color(0xFFAA00FF),
    },
    {
      'label': 'Arms',
      'value': '35 cm',
      'icon': Icons.straighten_rounded,
      'color': const Color(0xFF00BCD4),
    },
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    final confirmed = await _showConfirmDialog(
      title: 'Sign Out',
      message: 'Are you sure you want to sign out of FitLife?',
      confirmLabel: 'Sign Out',
      isDestructive: false,
    );
    if (!confirmed || !mounted) return;

    setState(() => _isLoggingOut = true);
    try {
      await _supabase.auth.signOut();
      await StorageService.setLoggedIn(false);
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    } catch (_) {
      setState(() => _isLoggingOut = false);
      _showSnack('Sign out failed. Please try again.', isError: true);
    }
  }

  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required bool isDestructive,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppColors.of(context, listen: false);
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final textSecondary =
        isDark ? const Color(0xFFB0B0B0) : const Color(0xFF555555);
    final borderColor =
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);

    return await showDialog<bool>(
          context: context,
          barrierColor: Colors.black.withOpacity(0.6),
          builder: (ctx) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: 340,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 40,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (isDestructive
                              ? const Color(0xFFFF1744)
                              : accent)
                          .withOpacity(0.12),
                    ),
                    child: Center(
                      child: Icon(
                        isDestructive
                            ? Icons.delete_forever_rounded
                            : Icons.logout_rounded,
                        color: isDestructive
                            ? const Color(0xFFFF1744)
                            : accent,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(title,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: textPrimary)),
                  const SizedBox(height: 8),
                  Text(message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13, color: textSecondary, height: 1.5)),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(ctx, false),
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: isDark
                                  ? const Color(0xFF252525)
                                  : const Color(0xFFF5F5F5),
                              border: Border.all(color: borderColor),
                            ),
                            child: Center(
                              child: Text('Cancel',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: textSecondary)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(ctx, true),
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                colors: isDestructive
                                    ? [
                                        const Color(0xFFFF1744),
                                        const Color(0xFFD50000),
                                      ]
                                    : AppColors.gradientOf(context,
                                        listen: false),
                              ),
                            ),
                            child: Center(
                              child: Text(confirmLabel,
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: isDestructive
                                          ? Colors.white
                                          : AppColors.onAccentOf(context,
                                              listen: false))),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ) ??
        false;
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    final accent = AppColors.of(context, listen: false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? const Color(0xFFFF1744) : accent,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (kIsWeb) return _buildWebLayout(isDark);
    return _buildMobileLayout(isDark);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WEB LAYOUT — full-width, multi-column
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildWebLayout(bool isDark) {
    final accent = AppColors.of(context);
    final gradient = AppColors.gradientOf(context);
    final onAccent = AppColors.onAccentOf(context);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final textSecondary =
        isDark ? const Color(0xFFB0B0B0) : const Color(0xFF555555);
    final cardColor = isDark ? const Color(0xFF141414) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);

    return FadeTransition(
      opacity: _fadeAnim,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero + Stats side by side ──────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero card — fixed width
                SizedBox(
                  width: 320,
                  child: _buildHeroCard(isDark, accent, gradient, onAccent,
                      textPrimary, textSecondary, cardColor, borderColor),
                ),
                const SizedBox(width: 20),
                // Fitness stats — fills remaining space
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('Fitness Stats',
                          Icons.monitor_heart_rounded, accent, textPrimary),
                      const SizedBox(height: 12),
                      _buildWebStatsGrid(
                          accent, textPrimary, cardColor, borderColor),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Body measurements + Achievements side by side ──────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('Body Measurements',
                          Icons.straighten_rounded, accent, textPrimary),
                      const SizedBox(height: 12),
                      _buildMeasurementsRow(isDark, textPrimary, textSecondary,
                          cardColor, borderColor),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('Achievements',
                          Icons.emoji_events_rounded, accent, textPrimary),
                      const SizedBox(height: 12),
                      _buildWebAchievementsGrid(isDark, accent, textPrimary,
                          textSecondary, cardColor, borderColor),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Weekly summary + Account side by side ──────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('This Week',
                          Icons.bar_chart_rounded, accent, textPrimary),
                      const SizedBox(height: 12),
                      _buildWeeklySummary(isDark, accent, gradient, onAccent,
                          textPrimary, textSecondary, cardColor, borderColor),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('Account',
                          Icons.manage_accounts_rounded, accent, textPrimary),
                      const SizedBox(height: 12),
                      _buildAccountActions(isDark, accent, gradient, onAccent,
                          textPrimary, textSecondary, cardColor, borderColor),
                      const SizedBox(height: 12),
                      _buildSignOutButton(isDark, borderColor),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Web stats grid — 3 columns, fixed height rows ─────────────────────────
  Widget _buildWebStatsGrid(
      Color accent, Color textPrimary, Color cardColor, Color borderColor) {
    final stats = [
      {
        'label': 'Weight',
        'value': '${_userWeight}kg',
        'icon': Icons.monitor_weight_rounded,
        'color': const Color(0xFF2979FF),
      },
      {
        'label': 'Height',
        'value': '${_userHeight}cm',
        'icon': Icons.height_rounded,
        'color': const Color(0xFFFF6D00),
      },
      {
        'label': 'Age',
        'value': '$_userAge yrs',
        'icon': Icons.cake_rounded,
        'color': const Color(0xFFAA00FF),
      },
      {
        'label': 'BMI',
        'value': _bmi.toStringAsFixed(1),
        'icon': Icons.analytics_rounded,
        'color': accent,
      },
      {
        'label': 'Category',
        'value': _bmiCategory,
        'icon': Icons.flag_rounded,
        'color': const Color(0xFFFFD600),
      },
      {
        'label': 'Goal',
        'value': _userGoal.split(' ').first,
        'icon': Icons.emoji_events_rounded,
        'color': const Color(0xFF00BCD4),
      },
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: stats.map((stat) {
        final color = stat['color'] as Color;
        final icon = stat['icon'] as IconData;
        return SizedBox(
          width: 140,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: cardColor,
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.12),
                  ),
                  child: Center(child: Icon(icon, size: 18, color: color)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(stat['value'] as String,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: color)),
                      Text(stat['label'] as String,
                          style: TextStyle(
                              fontSize: 10,
                              color: textPrimary.withOpacity(0.45))),
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

  // ── Web achievements — horizontal wrap, no GridView ───────────────────────
  Widget _buildWebAchievementsGrid(bool isDark, Color accent, Color textPrimary,
      Color textSecondary, Color cardColor, Color borderColor) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _achievements.map((a) {
        final unlocked = a['unlocked'] as bool;
        return Container(
          width: 140,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: unlocked
                ? accent.withOpacity(0.1)
                : (isDark
                    ? const Color(0xFF1A1A1A)
                    : const Color(0xFFF5F5F5)),
            border: Border.all(
                color: unlocked ? accent.withOpacity(0.35) : borderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              unlocked
                  ? Text(a['icon'] as String,
                      style: const TextStyle(fontSize: 24))
                  : Icon(Icons.lock_rounded,
                      size: 24, color: Colors.grey.withOpacity(0.4)),
              const SizedBox(height: 6),
              Text(a['title'] as String,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: unlocked
                          ? textPrimary
                          : textPrimary.withOpacity(0.3))),
              const SizedBox(height: 2),
              Text(a['desc'] as String,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 9,
                      color: unlocked
                          ? textSecondary
                          : textSecondary.withOpacity(0.3))),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MOBILE LAYOUT — scrollable, full Scaffold
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildMobileLayout(bool isDark) {
    final accent = AppColors.of(context);
    final gradient = AppColors.gradientOf(context);
    final onAccent = AppColors.onAccentOf(context);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final textSecondary =
        isDark ? const Color(0xFFB0B0B0) : const Color(0xFF555555);
    final bgColor =
        isDark ? const Color(0xFF050A05) : const Color(0xFFF5F5F5);
    final cardColor = isDark ? const Color(0xFF141414) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);

    // FIX: Only show back button if there is a route to go back to.
    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0D0D0D) : Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: canPop
            ? GestureDetector(
                onTap: () => Navigator.maybePop(context),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cardColor,
                    border: Border.all(color: borderColor),
                  ),
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      size: 15, color: textPrimary),
                ),
              )
            : null,
        title: Text('Profile',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: textPrimary)),
        actions: [
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/settings'),
            child: Container(
              margin: const EdgeInsets.only(right: 14),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withOpacity(0.12),
                border: Border.all(color: accent.withOpacity(0.3)),
              ),
              child: Center(
                  child:
                      Icon(Icons.settings_rounded, size: 17, color: accent)),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: borderColor),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroCard(isDark, accent, gradient, onAccent, textPrimary,
                  textSecondary, cardColor, borderColor),
              const SizedBox(height: 20),
              _buildSectionHeader('Fitness Stats',
                  Icons.monitor_heart_rounded, accent, textPrimary),
              const SizedBox(height: 12),
              _buildMobileStatsGrid(
                  accent, textPrimary, cardColor, borderColor),
              const SizedBox(height: 20),
              _buildSectionHeader('Body Measurements',
                  Icons.straighten_rounded, accent, textPrimary),
              const SizedBox(height: 12),
              _buildMeasurementsRow(isDark, textPrimary, textSecondary,
                  cardColor, borderColor),
              const SizedBox(height: 20),
              _buildSectionHeader('Achievements',
                  Icons.emoji_events_rounded, accent, textPrimary),
              const SizedBox(height: 12),
              _buildMobileAchievementsGrid(isDark, accent, textPrimary,
                  textSecondary, cardColor, borderColor),
              const SizedBox(height: 20),
              _buildSectionHeader(
                  'This Week', Icons.bar_chart_rounded, accent, textPrimary),
              const SizedBox(height: 12),
              _buildWeeklySummary(isDark, accent, gradient, onAccent,
                  textPrimary, textSecondary, cardColor, borderColor),
              const SizedBox(height: 20),
              _buildSectionHeader('Account',
                  Icons.manage_accounts_rounded, accent, textPrimary),
              const SizedBox(height: 12),
              _buildAccountActions(isDark, accent, gradient, onAccent,
                  textPrimary, textSecondary, cardColor, borderColor),
              const SizedBox(height: 12),
              _buildSignOutButton(isDark, borderColor),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Mobile stats grid — 3 columns with fixed childAspectRatio ─────────────
  Widget _buildMobileStatsGrid(
      Color accent, Color textPrimary, Color cardColor, Color borderColor) {
    final stats = [
      {
        'label': 'Weight',
        'value': '${_userWeight}kg',
        'icon': Icons.monitor_weight_rounded,
        'color': const Color(0xFF2979FF),
      },
      {
        'label': 'Height',
        'value': '${_userHeight}cm',
        'icon': Icons.height_rounded,
        'color': const Color(0xFFFF6D00),
      },
      {
        'label': 'Age',
        'value': '$_userAge yrs',
        'icon': Icons.cake_rounded,
        'color': const Color(0xFFAA00FF),
      },
      {
        'label': 'BMI',
        'value': _bmi.toStringAsFixed(1),
        'icon': Icons.analytics_rounded,
        'color': accent,
      },
      {
        'label': 'Category',
        'value': _bmiCategory,
        'icon': Icons.flag_rounded,
        'color': const Color(0xFFFFD600),
      },
      {
        'label': 'Goal',
        'value': _userGoal.split(' ').first,
        'icon': Icons.emoji_events_rounded,
        'color': const Color(0xFF00BCD4),
      },
    ];

    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.1,
      children: stats.map((stat) {
        final color = stat['color'] as Color;
        final icon = stat['icon'] as IconData;
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: cardColor,
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(height: 6),
              Text(stat['value'] as String,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: color)),
              const SizedBox(height: 2),
              Text(stat['label'] as String,
                  style: TextStyle(
                      fontSize: 9,
                      color: textPrimary.withOpacity(0.45))),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Mobile achievements grid — fixed aspect ratio ─────────────────────────
  Widget _buildMobileAchievementsGrid(bool isDark, Color accent,
      Color textPrimary, Color textSecondary, Color cardColor, Color borderColor) {
    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.95,
      children: _achievements.map((a) {
        final unlocked = a['unlocked'] as bool;
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: unlocked
                ? accent.withOpacity(0.1)
                : (isDark
                    ? const Color(0xFF1A1A1A)
                    : const Color(0xFFF5F5F5)),
            border: Border.all(
                color: unlocked ? accent.withOpacity(0.35) : borderColor),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (unlocked)
                Text(a['icon'] as String,
                    style: const TextStyle(fontSize: 24))
              else
                Icon(Icons.lock_rounded,
                    size: 24, color: Colors.grey.withOpacity(0.4)),
              const SizedBox(height: 6),
              Text(a['title'] as String,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: unlocked
                          ? textPrimary
                          : textPrimary.withOpacity(0.3))),
              const SizedBox(height: 2),
              Text(a['desc'] as String,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 8,
                      color: unlocked
                          ? textSecondary
                          : textSecondary.withOpacity(0.3))),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Shared widgets ─────────────────────────────────────────────────────────

  Widget _buildHeroCard(
    bool isDark,
    Color accent,
    List<Color> gradient,
    Color onAccent,
    Color textPrimary,
    Color textSecondary,
    Color cardColor,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [accent.withOpacity(0.15), accent.withOpacity(0.05)]
              : [accent.withOpacity(0.08), accent.withOpacity(0.03)],
        ),
        border: Border.all(color: accent.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: gradient),
                      boxShadow: [
                        BoxShadow(
                            color: accent.withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _userName.isNotEmpty
                            ? _userName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: onAccent),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF00C853),
                        border: Border.all(
                            color: isDark
                                ? const Color(0xFF050A05)
                                : Colors.white,
                            width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_userName,
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: textPrimary)),
                    const SizedBox(height: 2),
                    Text(_userEmail,
                        style:
                            TextStyle(fontSize: 12, color: textSecondary)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _buildMiniChip(
                          _isLoggedIn ? '✅ Free Plan' : '👤 Guest',
                          accent,
                        ),
                        _buildMiniChip(_userGoal, accent),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Text('Edit profile coming soon!'),
              backgroundColor: accent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(16),
            )),
            child: Container(
              width: double.infinity,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent.withOpacity(0.5)),
                color: accent.withOpacity(0.08),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit_rounded, size: 15, color: accent),
                  const SizedBox(width: 8),
                  Text('Edit Profile',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: accent)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniChip(String text, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: accent.withOpacity(0.15),
        border: Border.all(color: accent.withOpacity(0.3)),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 10, color: accent, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildSectionHeader(
      String title, IconData icon, Color accent, Color textPrimary) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: accent.withOpacity(0.12),
          ),
          child: Center(child: Icon(icon, size: 15, color: accent)),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: textPrimary)),
      ],
    );
  }

  Widget _buildMeasurementsRow(bool isDark, Color textPrimary,
      Color textSecondary, Color cardColor, Color borderColor) {
    return Row(
      children: _bodyStats.asMap().entries.map((entry) {
        final i = entry.key;
        final stat = entry.value;
        final color = stat['color'] as Color;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < _bodyStats.length - 1 ? 8 : 0),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: cardColor,
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Icon(stat['icon'] as IconData, size: 16, color: color),
                const SizedBox(height: 6),
                Text(stat['value'] as String,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: color)),
                const SizedBox(height: 2),
                Text(stat['label'] as String,
                    style: TextStyle(
                        fontSize: 9,
                        color: textPrimary.withOpacity(0.45))),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWeeklySummary(
    bool isDark,
    Color accent,
    List<Color> gradient,
    Color onAccent,
    Color textPrimary,
    Color textSecondary,
    Color cardColor,
    Color borderColor,
  ) {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final completed = [true, true, false, true, false, false, false];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: cardColor,
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Weekly Workouts',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textPrimary)),
              Text('3/7 days',
                  style: TextStyle(
                      fontSize: 12,
                      color: accent,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final done = completed[i];
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient:
                          done ? LinearGradient(colors: gradient) : null,
                      color: done
                          ? null
                          : (isDark
                              ? const Color(0xFF1A1A1A)
                              : const Color(0xFFF0F0F0)),
                      border:
                          Border.all(color: done ? Colors.transparent : borderColor),
                    ),
                    child: Center(
                      child: done
                          ? Icon(Icons.check_rounded, size: 14, color: onAccent)
                          : Text(days[i],
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: textSecondary)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (done)
                    Text(days[i],
                        style: TextStyle(fontSize: 9, color: accent)),
                ],
              );
            }),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Avg. Calories',
                  style: TextStyle(fontSize: 11, color: textSecondary)),
              Text('1,840 / 2,000 kcal',
                  style: TextStyle(
                      fontSize: 11,
                      color: accent,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 1840 / 2000,
              minHeight: 6,
              backgroundColor: accent.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountActions(
    bool isDark,
    Color accent,
    List<Color> gradient,
    Color onAccent,
    Color textPrimary,
    Color textSecondary,
    Color cardColor,
    Color borderColor,
  ) {
    final actions = [
      {
        'icon': Icons.settings_rounded,
        'label': 'Settings',
        'subtitle': 'Appearance, notifications & more',
        'color': accent,
        'onTap': () => Navigator.pushNamed(context, '/settings'),
      },
      {
        'icon': Icons.lock_outline_rounded,
        'label': 'Change Password',
        'subtitle': 'Update your account password',
        'color': const Color(0xFF2979FF),
        // FIX: Wrapped in try-catch to handle AuthApiException (rate limit, etc.)
        'onTap': () async {
          if (!_isLoggedIn) {
            _showSnack('Sign in to change password.', isError: true);
            return;
          }
          final email = _supabase.auth.currentUser?.email;
          if (email != null) {
            try {
              await _supabase.auth.resetPasswordForEmail(email);
              _showSnack('Password reset email sent!');
            } on AuthException catch (e) {
              _showSnack(e.message, isError: true);
            } catch (_) {
              _showSnack(
                  'Failed to send reset email. Please try again later.',
                  isError: true);
            }
          }
        },
      },
      {
        'icon': Icons.download_rounded,
        'label': 'Export Data',
        'subtitle': 'Download your fitness data',
        'color': const Color(0xFFFF6D00),
        'onTap': () => _showSnack('Export coming soon!'),
      },
      {
        'icon': Icons.help_outline_rounded,
        'label': 'Help & Support',
        'subtitle': 'Get help or contact us',
        'color': const Color(0xFFAA00FF),
        'onTap': () => _showSnack('Support coming soon!'),
      },
    ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: cardColor,
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: actions.asMap().entries.map((entry) {
          final i = entry.key;
          final action = entry.value;
          final color = action['color'] as Color;
          return Column(
            children: [
              GestureDetector(
                onTap: action['onTap'] as VoidCallback,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: color.withOpacity(0.12),
                        ),
                        child: Center(
                            child: Icon(action['icon'] as IconData,
                                size: 18, color: color)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(action['label'] as String,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary)),
                            Text(action['subtitle'] as String,
                                style: TextStyle(
                                    fontSize: 11, color: textSecondary)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          size: 18,
                          color: textSecondary.withOpacity(0.5)),
                    ],
                  ),
                ),
              ),
              if (i < actions.length - 1)
                Divider(
                    height: 1,
                    color: borderColor,
                    indent: 68,
                    endIndent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSignOutButton(bool isDark, Color borderColor) {
    return GestureDetector(
      onTap: _isLoggingOut ? null : _handleLogout,
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isDark
              ? const Color(0xFF1A0A0A)
              : const Color(0xFFFFF0F0),
          border:
              Border.all(color: const Color(0xFFFF1744).withOpacity(0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _isLoggingOut
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        color: Color(0xFFFF1744), strokeWidth: 2))
                : const Icon(Icons.logout_rounded,
                    size: 18, color: Color(0xFFFF1744)),
            const SizedBox(width: 10),
            const Text('Sign Out',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFF1744))),
          ],
        ),
      ),
    );
  }
}