import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../core/theme/app_colors.dart';
import '../workout/exercise_detail_screen.dart';

class WorkoutScreen extends StatefulWidget {
  final String userTier; // 'guest', 'free', 'premium'
  const WorkoutScreen({super.key, required this.userTier});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  String _selectedDifficulty = 'Beginner';
  String _searchQuery = '';

  final List<String> _difficulties = ['Beginner', 'Intermediate', 'Advanced'];

  // Tier required per difficulty
  String _requiredTierForDifficulty(String difficulty) {
    switch (difficulty) {
      case 'Beginner':
        return 'guest';
      case 'Intermediate':
        return 'free';
      case 'Advanced':
        return 'premium';
      default:
        return 'guest';
    }
  }

  bool _isTierUnlocked(String required) {
    const order = {'guest': 0, 'free': 1, 'premium': 2};
    return (order[widget.userTier] ?? 0) >= (order[required] ?? 0);
  }

  // Full exercise library
  final List<Map<String, dynamic>> _allExercises = [
    // ── BEGINNER ──
    {
      'name': 'Bench Press',
      'muscle': 'Chest',
      'difficulty': 'Beginner',
      'emoji': '🏋️',
      'color': Color(0xFF2979FF),
      'sets': 4, 'reps': 10, 'rest': '60s',
      'desc': 'Classic chest builder targeting middle chest fibres.',
    },
    {
      'name': 'Pull Ups',
      'muscle': 'Back',
      'difficulty': 'Beginner',
      'emoji': '💪',
      'color': Color(0xFF00C853),
      'sets': 3, 'reps': 8, 'rest': '90s',
      'desc': 'Bodyweight king for lat width and upper-back thickness.',
    },
    {
      'name': 'Shoulder Press',
      'muscle': 'Shoulders',
      'difficulty': 'Beginner',
      'emoji': '⚡',
      'color': Color(0xFFFF6D00),
      'sets': 3, 'reps': 10, 'rest': '45s',
      'desc': 'Press overhead to build full shoulder caps.',
    },
    {
      'name': 'Squat',
      'muscle': 'Legs',
      'difficulty': 'Beginner',
      'emoji': '🦵',
      'color': Color(0xFFAA00FF),
      'sets': 4, 'reps': 12, 'rest': '90s',
      'desc': 'King of lower-body movements — quads, glutes, core.',
    },
    {
      'name': 'Plank',
      'muscle': 'Core',
      'difficulty': 'Beginner',
      'emoji': '🔥',
      'color': Color(0xFFFF1744),
      'sets': 3, 'reps': 1, 'rest': '30s',
      'desc': 'Isometric core hold — builds anti-rotation stability.',
    },
    {
      'name': 'Dumbbell Curl',
      'muscle': 'Arms',
      'difficulty': 'Beginner',
      'emoji': '💛',
      'color': Color(0xFFFFD600),
      'sets': 3, 'reps': 12, 'rest': '45s',
      'desc': 'Isolated bicep curl for arm peak and fullness.',
    },
    // ── INTERMEDIATE ──
    {
      'name': 'Incline Bench Press',
      'muscle': 'Chest',
      'difficulty': 'Intermediate',
      'emoji': '🏋️',
      'color': Color(0xFF2979FF),
      'sets': 4, 'reps': 10, 'rest': '60s',
      'desc': 'Upper chest focus at 30-45° incline for a full chest look.',
    },
    {
      'name': 'Barbell Row',
      'muscle': 'Back',
      'difficulty': 'Intermediate',
      'emoji': '💪',
      'color': Color(0xFF00C853),
      'sets': 4, 'reps': 10, 'rest': '90s',
      'desc': 'Heavy compound pull for back thickness and width.',
    },
    {
      'name': 'Romanian Deadlift',
      'muscle': 'Legs',
      'difficulty': 'Intermediate',
      'emoji': '🦵',
      'color': Color(0xFFAA00FF),
      'sets': 3, 'reps': 10, 'rest': '90s',
      'desc': 'Hip-hinge for hamstrings, glutes and spinal erectors.',
    },
    {
      'name': 'Lateral Raises',
      'muscle': 'Shoulders',
      'difficulty': 'Intermediate',
      'emoji': '⚡',
      'color': Color(0xFFFF6D00),
      'sets': 4, 'reps': 15, 'rest': '30s',
      'desc': 'Side deltoid isolation for wide, capped shoulders.',
    },
    {
      'name': 'Cable Crunch',
      'muscle': 'Core',
      'difficulty': 'Intermediate',
      'emoji': '🔥',
      'color': Color(0xFFFF1744),
      'sets': 3, 'reps': 15, 'rest': '45s',
      'desc': 'Weighted ab flexion — adds thickness to the rectus.',
    },
    {
      'name': 'Skull Crushers',
      'muscle': 'Arms',
      'difficulty': 'Intermediate',
      'emoji': '💛',
      'color': Color(0xFFFFD600),
      'sets': 3, 'reps': 12, 'rest': '60s',
      'desc': 'Tricep isolation that builds the long head for arm size.',
    },
    // ── ADVANCED ──
    {
      'name': 'Weighted Dips',
      'muscle': 'Chest',
      'difficulty': 'Advanced',
      'emoji': '🏋️',
      'color': Color(0xFF2979FF),
      'sets': 4, 'reps': 8, 'rest': '90s',
      'desc': 'Heavy compound dip — lower chest and tricep builder.',
    },
    {
      'name': 'Deadlift',
      'muscle': 'Back',
      'difficulty': 'Advanced',
      'emoji': '💪',
      'color': Color(0xFF00C853),
      'sets': 4, 'reps': 5, 'rest': '120s',
      'desc': 'Total-body strength lift — the ultimate back thickener.',
    },
    {
      'name': 'Front Squat',
      'muscle': 'Legs',
      'difficulty': 'Advanced',
      'emoji': '🦵',
      'color': Color(0xFFAA00FF),
      'sets': 4, 'reps': 6, 'rest': '120s',
      'desc': 'High quad demand, upright torso — advanced leg strength.',
    },
    {
      'name': 'Arnold Press',
      'muscle': 'Shoulders',
      'difficulty': 'Advanced',
      'emoji': '⚡',
      'color': Color(0xFFFF6D00),
      'sets': 4, 'reps': 10, 'rest': '60s',
      'desc': 'Rotating press that hits all three deltoid heads fully.',
    },
    {
      'name': 'Dragon Flag',
      'muscle': 'Core',
      'difficulty': 'Advanced',
      'emoji': '🔥',
      'color': Color(0xFFFF1744),
      'sets': 3, 'reps': 6, 'rest': '90s',
      'desc': 'Full-body lever movement — elite core and hip flexor strength.',
    },
    {
      'name': 'Weighted Pull Ups',
      'muscle': 'Arms',
      'difficulty': 'Advanced',
      'emoji': '💛',
      'color': Color(0xFFFFD600),
      'sets': 4, 'reps': 6, 'rest': '90s',
      'desc': 'Adds load to pull-ups for bicep and lat overload.',
    },
  ];

  List<Map<String, dynamic>> get _filteredExercises {
    return _allExercises.where((e) {
      final matchDiff = e['difficulty'] == _selectedDifficulty;
      final matchSearch = _searchQuery.isEmpty ||
          (e['name'] as String)
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          (e['muscle'] as String)
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
      return matchDiff && matchSearch;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeIn));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Color _getMuscleColor(String muscle) {
    switch (muscle.toLowerCase()) {
      case 'chest': return const Color(0xFF2979FF);
      case 'back': return const Color(0xFF00C853);
      case 'shoulders': return const Color(0xFFFF6D00);
      case 'legs': return const Color(0xFFAA00FF);
      case 'arms': return const Color(0xFFFFD600);
      case 'core': return const Color(0xFFFF1744);
      default: return AppColors.primary;
    }
  }

  void _onExerciseTap(Map<String, dynamic> exercise) {
    final required = _requiredTierForDifficulty(exercise['difficulty'] as String);
    if (!_isTierUnlocked(required)) {
      _showUpgradeDialog(required);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExerciseDetailScreen(
          exercise: exercise,
          userTier: widget.userTier,
        ),
      ),
    );
  }

  void _showUpgradeDialog(String requiredTier) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF141414) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('🔒 Locked'),
        content: Text(
          requiredTier == 'premium'
              ? 'Advanced exercises require a Premium account. Upgrade to unlock!'
              : 'Intermediate exercises require a free account. Sign up to unlock!',
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
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                  context, requiredTier == 'premium' ? '/premium' : '/register');
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

  Widget _buildDifficultyTabs({
    required Color textPrimary,
    required Color cardColor,
    required Color borderColor,
  }) {
    return Row(
      children: _difficulties.map((diff) {
        final isSelected = _selectedDifficulty == diff;
        final required = _requiredTierForDifficulty(diff);
        final isUnlocked = _isTierUnlocked(required);
        final diffColor = diff == 'Beginner'
            ? AppColors.primary
            : diff == 'Intermediate'
                ? const Color(0xFFFF6D00)
                : const Color(0xFFAA00FF);

        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedDifficulty = diff),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isSelected ? diffColor : cardColor,
                border: Border.all(
                  color: isSelected ? diffColor : borderColor,
                ),
              ),
              child: Column(
                children: [
                  if (!isUnlocked)
                    Icon(Icons.lock_rounded,
                        size: 14,
                        color: isSelected ? Colors.white : textPrimary.withOpacity(0.4)),
                  Text(
                    diff,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? Colors.white
                          : isUnlocked
                              ? textPrimary
                              : textPrimary.withOpacity(0.4),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    diff == 'Beginner'
                        ? 'Guest'
                        : diff == 'Intermediate'
                            ? 'Free'
                            : '⭐ Pro',
                    style: TextStyle(
                      fontSize: 9,
                      color: isSelected
                          ? Colors.white70
                          : diffColor.withOpacity(0.7),
                      fontWeight: FontWeight.w600,
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

  Widget _buildSearchBar({
    required Color cardColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 18, color: textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: TextStyle(fontSize: 14, color: textPrimary),
              decoration: InputDecoration(
                hintText: 'Search exercises or muscle…',
                hintStyle: TextStyle(fontSize: 13, color: textSecondary),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard({
    required Map<String, dynamic> exercise,
    required Color cardColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    bool wide = false,
  }) {
    final color = exercise['color'] as Color;
    final diff = exercise['difficulty'] as String;
    final required = _requiredTierForDifficulty(diff);
    final isUnlocked = _isTierUnlocked(required);

    return GestureDetector(
      onTap: () => _onExerciseTap(exercise),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
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
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(isUnlocked ? 0.12 : 0.06),
                border: Border.all(color: color.withOpacity(0.25)),
              ),
              child: Center(
                child: isUnlocked
                    ? Text(exercise['emoji'] as String,
                        style: const TextStyle(fontSize: 22))
                    : Icon(Icons.lock_rounded,
                        size: 20, color: textSecondary),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        exercise['name'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isUnlocked ? textPrimary : textSecondary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _buildMiniTierBadge(required),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    exercise['desc'] as String,
                    style: TextStyle(fontSize: 11, color: textSecondary),
                    maxLines: wide ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildMiniChip(
                          exercise['muscle'] as String,
                          _getMuscleColor(exercise['muscle'] as String)),
                      const SizedBox(width: 6),
                      _buildMiniChip(
                          '${exercise['sets']}×${exercise['reps']}', color),
                      const SizedBox(width: 6),
                      _buildMiniChip('Rest ${exercise['rest']}',
                          textSecondary.withOpacity(0.7)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isUnlocked
                  ? Icons.arrow_forward_ios_rounded
                  : Icons.lock_outline_rounded,
              size: 14,
              color: isUnlocked ? color : textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: color.withOpacity(0.12),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 9, color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildMiniTierBadge(String tier) {
    final colors = {
      'guest': Colors.grey,
      'free': AppColors.primary,
      'premium': const Color(0xFFFFD600),
    };
    final labels = {'guest': 'FREE', 'free': 'MEMBER', 'premium': '⭐ PRO'};
    final color = colors[tier] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: color.withOpacity(0.12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(labels[tier] ?? 'FREE',
          style: TextStyle(
              fontSize: 8, color: color, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildLockedBanner({
    required String difficulty,
    required Color textPrimary,
    required Color textSecondary,
    required bool isDark,
  }) {
    final required = _requiredTierForDifficulty(difficulty);
    final isPremium = required == 'premium';
    final color = isPremium ? const Color(0xFFAA00FF) : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: color.withOpacity(isDark ? 0.08 : 0.05),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_rounded, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPremium
                      ? '⭐ Advanced requires Premium'
                      : '🔓 Intermediate requires Free Account',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textPrimary),
                ),
                Text(
                  isPremium
                      ? 'Upgrade to unlock all advanced exercises'
                      : 'Sign up for free to unlock intermediate exercises',
                  style: TextStyle(fontSize: 11, color: textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.pushNamed(
                context, isPremium ? '/premium' : '/register'),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: color,
              ),
              child: Text(
                isPremium ? 'Upgrade' : 'Join Free',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // MOBILE LAYOUT
  // ─────────────────────────────────────────
  Widget _buildMobileLayout(bool isDark) {
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final textSecondary =
        isDark ? const Color(0xFFB0B0B0) : const Color(0xFF555555);
    final bgColor =
        isDark ? const Color(0xFF050A05) : const Color(0xFFF5F5F5);
    final cardColor = isDark ? const Color(0xFF141414) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);

    final isCurrentLocked =
        !_isTierUnlocked(_requiredTierForDifficulty(_selectedDifficulty));

    return Scaffold(
      backgroundColor: bgColor,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Exercises 💪',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: textPrimary)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: AppColors.primary.withOpacity(0.1),
                          ),
                          child: Text(
                            '${_filteredExercises.length} exercises',
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildSearchBar(
                        cardColor: cardColor,
                        borderColor: borderColor,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary),
                    const SizedBox(height: 12),
                    _buildDifficultyTabs(
                        textPrimary: textPrimary,
                        cardColor: cardColor,
                        borderColor: borderColor),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              // List
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    if (isCurrentLocked)
                      _buildLockedBanner(
                          difficulty: _selectedDifficulty,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          isDark: isDark),
                    ..._filteredExercises.map((e) => _buildExerciseCard(
                          exercise: e,
                          cardColor: cardColor,
                          borderColor: borderColor,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        )),
                    if (_filteredExercises.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: Text('No exercises found',
                              style: TextStyle(
                                  fontSize: 14, color: textSecondary)),
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

  // ─────────────────────────────────────────
  // WEB LAYOUT
  // ─────────────────────────────────────────
  Widget _buildWebLayout(bool isDark) {
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final textSecondary =
        isDark ? const Color(0xFFB0B0B0) : const Color(0xFF555555);
    final bgColor =
        isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF0F2F5);
    final cardColor = isDark ? const Color(0xFF141414) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);

    final isCurrentLocked =
        !_isTierUnlocked(_requiredTierForDifficulty(_selectedDifficulty));

    return FadeTransition(
      opacity: _fadeAnim,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Exercise Library 💪',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: textPrimary)),
                        const SizedBox(height: 4),
                        Text('Browse by difficulty — tap any to start',
                            style: TextStyle(
                                fontSize: 13, color: textSecondary)),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: AppColors.primary.withOpacity(0.1),
                      ),
                      child: Text(
                        '${_filteredExercises.length} exercises',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Search + tabs row
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildSearchBar(
                          cardColor: cardColor,
                          borderColor: borderColor,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 4,
                      child: _buildDifficultyTabs(
                          textPrimary: textPrimary,
                          cardColor: cardColor,
                          borderColor: borderColor),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (isCurrentLocked)
                  _buildLockedBanner(
                      difficulty: _selectedDifficulty,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      isDark: isDark),
                // Grid of exercises
                if (_filteredExercises.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Text('No exercises found',
                          style:
                              TextStyle(fontSize: 14, color: textSecondary)),
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 520,
                      mainAxisExtent: 110,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _filteredExercises.length,
                    itemBuilder: (_, i) => _buildExerciseCard(
                      exercise: _filteredExercises[i],
                      cardColor: cardColor,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      wide: true,
                    ),
                  ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}