import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

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

  // Static data matching our Supabase schema
  final Map<String, List<Map<String, dynamic>>> _variationsData = {
    'Bench Press': [
      {
        'name': 'Flat Bench Press',
        'description': 'Classic chest builder — targets the middle chest',
        'steps': ['Lie flat on bench', 'Grip bar shoulder width apart', 'Lower bar to chest slowly', 'Press up explosively'],
        'sets': 4, 'reps': 10, 'rest': '60s',
        'tier': 'guest', 'emoji': '🏋️',
        'color': const Color(0xFF2979FF),
        'tip': 'Keep your feet flat on the floor and arch your back slightly',
      },
      {
        'name': 'Incline Bench Press',
        'description': 'Upper chest focus — great for a full chest look',
        'steps': ['Set bench to 30-45 degrees', 'Grip bar shoulder width', 'Lower to upper chest', 'Press up and squeeze'],
        'sets': 4, 'reps': 10, 'rest': '60s',
        'tier': 'free', 'emoji': '💪',
        'color': const Color(0xFF00C853),
        'tip': 'Don\'t go too steep — 30-45 degrees is optimal',
      },
      {
        'name': 'Decline Bench Press',
        'description': 'Lower chest focus — completes the chest shape',
        'steps': ['Set bench declined 15-30 degrees', 'Grip bar wide', 'Lower to lower chest', 'Press up powerfully'],
        'sets': 3, 'reps': 12, 'rest': '60s',
        'tier': 'free', 'emoji': '⚡',
        'color': const Color(0xFFFF6D00),
        'tip': 'Make sure your feet are secured before lifting',
      },
      {
        'name': 'Dumbbell Bench Press',
        'description': 'Full range of motion — maximizes muscle stretch',
        'steps': ['Hold dumbbells at chest level', 'Lie flat on bench', 'Lower with control past chest level', 'Press up and squeeze at top'],
        'sets': 4, 'reps': 12, 'rest': '60s',
        'tier': 'premium', 'emoji': '🔥',
        'color': const Color(0xFFAA00FF),
        'tip': 'Go deeper than barbell for maximum chest stretch',
      },
    ],
    'Pull Ups': [
      {
        'name': 'Wide Grip Pull Up',
        'description': 'Targets lat width — builds that V-taper',
        'steps': ['Grip bar wider than shoulders', 'Hang with arms fully extended', 'Pull chest to bar', 'Lower slowly and repeat'],
        'sets': 3, 'reps': 8, 'rest': '90s',
        'tier': 'free', 'emoji': '💪',
        'color': const Color(0xFF00C853),
        'tip': 'Focus on pulling elbows down, not just pulling up',
      },
      {
        'name': 'Narrow Grip Pull Up',
        'description': 'Targets biceps more — great arm builder',
        'steps': ['Grip bar narrower than shoulders', 'Hang fully extended', 'Pull up explosively', 'Lower with control'],
        'sets': 3, 'reps': 10, 'rest': '90s',
        'tier': 'free', 'emoji': '🏋️',
        'color': const Color(0xFF2979FF),
        'tip': 'Supinate your grip for maximum bicep activation',
      },
    ],
    'Shoulder Press': [
      {
        'name': 'Standing Shoulder Press',
        'description': 'Core stability + shoulders — full body tension',
        'steps': ['Stand with dumbbells at shoulder height', 'Press overhead until arms extended', 'Lower to shoulder level', 'Repeat with control'],
        'sets': 3, 'reps': 10, 'rest': '45s',
        'tier': 'guest', 'emoji': '⚡',
        'color': const Color(0xFFFF6D00),
        'tip': 'Brace your core — don\'t lean back excessively',
      },
      {
        'name': 'Seated Shoulder Press',
        'description': 'Strict form — isolates shoulders perfectly',
        'steps': ['Sit on bench with back support', 'Hold dumbbells at shoulder height', 'Press straight overhead', 'Lower slowly to start'],
        'sets': 4, 'reps': 10, 'rest': '45s',
        'tier': 'free', 'emoji': '💪',
        'color': const Color(0xFF2979FF),
        'tip': 'Keep your back pressed against the pad throughout',
      },
    ],
  };

  List<Map<String, dynamic>> get variations {
    final name = widget.exercise['name'] as String;
    return _variationsData[name] ?? [];
  }

  bool _isTierUnlocked(String tier) {
    const tierOrder = {'guest': 0, 'free': 1, 'premium': 2};
    return (tierOrder[widget.userTier] ?? 0) >= (tierOrder[tier] ?? 0);
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final textSecondary = isDark ? const Color(0xFFB0B0B0) : const Color(0xFF555555);
    final bgColor = isDark ? const Color(0xFF050A05) : const Color(0xFFF5F5F5);
    final cardColor = isDark ? const Color(0xFF141414) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);

    final exercise = widget.exercise;
    final muscleColor = _getMuscleColor(exercise['muscle'] as String? ?? '');

    return Scaffold(
      backgroundColor: bgColor,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: bgColor,
              leading: GestureDetector(
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
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        muscleColor.withOpacity(isDark ? 0.3 : 0.15),
                        muscleColor.withOpacity(isDark ? 0.1 : 0.05),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: muscleColor.withOpacity(0.15),
                                  border: Border.all(
                                      color: muscleColor.withOpacity(0.4),
                                      width: 2),
                                ),
                                child: Center(
                                  child: Text(
                                    exercise['emoji'] as String? ?? '💪',
                                    style: const TextStyle(fontSize: 28),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      exercise['name'] as String? ?? '',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        _buildBadge(
                                            exercise['muscle'] as String? ?? '',
                                            muscleColor),
                                        const SizedBox(width: 8),
                                        _buildBadge(
                                            exercise['difficulty'] as String? ?? 'beginner',
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
                ),
              ),
            ),

            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Variations label
                    Text(
                      'Exercise Variations',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${variations.length} variations available',
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                    const SizedBox(height: 16),

                    // Variation selector tabs
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: variations.length,
                        itemBuilder: (context, index) {
                          final v = variations[index];
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: isSelected
                                    ? color
                                    : color.withOpacity(0.1),
                                border: Border.all(
                                  color: isSelected
                                      ? color
                                      : color.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  if (!isUnlocked)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 4),
                                      child: Icon(Icons.lock_rounded,
                                          size: 12, color: Colors.white),
                                    ),
                                  Text(
                                    v['name'] as String,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : isUnlocked
                                              ? color
                                              : textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Selected variation detail
                    if (variations.isNotEmpty) ...[
                      _buildVariationDetail(
                        variations[_selectedVariation],
                        cardColor,
                        borderColor,
                        textPrimary,
                        textSecondary,
                        isDark,
                      ),
                    ],

                    const SizedBox(height: 20),

                    // All variations list
                    Text(
                      'All Variations',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...variations.asMap().entries.map((entry) {
                      final index = entry.key;
                      final v = entry.value;
                      final isUnlocked = _isTierUnlocked(v['tier'] as String);
                      final color = v['color'] as Color;
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
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: isSelected
                                ? color.withOpacity(0.08)
                                : cardColor,
                            border: Border.all(
                              color: isSelected
                                  ? color.withOpacity(0.4)
                                  : borderColor,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: color.withOpacity(0.12),
                                ),
                                child: Center(
                                  child: isUnlocked
                                      ? Text(v['emoji'] as String,
                                          style:
                                              const TextStyle(fontSize: 18))
                                      : Icon(Icons.lock_rounded,
                                          size: 18,
                                          color: textSecondary),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      v['name'] as String,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: isUnlocked
                                            ? textPrimary
                                            : textSecondary,
                                      ),
                                    ),
                                    Text(
                                      v['description'] as String,
                                      style: TextStyle(
                                          fontSize: 11, color: textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _buildTierBadge(v['tier'] as String),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${v['sets']}×${v['reps']}',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: color,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVariationDetail(
    Map<String, dynamic> variation,
    Color cardColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
    bool isDark,
  ) {
    final color = variation['color'] as Color;
    final steps = variation['steps'] as List<String>;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: cardColor,
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                variation['emoji'] as String,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      variation['name'] as String,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      variation['description'] as String,
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Stats row
          Row(
            children: [
              _buildStatChip('Sets', '${variation['sets']}', color),
              const SizedBox(width: 10),
              _buildStatChip('Reps', '${variation['reps']}', color),
              const SizedBox(width: 10),
              _buildStatChip('Rest', variation['rest'] as String, color),
            ],
          ),

          const SizedBox(height: 16),

          // Steps
          Text(
            'How to do it:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          ...steps.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withOpacity(0.15),
                      border: Border.all(color: color.withOpacity(0.4)),
                    ),
                    child: Center(
                      child: Text(
                        '${entry.key + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: TextStyle(fontSize: 13, color: textSecondary),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),

          const SizedBox(height: 12),

          // Pro tip
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: AppColors.primary.withOpacity(0.08),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💡', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pro Tip',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        variation['tip'] as String,
                        style: TextStyle(fontSize: 12, color: textSecondary),
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

  Widget _buildStatChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: color.withOpacity(0.08),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withOpacity(0.15),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
            fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildTierBadge(String tier) {
    final colors = {
      'guest': Colors.grey,
      'free': AppColors.primary,
      'premium': const Color(0xFFFFD600),
    };
    final labels = {
      'guest': 'FREE',
      'free': 'MEMBER',
      'premium': '⭐ PRO',
    };
    final color = colors[tier] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: color.withOpacity(0.15),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        labels[tier] ?? 'FREE',
        style: TextStyle(
            fontSize: 9, color: color, fontWeight: FontWeight.w700),
      ),
    );
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

  void _showUpgradeDialog(String requiredTier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF141414)
                : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                  context,
                  requiredTier == 'premium' ? '/premium' : '/register');
            },
            child: Text(
                requiredTier == 'premium' ? 'Upgrade' : 'Sign Up Free'),
          ),
        ],
      ),
    );
  }
}