import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/supabase_service.dart';
import '../detail/meal_detail_screen.dart';
import '../scan/food_scan_screen.dart';

class WebMeals extends StatefulWidget {
  final String userTier;
  const WebMeals({super.key, required this.userTier});

  @override
  State<WebMeals> createState() => _WebMealsState();
}

class _WebMealsState extends State<WebMeals>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  String _selectedTab = 'Plan';
  String _selectedType = 'All';
  final List<String> _types = [
    'All',
    'breakfast',
    'lunch',
    'snack',
    'dinner'
  ];
  final Map<String, String> _typeLabels = {
    'All': 'All',
    'breakfast': 'Breakfast',
    'lunch': 'Lunch',
    'snack': 'Snack',
    'dinner': 'Dinner',
  };

  List<Map<String, dynamic>> _allMeals = [];
  List<Map<String, dynamic>> _userMeals = [];
  bool _loading = true;
  String _userTier = 'guest';
  String? _userGoal;

  int get _totalCalories => _userMeals.fold(0, (s, um) {
        final meal = um['meals'] as Map<String, dynamic>?;
        return s + ((meal?['calories'] as int?) ?? 0);
      });

  int get _totalProtein => _userMeals.fold(0, (s, um) {
        final meal = um['meals'] as Map<String, dynamic>?;
        return s + (((meal?['protein'] as double?) ?? 0).round());
      });

  int get _totalCarbs => _userMeals.fold(0, (s, um) {
        final meal = um['meals'] as Map<String, dynamic>?;
        return s + (((meal?['carbs'] as double?) ?? 0).round());
      });

  // ── Goal-based suggestions ─────────────────────────────────────────────
  List<Map<String, dynamic>> get _suggestedMeals {
    if (_userGoal == null || _allMeals.isEmpty) return [];
    if (_userGoal == 'Build Muscle') {
      return _allMeals
          .where((m) => ((m['protein'] as double?) ?? 0) >= 35)
          .take(6)
          .toList();
    }
    if (_userGoal == 'Lose Weight') {
      return _allMeals
          .where((m) => ((m['calories'] as int?) ?? 999) <= 400)
          .take(6)
          .toList();
    }
    return _allMeals.take(4).toList();
  }

  String get _suggestionLabel {
    if (_userGoal == 'Build Muscle') return '💪 For Muscle Gain';
    if (_userGoal == 'Lose Weight') return '🔥 For Fat Loss';
    return '⭐ Recommended';
  }

  String get _suggestionSubtitle {
    if (_userGoal == 'Build Muscle') return 'High protein meals (35g+)';
    if (_userGoal == 'Lose Weight') return 'Low calorie meals (≤400 kcal)';
    return 'Based on your profile';
  }

  Color get _accentColor {
    if (_userGoal == 'Build Muscle') return const Color(0xFF2979FF);
    if (_userGoal == 'Lose Weight') return const Color(0xFFFF6D00);
    return AppColors.primary;
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _userTier = widget.userTier;
    _loadData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final tier = await SupabaseService.getUserTier();
      final goal = await SupabaseService.getUserGoal();
      final meals = await SupabaseService.getMeals(tier: tier);
      final userMeals =
          await SupabaseService.getUserMeals(date: DateTime.now());
      if (mounted) {
        setState(() {
          _userTier = tier;
          _userGoal = goal;
          _allMeals = meals;
          _userMeals = userMeals;
          _loading = false;
        });
        _animController.forward();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _isTierUnlocked(String required) {
    const order = {'guest': 0, 'free': 1, 'premium': 2};
    return (order[_userTier] ?? 0) >= (order[required] ?? 0);
  }

  List<Map<String, dynamic>> get _filteredLibrary {
    if (_selectedType == 'All') return _allMeals;
    return _allMeals.where((m) => m['type'] == _selectedType).toList();
  }

  Future<void> _onAddToPlan(Map<String, dynamic> meal) async {
    final mealId = meal['id'] as int;
    final already = await SupabaseService.isMealLoggedToday(mealId);
    if (already) {
      _showSnack('Already in today\'s plan', isError: true);
      return;
    }
    final ok = await SupabaseService.logMeal(mealId);
    if (ok) {
      _showSnack('Added to today\'s plan ✓');
      await _loadData();
    }
  }

  Future<void> _onToggleCompleted(int userMealId, bool current) async {
    await SupabaseService.toggleMealCompleted(userMealId, !current);
    await _loadData();
  }

  Future<void> _onRemove(int userMealId) async {
    await SupabaseService.removeMealFromPlan(userMealId);
    await _loadData();
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600)),
      backgroundColor:
          isError ? const Color(0xFFFF1744) : AppColors.primary,
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }

  void _onMealTap(Map<String, dynamic> meal) {
    final tier = (meal['tier_required'] as String?) ?? 'guest';
    if (!_isTierUnlocked(tier)) {
      _showUpgradeDialog(tier);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MealDetailScreen(meal: meal, userTier: _userTier),
      ),
    );
  }

  void _showUpgradeDialog(String required) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor:
            isDark ? const Color(0xFF141414) : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('🔒 Locked Content'),
        content: Text(required == 'premium'
            ? 'This meal is exclusive to Premium members. Upgrade to unlock all premium recipes.'
            : 'This meal requires a free account. Sign up to access member content.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context,
                  required == 'premium' ? '/premium' : '/register');
            },
            child: Text(
                required == 'premium' ? 'Go Premium' : 'Sign Up Free'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? Colors.white : const Color(0xFF0A0A0A);
    final textSecondary =
        isDark ? const Color(0xFFB0B0B0) : const Color(0xFF666666);
    final bgColor =
        isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF0F2F5);
    final cardColor =
        isDark ? const Color(0xFF141414) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);

    return Scaffold(
      backgroundColor: bgColor,
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 2))
          : FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: Center(
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxWidth: 1200),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Top bar ──────────────────────────────
                        _buildTopBar(isDark, textPrimary,
                            textSecondary, cardColor, borderColor),
                        const SizedBox(height: 24),

                        // ── Goal suggestions ─────────────────────
                        if (SupabaseService.isLoggedIn &&
                            _suggestedMeals.isNotEmpty) ...[
                          _buildSuggestionsSection(
                              isDark, textPrimary, textSecondary,
                              cardColor, borderColor),
                          const SizedBox(height: 28),
                        ],

                        // ── Macro / filter row ───────────────────
                        if (_selectedTab == 'Plan')
                          _buildMacroBar(isDark, textPrimary,
                              textSecondary, cardColor, borderColor)
                        else
                          _buildTypeFilter(isDark, textPrimary,
                              cardColor, borderColor),
                        const SizedBox(height: 24),

                        // ── Content ──────────────────────────────
                        if (_selectedTab == 'Plan')
                          _buildPlanContent(isDark, textPrimary,
                              textSecondary, cardColor, borderColor)
                        else
                          _buildLibraryContent(isDark, textPrimary,
                              textSecondary, cardColor, borderColor),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────
  Widget _buildTopBar(bool isDark, Color textPrimary,
      Color textSecondary, Color cardColor, Color borderColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nutrition',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: textPrimary,
                    letterSpacing: -0.5)),
            const SizedBox(height: 4),
            Text('Your daily meal plan & complete food library',
                style:
                    TextStyle(fontSize: 13, color: textSecondary)),
          ],
        ),
        const Spacer(),

// ── AI Scan Button ───────────────────────────────
MouseRegion(
  cursor: SystemMouseCursors.click,
  child: GestureDetector(
    onTap: () {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => FoodScanScreen(
          userGoal: _userGoal ?? 'Improve Fitness',
          userTier: _userTier,
        ),
      ));
    },
    child: Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.primary,
        boxShadow: [BoxShadow(
          color: AppColors.primary.withOpacity(0.3),
          blurRadius: 10, offset: const Offset(0, 3),
        )],
      ),
      child: const Row(children: [
        Icon(Icons.camera_alt_rounded, size: 15, color: Colors.black),
        SizedBox(width: 8),
        Text('🤖  Scan Food with AI', style: TextStyle(
            fontSize: 12, color: Colors.black,
            fontWeight: FontWeight.w700)),
      ]),
    ),
  ),
),
        // Tier badge
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: _tierColor(_userTier).withOpacity(0.12),
            border: Border.all(
                color: _tierColor(_userTier).withOpacity(0.3)),
          ),
          child: Text(
            _tierLabel(_userTier),
            style: TextStyle(
                fontSize: 11,
                color: _tierColor(_userTier),
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5),
          ),
        ),

        // Tab toggle
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: ['Plan', 'Library'].map((tab) {
              final sel = _selectedTab == tab;
              return GestureDetector(
                onTap: () => setState(() => _selectedTab = tab),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 9),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: sel
                        ? AppColors.primary
                        : Colors.transparent,
                    boxShadow: sel
                        ? [
                            BoxShadow(
                              color: AppColors.primary
                                  .withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null,
                  ),
                  child: Text(
                    tab == 'Plan'
                        ? '📋  Today\'s Plan'
                        : '🍽  Food Library',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: sel
                          ? Colors.black
                          : textPrimary.withOpacity(0.5),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ── Suggestions Section ───────────────────────────────────────────────────
  Widget _buildSuggestionsSection(bool isDark, Color textPrimary,
      Color textSecondary, Color cardColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: _accentColor.withOpacity(isDark ? 0.06 : 0.04),
        border: Border.all(color: _accentColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: _accentColor.withOpacity(0.12),
                  border:
                      Border.all(color: _accentColor.withOpacity(0.3)),
                ),
                child: Text(
                  _suggestionLabel,
                  style: TextStyle(
                      fontSize: 12,
                      color: _accentColor,
                      fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _suggestionSubtitle,
                style:
                    TextStyle(fontSize: 13, color: textSecondary),
              ),
              const Spacer(),
              Text(
                '${_suggestedMeals.length} meals found',
                style: TextStyle(
                    fontSize: 11,
                    color: _accentColor,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Horizontal scroll cards
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _suggestedMeals.length,
              itemBuilder: (_, i) => _buildSuggestionCard(
                meal: _suggestedMeals[i],
                isDark: isDark,
                textPrimary: textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Suggestion Card ───────────────────────────────────────────────────────
  Widget _buildSuggestionCard({
    required Map<String, dynamic> meal,
    required bool isDark,
    required Color textPrimary,
  }) {
    final tier = (meal['tier_required'] as String?) ?? 'guest';
    final unlocked = _isTierUnlocked(tier);
    final imageUrl = (meal['image_url'] as String?) ?? '';
    final name = (meal['name'] as String?) ?? '';
    final type = (meal['type'] as String?) ?? '';
    final calories = (meal['calories'] as int?) ?? 0;
    final protein = ((meal['protein'] as double?) ?? 0).round();

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _onMealTap(meal),
        child: Container(
          width: 200,
          margin: const EdgeInsets.only(right: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withOpacity(isDark ? 0.4 : 0.12),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image
                imageUrl.isNotEmpty
                    ? Image.network(imageUrl,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        errorBuilder: (_, __, ___) =>
                            _imageFallback(type))
                    : _imageFallback(type),

                // Lock overlay
                if (!unlocked)
                  Container(
                    color: Colors.black.withOpacity(0.55),
                    child: const Center(
                      child: Icon(Icons.lock_rounded,
                          size: 28, color: Colors.white54),
                    ),
                  ),

                // Gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.85),
                      ],
                      stops: const [0.4, 1.0],
                    ),
                  ),
                ),

                // Accent top bar
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(height: 3, color: _accentColor),
                ),

                // Type badge
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: Colors.black.withOpacity(0.55),
                    ),
                    child: Text(
                      _typeLabels[type] ?? type,
                      style: const TextStyle(
                          fontSize: 9,
                          color: Colors.white70,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),

                // Add button top right (if logged in + unlocked)
                if (unlocked && SupabaseService.isLoggedIn)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _onAddToPlan(meal),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: AppColors.primary,
                        ),
                        child: const Text('+ Add',
                            style: TextStyle(
                                fontSize: 9,
                                color: Colors.black,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),

                // Bottom content
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.2),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(children: [
                        _statChip(
                            '$calories kcal', const Color(0xFFFF6D00)),
                        const SizedBox(width: 5),
                        _statChip(
                            'P: ${protein}g', const Color(0xFF2979FF)),
                      ]),
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

  // ── Macro bar ─────────────────────────────────────────────────────────────
  Widget _buildMacroBar(bool isDark, Color textPrimary,
      Color textSecondary, Color cardColor, Color borderColor) {
    final pct = (_totalCalories / 2000).clamp(0.0, 1.0);
    final macros = [
      {
        'label': 'Calories',
        'value': '$_totalCalories',
        'unit': 'kcal',
        'color': const Color(0xFFFF6D00),
      },
      {
        'label': 'Protein',
        'value': '$_totalProtein',
        'unit': 'g',
        'color': const Color(0xFF2979FF),
      },
      {
        'label': 'Carbs',
        'value': '$_totalCarbs',
        'unit': 'g',
        'color': const Color(0xFFAA00FF),
      },
      {
        'label': 'Goal',
        'value': '2000',
        'unit': 'kcal',
        'color': AppColors.primary,
      },
    ];

    return Row(
      children: [
        ...macros.asMap().entries.map((e) {
          final i = e.key;
          final m = e.value;
          final color = m['color'] as Color;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < 3 ? 12 : 0),
              padding: const EdgeInsets.symmetric(
                  vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: color.withOpacity(0.07),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m['value'] as String,
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: color)),
                  Text('${m['unit']}  ·  ${m['label']}',
                      style: TextStyle(
                          fontSize: 10,
                          color: color.withOpacity(0.7))),
                  if (i == 0) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: Stack(children: [
                        Container(
                            height: 4,
                            color: color.withOpacity(0.15)),
                        FractionallySizedBox(
                          widthFactor: pct,
                          child: Container(
                              height: 4, color: color),
                        ),
                      ]),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ── Type filter ───────────────────────────────────────────────────────────
  Widget _buildTypeFilter(bool isDark, Color textPrimary,
      Color cardColor, Color borderColor) {
    return Row(
      children: [
        Text('Filter:',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textPrimary.withOpacity(0.5))),
        const SizedBox(width: 12),
        ..._types.map((t) {
          final sel = _selectedType == t;
          return GestureDetector(
            onTap: () => setState(() => _selectedType = t),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: sel ? AppColors.primary : cardColor,
                border: Border.all(
                    color: sel ? AppColors.primary : borderColor),
                boxShadow: sel
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.25),
                          blurRadius: 8,
                        )
                      ]
                    : null,
              ),
              child: Text(
                _typeLabels[t] ?? t,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: sel
                      ? Colors.black
                      : textPrimary.withOpacity(0.6),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ── Plan Content ──────────────────────────────────────────────────────────
  Widget _buildPlanContent(bool isDark, Color textPrimary,
      Color textSecondary, Color cardColor, Color borderColor) {
    if (_userMeals.isEmpty) {
      return _buildEmptyPlan(isDark, textPrimary, textSecondary);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate:
              const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 560,
            mainAxisExtent: 220,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: _userMeals.length,
          itemBuilder: (_, i) {
            final um = _userMeals[i];
            final meal = um['meals'] as Map<String, dynamic>?;
            if (meal == null) return const SizedBox.shrink();
            return _buildWebPlanCard(
              userMeal: um,
              meal: meal,
              isDark: isDark,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            );
          },
        ),
        const SizedBox(height: 24),
        Center(
          child: GestureDetector(
            onTap: () => setState(() => _selectedTab = 'Library'),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.primary.withOpacity(0.3)),
                color: AppColors.primary.withOpacity(0.05),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_circle_outline_rounded,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text('Browse Food Library to add meals',
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

  // ── Library Content ───────────────────────────────────────────────────────
  Widget _buildLibraryContent(bool isDark, Color textPrimary,
      Color textSecondary, Color cardColor, Color borderColor) {
    final meals = _filteredLibrary;
    if (meals.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Text('No meals found',
              style:
                  TextStyle(color: textSecondary, fontSize: 14)),
        ),
      );
    }

    final hero = meals.first;
    final rest = meals.skip(1).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeroCard(
          meal: hero,
          isDark: isDark,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        ),
        const SizedBox(height: 20),

        if (rest.isNotEmpty) ...[
          Text('All Meals',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: textPrimary)),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 380,
              mainAxisExtent: 260,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: rest.length,
            itemBuilder: (_, i) => _buildGridCard(
              meal: rest[i],
              isDark: isDark,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  // ── Hero Card ─────────────────────────────────────────────────────────────
  Widget _buildHeroCard({
    required Map<String, dynamic> meal,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final tier = (meal['tier_required'] as String?) ?? 'guest';
    final unlocked = _isTierUnlocked(tier);
    final imageUrl = (meal['image_url'] as String?) ?? '';
    final name = (meal['name'] as String?) ?? '';
    final type = (meal['type'] as String?) ?? '';
    final calories = (meal['calories'] as int?) ?? 0;
    final protein = ((meal['protein'] as double?) ?? 0).round();
    final carbs = ((meal['carbs'] as double?) ?? 0).round();
    final fat = ((meal['fat'] as double?) ?? 0).round();

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _onMealTap(meal),
        child: Container(
          height: 320,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withOpacity(isDark ? 0.5 : 0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                imageUrl.isNotEmpty
                    ? Image.network(imageUrl,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        errorBuilder: (_, __, ___) =>
                            _imageFallback(type))
                    : _imageFallback(type),
                if (!unlocked)
                  Container(
                    color: Colors.black.withOpacity(0.6),
                    child: const Center(
                      child: Icon(Icons.lock_rounded,
                          size: 48, color: Colors.white54),
                    ),
                  ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.2),
                        Colors.black.withOpacity(0.9),
                      ],
                      stops: const [0.3, 0.6, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  top: 20,
                  left: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: AppColors.primary.withOpacity(0.9),
                    ),
                    child: const Text('FEATURED',
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.black,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1)),
                  ),
                ),
                Positioned(
                  top: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.black.withOpacity(0.6),
                      border: Border.all(
                          color: _tierColor(tier).withOpacity(0.5)),
                    ),
                    child: Text(_tierLabel(tier),
                        style: TextStyle(
                            fontSize: 10,
                            color: _tierColor(tier),
                            fontWeight: FontWeight.w800)),
                  ),
                ),
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 24,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(6),
                                color:
                                    Colors.white.withOpacity(0.15),
                              ),
                              child: Text(
                                  _typeLabels[type] ?? type,
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(height: 8),
                            Text(name,
                                style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.5)),
                            const SizedBox(height: 10),
                            Row(children: [
                              _statChip('$calories kcal',
                                  const Color(0xFFFF6D00)),
                              const SizedBox(width: 8),
                              _statChip('P: ${protein}g',
                                  const Color(0xFF2979FF)),
                              const SizedBox(width: 8),
                              _statChip('C: ${carbs}g',
                                  const Color(0xFFAA00FF)),
                              const SizedBox(width: 8),
                              _statChip('F: ${fat}g',
                                  const Color(0xFFFFD600)),
                            ]),
                          ],
                        ),
                      ),
                      if (unlocked && SupabaseService.isLoggedIn)
                        GestureDetector(
                          onTap: () => _onAddToPlan(meal),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(12),
                              color: AppColors.primary,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary
                                      .withOpacity(0.4),
                                  blurRadius: 12,
                                )
                              ],
                            ),
                            child: const Text('+ Add to Plan',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w700)),
                          ),
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

  // ── Grid Card ─────────────────────────────────────────────────────────────
  Widget _buildGridCard({
    required Map<String, dynamic> meal,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final tier = (meal['tier_required'] as String?) ?? 'guest';
    final unlocked = _isTierUnlocked(tier);
    final imageUrl = (meal['image_url'] as String?) ?? '';
    final name = (meal['name'] as String?) ?? '';
    final type = (meal['type'] as String?) ?? '';
    final calories = (meal['calories'] as int?) ?? 0;
    final protein = ((meal['protein'] as double?) ?? 0).round();

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _onMealTap(meal),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withOpacity(isDark ? 0.4 : 0.1),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                imageUrl.isNotEmpty
                    ? Image.network(imageUrl,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        errorBuilder: (_, __, ___) =>
                            _imageFallback(type))
                    : _imageFallback(type),
                if (!unlocked)
                  Container(
                    color: Colors.black.withOpacity(0.6),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_rounded,
                              size: 32, color: _tierColor(tier)),
                          const SizedBox(height: 6),
                          Text(
                            tier == 'premium'
                                ? 'Premium Only'
                                : 'Members Only',
                            style: TextStyle(
                                fontSize: 11,
                                color: _tierColor(tier),
                                fontWeight: FontWeight.w700),
                          ),
                        ],
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
                        Colors.black.withOpacity(0.25),
                        Colors.black.withOpacity(0.88),
                      ],
                      stops: const [0.35, 0.65, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.black.withOpacity(0.55),
                    ),
                    child: Text(_typeLabels[type] ?? type,
                        style: const TextStyle(
                            fontSize: 9,
                            color: Colors.white70,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.black.withOpacity(0.55),
                      border: Border.all(
                          color: _tierColor(tier).withOpacity(0.5)),
                    ),
                    child: Text(_tierLabel(tier),
                        style: TextStyle(
                            fontSize: 9,
                            color: _tierColor(tier),
                            fontWeight: FontWeight.w800)),
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.2),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _statChip('$calories kcal',
                              const Color(0xFFFF6D00)),
                          const SizedBox(width: 6),
                          _statChip('P: ${protein}g',
                              const Color(0xFF2979FF)),
                          const Spacer(),
                          if (unlocked && SupabaseService.isLoggedIn)
                            GestureDetector(
                              onTap: () => _onAddToPlan(meal),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.circular(8),
                                  color: AppColors.primary,
                                ),
                                child: const Text('+ Add',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w700)),
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

  // ── Web Plan Card ─────────────────────────────────────────────────────────
  Widget _buildWebPlanCard({
    required Map<String, dynamic> userMeal,
    required Map<String, dynamic> meal,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final completed = (userMeal['completed'] as bool?) ?? false;
    final userMealId = userMeal['id'] as int;
    final imageUrl = (meal['image_url'] as String?) ?? '';
    final name = (meal['name'] as String?) ?? '';
    final type = (meal['type'] as String?) ?? '';
    final calories = (meal['calories'] as int?) ?? 0;
    final protein = ((meal['protein'] as double?) ?? 0).round();
    final fullMeal = {...meal};

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _onMealTap(fullMeal),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              imageUrl.isNotEmpty
                  ? Image.network(imageUrl,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      errorBuilder: (_, __, ___) =>
                          _imageFallback(type))
                  : _imageFallback(type),
              if (completed)
                Container(color: Colors.black.withOpacity(0.5)),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.85),
                    ],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: Colors.black.withOpacity(0.55),
                  ),
                  child: Text(_typeLabels[type] ?? type,
                      style: const TextStyle(
                          fontSize: 9,
                          color: Colors.white70,
                          fontWeight: FontWeight.w600)),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Row(children: [
                  GestureDetector(
                    onTap: () =>
                        _onToggleCompleted(userMealId, completed),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: completed
                            ? AppColors.primary
                            : Colors.black.withOpacity(0.5),
                        border: Border.all(
                            color: completed
                                ? AppColors.primary
                                : Colors.white38,
                            width: 2),
                      ),
                      child: completed
                          ? const Icon(Icons.check_rounded,
                              size: 16, color: Colors.black)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _onRemove(userMealId),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red.withOpacity(0.3),
                        border: Border.all(
                            color: Colors.red.withOpacity(0.5)),
                      ),
                      child: const Icon(Icons.close_rounded,
                          size: 16, color: Colors.redAccent),
                    ),
                  ),
                ]),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: completed
                                ? Colors.white54
                                : Colors.white,
                            decoration: completed
                                ? TextDecoration.lineThrough
                                : null),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Row(children: [
                      _statChip('$calories kcal',
                          const Color(0xFFFF6D00)),
                      const SizedBox(width: 6),
                      _statChip(
                          'P: ${protein}g', const Color(0xFF2979FF)),
                      if (completed) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color:
                                AppColors.primary.withOpacity(0.2),
                          ),
                          child: Text('Eaten ✓',
                              style: TextStyle(
                                  fontSize: 9,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Empty plan ────────────────────────────────────────────────────────────
  Widget _buildEmptyPlan(
      bool isDark, Color textPrimary, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.primary.withOpacity(0.05),
        border: Border.all(
            color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.1),
            ),
            child: Icon(Icons.restaurant_menu_rounded,
                size: 32, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text('No meals planned today',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: textPrimary)),
          const SizedBox(height: 8),
          Text(
              'Switch to Food Library and add meals to start tracking your nutrition',
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 13, color: textSecondary)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => setState(() => _selectedTab = 'Library'),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.primary,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: const Text('Browse Food Library',
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.black,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _statChip(String label, Color color) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: color.withOpacity(0.2),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 9,
              color: color,
              fontWeight: FontWeight.w700)),
    );
  }

  Widget _imageFallback(String type) {
    final colors = {
      'breakfast': const Color(0xFFFFD600),
      'lunch': const Color(0xFF00C853),
      'snack': const Color(0xFFAA00FF),
      'dinner': const Color(0xFF2979FF),
    };
    final color = colors[type] ?? AppColors.primary;
    return Container(
      color: color.withOpacity(0.15),
      child: Center(
          child: Icon(Icons.restaurant_rounded,
              size: 48, color: color)),
    );
  }

  Color _tierColor(String tier) {
    if (tier == 'premium') return const Color(0xFFFFD600);
    if (tier == 'free') return AppColors.primary;
    return Colors.grey;
  }

  String _tierLabel(String tier) {
    if (tier == 'premium') return '⭐ PREMIUM';
    if (tier == 'free') return 'MEMBER';
    return 'FREE';
  }
}