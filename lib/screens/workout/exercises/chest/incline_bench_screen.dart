import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/supabase_service.dart';

// ══════════════════════════════════════════════════════════════════════════════
// INCLINE BENCH SCREEN
// Standalone screen for Incline Bench Press — all data, variations, video,
// tips, and mistakes are fully self-contained here.
// Place at: lib/screens/workout/exercises/chest/incline_bench_screen.dart
// ══════════════════════════════════════════════════════════════════════════════

class InclineBenchScreen extends StatefulWidget {
  final String userTier; // 'guest', 'free', 'premium'

  const InclineBenchScreen({super.key, required this.userTier});

  @override
  State<InclineBenchScreen> createState() => _InclineBenchScreenState();
}

class _InclineBenchScreenState extends State<InclineBenchScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  YoutubePlayerController? _ytController;

  int _selectedVariation = 0;
  bool _isLoggingWorkout = false;

  // ── Exercise colour ────────────────────────────────────────────────────────
  static const Color _color = Color(0xFF00C853);
  static const List<Color> _gradient = [Color(0xFF00695C), Color(0xFF00C853)];

  // ── Core exercise data ─────────────────────────────────────────────────────
  static const Map<String, dynamic> _exercise = {
    'name': 'Incline Bench Press',
    'difficulty': 'Intermediate',
    'tier': 'free',
    'emoji': '💪',
    'sets': 4,
    'reps': 10,
    'rest': '60s',
    'calories': 110,
    'desc': 'Upper chest focus at 30–45° incline for a full chest look.',
    'muscle': 'Chest',
    'equipment': 'Barbell / Dumbbells, Incline Bench',
    'image':
        'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800&q=80',
    'videoThumbnail':
        'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=800&q=80',
    'videoUrl': 'https://www.youtube.com/watch?v=jPLdzuHckI8',
    'videoId': 'jPLdzuHckI8',
  };

  static const List<String> _primaryMuscles = [
    'Upper Pectoralis Major',
    'Anterior Deltoid',
    'Triceps Brachii',
  ];

  static const List<String> _secondaryMuscles = [
    'Serratus Anterior',
    'Biceps Brachii (stabiliser)',
  ];

  static const List<String> _tips = [
    'Set the bench between 30–45°. Higher than 45° shifts too much work to the shoulders.',
    'Keep your shoulder blades pinched and retracted throughout the movement.',
    'Lower the bar to your upper chest — just below the collar bone.',
    'Drive your feet hard into the floor to stabilise your whole body.',
    'Use a controlled 2-second descent; don\'t drop the bar.',
  ];

  static const List<String> _commonMistakes = [
    'Setting the incline too high (>45°) — turns it into a shoulder press.',
    'Letting your lower back arch excessively off the bench.',
    'Touching the bar too low (mid-chest) — misses the upper pec.',
    'Flaring elbows out more than 75° — increases shoulder injury risk.',
  ];

  // ── Variations ─────────────────────────────────────────────────────────────
  static const List<Map<String, dynamic>> _variations = [
    {
      'name': 'Barbell Incline Press',
      'tier': 'free',
      'sets': 4,
      'reps': 10,
      'rest': '60s',
      'desc': 'Classic upper chest builder',
      'color': Color(0xFF00C853),
      'image':
          'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=600&q=80',
      'emoji': '💪',
      'steps': [
        'Set bench to 30–45 degrees incline.',
        'Grip bar slightly wider than shoulder-width, unrack.',
        'Lower bar slowly to upper chest (just below the collar bone).',
        'Press up explosively, lock out, and squeeze upper chest at top.',
      ],
      'tip': 'Keep elbows at roughly 60–75° from your torso — not fully flared.',
    },
    {
      'name': 'Dumbbell Incline Press',
      'tier': 'free',
      'sets': 4,
      'reps': 12,
      'rest': '60s',
      'desc': 'Greater range of motion and unilateral balance',
      'color': Color(0xFF2979FF),
      'image':
          'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=600&q=80',
      'emoji': '🏋️',
      'steps': [
        'Hold a dumbbell in each hand, sit on incline bench.',
        'Press dumbbells to the start position at shoulder height.',
        'Lower dumbbells out and down, elbows at 70°, deep stretch.',
        'Press back up, squeeze upper chest, bring dumbbells together slightly.',
      ],
      'tip':
          'Go slightly deeper than with a barbell for maximum upper-pec stretch.',
    },
    {
      'name': 'Close-Grip Incline Press',
      'tier': 'premium',
      'sets': 3,
      'reps': 12,
      'rest': '60s',
      'desc': 'Upper chest + tricep emphasis',
      'color': Color(0xFFAA00FF),
      'image':
          'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=600&q=80',
      'emoji': '🔥',
      'steps': [
        'Set bench to 30–45° incline.',
        'Grip bar at shoulder-width or slightly narrower.',
        'Lower bar to upper chest with elbows tucked close to your body.',
        'Press up powerfully, locking out triceps at the top.',
      ],
      'tip':
          'Narrower grip puts more emphasis on triceps — great for finishing sets.',
    },
    {
      'name': 'Cable Incline Fly',
      'tier': 'premium',
      'sets': 3,
      'reps': 15,
      'rest': '45s',
      'desc': 'Constant tension isolation for upper chest',
      'color': Color(0xFFFF6D00),
      'image':
          'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?w=600&q=80',
      'emoji': '⚡',
      'steps': [
        'Set cables low, position incline bench at 30–45° between them.',
        'Grab one cable in each hand, lie back on bench.',
        'With a slight bend in the elbows, arc the handles up and together.',
        'Squeeze upper chest at the top, then slowly lower back out.',
      ],
      'tip':
          'Cables keep constant tension unlike dumbbells — great for the stretch at the bottom.',
    },
  ];

  // ── Tier helpers ───────────────────────────────────────────────────────────
  bool _isTierUnlocked(String required) {
    const order = {'guest': 0, 'free': 1, 'premium': 2};
    return (order[widget.userTier] ?? 0) >= (order[required] ?? 0);
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(
            CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();

    if (!kIsWeb) {
      _ytController = YoutubePlayerController.fromVideoId(
        videoId: 'jPLdzuHckI8',
        autoPlay: false,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          mute: false,
        ),
      );
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    if (!kIsWeb) {
      _ytController?.close();
    }
    super.dispose();
  }

  // ── Log workout ────────────────────────────────────────────────────────────
  Future<void> _logWorkout() async {
    if (!SupabaseService.isLoggedIn) {
      _showUpgradeDialog('free');
      return;
    }
    setState(() => _isLoggingWorkout = true);
    bool success = false;
    try {
      final exercises = await SupabaseService.getExercises(muscle: 'Chest');
      final match = exercises.firstWhere(
        (e) =>
            (e['name'] as String?)?.toLowerCase().contains('incline') == true,
        orElse: () => {},
      );
      if (match.isNotEmpty && match['id'] != null) {
        success = await SupabaseService.logWorkout(match['id'] as int);
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _isLoggingWorkout = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success
            ? '✅ Incline Bench logged!'
            : '⚠️ Could not log — try again'),
        backgroundColor:
            success ? const Color(0xFF00C853) : const Color(0xFFFF1744),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  // ── Upgrade dialogs ────────────────────────────────────────────────────────
  void _showUpgradeDialog(String requiredTier) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF141414) : Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🔒 Locked'),
        content: Text(
          requiredTier == 'premium'
              ? 'This variation requires a Premium account. Upgrade to unlock all exercises!'
              : 'This variation requires a free account. Sign up to unlock!',
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
              Navigator.pushNamed(
                  context,
                  requiredTier == 'premium' ? '/premium' : '/register');
            },
            child:
                Text(requiredTier == 'premium' ? 'Upgrade' : 'Sign Up Free'),
          ),
        ],
      ),
    );
  }

  void _showUpgradeSheet(String requiredTier) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPremium = requiredTier == 'premium';
    final color = isPremium ? const Color(0xFFAA00FF) : AppColors.primary;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 48),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141414) : Colors.white,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 24),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [
                  color.withOpacity(0.15),
                  color.withOpacity(0.35)
                ]),
                border: Border.all(color: color.withOpacity(0.4), width: 2),
              ),
              child: Center(
                  child: Icon(Icons.lock_rounded, color: color, size: 30)),
            ),
            const SizedBox(height: 18),
            Text(
              isPremium ? '⭐ Premium Required' : '🔓 Free Account Required',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black),
            ),
            const SizedBox(height: 10),
            Text(
              isPremium
                  ? 'This variation is exclusive to Premium members. Upgrade to unlock all advanced workouts.'
                  : 'Create a free account to unlock this variation and track your progress.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? const Color(0xFFB0B0B0)
                      : const Color(0xFF666666),
                  height: 1.5),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(
                    context, isPremium ? '/premium' : '/register');
              },
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: isPremium
                        ? [const Color(0xFF7B1FA2), const Color(0xFFCE93D8)]
                        : [const Color(0xFF00C853), const Color(0xFF5EFC82)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8))
                  ],
                ),
                child: Center(
                  child: Text(
                    isPremium
                        ? '⭐ Upgrade to Premium'
                        : '✨ Create Free Account',
                    style: TextStyle(
                        color: isPremium ? Colors.white : Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Maybe Later',
                  style: TextStyle(
                      color: isDark
                          ? const Color(0xFFB0B0B0)
                          : const Color(0xFF888888),
                      fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (kIsWeb) return _buildWebLayout(isDark);
    return _buildMobileLayout(isDark);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SHARED WIDGETS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withOpacity(0.15),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildTierBadge(String tier) {
    final colors = {
      'guest': Colors.grey,
      'free': AppColors.primary,
      'premium': const Color(0xFFFFD600)
    };
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
          style: TextStyle(
              fontSize: 8,
              color: color,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5)),
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
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color.withOpacity(0.7))),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Text(title,
        style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w800, color: color));
  }

  Widget _buildMuscleBadge(String muscle, Color color, bool isPrimary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isPrimary ? color.withOpacity(0.15) : Colors.transparent,
        border: Border.all(
            color: isPrimary
                ? color.withOpacity(0.5)
                : color.withOpacity(0.25)),
      ),
      child: Text(muscle,
          style: TextStyle(
              fontSize: 10,
              color: isPrimary ? color : color.withOpacity(0.6),
              fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w500)),
    );
  }

  // ── Variation selector pills ───────────────────────────────────────────────
  Widget _buildVariationSelector(
      {required Color textPrimary, required Color textSecondary}) {
    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _variations.length,
        itemBuilder: (_, index) {
          final v = _variations[index];
          final isSelected = _selectedVariation == index;
          final isUnlocked = _isTierUnlocked(v['tier'] as String? ?? 'free');
          final color = v['color'] as Color? ?? _color;

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
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: isSelected ? color : color.withOpacity(0.1),
                border: Border.all(
                    color: isSelected ? color : color.withOpacity(0.3)),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                            color: color.withOpacity(0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4))
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isUnlocked)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(Icons.lock_rounded,
                          size: 11,
                          color:
                              isSelected ? Colors.white : textSecondary),
                    ),
                  Text(v['name'] as String,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : (isUnlocked ? color : textSecondary))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Variation detail card ──────────────────────────────────────────────────
  Widget _buildVariationDetail({
    required Map<String, dynamic> variation,
    required Color cardColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required bool isDark,
  }) {
    final color = variation['color'] as Color? ?? _color;
    final steps = (variation['steps'] as List?)?.cast<String>() ?? [];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: cardColor,
        border: Border.all(color: color.withOpacity(0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(isDark ? 0.12 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    variation['image'] as String? ??
                        _exercise['image'] as String,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.withOpacity(0.6),
                            color.withOpacity(0.3)
                          ],
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
                    left: 16,
                    right: 16,
                    bottom: 14,
                    child: Row(
                      children: [
                        Text(variation['emoji'] as String? ?? '💪',
                            style: const TextStyle(fontSize: 28)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(variation['name'] as String,
                                  style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: -0.2)),
                              Text(variation['desc'] as String? ?? '',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white.withOpacity(0.8)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        _buildTierBadge(
                            variation['tier'] as String? ?? 'free'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
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
                    _buildStatChip(
                        'Rest', variation['rest'] as String? ?? '60s', color),
                  ],
                ),
                const SizedBox(height: 18),
                Text('How to perform:',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: textPrimary)),
                const SizedBox(height: 10),
                ...steps.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(colors: [
                              color.withOpacity(0.2),
                              color.withOpacity(0.1)
                            ]),
                            border:
                                Border.all(color: color.withOpacity(0.4)),
                          ),
                          child: Center(
                            child: Text('${entry.key + 1}',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: color)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(entry.value,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: textSecondary,
                                    height: 1.4)),
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
                    border:
                        Border.all(color: AppColors.primary.withOpacity(0.2)),
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
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary)),
                            const SizedBox(height: 2),
                            Text(variation['tip'] as String? ?? '',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: textSecondary,
                                    height: 1.4)),
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

  // ── Variations list ────────────────────────────────────────────────────────
  Widget _buildVariationsList({
    required Color cardColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Column(
      children: _variations.asMap().entries.map((entry) {
        final index = entry.key;
        final v = entry.value;
        final isUnlocked = _isTierUnlocked(v['tier'] as String? ?? 'free');
        final color = v['color'] as Color? ?? _color;
        final isSelected = _selectedVariation == index;

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
                  width: isSelected ? 1.5 : 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Row(
                children: [
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          v['image'] as String? ??
                              _exercise['image'] as String,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: color.withOpacity(0.15),
                            child: Center(
                                child: Text(v['emoji'] as String? ?? '💪',
                                    style:
                                        const TextStyle(fontSize: 22))),
                          ),
                        ),
                        if (!isUnlocked)
                          Container(
                            color: Colors.black.withOpacity(0.55),
                            child: const Center(
                                child: Icon(Icons.lock_rounded,
                                    color: Colors.white, size: 18)),
                          ),
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
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
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: isUnlocked
                                            ? textPrimary
                                            : textSecondary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Text(v['desc'] as String? ?? '',
                                    style: TextStyle(
                                        fontSize: 10, color: textSecondary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _buildTierBadge(
                                  v['tier'] as String? ?? 'free'),
                              const SizedBox(height: 4),
                              Text('${v['sets']}×${v['reps']}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: color,
                                      fontWeight: FontWeight.w900)),
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

  // ── Video card — platform-aware ────────────────────────────────────────────
  Widget _buildVideoCard(bool isDark) {
    if (kIsWeb) {
      return GestureDetector(
        onTap: () => launchUrl(
          Uri.parse(_exercise['videoUrl'] as String),
          mode: LaunchMode.externalApplication,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  _exercise['videoThumbnail'] as String,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.black,
                  ),
                ),
                Container(
                  color: Colors.black.withOpacity(0.35),
                ),
                const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_circle_filled_rounded,
                          color: Colors.red, size: 64),
                      SizedBox(height: 10),
                      Text('Watch on YouTube',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Mobile: embedded player
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: YoutubePlayerScaffold(
        controller: _ytController!,
        aspectRatio: 16 / 9,
        builder: (context, player) => player,
      ),
    );
  }

  // ── Log button ─────────────────────────────────────────────────────────────
  Widget _buildLogButton() {
    return GestureDetector(
      onTap: _isLoggingWorkout ? null : _logWorkout,
      child: Container(
        width: double.infinity,
        height: 56,
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
                blurRadius: 20,
                offset: const Offset(0, 8))
          ],
        ),
        child: Center(
          child: _isLoggingWorkout
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.black))
              : const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fitness_center_rounded,
                        color: Colors.black, size: 20),
                    SizedBox(width: 8),
                    Text('Log This Workout',
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w900)),
                  ],
                ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MOBILE LAYOUT
  // ══════════════════════════════════════════════════════════════════════════
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
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 260,
              pinned: true,
              backgroundColor: bgColor,
              leading: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.4),
                    border:
                        Border.all(color: Colors.white.withOpacity(0.3)),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: _isLoggingWorkout
                            ? Colors.black.withOpacity(0.3)
                            : AppColors.primary.withOpacity(0.9),
                      ),
                      child: _isLoggingWorkout
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('+ Log',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800)),
                    ),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      _exercise['image'] as String,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: _gradient,
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
                            Colors.black.withOpacity(0.3),
                            Colors.black.withOpacity(0.85)
                          ],
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding:
                            const EdgeInsets.fromLTRB(20, 48, 20, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _color.withOpacity(0.25),
                                    border: Border.all(
                                        color: _color.withOpacity(0.6),
                                        width: 2),
                                  ),
                                  child: const Center(
                                    child: Text('💪',
                                        style: TextStyle(fontSize: 24)),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('Incline Bench Press',
                                          style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                              letterSpacing: -0.4)),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          _buildBadge('Chest', _color),
                                          const SizedBox(width: 8),
                                          _buildBadge('Intermediate',
                                              AppColors.primary),
                                          const SizedBox(width: 8),
                                          _buildBadge(
                                              '4 Variations', textSecondary),
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
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: cardColor,
                        border:
                            Border.all(color: _color.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.construction_rounded,
                              size: 14, color: _color),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_exercise['equipment'] as String,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: textPrimary,
                                    fontWeight: FontWeight.w600)),
                          ),
                          const Icon(Icons.local_fire_department_rounded,
                              size: 14, color: Color(0xFFFFD600)),
                          const SizedBox(width: 4),
                          const Text('~110 kcal/session',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFFFD600),
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildSectionHeader('💪 Muscles Worked', _color),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        ..._primaryMuscles
                            .map((m) => _buildMuscleBadge(m, _color, true)),
                        ..._secondaryMuscles
                            .map((m) => _buildMuscleBadge(m, _color, false)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSectionHeader('🎬 Tutorial Video', _color),
                    const SizedBox(height: 10),
                    _buildVideoCard(isDark),
                    const SizedBox(height: 20),
                    _buildSectionHeader('💡 Pro Tips', _color),
                    const SizedBox(height: 10),
                    ..._tips.asMap().entries.map((entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _color.withOpacity(0.15),
                                  border: Border.all(
                                      color: _color.withOpacity(0.4)),
                                ),
                                child: Center(
                                  child: Text('${entry.key + 1}',
                                      style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          color: _color)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 3),
                                  child: Text(entry.value,
                                      style: TextStyle(
                                          fontSize: 12.5,
                                          color: textSecondary,
                                          height: 1.4)),
                                ),
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(height: 20),
                    _buildSectionHeader(
                        '⚠️ Common Mistakes', const Color(0xFFFF1744)),
                    const SizedBox(height: 10),
                    ..._commonMistakes.map((m) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Icon(Icons.cancel_outlined,
                                    size: 14, color: Color(0xFFFF1744)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(m,
                                    style: TextStyle(
                                        fontSize: 12.5,
                                        color: textSecondary,
                                        height: 1.4)),
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(height: 20),
                    Text('Exercise Variations',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: textPrimary)),
                    const SizedBox(height: 4),
                    Text('${_variations.length} variations available',
                        style:
                            TextStyle(fontSize: 12, color: textSecondary)),
                    const SizedBox(height: 14),
                    _buildVariationSelector(
                        textPrimary: textPrimary,
                        textSecondary: textSecondary),
                    const SizedBox(height: 20),
                    _buildVariationDetail(
                      variation: _variations[_selectedVariation],
                      cardColor: cardColor,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 24),
                    Text('All Variations',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: textPrimary)),
                    const SizedBox(height: 12),
                    _buildVariationsList(
                      cardColor: cardColor,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    const SizedBox(height: 36),
                    _buildLogButton(),
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

  // ══════════════════════════════════════════════════════════════════════════
  // WEB LAYOUT
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildWebLayout(bool isDark) {
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final textSecondary =
        isDark ? const Color(0xFFB0B0B0) : const Color(0xFF666666);
    final bgColor =
        isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF0F2F5);
    final cardColor = isDark ? const Color(0xFF141414) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5E5);

    return Scaffold(
      backgroundColor: bgColor,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SizedBox.expand(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.arrow_back_ios_new_rounded,
                                  size: 14, color: textSecondary),
                              const SizedBox(width: 6),
                              Text('Back to Chest',
                                  style: TextStyle(
                                      fontSize: 13, color: textSecondary)),
                            ],
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: _isLoggingWorkout ? null : _logWorkout,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: const LinearGradient(colors: [
                                Color(0xFF00C853),
                                Color(0xFF69F0AE)
                              ]),
                              boxShadow: [
                                BoxShadow(
                                    color: const Color(0xFF00C853)
                                        .withOpacity(0.35),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4))
                              ],
                            ),
                            child: _isLoggingWorkout
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.black))
                                : const Row(
                                    children: [
                                      Icon(Icons.fitness_center_rounded,
                                          color: Colors.black, size: 16),
                                      SizedBox(width: 6),
                                      Text('Log Workout',
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800)),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: SizedBox(
                        height: 240,
                        width: double.infinity,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              _exercise['image'] as String,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                      colors: _gradient,
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight),
                                ),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Colors.black.withOpacity(0.85),
                                    Colors.black.withOpacity(0.2)
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              left: 28,
                              top: 0,
                              bottom: 0,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('💪',
                                      style: TextStyle(fontSize: 40)),
                                  const SizedBox(height: 8),
                                  const Text('Incline Bench Press',
                                      style: TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          letterSpacing: -0.5)),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      _buildBadge('Chest', _color),
                                      const SizedBox(width: 8),
                                      _buildBadge(
                                          'Intermediate', AppColors.primary),
                                      const SizedBox(width: 8),
                                      _buildBadge('Barbell / Dumbbells',
                                          const Color(0xFFFFD600)),
                                      const SizedBox(width: 8),
                                      _buildBadge(
                                          '${_variations.length} Variations',
                                          textSecondary),
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
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: cardColor,
                        border: Border.all(color: _color.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('💪 Primary Muscles',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: textPrimary)),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: _primaryMuscles
                                      .map((m) =>
                                          _buildMuscleBadge(m, _color, true))
                                      .toList(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('🔧 Secondary Muscles',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: textPrimary)),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: _secondaryMuscles
                                      .map((m) =>
                                          _buildMuscleBadge(m, _color, false))
                                      .toList(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.construction_rounded,
                                      size: 13, color: _color),
                                  SizedBox(width: 6),
                                  Text('Barbell / Dumbbells',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF888888),
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                              SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.local_fire_department_rounded,
                                      size: 13, color: Color(0xFFFFD600)),
                                  SizedBox(width: 4),
                                  Text('~110 kcal/session',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFFFFD600),
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: cardColor,
                              border: Border.all(
                                  color: _color.withOpacity(0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionHeader('💡 Pro Tips', _color),
                                const SizedBox(height: 12),
                                ..._tips.asMap().entries.map(
                                      (entry) => Padding(
                                        padding: const EdgeInsets.only(
                                            bottom: 10),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 22,
                                              height: 22,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color:
                                                    _color.withOpacity(0.15),
                                                border: Border.all(
                                                    color: _color
                                                        .withOpacity(0.4)),
                                              ),
                                              child: Center(
                                                child: Text(
                                                    '${entry.key + 1}',
                                                    style: const TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        color: _color)),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.only(
                                                        top: 3),
                                                child: Text(entry.value,
                                                    style: TextStyle(
                                                        fontSize: 12.5,
                                                        color: textSecondary,
                                                        height: 1.4)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: cardColor,
                                  border: Border.all(
                                      color: const Color(0xFFFF1744)
                                          .withOpacity(0.2)),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    _buildSectionHeader(
                                        '⚠️ Common Mistakes',
                                        const Color(0xFFFF1744)),
                                    const SizedBox(height: 12),
                                    ..._commonMistakes.map(
                                      (m) => Padding(
                                        padding: const EdgeInsets.only(
                                            bottom: 10),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Padding(
                                              padding:
                                                  EdgeInsets.only(top: 3),
                                              child: Icon(
                                                  Icons.cancel_outlined,
                                                  size: 14,
                                                  color: Color(0xFFFF1744)),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(m,
                                                  style: TextStyle(
                                                      fontSize: 12.5,
                                                      color: textSecondary,
                                                      height: 1.4)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                              _buildSectionHeader(
                                  '🎬 Tutorial Video', _color),
                              const SizedBox(height: 10),
                              _buildVideoCard(isDark),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('Exercise Variations',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: textPrimary)),
                    const SizedBox(height: 12),
                    _buildVariationSelector(
                        textPrimary: textPrimary,
                        textSecondary: textSecondary),
                    const SizedBox(height: 20),
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
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: textPrimary)),
                              const SizedBox(height: 12),
                              _buildVariationsList(
                                cardColor: cardColor,
                                borderColor: borderColor,
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildLogButton(),
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