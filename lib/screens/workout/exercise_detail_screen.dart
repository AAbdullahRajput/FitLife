import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../core/theme/app_colors.dart';
import '../../services/supabase_service.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final Map<String, dynamic> exercise;
  final String userTier; // 'guest', 'free', 'premium'

  const ExerciseDetailScreen({
    super.key,
    required this.exercise,
    required this.userTier,
  });

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  int _selectedVariation = 0;
  bool _isLoadingVariations = false;
  bool _isLoggingWorkout = false;
  List<Map<String, dynamic>> _dbVariations = [];

  // ── Real workout images per variation type ─────────────────────────────────
  static const Map<String, String> _variationImages = {
    'Flat Bench Press':
        'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=800&q=80',
    'Incline Bench Press':
        'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800&q=80',
    'Decline Bench Press':
        'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?w=800&q=80',
    'Dumbbell Bench Press':
        'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=800&q=80',
    'Wide Grip Pull Up':
        'https://images.unsplash.com/photo-1598971639058-fab3c3109a00?w=800&q=80',
    'Narrow Grip Pull Up':
        'https://images.unsplash.com/photo-1567598508481-65985588e295?w=800&q=80',
    'Weighted Pull Up':
        'https://images.unsplash.com/photo-1534368959876-26bf04f2c947?w=800&q=80',
    'Standing Shoulder Press':
        'https://images.unsplash.com/photo-1532029837206-abbe2b7620e3?w=800&q=80',
    'Seated Shoulder Press':
        'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?w=800&q=80',
    'Arnold Press':
        'https://images.unsplash.com/photo-1581009137042-c552e485697a?w=800&q=80',
  };

  static const Map<String, String> _muscleImages = {
    'Chest':
        'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=800&q=80',
    'Back':
        'https://images.unsplash.com/photo-1598971639058-fab3c3109a00?w=800&q=80',
    'Shoulders':
        'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?w=800&q=80',
    'Legs':
        'https://images.unsplash.com/photo-1574680096145-d05b474e2155?w=800&q=80',
    'Arms':
        'https://images.unsplash.com/photo-1581009137042-c552e485697a?w=800&q=80',
    'Core':
        'https://images.unsplash.com/photo-1549060279-7e168fcee0c2?w=800&q=80',
  };

  String _getVariationImage(String variationName, String muscle) {
    return _variationImages[variationName] ??
        _muscleImages[muscle] ??
        'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=800&q=80';
  }

  // ── Local variation data (fallback) ──────────────────────────────────────────
  final Map<String, List<Map<String, dynamic>>> _localVariationsData = {
    'Bench Press': [
      {
        'name': 'Flat Bench Press',
        'description': 'Classic chest builder — targets the middle chest',
        'steps': [
          'Lie flat on bench with feet firmly on the floor.',
          'Grip bar slightly wider than shoulder-width apart.',
          'Lower bar slowly to mid-chest with control.',
          'Press up explosively, locking out at the top.',
        ],
        'sets': 4, 'reps': 10, 'rest': '60s',
        'tier': 'guest', 'emoji': '🏋️',
        'color': const Color(0xFF2979FF),
        'tip': 'Keep your feet flat and arch your back slightly for stability.',
      },
      {
        'name': 'Incline Bench Press',
        'description': 'Upper chest focus — great for a full chest look',
        'steps': [
          'Set bench to 30–45 degrees incline.',
          'Grip bar shoulder-width apart.',
          'Lower bar to upper chest with a controlled descent.',
          'Press up and squeeze the upper chest at the top.',
        ],
        'sets': 4, 'reps': 10, 'rest': '60s',
        'tier': 'free', 'emoji': '💪',
        'color': const Color(0xFF00C853),
        'tip': 'Don\'t go too steep — 30–45 degrees is the sweet spot.',
      },
      {
        'name': 'Decline Bench Press',
        'description': 'Lower chest focus — completes the chest shape',
        'steps': [
          'Set bench declined 15–30 degrees.',
          'Grip bar slightly wider than shoulder-width.',
          'Lower the bar to your lower chest.',
          'Press up powerfully and repeat.',
        ],
        'sets': 3, 'reps': 12, 'rest': '60s',
        'tier': 'free', 'emoji': '⚡',
        'color': const Color(0xFFFF6D00),
        'tip': 'Make sure your feet are secured before lifting.',
      },
      {
        'name': 'Dumbbell Bench Press',
        'description': 'Full range of motion — maximizes muscle stretch',
        'steps': [
          'Hold dumbbells at chest level, lie flat on bench.',
          'Lower dumbbells past chest level for maximum stretch.',
          'Press up and squeeze at the top.',
          'Control the descent on every rep.',
        ],
        'sets': 4, 'reps': 12, 'rest': '60s',
        'tier': 'premium', 'emoji': '🔥',
        'color': const Color(0xFFAA00FF),
        'tip': 'Go deeper than barbell for maximum chest stretch and activation.',
      },
    ],
    'Pull Ups': [
      {
        'name': 'Wide Grip Pull Up',
        'description': 'Targets lat width — builds that V-taper',
        'steps': [
          'Grip bar wider than shoulder-width.',
          'Hang with arms fully extended, core tight.',
          'Pull chest toward the bar by driving elbows down.',
          'Lower slowly until arms are fully extended.',
        ],
        'sets': 3, 'reps': 8, 'rest': '90s',
        'tier': 'guest', 'emoji': '💪',
        'color': const Color(0xFF00C853),
        'tip': 'Focus on pulling elbows down, not just pulling up.',
      },
      {
        'name': 'Narrow Grip Pull Up',
        'description': 'Targets biceps more — great arm builder',
        'steps': [
          'Grip bar narrower than shoulder-width.',
          'Hang with arms fully extended.',
          'Pull up explosively, chin over the bar.',
          'Lower with control back to full extension.',
        ],
        'sets': 3, 'reps': 10, 'rest': '90s',
        'tier': 'free', 'emoji': '🏋️',
        'color': const Color(0xFF2979FF),
        'tip': 'Supinate your grip for maximum bicep activation.',
      },
      {
        'name': 'Weighted Pull Up',
        'description': 'Advanced overload — accelerates back development',
        'steps': [
          'Attach weight belt or hold dumbbell between feet.',
          'Grip bar at shoulder-width or slightly wider.',
          'Pull explosively until chin clears the bar.',
          'Lower slowly — resist gravity on the way down.',
        ],
        'sets': 4, 'reps': 6, 'rest': '120s',
        'tier': 'premium', 'emoji': '🔥',
        'color': const Color(0xFFAA00FF),
        'tip': 'Start with lighter weight and prioritize full range of motion.',
      },
    ],
    'Shoulder Press': [
      {
        'name': 'Standing Shoulder Press',
        'description': 'Core stability + shoulders — full body tension',
        'steps': [
          'Stand with dumbbells at shoulder height, palms forward.',
          'Brace your core and glutes.',
          'Press overhead until arms are fully extended.',
          'Lower back to shoulder level with control.',
        ],
        'sets': 3, 'reps': 10, 'rest': '45s',
        'tier': 'guest', 'emoji': '⚡',
        'color': const Color(0xFFFF6D00),
        'tip': 'Brace your core — don\'t lean back excessively.',
      },
      {
        'name': 'Seated Shoulder Press',
        'description': 'Strict form — isolates shoulders perfectly',
        'steps': [
          'Sit on a bench with back support.',
          'Hold dumbbells at shoulder height, elbows at 90 degrees.',
          'Press straight overhead until arms are extended.',
          'Lower slowly back to the start.',
        ],
        'sets': 4, 'reps': 10, 'rest': '45s',
        'tier': 'free', 'emoji': '💪',
        'color': const Color(0xFF2979FF),
        'tip': 'Keep your back pressed firmly against the pad throughout.',
      },
      {
        'name': 'Arnold Press',
        'description': 'Full shoulder activation — all three heads',
        'steps': [
          'Sit with dumbbells at chin height, palms facing you.',
          'Rotate palms outward as you press overhead.',
          'Fully extend arms at the top.',
          'Reverse the rotation as you lower back down.',
        ],
        'sets': 3, 'reps': 12, 'rest': '45s',
        'tier': 'premium', 'emoji': '🔥',
        'color': const Color(0xFFAA00FF),
        'tip': 'Go lighter than normal — the rotation makes this harder.',
      },
    ],
  };

  List<Map<String, dynamic>> get _variations {
    if (_dbVariations.isNotEmpty) return _dbVariations;
    final name = widget.exercise['name'] as String? ?? '';
    return _localVariationsData[name] ?? [];
  }

  bool _isTierUnlocked(String required) {
    const order = {'guest': 0, 'free': 1, 'premium': 2};
    return (order[widget.userTier] ?? 0) >= (order[required] ?? 0);
  }

  Color _getMuscleColor(String muscle) {
    switch (muscle.toLowerCase()) {
      case 'chest':     return const Color(0xFF2979FF);
      case 'back':      return const Color(0xFF00C853);
      case 'shoulders': return const Color(0xFFFF6D00);
      case 'legs':      return const Color(0xFFAA00FF);
      case 'arms':      return const Color(0xFFFFD600);
      case 'core':      return const Color(0xFFFF1744);
      default:          return AppColors.primary;
    }
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
    _loadVariationsFromDB();
  }

  Future<void> _loadVariationsFromDB() async {
    final exerciseId = widget.exercise['id'];
    if (exerciseId == null) return;
    setState(() => _isLoadingVariations = true);
    try {
      final vars = await SupabaseService.getExerciseVariations(exerciseId as int);
      if (mounted && vars.isNotEmpty) {
        final mapped = vars.map((v) {
          final tierRaw = v['tier_required'] as String? ?? 'guest';
          final steps = (v['steps'] as List?)?.cast<String>() ?? [];
          final restSecs = v['rest_seconds'] as int? ?? 60;
          final restStr = restSecs >= 60 ? '${(restSecs / 60).round()}m' : '${restSecs}s';
          final colorMap = {
            'guest': const Color(0xFF2979FF),
            'free': const Color(0xFF00C853),
            'premium': const Color(0xFFAA00FF),
          };
          return {
            'name': v['name'] ?? '',
            'description': v['description'] ?? '',
            'steps': steps,
            'sets': v['sets'] ?? 3,
            'reps': v['reps'] ?? 10,
            'rest': restStr,
            'tier': tierRaw,
            'emoji': _getEmojiForTier(tierRaw),
            'color': colorMap[tierRaw] ?? const Color(0xFF2979FF),
            'tip': 'Focus on form and controlled movement throughout.',
          };
        }).toList();
        setState(() => _dbVariations = mapped);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingVariations = false);
  }

  String _getEmojiForTier(String tier) {
    switch (tier) {
      case 'premium': return '🔥';
      case 'free':    return '💪';
      default:        return '🏋️';
    }
  }

  Future<void> _logWorkout() async {
    if (!SupabaseService.isLoggedIn) {
      _showUpgradeDialog('free');
      return;
    }
    setState(() => _isLoggingWorkout = true);
    final exerciseId = widget.exercise['id'];
    bool success = false;
    if (exerciseId != null) {
      success = await SupabaseService.logWorkout(exerciseId as int);
    }
    if (mounted) {
      setState(() => _isLoggingWorkout = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '✅ Workout logged!' : '⚠️ Could not log — try again'),
          backgroundColor: success ? const Color(0xFF00C853) : const Color(0xFFFF1744),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _showUpgradeDialog(String requiredTier) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF141414) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🔒 Locked'),
        content: Text(
          requiredTier == 'premium'
              ? 'This variation requires a Premium account. Upgrade to unlock all exercises!'
              : 'This variation requires a free account. Sign up to unlock!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, requiredTier == 'premium' ? '/premium' : '/register');
            },
            child: Text(requiredTier == 'premium' ? 'Upgrade' : 'Sign Up Free'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (kIsWeb) return _buildWebLayout(isDark);
    return _buildMobileLayout(isDark);
  }

  // ─────────────────────────────────────────
  // SHARED WIDGETS
  // ─────────────────────────────────────────

  Widget _buildTierBadge(String tier) {
    final colors = {'guest': Colors.grey, 'free': AppColors.primary, 'premium': const Color(0xFFFFD600)};
    final labels = {'guest': 'FREE', 'free': 'MEMBER', 'premium': '⭐ PRO'};
    final color = colors[tier] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: color.withOpacity(0.12),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(labels[tier] ?? 'FREE',
          style: TextStyle(fontSize: 8, color: color, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withOpacity(0.15),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(text,
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color.withOpacity(0.08),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                    color: color.withOpacity(0.7))),
          ],
        ),
      ),
    );
  }

  Widget _buildVariationSelector({required Color textPrimary, required Color textSecondary}) {
    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _variations.length,
        itemBuilder: (_, index) {
          final v = _variations[index];
          final isSelected = _selectedVariation == index;
          final isUnlocked = _isTierUnlocked(v['tier'] as String);
          final color = v['color'] as Color;

          return GestureDetector(
            onTap: () {
              if (isUnlocked) {
                setState(() => _selectedVariation = index);
              } else {
                _showUpgradeDialog(v['tier'] as String);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: isSelected ? color : color.withOpacity(0.1),
                border: Border.all(color: isSelected ? color : color.withOpacity(0.3)),
                boxShadow: isSelected
                    ? [BoxShadow(color: color.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isUnlocked)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(Icons.lock_rounded, size: 11, color: isSelected ? Colors.white : textSecondary),
                    ),
                  Text(
                    v['name'] as String,
                    style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : (isUnlocked ? color : textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Variation detail card WITH image ─────────────────────────────────────────
  Widget _buildVariationDetail({
    required Map<String, dynamic> variation,
    required Color cardColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required bool isDark,
    required String muscle,
  }) {
    final color = variation['color'] as Color;
    final steps = (variation['steps'] as List?)?.cast<String>() ?? [];
    final imageUrl = _getVariationImage(variation['name'] as String, muscle);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: cardColor,
        border: Border.all(color: color.withOpacity(0.25), width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withOpacity(isDark ? 0.12 : 0.08),
              blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Photo header ──────────────────────────────────────────────────────
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color.withOpacity(0.6), color.withOpacity(0.3)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
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
                  Positioned(
                    left: 16, right: 16, bottom: 14,
                    child: Row(
                      children: [
                        Text(variation['emoji'] as String,
                            style: const TextStyle(fontSize: 28)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(variation['name'] as String,
                                  style: const TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.w900,
                                    color: Colors.white, letterSpacing: -0.2,
                                  )),
                              Text(variation['description'] as String,
                                  style: TextStyle(
                                    fontSize: 11, color: Colors.white.withOpacity(0.8),
                                  ),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        _buildTierBadge(variation['tier'] as String),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Body ──────────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildStatChip('Sets', '${variation['sets']}', color),
                    const SizedBox(width: 10),
                    _buildStatChip('Reps', '${variation['reps']}', color),
                    const SizedBox(width: 10),
                    _buildStatChip('Rest', variation['rest'] as String, color),
                  ],
                ),

                const SizedBox(height: 18),

                Text('How to perform:',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w800, color: textPrimary)),
                const SizedBox(height: 10),
                ...steps.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 26, height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
                            ),
                            border: Border.all(color: color.withOpacity(0.4)),
                          ),
                          child: Center(
                            child: Text('${entry.key + 1}',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w900, color: color)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(entry.value,
                                style: TextStyle(fontSize: 13, color: textSecondary, height: 1.4)),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 14),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isDark
                        ? AppColors.primary.withOpacity(0.08)
                        : AppColors.primary.withOpacity(0.05),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('💡', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Pro Tip',
                                style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                )),
                            const SizedBox(height: 2),
                            Text(variation['tip'] as String,
                                style: TextStyle(fontSize: 12, color: textSecondary, height: 1.4)),
                          ],
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
  }

  Widget _buildVariationsList({
    required Color cardColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required String muscle,
  }) {
    return Column(
      children: _variations.asMap().entries.map((entry) {
        final index = entry.key;
        final v = entry.value;
        final isUnlocked = _isTierUnlocked(v['tier'] as String);
        final color = v['color'] as Color;
        final isSelected = _selectedVariation == index;
        final imageUrl = _getVariationImage(v['name'] as String, muscle);

        return GestureDetector(
          onTap: () {
            if (isUnlocked) {
              setState(() => _selectedVariation = index);
            } else {
              _showUpgradeDialog(v['tier'] as String);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isSelected ? color.withOpacity(0.08) : cardColor,
              border: Border.all(
                color: isSelected ? color.withOpacity(0.45) : borderColor,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Row(
                children: [
                  SizedBox(
                    width: 64, height: 64,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: color.withOpacity(0.15),
                            child: Center(child: Text(v['emoji'] as String,
                                style: const TextStyle(fontSize: 22))),
                          ),
                        ),
                        if (!isUnlocked)
                          Container(
                            color: Colors.black.withOpacity(0.55),
                            child: const Center(
                              child: Icon(Icons.lock_rounded, color: Colors.white, size: 18),
                            ),
                          ),
                        Positioned(
                          left: 0, top: 0, bottom: 0,
                          child: Container(width: 3, color: color),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(v['name'] as String,
                                    style: TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w800,
                                      color: isUnlocked ? textPrimary : textSecondary,
                                    ),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Text(v['description'] as String,
                                    style: TextStyle(fontSize: 10, color: textSecondary),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _buildTierBadge(v['tier'] as String),
                              const SizedBox(height: 4),
                              Text('${v['sets']}×${v['reps']}',
                                  style: TextStyle(
                                    fontSize: 12, color: color, fontWeight: FontWeight.w900,
                                  )),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─────────────────────────────────────────
  // MOBILE LAYOUT
  // ─────────────────────────────────────────
  Widget _buildMobileLayout(bool isDark) {
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final textSecondary = isDark ? const Color(0xFFB0B0B0) : const Color(0xFF666666);
    final bgColor = isDark ? const Color(0xFF050A05) : const Color(0xFFF4F6F8);
    final cardColor = isDark ? const Color(0xFF141414) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5E5);

    final exercise = widget.exercise;
    final muscle = exercise['muscle'] as String? ?? '';
    final muscleColor = _getMuscleColor(muscle);
    final heroImageUrl = _muscleImages[muscle] ??
        'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=800&q=80';

    return Scaffold(
      backgroundColor: bgColor,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              backgroundColor: bgColor,
              leading: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.4),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 16, color: Colors.white),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: _isLoggingWorkout ? null : _logWorkout,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: _isLoggingWorkout
                            ? Colors.black.withOpacity(0.3)
                            : AppColors.primary.withOpacity(0.9),
                      ),
                      child: _isLoggingWorkout
                          ? const SizedBox(
                              width: 14, height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('+ Log',
                              style: TextStyle(
                                color: Colors.black, fontSize: 12, fontWeight: FontWeight.w800,
                              )),
                    ),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(heroImageUrl, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [muscleColor.withOpacity(0.6), muscleColor.withOpacity(0.3)],
                            ),
                          ),
                        )),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black.withOpacity(0.3), Colors.black.withOpacity(0.75)],
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 44, 20, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 54, height: 54,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: muscleColor.withOpacity(0.25),
                                    border: Border.all(color: muscleColor.withOpacity(0.6), width: 2),
                                  ),
                                  child: Center(
                                    child: Text(exercise['emoji'] as String? ?? '💪',
                                        style: const TextStyle(fontSize: 24)),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(exercise['name'] as String? ?? '',
                                          style: const TextStyle(
                                            fontSize: 24, fontWeight: FontWeight.w900,
                                            color: Colors.white, letterSpacing: -0.4,
                                          )),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          _buildBadge(muscle, muscleColor),
                                          const SizedBox(width: 8),
                                          _buildBadge(
                                              exercise['difficulty'] as String? ?? 'Beginner',
                                              AppColors.primary),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Exercise Variations',
                                  style: TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.w900, color: textPrimary)),
                              const SizedBox(height: 2),
                              Text(
                                _isLoadingVariations
                                    ? 'Loading from database…'
                                    : '${_variations.length} variations available',
                                style: TextStyle(fontSize: 12, color: textSecondary),
                              ),
                            ],
                          ),
                        ),
                        if (_isLoadingVariations)
                          SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    _buildVariationSelector(textPrimary: textPrimary, textSecondary: textSecondary),
                    const SizedBox(height: 20),

                    if (_variations.isNotEmpty)
                      _buildVariationDetail(
                        variation: _variations[_selectedVariation],
                        cardColor: cardColor,
                        borderColor: borderColor,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        isDark: isDark,
                        muscle: muscle,
                      ),

                    const SizedBox(height: 24),

                    Text('All Variations',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textPrimary)),
                    const SizedBox(height: 12),

                    _buildVariationsList(
                      cardColor: cardColor,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      muscle: muscle,
                    ),

                    const SizedBox(height: 36),

                    GestureDetector(
                      onTap: _isLoggingWorkout ? null : _logWorkout,
                      child: Container(
                        width: double.infinity, height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00C853), Color(0xFF69F0AE)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00C853).withOpacity(0.4),
                              blurRadius: 20, offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: _isLoggingWorkout
                              ? const SizedBox(
                                  width: 22, height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black),
                                )
                              : const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.fitness_center_rounded, color: Colors.black, size: 20),
                                    SizedBox(width: 8),
                                    Text('Log This Workout',
                                        style: TextStyle(
                                          color: Colors.black, fontSize: 16, fontWeight: FontWeight.w900,
                                        )),
                                  ],
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // WEB LAYOUT
  // ─────────────────────────────────────────
  Widget _buildWebLayout(bool isDark) {
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final textSecondary = isDark ? const Color(0xFFB0B0B0) : const Color(0xFF666666);
    final bgColor = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF0F2F5);
    final cardColor = isDark ? const Color(0xFF141414) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5E5);

    final exercise = widget.exercise;
    final muscle = exercise['muscle'] as String? ?? '';
    final muscleColor = _getMuscleColor(muscle);
    final heroImageUrl = _muscleImages[muscle] ??
        'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=800&q=80';

    return Scaffold(
      backgroundColor: bgColor,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SizedBox.expand(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back + Log row
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: textSecondary),
                              const SizedBox(width: 6),
                              Text('Back to Exercises',
                                  style: TextStyle(fontSize: 13, color: textSecondary)),
                            ],
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: _isLoggingWorkout ? null : _logWorkout,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00C853), Color(0xFF69F0AE)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00C853).withOpacity(0.35),
                                  blurRadius: 12, offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: _isLoggingWorkout
                                ? const SizedBox(
                                    width: 16, height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                  )
                                : const Row(
                                    children: [
                                      Icon(Icons.fitness_center_rounded, color: Colors.black, size: 16),
                                      SizedBox(width: 6),
                                      Text('Log Workout',
                                          style: TextStyle(
                                            color: Colors.black, fontSize: 13, fontWeight: FontWeight.w800,
                                          )),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Hero card with real photo
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: SizedBox(
                        height: 220,
                        width: double.infinity,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(heroImageUrl, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [muscleColor.withOpacity(0.5), muscleColor.withOpacity(0.2)],
                                    ),
                                  ),
                                )),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [Colors.black.withOpacity(0.8), Colors.black.withOpacity(0.2)],
                                ),
                              ),
                            ),
                            Positioned(
                              left: 28, top: 0, bottom: 0,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(exercise['emoji'] as String? ?? '💪',
                                      style: const TextStyle(fontSize: 40)),
                                  const SizedBox(height: 8),
                                  Text(exercise['name'] as String? ?? '',
                                      style: const TextStyle(
                                        fontSize: 30, fontWeight: FontWeight.w900,
                                        color: Colors.white, letterSpacing: -0.5,
                                      )),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      _buildBadge(muscle, muscleColor),
                                      const SizedBox(width: 8),
                                      _buildBadge(exercise['difficulty'] as String? ?? 'Beginner',
                                          AppColors.primary),
                                      const SizedBox(width: 8),
                                      _buildBadge('${_variations.length} Variations', textSecondary),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Text('Exercise Variations',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textPrimary)),
                        const Spacer(),
                        if (_isLoadingVariations)
                          Row(
                            children: [
                              SizedBox(width: 14, height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                              const SizedBox(width: 6),
                              Text('Loading…', style: TextStyle(fontSize: 11, color: textSecondary)),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildVariationSelector(textPrimary: textPrimary, textSecondary: textSecondary),
                    const SizedBox(height: 20),

                    if (_variations.isNotEmpty)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _buildVariationDetail(
                              variation: _variations[_selectedVariation],
                              cardColor: cardColor,
                              borderColor: borderColor,
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                              isDark: isDark,
                              muscle: muscle,
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('All Variations',
                                    style: TextStyle(
                                        fontSize: 15, fontWeight: FontWeight.w800, color: textPrimary)),
                                const SizedBox(height: 12),
                                _buildVariationsList(
                                  cardColor: cardColor,
                                  borderColor: borderColor,
                                  textPrimary: textPrimary,
                                  textSecondary: textSecondary,
                                  muscle: muscle,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}