import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../core/theme/app_colors.dart';
import '../../services/supabase_service.dart';
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
  String _selectedMuscle = 'All';
  bool _isLoadingFromDB = false;
  List<Map<String, dynamic>> _dbExercises = [];

  final List<String> _difficulties = ['Beginner', 'Intermediate', 'Advanced'];
  final List<String> _muscleFilters = [
    'All', 'Chest', 'Back', 'Shoulders', 'Legs', 'Arms', 'Core'
  ];

  // ── Real exercise images from Unsplash (stable, no-expiry URLs) ──────────────
  static const Map<String, String> _exerciseImages = {
    // Chest
    'Bench Press':
        'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=600&q=80',
    'Incline Bench':
        'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=600&q=80',
    'Weighted Dips':
        'https://images.unsplash.com/photo-1581009137042-c552e485697a?w=600&q=80',
    // Back
    'Pull Ups':
        'https://images.unsplash.com/photo-1598971639058-fab3c3109a00?w=600&q=80',
    'Barbell Row':
        'https://images.unsplash.com/photo-1567598508481-65985588e295?w=600&q=80',
    'Deadlift':
        'https://images.unsplash.com/photo-1534368959876-26bf04f2c947?w=600&q=80',
    // Shoulders
    'Shoulder Press':
        'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?w=600&q=80',
    'Lateral Raises':
        'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=600&q=80',
    'Arnold Press':
        'https://images.unsplash.com/photo-1532029837206-abbe2b7620e3?w=600&q=80',
    // Legs
    'Squat':
        'https://images.unsplash.com/photo-1574680096145-d05b474e2155?w=600&q=80',
    'Romanian Deadlift':
        'https://images.unsplash.com/photo-1601422407692-ec4eeec1d9b3?w=600&q=80',
    'Front Squat':
        'https://images.unsplash.com/photo-1566241142559-40e1dab266c6?w=600&q=80',
    // Arms
    'Dumbbell Curl':
        'https://images.unsplash.com/photo-1581009137042-c552e485697a?w=600&q=80',
    'Skull Crushers':
        'https://images.unsplash.com/photo-1530822847156-5df684ec5933?w=600&q=80',
    'Weighted Pull Ups':
        'https://images.unsplash.com/photo-1598971639058-fab3c3109a00?w=600&q=80',
    // Core
    'Plank':
        'https://images.unsplash.com/photo-1566241142559-40e1dab266c6?w=600&q=80',
    'Cable Crunch':
        'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=600&q=80',
    'Dragon Flag':
        'https://images.unsplash.com/photo-1549060279-7e168fcee0c2?w=600&q=80',
  };

  // Generic fallback images by muscle group
  static const Map<String, String> _muscleImages = {
    'Chest':
        'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=600&q=80',
    'Back':
        'https://images.unsplash.com/photo-1598971639058-fab3c3109a00?w=600&q=80',
    'Shoulders':
        'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?w=600&q=80',
    'Legs':
        'https://images.unsplash.com/photo-1574680096145-d05b474e2155?w=600&q=80',
    'Arms':
        'https://images.unsplash.com/photo-1581009137042-c552e485697a?w=600&q=80',
    'Core':
        'https://images.unsplash.com/photo-1549060279-7e168fcee0c2?w=600&q=80',
  };

  String _getExerciseImage(String name, String muscle) {
    return _exerciseImages[name] ?? _muscleImages[muscle] ??
        'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=600&q=80';
  }

  // ── Tier gate ─────────────────────────────────────────────────────────────────
  String _requiredTierForDifficulty(String difficulty) {
    switch (difficulty) {
      case 'Beginner':     return 'guest';
      case 'Intermediate': return 'free';
      case 'Advanced':     return 'premium';
      default:             return 'guest';
    }
  }

  bool _isTierUnlocked(String required) {
    const order = {'guest': 0, 'free': 1, 'premium': 2};
    return (order[widget.userTier] ?? 0) >= (order[required] ?? 0);
  }

  // ── Local exercise library ────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _localExercises = [
    // BEGINNER
    {'name': 'Bench Press',    'muscle': 'Chest',     'difficulty': 'Beginner',     'emoji': '🏋️', 'color': Color(0xFF2979FF), 'sets': 4, 'reps': 10, 'rest': '60s', 'desc': 'Classic chest builder targeting middle chest fibres.', 'gradient': [Color(0xFF1565C0), Color(0xFF2979FF)]},
    {'name': 'Pull Ups',       'muscle': 'Back',      'difficulty': 'Beginner',     'emoji': '💪', 'color': Color(0xFF00C853), 'sets': 3, 'reps': 8,  'rest': '90s', 'desc': 'Bodyweight king for lat width and upper-back thickness.', 'gradient': [Color(0xFF00695C), Color(0xFF00C853)]},
    {'name': 'Shoulder Press', 'muscle': 'Shoulders', 'difficulty': 'Beginner',     'emoji': '⚡', 'color': Color(0xFFFF6D00), 'sets': 3, 'reps': 10, 'rest': '45s', 'desc': 'Press overhead to build full shoulder caps.', 'gradient': [Color(0xFFBF360C), Color(0xFFFF6D00)]},
    {'name': 'Squat',          'muscle': 'Legs',      'difficulty': 'Beginner',     'emoji': '🦵', 'color': Color(0xFFAA00FF), 'sets': 4, 'reps': 12, 'rest': '90s', 'desc': 'King of lower-body movements — quads, glutes, core.', 'gradient': [Color(0xFF4A148C), Color(0xFFAA00FF)]},
    {'name': 'Plank',          'muscle': 'Core',      'difficulty': 'Beginner',     'emoji': '🔥', 'color': Color(0xFFFF1744), 'sets': 3, 'reps': 1,  'rest': '30s', 'desc': 'Isometric core hold — builds anti-rotation stability.', 'gradient': [Color(0xFFB71C1C), Color(0xFFFF1744)]},
    {'name': 'Dumbbell Curl',  'muscle': 'Arms',      'difficulty': 'Beginner',     'emoji': '💛', 'color': Color(0xFFFFD600), 'sets': 3, 'reps': 12, 'rest': '45s', 'desc': 'Isolated bicep curl for arm peak and fullness.', 'gradient': [Color(0xFFF57F17), Color(0xFFFFD600)]},
    // INTERMEDIATE
    {'name': 'Incline Bench',      'muscle': 'Chest',     'difficulty': 'Intermediate', 'emoji': '🏋️', 'color': Color(0xFF2979FF), 'sets': 4, 'reps': 10, 'rest': '60s', 'desc': 'Upper chest focus at 30-45° incline for a full chest look.', 'gradient': [Color(0xFF1565C0), Color(0xFF2979FF)]},
    {'name': 'Barbell Row',        'muscle': 'Back',      'difficulty': 'Intermediate', 'emoji': '💪', 'color': Color(0xFF00C853), 'sets': 4, 'reps': 10, 'rest': '90s', 'desc': 'Heavy compound pull for back thickness and width.', 'gradient': [Color(0xFF00695C), Color(0xFF00C853)]},
    {'name': 'Romanian Deadlift',  'muscle': 'Legs',      'difficulty': 'Intermediate', 'emoji': '🦵', 'color': Color(0xFFAA00FF), 'sets': 3, 'reps': 10, 'rest': '90s', 'desc': 'Hip-hinge for hamstrings, glutes and spinal erectors.', 'gradient': [Color(0xFF4A148C), Color(0xFFAA00FF)]},
    {'name': 'Lateral Raises',     'muscle': 'Shoulders', 'difficulty': 'Intermediate', 'emoji': '⚡', 'color': Color(0xFFFF6D00), 'sets': 4, 'reps': 15, 'rest': '30s', 'desc': 'Side deltoid isolation for wide, capped shoulders.', 'gradient': [Color(0xFFBF360C), Color(0xFFFF6D00)]},
    {'name': 'Cable Crunch',       'muscle': 'Core',      'difficulty': 'Intermediate', 'emoji': '🔥', 'color': Color(0xFFFF1744), 'sets': 3, 'reps': 15, 'rest': '45s', 'desc': 'Weighted ab flexion — adds thickness to the rectus.', 'gradient': [Color(0xFFB71C1C), Color(0xFFFF1744)]},
    {'name': 'Skull Crushers',     'muscle': 'Arms',      'difficulty': 'Intermediate', 'emoji': '💛', 'color': Color(0xFFFFD600), 'sets': 3, 'reps': 12, 'rest': '60s', 'desc': 'Tricep isolation that builds the long head for arm size.', 'gradient': [Color(0xFFF57F17), Color(0xFFFFD600)]},
    // ADVANCED
    {'name': 'Weighted Dips',   'muscle': 'Chest',     'difficulty': 'Advanced', 'emoji': '🏋️', 'color': Color(0xFF2979FF), 'sets': 4, 'reps': 8, 'rest': '90s',  'desc': 'Heavy compound dip — lower chest and tricep builder.', 'gradient': [Color(0xFF1565C0), Color(0xFF2979FF)]},
    {'name': 'Deadlift',        'muscle': 'Back',      'difficulty': 'Advanced', 'emoji': '💪', 'color': Color(0xFF00C853), 'sets': 4, 'reps': 5, 'rest': '120s', 'desc': 'Total-body strength lift — the ultimate back thickener.', 'gradient': [Color(0xFF00695C), Color(0xFF00C853)]},
    {'name': 'Front Squat',     'muscle': 'Legs',      'difficulty': 'Advanced', 'emoji': '🦵', 'color': Color(0xFFAA00FF), 'sets': 4, 'reps': 6, 'rest': '120s', 'desc': 'High quad demand, upright torso — advanced leg strength.', 'gradient': [Color(0xFF4A148C), Color(0xFFAA00FF)]},
    {'name': 'Arnold Press',    'muscle': 'Shoulders', 'difficulty': 'Advanced', 'emoji': '⚡', 'color': Color(0xFFFF6D00), 'sets': 4, 'reps': 10, 'rest': '60s', 'desc': 'Rotating press that hits all three deltoid heads fully.', 'gradient': [Color(0xFFBF360C), Color(0xFFFF6D00)]},
    {'name': 'Dragon Flag',     'muscle': 'Core',      'difficulty': 'Advanced', 'emoji': '🔥', 'color': Color(0xFFFF1744), 'sets': 3, 'reps': 6,  'rest': '90s', 'desc': 'Full-body lever — elite core and hip flexor strength.', 'gradient': [Color(0xFFB71C1C), Color(0xFFFF1744)]},
    {'name': 'Weighted Pull Ups','muscle': 'Arms',     'difficulty': 'Advanced', 'emoji': '💛', 'color': Color(0xFFFFD600), 'sets': 4, 'reps': 6,  'rest': '90s', 'desc': 'Adds load to pull-ups for bicep and lat overload.', 'gradient': [Color(0xFFF57F17), Color(0xFFFFD600)]},
  ];

  List<Map<String, dynamic>> get _allExercises {
    if (_dbExercises.isEmpty) return _localExercises;
    return _dbExercises.map((dbEx) {
      final name = dbEx['name'] as String? ?? '';
      final muscle = (dbEx['muscle'] as String? ?? '');
      final local = _localExercises.firstWhere(
        (l) => (l['name'] as String).toLowerCase() == name.toLowerCase(),
        orElse: () => {},
      );
      if (local.isEmpty) {
        final color = _muscleColor(muscle);
        return {
          ...dbEx,
          'emoji': _muscleEmoji(muscle),
          'color': color,
          'gradient': [color.withOpacity(0.7), color],
          'difficulty': _mapDifficulty(dbEx['difficulty'] as String? ?? 'beginner'),
          'sets': dbEx['sets'] ?? 3,
          'reps': dbEx['reps'] ?? 10,
          'rest': '60s',
          'desc': dbEx['description'] ?? 'Great exercise for building strength.',
        };
      }
      return {
        ...local,
        'id': dbEx['id'],
        'sets': dbEx['sets'] ?? local['sets'],
        'reps': dbEx['reps'] ?? local['reps'],
        'desc': local['desc'],
      };
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredExercises {
    return _allExercises.where((e) {
      final matchDiff = (e['difficulty'] as String?) == _selectedDifficulty;
      final matchSearch = _searchQuery.isEmpty ||
          (e['name'] as String).toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (e['muscle'] as String).toLowerCase().contains(_searchQuery.toLowerCase());
      return matchDiff && matchSearch;
    }).toList();
  }

  List<Map<String, dynamic>> get _displayExercises {
    if (_selectedMuscle == 'All') return _filteredExercises;
    return _filteredExercises.where((e) => e['muscle'] == _selectedMuscle).toList();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────
  String _mapDifficulty(String raw) {
    final lower = raw.toLowerCase();
    if (lower == 'intermediate') return 'Intermediate';
    if (lower == 'advanced') return 'Advanced';
    return 'Beginner';
  }

  String _muscleEmoji(String muscle) {
    const map = {'Chest': '🏋️', 'Back': '💪', 'Shoulders': '⚡', 'Legs': '🦵', 'Arms': '💛', 'Core': '🔥'};
    return map[muscle] ?? '💪';
  }

  Color _muscleColor(String muscle) {
    const map = {
      'Chest': Color(0xFF2979FF), 'Back': Color(0xFF00C853),
      'Shoulders': Color(0xFFFF6D00), 'Legs': Color(0xFFAA00FF),
      'Arms': Color(0xFFFFD600), 'Core': Color(0xFFFF1744),
    };
    return map[muscle] ?? AppColors.primary;
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
    _loadFromDB();
  }

  Future<void> _loadFromDB() async {
    setState(() => _isLoadingFromDB = true);
    try {
      final exercises = await SupabaseService.getExercises();
      if (mounted && exercises.isNotEmpty) {
        setState(() => _dbExercises = exercises);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingFromDB = false);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onExerciseTap(Map<String, dynamic> exercise) {
    final required = _requiredTierForDifficulty(exercise['difficulty'] as String);
    if (!_isTierUnlocked(required)) {
      _showUpgradeSheet(required);
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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.15), color.withOpacity(0.35)],
                ),
                border: Border.all(color: color.withOpacity(0.4), width: 2),
              ),
              child: Center(child: Icon(Icons.lock_rounded, color: color, size: 30)),
            ),
            const SizedBox(height: 18),
            Text(
              isPremium ? '⭐ Premium Required' : '🔓 Free Account Required',
              style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isPremium
                  ? 'Advanced exercises are exclusive to Premium members. Upgrade to unlock elite workouts and track unlimited progress.'
                  : 'Create a free account to unlock intermediate exercises and start tracking your fitness journey.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? const Color(0xFFB0B0B0) : const Color(0xFF666666),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, isPremium ? '/premium' : '/register');
              },
              child: Container(
                width: double.infinity, height: 56,
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
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    isPremium ? '⭐ Upgrade to Premium' : '✨ Create Free Account',
                    style: TextStyle(
                      color: isPremium ? Colors.white : Colors.black,
                      fontSize: 16, fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Maybe Later',
                style: TextStyle(color: textSecondaryColor(isDark), fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }

  Color textSecondaryColor(bool isDark) =>
      isDark ? const Color(0xFFB0B0B0) : const Color(0xFF888888);

  // ════════════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (kIsWeb) return _buildWebLayout(isDark);
    return _buildMobileLayout(isDark);
  }

  // ── Difficulty tabs ───────────────────────────────────────────────────────────
  Widget _buildDifficultyTabs({required bool isDark, required Color textPrimary}) {
    return Row(
      children: _difficulties.map((diff) {
        final isSelected = _selectedDifficulty == diff;
        final required = _requiredTierForDifficulty(diff);
        final isUnlocked = _isTierUnlocked(required);
        final configs = {
          'Beginner':     {'colors': [const Color(0xFF00C853), const Color(0xFF69F0AE)], 'label': 'Free'},
          'Intermediate': {'colors': [const Color(0xFFFF6D00), const Color(0xFFFFB74D)], 'label': 'Member'},
          'Advanced':     {'colors': [const Color(0xFFAA00FF), const Color(0xFFCE93D8)], 'label': '⭐ Pro'},
        };
        final cfg = configs[diff]!;
        final colors = cfg['colors'] as List<Color>;
        final sublabel = cfg['label'] as String;

        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedDifficulty = diff),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: isSelected
                    ? LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight)
                    : null,
                color: isSelected ? null : (isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF0F0F0)),
                border: Border.all(
                  color: isSelected ? Colors.transparent : colors[0].withOpacity(0.25),
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: colors[0].withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))]
                    : [],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isUnlocked)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Icon(Icons.lock_rounded, size: 10,
                          color: isSelected ? Colors.white60 : colors[0].withOpacity(0.5)),
                    ),
                  Text(diff,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : (isUnlocked ? textPrimary : textPrimary.withOpacity(0.4)),
                      )),
                  const SizedBox(height: 1),
                  Text(sublabel,
                      style: TextStyle(
                        fontSize: 9, fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white70 : colors[0].withOpacity(0.6),
                      )),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Search bar ────────────────────────────────────────────────────────────────
  Widget _buildSearchBar({required bool isDark, required Color textPrimary}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5E5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 8, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 18, color: textPrimary.withOpacity(0.4)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: TextStyle(fontSize: 14, color: textPrimary),
              decoration: InputDecoration(
                hintText: 'Search exercises or muscle group…',
                hintStyle: TextStyle(fontSize: 13, color: textPrimary.withOpacity(0.35)),
                border: InputBorder.none, isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () => setState(() => _searchQuery = ''),
              child: Icon(Icons.close_rounded, size: 16, color: textPrimary.withOpacity(0.4)),
            ),
        ],
      ),
    );
  }

  // ── Muscle filter pills ───────────────────────────────────────────────────────
  Widget _buildMuscleFilter({required bool isDark, required Color textPrimary}) {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _muscleFilters.map((m) {
          final isSelected = _selectedMuscle == m;
          final color = m == 'All' ? AppColors.primary : _muscleColor(m);
          return GestureDetector(
            onTap: () => setState(() => _selectedMuscle = m),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: isSelected ? color : (isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF0F0F0)),
                border: Border.all(color: isSelected ? Colors.transparent : color.withOpacity(0.25)),
              ),
              child: Text(m,
                  style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : textPrimary.withOpacity(0.65),
                  )),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // HERO EXERCISE CARD — photo background with gradient overlay
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildHeroExerciseCard({
    required Map<String, dynamic> exercise,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    int index = 0,
  }) {
    final color = exercise['color'] as Color? ?? AppColors.primary;
    final gradientColors = exercise['gradient'] as List<Color>? ??
        [color.withOpacity(0.8), color];
    final diff = exercise['difficulty'] as String? ?? 'Beginner';
    final required = _requiredTierForDifficulty(diff);
    final isUnlocked = _isTierUnlocked(required);
    final name = exercise['name'] as String? ?? '';
    final muscle = exercise['muscle'] as String? ?? '';
    final imageUrl = _getExerciseImage(name, muscle);

    return GestureDetector(
      onTap: () => _onExerciseTap(exercise),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 145,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(isDark ? 0.35 : 0.2),
              blurRadius: 24, offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Real photo background ────────────────────────────────────────
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),

              // ── Dark gradient overlay (left-heavy for readability) ────────────
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withOpacity(0.85),
                      Colors.black.withOpacity(0.55),
                      Colors.black.withOpacity(0.15),
                    ],
                  ),
                ),
              ),

              // ── Color accent strip on left ────────────────────────────────────
              Positioned(
                left: 0, top: 0, bottom: 0,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

              // ── Subtle circle accents ─────────────────────────────────────────
              Positioned(
                right: -10, top: -20,
                child: Container(
                  width: 110, height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.12),
                  ),
                ),
              ),

              // ── Content ──────────────────────────────────────────────────────
              Positioned(
                left: 18, top: 16, right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Muscle badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: color.withOpacity(0.3),
                        border: Border.all(color: color.withOpacity(0.5)),
                      ),
                      child: Text(muscle,
                          style: TextStyle(
                            fontSize: 9, color: Colors.white,
                            fontWeight: FontWeight.w800, letterSpacing: 0.5,
                          )),
                    ),
                    const SizedBox(height: 7),
                    // Name
                    Text(name,
                        style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w900,
                          color: Colors.white, letterSpacing: -0.3, height: 1.1,
                        ),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    // Description
                    Text(exercise['desc'] as String? ?? '',
                        style: TextStyle(
                          fontSize: 11.5, color: Colors.white.withOpacity(0.75), height: 1.35,
                        ),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),

              // ── Stats row at bottom ───────────────────────────────────────────
              Positioned(
                left: 18, right: 16, bottom: 14,
                child: Row(
                  children: [
                    _buildStatPill('${exercise['sets']} sets', color),
                    const SizedBox(width: 6),
                    _buildStatPill('${exercise['reps']} reps', color),
                    const SizedBox(width: 6),
                    _buildStatPill('Rest ${exercise['rest']}', color),
                    const Spacer(),
                    Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withOpacity(0.3),
                        border: Border.all(color: color.withOpacity(0.6)),
                      ),
                      child: const Center(
                        child: Icon(Icons.arrow_forward_rounded, size: 15, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Blur overlay for locked ────────────────────────────────────────
              if (!isUnlocked)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                      child: Container(
                        color: Colors.black.withOpacity(0.5),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 52, height: 52,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: color.withOpacity(0.2),
                                  border: Border.all(color: color.withOpacity(0.5), width: 2),
                                ),
                                child: const Center(
                                  child: Icon(Icons.lock_rounded, color: Colors.white, size: 24),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                required == 'premium' ? '⭐ Premium Only' : 'Free Account Required',
                                style: const TextStyle(
                                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text('Tap to unlock',
                                  style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.15),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600)),
    );
  }

  // ── Tier unlock banner ────────────────────────────────────────────────────────
  Widget _buildTierUnlockBanner({required String difficulty, required bool isDark}) {
    final required = _requiredTierForDifficulty(difficulty);
    final isPremium = required == 'premium';
    final color = isPremium ? const Color(0xFFAA00FF) : AppColors.primary;
    final gradColors = isPremium
        ? [const Color(0xFF4A148C), const Color(0xFFAA00FF)]
        : [const Color(0xFF00695C), const Color(0xFF00C853)];

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(colors: gradColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: [BoxShadow(color: color.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.15)),
            child: Center(child: Icon(Icons.lock_open_rounded, color: Colors.white, size: 24)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPremium ? '⭐ Advanced requires Premium' : '🔓 Sign up to unlock Intermediate',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  isPremium ? 'Upgrade to access elite workouts' : 'Create a free account — 30 seconds',
                  style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, isPremium ? '/premium' : '/register'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white.withOpacity(0.18),
                border: Border.all(color: Colors.white.withOpacity(0.4)),
              ),
              child: Text(isPremium ? 'Upgrade' : 'Join Free',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats header strip ────────────────────────────────────────────────────────
  Widget _buildStatsStrip({required bool isDark, required Color textPrimary, required Color textSecondary}) {
    final total = _displayExercises.length;
    final unlocked = _displayExercises.where((e) {
      final req = _requiredTierForDifficulty(e['difficulty'] as String);
      return _isTierUnlocked(req);
    }).length;
    final color = _requiredTierForDifficulty(_selectedDifficulty) == 'guest'
        ? const Color(0xFF00C853)
        : _requiredTierForDifficulty(_selectedDifficulty) == 'free'
            ? const Color(0xFFFF6D00)
            : const Color(0xFFAA00FF);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isDark ? const Color(0xFF141414) : Colors.white,
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          _buildMiniStat('$total', 'Total', color, isDark),
          _buildDivider(isDark),
          _buildMiniStat('$unlocked', 'Unlocked', const Color(0xFF00C853), isDark),
          _buildDivider(isDark),
          _buildMiniStat('${total - unlocked}', 'Locked', const Color(0xFFFF1744), isDark),
          _buildDivider(isDark),
          _buildMiniStat(_selectedDifficulty, 'Level', color, isDark),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String value, String label, Color color, bool isDark) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(label,
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF888888) : const Color(0xFF999999))),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      width: 1, height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // MOBILE LAYOUT
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildMobileLayout(bool isDark) {
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final textSecondary = isDark ? const Color(0xFFB0B0B0) : const Color(0xFF666666);
    final bgColor = isDark ? const Color(0xFF050A05) : const Color(0xFFF4F6F8);
    final isCurrentLocked = !_isTierUnlocked(_requiredTierForDifficulty(_selectedDifficulty));

    return Scaffold(
      backgroundColor: bgColor,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ────────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Exercises',
                                  style: TextStyle(
                                    fontSize: 28, fontWeight: FontWeight.w900,
                                    color: textPrimary, letterSpacing: -0.5,
                                  )),
                              const SizedBox(height: 2),
                              Text('${_displayExercises.length} workouts available',
                                  style: TextStyle(fontSize: 12, color: textSecondary)),
                            ],
                          ),
                        ),
                        if (_isLoadingFromDB)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.primary,
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: AppColors.primary.withOpacity(0.1),
                              border: Border.all(color: AppColors.primary.withOpacity(0.25)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  widget.userTier == 'premium' ? Icons.star_rounded
                                      : widget.userTier == 'free' ? Icons.verified_rounded
                                      : Icons.person_outline_rounded,
                                  size: 12, color: AppColors.primary,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  widget.userTier == 'premium' ? 'Premium'
                                      : widget.userTier == 'free' ? 'Free'
                                      : 'Guest',
                                  style: const TextStyle(
                                    fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSearchBar(isDark: isDark, textPrimary: textPrimary),
                    const SizedBox(height: 12),
                    _buildDifficultyTabs(isDark: isDark, textPrimary: textPrimary),
                    const SizedBox(height: 12),
                    _buildMuscleFilter(isDark: isDark, textPrimary: textPrimary),
                    const SizedBox(height: 12),
                    _buildStatsStrip(isDark: isDark, textPrimary: textPrimary, textSecondary: textSecondary),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              // ── List ──────────────────────────────────────────────────────────
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  children: [
                    if (isCurrentLocked)
                      _buildTierUnlockBanner(difficulty: _selectedDifficulty, isDark: isDark),
                    ..._displayExercises.asMap().entries.map((entry) =>
                        _buildHeroExerciseCard(
                          exercise: entry.value,
                          isDark: isDark,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          index: entry.key,
                        )),
                    if (_displayExercises.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: Column(
                          children: [
                            Icon(Icons.fitness_center_rounded, size: 52,
                                color: textSecondary.withOpacity(0.25)),
                            const SizedBox(height: 14),
                            Text('No exercises found',
                                style: TextStyle(fontSize: 16, color: textSecondary, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text('Try a different search or muscle group',
                                style: TextStyle(fontSize: 12, color: textSecondary.withOpacity(0.6))),
                          ],
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

  // ════════════════════════════════════════════════════════════════════════════
  // WEB LAYOUT
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildWebLayout(bool isDark) {
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final textSecondary = isDark ? const Color(0xFFB0B0B0) : const Color(0xFF666666);
    final bgColor = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF0F2F5);
    final isCurrentLocked = !_isTierUnlocked(_requiredTierForDifficulty(_selectedDifficulty));

    return FadeTransition(
      opacity: _fadeAnim,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Page header ────────────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Exercise Library',
                            style: TextStyle(
                              fontSize: 30, fontWeight: FontWeight.w900,
                              color: textPrimary, letterSpacing: -0.6,
                            )),
                        const SizedBox(height: 4),
                        Text(
                          '${_displayExercises.length} exercises · $_selectedDifficulty difficulty',
                          style: TextStyle(fontSize: 14, color: textSecondary),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (_isLoadingFromDB)
                      Row(
                        children: [
                          SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          ),
                          const SizedBox(width: 8),
                          Text('Syncing with database…',
                              style: TextStyle(fontSize: 12, color: textSecondary)),
                        ],
                      ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: AppColors.primary.withOpacity(0.1),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            widget.userTier == 'premium' ? Icons.star_rounded
                                : widget.userTier == 'free' ? Icons.verified_rounded
                                : Icons.person_outline_rounded,
                            size: 14, color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.userTier == 'premium' ? 'Premium Member'
                                : widget.userTier == 'free' ? 'Free Member'
                                : 'Guest',
                            style: const TextStyle(
                              fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                // ── Controls ──────────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(flex: 3, child: _buildSearchBar(isDark: isDark, textPrimary: textPrimary)),
                    const SizedBox(width: 16),
                    Expanded(flex: 4, child: _buildDifficultyTabs(isDark: isDark, textPrimary: textPrimary)),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _buildMuscleFilter(isDark: isDark, textPrimary: textPrimary)),
                    const SizedBox(width: 16),
                    _buildStatsStrip(isDark: isDark, textPrimary: textPrimary, textSecondary: textSecondary),
                  ],
                ),
                const SizedBox(height: 20),
                if (isCurrentLocked)
                  _buildTierUnlockBanner(difficulty: _selectedDifficulty, isDark: isDark),

                // ── Grid ──────────────────────────────────────────────────────
                if (_displayExercises.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: Column(
                        children: [
                          Icon(Icons.fitness_center_rounded, size: 60,
                              color: textSecondary.withOpacity(0.25)),
                          const SizedBox(height: 16),
                          Text('No exercises found',
                              style: TextStyle(fontSize: 20, color: textSecondary, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          Text('Try a different search or muscle group',
                              style: TextStyle(fontSize: 13, color: textSecondary.withOpacity(0.6))),
                        ],
                      ),
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 560,
                      mainAxisExtent: 155,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _displayExercises.length,
                    itemBuilder: (_, i) => _buildHeroExerciseCard(
                      exercise: _displayExercises[i],
                      isDark: isDark,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      index: i,
                    ),
                  ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}