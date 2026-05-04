import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/supabase_service.dart';
import '../detail/meal_detail_screen.dart';
import '../scan/food_scan_screen.dart';

class MobileMeals extends StatefulWidget {
  final String userTier;
  const MobileMeals({super.key, required this.userTier});

  @override
  State<MobileMeals> createState() => _MobileMealsState();
}

class _MobileMealsState extends State<MobileMeals>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  String _selectedTab = 'Plan';
  String _selectedType = 'All';
  final List<String> _types = ['All', 'breakfast', 'lunch', 'snack', 'dinner'];
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
      backgroundColor: isError ? const Color(0xFFFF1744) : AppColors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        builder: (_) => MealDetailScreen(meal: meal, userTier: _userTier),
      ),
    );
  }

  void _showUpgradeDialog(String required) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF141414) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🔒 Locked Content'),
        content: Text(required == 'premium'
            ? 'This meal is exclusive to Premium members. Upgrade to unlock all premium recipes and nutrition plans.'
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
              Navigator.pushNamed(
                  context, required == 'premium' ? '/premium' : '/register');
            },
            child:
                Text(required == 'premium' ? 'Go Premium' : 'Sign Up Free'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final textSecondary =
        isDark ? const Color(0xFFB0B0B0) : const Color(0xFF666666);
    final bgColor =
        isDark ? const Color(0xFF050A05) : const Color(0xFFF2F4F7);
    final cardColor = isDark ? const Color(0xFF111111) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF222222) : const Color(0xFFE8E8E8);

    return Scaffold(
      backgroundColor: bgColor,
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 2))
          : FadeTransition(
              opacity: _fadeAnim,
              child: SafeArea(
                child: Column(
                  children: [
                    _buildHeader(isDark, textPrimary, textSecondary,
                        cardColor, borderColor),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadData,
                        color: AppColors.primary,
                        backgroundColor: cardColor,
                        child: _selectedTab == 'Plan'
                            ? _buildPlanTab(isDark, textPrimary,
                                textSecondary, cardColor, borderColor)
                            : _buildLibraryTab(isDark, textPrimary,
                                textSecondary, cardColor, borderColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader(bool isDark, Color textPrimary, Color textSecondary,
      Color cardColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Nutrition',
            style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: textPrimary,
                letterSpacing: -0.5)),
        Text('Track your daily fuel',
            style: TextStyle(fontSize: 12, color: textSecondary)),
      ],
    ),
    Row(children: [
      // ── AI Scan Button ──────────────────────
      GestureDetector(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => FoodScanScreen(
              userGoal: _userGoal ?? 'Improve Fitness',
              userTier: _userTier,
            ),
          ));
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: AppColors.primary,
            boxShadow: [BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 8, offset: const Offset(0, 3),
            )],
          ),
          child: const Row(children: [
            Icon(Icons.camera_alt_rounded, size: 14, color: Colors.black),
            SizedBox(width: 5),
            Text('Scan Food', style: TextStyle(
                fontSize: 11, color: Colors.black,
                fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
      const SizedBox(width: 10),
      // ── Tier badge ──────────────────────────
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: _tierColor(_userTier).withOpacity(0.12),
          border: Border.all(color: _tierColor(_userTier).withOpacity(0.3)),
        ),
        child: Text(
          _tierLabel(_userTier),
          style: TextStyle(
              fontSize: 10,
              color: _tierColor(_userTier),
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5),
        ),
      ),
    ]),
  ],
),
          const SizedBox(height: 14),

          // ── Suggestions strip (shown above tabs if goal set) ──────────
          if (SupabaseService.isLoggedIn && _suggestedMeals.isNotEmpty) ...[
            _buildSuggestionsStrip(isDark, textPrimary, textSecondary),
            const SizedBox(height: 14),
          ],

          _buildTabToggle(isDark, textPrimary, cardColor, borderColor),
          const SizedBox(height: 14),

          if (_selectedTab == 'Plan')
            _buildMacroRow(isDark, textSecondary)
          else
            _buildTypeFilter(isDark, textPrimary, cardColor, borderColor),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ── Suggestions Strip ────────────────────────────────────────────────────
  Widget _buildSuggestionsStrip(
      bool isDark, Color textPrimary, Color textSecondary) {
    final accentColor = _userGoal == 'Build Muscle'
        ? const Color(0xFF2979FF)
        : _userGoal == 'Lose Weight'
            ? const Color(0xFFFF6D00)
            : AppColors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: accentColor.withOpacity(0.12),
                border: Border.all(color: accentColor.withOpacity(0.3)),
              ),
              child: Text(
                _suggestionLabel,
                style: TextStyle(
                    fontSize: 11,
                    color: accentColor,
                    fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _suggestionSubtitle,
              style: TextStyle(fontSize: 11, color: textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _suggestedMeals.length,
            itemBuilder: (_, i) => _buildSuggestionCard(
              meal: _suggestedMeals[i],
              isDark: isDark,
              accentColor: accentColor,
            ),
          ),
        ),
      ],
    );
  }

  // ── Suggestion Card ──────────────────────────────────────────────────────
  Widget _buildSuggestionCard({
    required Map<String, dynamic> meal,
    required bool isDark,
    required Color accentColor,
  }) {
    final tier = (meal['tier_required'] as String?) ?? 'guest';
    final unlocked = _isTierUnlocked(tier);
    final imageUrl = (meal['image_url'] as String?) ?? '';
    final name = (meal['name'] as String?) ?? '';
    final type = (meal['type'] as String?) ?? '';
    final calories = (meal['calories'] as int?) ?? 0;
    final protein = ((meal['protein'] as double?) ?? 0).round();

    return GestureDetector(
      onTap: () => _onMealTap(meal),
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image
              imageUrl.isNotEmpty
                  ? Image.network(imageUrl,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      errorBuilder: (_, __, ___) => _imageFallback(type))
                  : _imageFallback(type),

              // Lock blur
              if (!unlocked)
                Container(color: Colors.black.withOpacity(0.5),
                    child: const Center(
                        child: Icon(Icons.lock_rounded,
                            size: 22, color: Colors.white54))),

              // Gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
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
                child: Container(
                  height: 3,
                  color: accentColor,
                ),
              ),

              // Bottom content
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.2),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(children: [
                      _miniChip('$calories', const Color(0xFFFF6D00)),
                      const SizedBox(width: 4),
                      _miniChip('P:${protein}g', const Color(0xFF2979FF)),
                    ]),
                  ],
                ),
              ),

              // Type badge top left
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.black.withOpacity(0.5),
                  ),
                  child: Text(
                    _typeLabels[type] ?? type,
                    style: const TextStyle(
                        fontSize: 8,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tab toggle ────────────────────────────────────────────────────────────
  Widget _buildTabToggle(bool isDark, Color textPrimary, Color cardColor,
      Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: ['Plan', 'Library'].map((tab) {
          final sel = _selectedTab == tab;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = tab),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: sel ? AppColors.primary : Colors.transparent,
                  boxShadow: sel
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Text(
                  tab == 'Plan' ? '📋  Today\'s Plan' : '🍽  Food Library',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: sel ? Colors.black : textPrimary.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Macro summary row ─────────────────────────────────────────────────────
  Widget _buildMacroRow(bool isDark, Color textSecondary) {
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
        'label': 'Goal',
        'value': '2000',
        'unit': 'kcal',
        'color': AppColors.primary,
      },
    ];
    return Row(
      children: macros.asMap().entries.map((e) {
        final i = e.key;
        final m = e.value;
        final color = m['color'] as Color;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: color.withOpacity(0.08),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Text(m['value'] as String,
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: color)),
                Text('${m['unit']}  ${m['label']}',
                    style:
                        TextStyle(fontSize: 9, color: color.withOpacity(0.7))),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Type filter pills ─────────────────────────────────────────────────────
  Widget _buildTypeFilter(bool isDark, Color textPrimary, Color cardColor,
      Color borderColor) {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _types.map((t) {
          final sel = _selectedType == t;
          return GestureDetector(
            onTap: () => setState(() => _selectedType = t),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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
                  color:
                      sel ? Colors.black : textPrimary.withOpacity(0.6),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Plan Tab ──────────────────────────────────────────────────────────────
  Widget _buildPlanTab(bool isDark, Color textPrimary, Color textSecondary,
      Color cardColor, Color borderColor) {
    if (_userMeals.isEmpty) {
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          const SizedBox(height: 40),
          _buildEmptyPlan(isDark, textPrimary, textSecondary),
          const SizedBox(height: 30),
          Text('Suggested for you',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: textPrimary)),
          const SizedBox(height: 12),
          ..._allMeals
              .where((m) =>
                  _isTierUnlocked((m['tier_required'] as String?) ?? 'guest'))
              .take(3)
              .map((m) => _buildCoverCard(
                    meal: m,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    showAddButton: true,
                  )),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _buildCalorieProgress(isDark, textSecondary),
        const SizedBox(height: 16),
        ..._userMeals.map((um) {
          final meal = um['meals'] as Map<String, dynamic>?;
          if (meal == null) return const SizedBox.shrink();
          final completed = (um['completed'] as bool?) ?? false;
          final userMealId = um['id'] as int;
          return _buildPlanCard(
            userMeal: um,
            meal: meal,
            completed: completed,
            userMealId: userMealId,
            isDark: isDark,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          );
        }),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () => setState(() => _selectedTab = 'Library'),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  style: BorderStyle.solid),
              color: AppColors.primary.withOpacity(0.05),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline_rounded,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Add more meals from library',
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Library Tab ───────────────────────────────────────────────────────────
  Widget _buildLibraryTab(bool isDark, Color textPrimary,
      Color textSecondary, Color cardColor, Color borderColor) {
    final meals = _filteredLibrary;
    if (meals.isEmpty) {
      return Center(
        child: Text('No meals found',
            style: TextStyle(color: textSecondary, fontSize: 14)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: meals.length,
      itemBuilder: (_, i) => _buildCoverCard(
        meal: meals[i],
        isDark: isDark,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        showAddButton: SupabaseService.isLoggedIn,
      ),
    );
  }

  // ── Cover Card (Library) ──────────────────────────────────────────────────
  Widget _buildCoverCard({
    required Map<String, dynamic> meal,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    bool showAddButton = false,
  }) {
    final tier = (meal['tier_required'] as String?) ?? 'guest';
    final unlocked = _isTierUnlocked(tier);
    final imageUrl = (meal['image_url'] as String?) ?? '';
    final name = (meal['name'] as String?) ?? '';
    final type = (meal['type'] as String?) ?? '';
    final calories = (meal['calories'] as int?) ?? 0;
    final protein = ((meal['protein'] as double?) ?? 0).round();

    return GestureDetector(
      onTap: () => _onMealTap(meal),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.12),
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
                      errorBuilder: (_, __, ___) => _imageFallback(type))
                  : _imageFallback(type),
              if (!unlocked)
                Container(
                  color: Colors.black.withOpacity(0.55),
                  child: const Center(
                    child: Icon(Icons.lock_rounded,
                        size: 36, color: Colors.white54),
                  ),
                ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.85),
                    ],
                    stops: const [0.3, 0.6, 1.0],
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.black.withOpacity(0.6),
                    border:
                        Border.all(color: _tierColor(tier).withOpacity(0.5)),
                  ),
                  child: Text(_tierLabel(tier),
                      style: TextStyle(
                          fontSize: 9,
                          color: _tierColor(tier),
                          fontWeight: FontWeight.w800)),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
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
                left: 16,
                right: 16,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.3),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(children: [
                      _statChip('$calories kcal', const Color(0xFFFF6D00)),
                      const SizedBox(width: 6),
                      _statChip('P: ${protein}g', const Color(0xFF2979FF)),
                      const Spacer(),
                      if (showAddButton && unlocked)
                        GestureDetector(
                          onTap: () => _onAddToPlan(meal),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: AppColors.primary,
                            ),
                            child: const Text('+ Add',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ),
                      if (!unlocked)
                        Icon(Icons.lock_outline_rounded,
                            size: 16, color: _tierColor(tier)),
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

  // ── Plan Card ─────────────────────────────────────────────────────────────
  Widget _buildPlanCard({
    required Map<String, dynamic> userMeal,
    required Map<String, dynamic> meal,
    required bool completed,
    required int userMealId,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final imageUrl = (meal['image_url'] as String?) ?? '';
    final name = (meal['name'] as String?) ?? '';
    final type = (meal['type'] as String?) ?? '';
    final calories = (meal['calories'] as int?) ?? 0;
    final protein = ((meal['protein'] as double?) ?? 0).round();
    final fullMeal = {...meal};

    return GestureDetector(
      onTap: () => _onMealTap(fullMeal),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: completed
                  ? AppColors.primary.withOpacity(0.15)
                  : Colors.black.withOpacity(isDark ? 0.3 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: 110,
            child: Stack(
              fit: StackFit.expand,
              children: [
                imageUrl.isNotEmpty
                    ? Image.network(imageUrl,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        errorBuilder: (_, __, ___) => _imageFallback(type))
                    : _imageFallback(type),
                if (completed)
                  Container(color: Colors.black.withOpacity(0.45)),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.75),
                        Colors.black.withOpacity(0.1),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: Colors.white.withOpacity(0.15),
                                ),
                                child: Text(_typeLabels[type] ?? type,
                                    style: const TextStyle(
                                        fontSize: 9,
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ]),
                            const SizedBox(height: 4),
                            Text(name,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: completed
                                        ? Colors.white54
                                        : Colors.white,
                                    decoration: completed
                                        ? TextDecoration.lineThrough
                                        : null),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 6),
                            Row(children: [
                              _statChip('$calories kcal', const Color(0xFFFF6D00)),
                              const SizedBox(width: 5),
                              _statChip('P: ${protein}g', const Color(0xFF2979FF)),
                            ]),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
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
                                    : Colors.white.withOpacity(0.15),
                                border: Border.all(
                                    color: completed
                                        ? AppColors.primary
                                        : Colors.white38,
                                    width: 2),
                                boxShadow: completed
                                    ? [
                                        BoxShadow(
                                            color: AppColors.primary
                                                .withOpacity(0.4),
                                            blurRadius: 8)
                                      ]
                                    : null,
                              ),
                              child: completed
                                  ? const Icon(Icons.check_rounded,
                                      size: 16, color: Colors.black)
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () => _onRemove(userMealId),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.red.withOpacity(0.2),
                                border: Border.all(
                                    color: Colors.red.withOpacity(0.4)),
                              ),
                              child: const Icon(Icons.close_rounded,
                                  size: 14, color: Colors.redAccent),
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

  // ── Calorie progress ──────────────────────────────────────────────────────
  Widget _buildCalorieProgress(bool isDark, Color textSecondary) {
    final pct = (_totalCalories / 2000).clamp(0.0, 1.0);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Daily calories',
                style: TextStyle(fontSize: 11, color: textSecondary)),
            Text('$_totalCalories / 2000 kcal',
                style: TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            children: [
              Container(height: 6, color: AppColors.primary.withOpacity(0.1)),
              FractionallySizedBox(
                widthFactor: pct,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 4)
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Empty plan ────────────────────────────────────────────────────────────
  Widget _buildEmptyPlan(
      bool isDark, Color textPrimary, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.primary.withOpacity(0.06),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.12),
            ),
            child: Icon(Icons.restaurant_menu_rounded,
                size: 28, color: AppColors.primary),
          ),
          const SizedBox(height: 14),
          Text('No meals planned today',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textPrimary)),
          const SizedBox(height: 6),
          Text(
              'Browse the food library and add meals to track your nutrition',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: textSecondary)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => setState(() => _selectedTab = 'Library'),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: AppColors.primary,
              ),
              child: const Text('Browse Food Library',
                  style: TextStyle(
                      fontSize: 12,
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: color.withOpacity(0.2),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 9, color: color, fontWeight: FontWeight.w700)),
    );
  }

  Widget _miniChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: color.withOpacity(0.2),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 8, color: color, fontWeight: FontWeight.w700)),
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
      child:
          Center(child: Icon(Icons.restaurant_rounded, size: 40, color: color)),
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