import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../../core/theme/app_colors.dart';
import 'bench_press_screen.dart';
import 'incline_bench_screen.dart';

// ══════════════════════════════════════════════════════════════════════════════
// CHEST SCREEN
// Lists chest exercises grouped by Beginner / Intermediate / Advanced.
// Web  → rendered inside HomeScreen's content area via callbacks (navbar stays).
// Mobile → pushed normally via Navigator.push.
// Place at: lib/screens/workout/exercises/chest/chest_screen.dart
// ══════════════════════════════════════════════════════════════════════════════

class ChestScreen extends StatefulWidget {
  final String userTier;

  /// Web only — called when user taps "Back to Workouts"
  final VoidCallback? onBack;

  /// Web only — called when user taps an exercise card.
  /// Pass the screen widget to render inside HomeScreen's content area.
  final void Function(Widget screen)? onNavigateTo;

  const ChestScreen({
    super.key,
    required this.userTier,
    this.onBack,
    this.onNavigateTo,
  });

  @override
  State<ChestScreen> createState() => _ChestScreenState();
}

class _ChestScreenState extends State<ChestScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  static const Color _color = Color(0xFF2979FF);

  // ── All chest exercises ──────────────────────────────────────────────────
  static const List<Map<String, dynamic>> _exercises = [
    {
      'name': 'Bench Press',
      'difficulty': 'Beginner',
      'tier': 'guest',
      'emoji': '🏋️',
      'sets': 4,
      'reps': 10,
      'rest': '60s',
      'calories': 120,
      'desc': 'Classic chest builder targeting middle chest fibres.',
      'image':
          'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=600&q=80',
      'color': Color(0xFF2979FF),
    },
    {
      'name': 'Incline Bench Press',
      'difficulty': 'Intermediate',
      'tier': 'free',
      'emoji': '💪',
      'sets': 4,
      'reps': 10,
      'rest': '60s',
      'calories': 110,
      'desc': 'Upper chest focus at 30–45° incline for a full chest look.',
      'image':
          'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=600&q=80',
      'color': Color(0xFF00C853),
    },
  ];

  // ── Tier helpers ─────────────────────────────────────────────────────────
  bool _isTierUnlocked(String required) {
    const order = {'guest': 0, 'free': 1, 'premium': 2};
    return (order[widget.userTier] ?? 0) >= (order[required] ?? 0);
  }

  Color _difficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Beginner':
        return const Color(0xFF00C853);
      case 'Intermediate':
        return const Color(0xFFFF6D00);
      case 'Advanced':
        return const Color(0xFFAA00FF);
      default:
        return AppColors.primary;
    }
  }

  List<Map<String, dynamic>> _exercisesForDifficulty(String difficulty) =>
      _exercises.where((e) => e['difficulty'] == difficulty).toList();

  // ── Open exercise ────────────────────────────────────────────────────────
  void _openExercise(Map<String, dynamic> exercise) {
    final required = exercise['tier'] as String;
    if (!_isTierUnlocked(required)) {
      _showUpgradeDialog(required);
      return;
    }

    Widget screen;
    switch (exercise['name'] as String) {
      case 'Bench Press':
        screen = BenchPressScreen(userTier: widget.userTier);
        break;
      case 'Incline Bench Press':
        screen = InclineBenchScreen(userTier: widget.userTier);
        break;
      default:
        return;
    }

    if (kIsWeb && widget.onNavigateTo != null) {
      widget.onNavigateTo!(screen);
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    }
  }

  void _showUpgradeDialog(String requiredTier) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF141414) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🔒 Locked'),
        content: Text(
          requiredTier == 'premium'
              ? 'This exercise requires a Premium account.'
              : 'Create a free account to unlock this exercise!',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context,
                  requiredTier == 'premium' ? '/premium' : '/register');
            },
            child:
                Text(requiredTier == 'premium' ? 'Upgrade' : 'Sign Up Free'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FadeTransition(
      opacity: _fadeAnim,
      child: kIsWeb ? _buildWebLayout(isDark) : _buildMobileLayout(isDark),
    );
  }

  // ── Exercise card (shared) ───────────────────────────────────────────────
  Widget _buildExerciseCard(
    Map<String, dynamic> exercise, {
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color cardColor,
    required Color borderColor,
  }) {
    final color = exercise['color'] as Color? ?? _color;
    final isUnlocked = _isTierUnlocked(exercise['tier'] as String);
    final diffColor = _difficultyColor(exercise['difficulty'] as String);

    return GestureDetector(
      onTap: () => _openExercise(exercise),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: cardColor,
          border: Border.all(color: color.withOpacity(0.25), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(isDark ? 0.15 : 0.08),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image ────────────────────────────────────────────────
              SizedBox(
                height: 160,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      exercise['image'] as String,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            color.withOpacity(0.7),
                            color.withOpacity(0.3)
                          ]),
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.75),
                          ],
                        ),
                      ),
                    ),
                    // Lock overlay
                    if (!isUnlocked)
                      Container(
                        color: Colors.black.withOpacity(0.55),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: color.withOpacity(0.2),
                                  border: Border.all(
                                      color: color.withOpacity(0.5),
                                      width: 2),
                                ),
                                child: const Center(
                                  child: Icon(Icons.lock_rounded,
                                      color: Colors.white, size: 24),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                exercise['tier'] == 'premium'
                                    ? '⭐ Premium Only'
                                    : 'Free Account Required',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 3),
                              Text('Tap to unlock',
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.65),
                                      fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                    // Bottom info
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 12,
                      child: Row(
                        children: [
                          Text(exercise['emoji'] as String,
                              style: const TextStyle(fontSize: 26)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  exercise['name'] as String,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: -0.3),
                                ),
                                Text(
                                  exercise['desc'] as String,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white.withOpacity(0.8)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: diffColor.withOpacity(0.2),
                              border: Border.all(
                                  color: diffColor.withOpacity(0.5)),
                            ),
                            child: Text(
                              exercise['difficulty'] as String,
                              style: TextStyle(
                                  fontSize: 10,
                                  color: diffColor,
                                  fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // ── Stats ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _buildStat('Sets', '${exercise['sets']}', color),
                    const SizedBox(width: 14),
                    _buildStat('Reps', '${exercise['reps']}', color),
                    const SizedBox(width: 14),
                    _buildStat('Rest', exercise['rest'] as String, color),
                    const SizedBox(width: 14),
                    _buildStat(
                        'Calories', '~${exercise['calories']} kcal', color),
                    const Spacer(),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withOpacity(0.12),
                        border:
                            Border.all(color: color.withOpacity(0.35)),
                      ),
                      child: Center(
                        child: Icon(
                          isUnlocked
                              ? Icons.arrow_forward_rounded
                              : Icons.lock_rounded,
                          size: 16,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w900, color: color)),
        Text(label,
            style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: color.withOpacity(0.6))),
      ],
    );
  }

  Widget _buildSectionHeader(
      String difficulty, Color color, Color textPrimary) {
    final exercises = _exercisesForDifficulty(difficulty);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 10),
          Text(difficulty,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: textPrimary)),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: color.withOpacity(0.1),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              '${exercises.length} exercise${exercises.length == 1 ? '' : 's'}',
              style: TextStyle(
                  fontSize: 10, color: color, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // MOBILE LAYOUT
  // ════════════════════════════════════════════════════════════════════════
  Widget _buildMobileLayout(bool isDark) {
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final textSecondary =
        isDark ? const Color(0xFFB0B0B0) : const Color(0xFF666666);
    final bgColor =
        isDark ? const Color(0xFF050A05) : const Color(0xFFF4F6F8);
    final cardColor = isDark ? const Color(0xFF141414) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5E5);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (widget.onBack != null) {
                        widget.onBack!();
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _color.withOpacity(0.1),
                        border: Border.all(color: _color.withOpacity(0.3)),
                      ),
                      child: const Center(
                        child: Icon(Icons.arrow_back_ios_new_rounded,
                            size: 16, color: _color),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Chest',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: _color,
                                letterSpacing: -0.4)),
                        Text('${_exercises.length} exercises',
                            style: TextStyle(
                                fontSize: 12, color: textSecondary)),
                      ],
                    ),
                  ),
                  const Text('🏋️', style: TextStyle(fontSize: 30)),
                ],
              ),
            ),
            // List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                children: [
                  for (final diff in ['Beginner', 'Intermediate', 'Advanced'])
                    if (_exercisesForDifficulty(diff).isNotEmpty) ...[
                      _buildSectionHeader(
                          diff, _difficultyColor(diff), textPrimary),
                      ..._exercisesForDifficulty(diff).map(
                        (e) => _buildExerciseCard(
                          e,
                          isDark: isDark,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          cardColor: cardColor,
                          borderColor: borderColor,
                        ),
                      ),
                    ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // WEB LAYOUT
  // ════════════════════════════════════════════════════════════════════════
  Widget _buildWebLayout(bool isDark) {
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final textSecondary =
        isDark ? const Color(0xFFB0B0B0) : const Color(0xFF666666);
    final bgColor =
        isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF0F2F5);
    final cardColor = isDark ? const Color(0xFF141414) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5E5);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (widget.onBack != null) {
                        widget.onBack!();
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back_ios_new_rounded,
                              size: 13, color: textSecondary),
                          const SizedBox(width: 5),
                          Text('Back to Workouts',
                              style: TextStyle(
                                  fontSize: 13, color: textSecondary)),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Text('🏋️', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 10),
                  Text('Chest Exercises',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: textPrimary,
                          letterSpacing: -0.4)),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: _color.withOpacity(0.1),
                      border: Border.all(color: _color.withOpacity(0.3)),
                    ),
                    child: Text('${_exercises.length} exercises',
                        style: const TextStyle(
                            fontSize: 11,
                            color: _color,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Sections
              for (final diff in ['Beginner', 'Intermediate', 'Advanced'])
                if (_exercisesForDifficulty(diff).isNotEmpty) ...[
                  _buildSectionHeader(
                      diff, _difficultyColor(diff), textPrimary),
                  ..._exercisesForDifficulty(diff).map(
                    (e) => _buildExerciseCard(
                      e,
                      isDark: isDark,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      cardColor: cardColor,
                      borderColor: borderColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
            ],
          ),
        ),
      ),
    );
  }
}