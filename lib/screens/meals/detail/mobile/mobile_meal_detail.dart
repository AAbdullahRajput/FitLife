import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/supabase_service.dart';

class MobileMealDetail extends StatefulWidget {
  final Map<String, dynamic> meal;
  final String userTier;

  const MobileMealDetail({
    super.key,
    required this.meal,
    required this.userTier,
  });

  @override
  State<MobileMealDetail> createState() => _MobileMealDetailState();
}

class _MobileMealDetailState extends State<MobileMealDetail>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  Map<String, dynamic>? _detail;
  bool _loading = true;
  String _userTier = 'guest';
  bool _addedToPlan = false;

  String get _mealName =>
      (widget.meal['name'] as String?) ?? '';
  String get _mealType =>
      (widget.meal['type'] as String?) ?? '';
  String get _imageUrl =>
      (widget.meal['image_url'] as String?) ?? '';
  int get _calories =>
      (widget.meal['calories'] as int?) ?? 0;
  int get _protein =>
      ((widget.meal['protein'] as double?) ?? 0).round();
  int get _carbs =>
      ((widget.meal['carbs'] as double?) ?? 0).round();
  int get _fat =>
      ((widget.meal['fat'] as double?) ?? 0).round();
  String get _tierRequired =>
      (widget.meal['tier_required'] as String?) ?? 'guest';

  bool get _isUnlocked {
    const order = {'guest': 0, 'free': 1, 'premium': 2};
    return (order[_userTier] ?? 0) >= (order[_tierRequired] ?? 0);
  }

  final Map<String, String> _typeLabels = {
    'breakfast': 'Breakfast',
    'lunch': 'Lunch',
    'snack': 'Snack',
    'dinner': 'Dinner',
  };

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _userTier = widget.userTier;
    _loadDetail();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    setState(() => _loading = true);
    try {
      final tier = await SupabaseService.getUserTier();
      final mealId = widget.meal['id'] as int?;
      Map<String, dynamic>? detail;
      if (mealId != null) {
        detail = await SupabaseService.getMealDetail(mealId);
      }
      if (mounted) {
        setState(() {
          _userTier = tier;
          _detail = detail;
          _loading = false;
        });
        _animController.forward();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onAddToPlan() async {
    final mealId = widget.meal['id'] as int?;
    if (mealId == null) return;
    final already = await SupabaseService.isMealLoggedToday(mealId);
    if (already) {
      _showSnack('Already in today\'s plan', isError: true);
      return;
    }
    final ok = await SupabaseService.logMeal(mealId);
    if (ok && mounted) {
      setState(() => _addedToPlan = true);
      _showSnack('Added to today\'s plan ✓');
    }
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

  // Parse recipe text into steps (split by newlines)
  List<String> get _recipeSteps {
    final recipe = (_detail?['recipe'] as String?) ?? '';
    if (recipe.isEmpty) return [];
    return recipe
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  List<String> get _ingredients {
    final raw = _detail?['ingredients'];
    if (raw == null) return [];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    return [];
  }

  int get _prepTime => (_detail?['prep_time_minutes'] as int?) ?? 0;

  Color get _typeColor {
    const colors = {
      'breakfast': Color(0xFFFFD600),
      'lunch': Color(0xFF00C853),
      'snack': Color(0xFFAA00FF),
      'dinner': Color(0xFF2979FF),
    };
    return colors[_mealType] ?? AppColors.primary;
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? Colors.white : const Color(0xFF0A0A0A);
    final textSecondary =
        isDark ? const Color(0xFFB0B0B0) : const Color(0xFF666666);
    final bgColor =
        isDark ? const Color(0xFF050A05) : const Color(0xFFF2F4F7);
    final cardColor =
        isDark ? const Color(0xFF111111) : Colors.white;
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
              child: CustomScrollView(
                slivers: [
                  // ── Hero app bar ─────────────────────────────────
                  SliverAppBar(
                    expandedHeight: 280,
                    pinned: true,
                    backgroundColor: bgColor,
                    leading: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.5),
                          border: Border.all(
                              color: Colors.white24, width: 1),
                        ),
                        child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 16,
                            color: Colors.white),
                      ),
                    ),
                    actions: [
                      if (SupabaseService.isLoggedIn && _isUnlocked)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: _onAddToPlan,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(20),
                                color: _addedToPlan
                                    ? Colors.black.withOpacity(0.5)
                                    : AppColors.primary,
                              ),
                              child: Text(
                                _addedToPlan
                                    ? '✓ Added'
                                    : '+ Add to Plan',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: _addedToPlan
                                        ? AppColors.primary
                                        : Colors.black,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Hero image
                          _imageUrl.isNotEmpty
                              ? Image.network(
                                  _imageUrl,
                                  fit: BoxFit.cover,
                                  alignment: Alignment.center,
                                  errorBuilder: (_, __, ___) =>
                                      _imageFallback(),
                                )
                              : _imageFallback(),

                          // Lock overlay for locked meals
                          if (!_isUnlocked)
                            Container(
                              color: Colors.black.withOpacity(0.65),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.lock_rounded,
                                        size: 48,
                                        color: _tierColor(
                                            _tierRequired)),
                                    const SizedBox(height: 10),
                                    Text(
                                      _tierRequired == 'premium'
                                          ? 'Premium Content'
                                          : 'Members Only',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: _tierColor(
                                              _tierRequired)),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _tierRequired == 'premium'
                                          ? 'Upgrade to Premium to unlock'
                                          : 'Sign up free to unlock',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white54),
                                    ),
                                    const SizedBox(height: 16),
                                    GestureDetector(
                                      onTap: () =>
                                          Navigator.pushNamed(
                                              context,
                                              _tierRequired ==
                                                      'premium'
                                                  ? '/premium'
                                                  : '/register'),
                                      child: Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 20,
                                                vertical: 10),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(
                                                  20),
                                          color: _tierColor(
                                              _tierRequired),
                                        ),
                                        child: Text(
                                          _tierRequired == 'premium'
                                              ? 'Go Premium'
                                              : 'Sign Up Free',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.black,
                                              fontWeight:
                                                  FontWeight.w700),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // Gradient at bottom
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            height: 120,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    bgColor.withOpacity(0.95),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Type + tier badges
                          if (_isUnlocked)
                            Positioned(
                              bottom: 16,
                              left: 20,
                              child: Row(children: [
                                _badgeChip(
                                    _typeLabels[_mealType] ??
                                        _mealType,
                                    _typeColor),
                                const SizedBox(width: 8),
                                _badgeChip(_tierLabel(_tierRequired),
                                    _tierColor(_tierRequired)),
                              ]),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // ── Body ────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                          20, 0, 20, 40),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          // Meal name
                          Text(
                            _mealName,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Prep time
                          if (_prepTime > 0)
                            Row(children: [
                              Icon(Icons.timer_outlined,
                                  size: 14,
                                  color: textSecondary),
                              const SizedBox(width: 4),
                              Text('$_prepTime min prep time',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: textSecondary)),
                            ]),
                          const SizedBox(height: 20),

                          // Macro cards
                          _buildMacroRow(
                              isDark, textSecondary),
                          const SizedBox(height: 24),

                          // Locked content gate
                          if (!_isUnlocked)
                            _buildLockedGate(
                                isDark, textPrimary, textSecondary)
                          else ...[
                            // Ingredients
                            if (_ingredients.isNotEmpty) ...[
                              _sectionHeader(
                                  '🛒  Ingredients', textPrimary),
                              const SizedBox(height: 12),
                              _buildIngredients(isDark, textPrimary,
                                  cardColor, borderColor),
                              const SizedBox(height: 24),
                            ],

                            // Recipe steps
                            if (_recipeSteps.isNotEmpty) ...[
                              _sectionHeader(
                                  '👨‍🍳  How to Prepare',
                                  textPrimary),
                              const SizedBox(height: 12),
                              _buildSteps(isDark, textPrimary,
                                  textSecondary, cardColor,
                                  borderColor),
                              const SizedBox(height: 24),
                            ],

                            // Nutrition tip
                            _buildNutritionTip(
                                isDark, textSecondary),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ── Macro row ────────────────────────────────────────────────────────────
  Widget _buildMacroRow(bool isDark, Color textSecondary) {
    final macros = [
      {
        'label': 'Calories',
        'value': '$_calories',
        'unit': 'kcal',
        'color': _typeColor,
      },
      {
        'label': 'Protein',
        'value': '$_protein',
        'unit': 'g',
        'color': const Color(0xFF2979FF),
      },
      {
        'label': 'Carbs',
        'value': '$_carbs',
        'unit': 'g',
        'color': const Color(0xFFFF6D00),
      },
      {
        'label': 'Fat',
        'value': '$_fat',
        'unit': 'g',
        'color': const Color(0xFFFFD600),
      },
    ];

    return Row(
      children: macros.asMap().entries.map((e) {
        final i = e.key;
        final m = e.value;
        final color = m['color'] as Color;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < 3 ? 8 : 0),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: color.withOpacity(0.08),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Text(m['value'] as String,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: color)),
                const SizedBox(height: 2),
                Text(m['unit'] as String,
                    style: TextStyle(
                        fontSize: 9,
                        color: color.withOpacity(0.7))),
                Text(m['label'] as String,
                    style: TextStyle(
                        fontSize: 9,
                        color: color.withOpacity(0.7))),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Ingredients ──────────────────────────────────────────────────────────
  Widget _buildIngredients(bool isDark, Color textPrimary,
      Color cardColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: cardColor,
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: _ingredients
            .map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.only(top: 5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _typeColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(item,
                            style: TextStyle(
                                fontSize: 13,
                                color: textPrimary,
                                height: 1.4)),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  // ── Recipe steps ─────────────────────────────────────────────────────────
  Widget _buildSteps(bool isDark, Color textPrimary,
      Color textSecondary, Color cardColor, Color borderColor) {
    return Column(
      children: _recipeSteps.asMap().entries.map((e) {
        final step = e.value;
        final num = e.key + 1;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: cardColor,
            border: Border.all(color: borderColor),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _typeColor.withOpacity(0.15),
                  border: Border.all(
                      color: _typeColor.withOpacity(0.4)),
                ),
                child: Center(
                  child: Text('$num',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: _typeColor)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(step,
                    style: TextStyle(
                        fontSize: 13,
                        color: textSecondary,
                        height: 1.5)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Nutrition tip ────────────────────────────────────────────────────────
  Widget _buildNutritionTip(bool isDark, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.primary.withOpacity(isDark ? 0.08 : 0.05),
        border:
            Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nutrition Tip',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
                const SizedBox(height: 4),
                Text(
                  'Meal prep this on Sundays to stay consistent with your nutrition goals throughout the week.',
                  style:
                      TextStyle(fontSize: 12, color: textSecondary, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Locked gate ──────────────────────────────────────────────────────────
  Widget _buildLockedGate(
      bool isDark, Color textPrimary, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: _tierColor(_tierRequired).withOpacity(0.06),
        border: Border.all(
            color: _tierColor(_tierRequired).withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(Icons.lock_rounded,
              size: 40, color: _tierColor(_tierRequired)),
          const SizedBox(height: 12),
          Text(
            _tierRequired == 'premium'
                ? 'Premium Recipe'
                : 'Member Recipe',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            _tierRequired == 'premium'
                ? 'Upgrade to Premium to see the full ingredients list and step-by-step recipe.'
                : 'Create a free account to access this recipe and much more.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: textSecondary),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => Navigator.pushNamed(
                context,
                _tierRequired == 'premium'
                    ? '/premium'
                    : '/register'),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: _tierColor(_tierRequired),
                boxShadow: [
                  BoxShadow(
                    color:
                        _tierColor(_tierRequired).withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Text(
                _tierRequired == 'premium'
                    ? 'Upgrade to Premium'
                    : 'Sign Up Free',
                style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  Widget _sectionHeader(String title, Color textPrimary) {
    return Text(title,
        style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: textPrimary));
  }

  Widget _badgeChip(String label, Color color) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.black.withOpacity(0.55),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w700)),
    );
  }

  Widget _imageFallback() {
    return Container(
      color: _typeColor.withOpacity(0.15),
      child: Center(
          child: Icon(Icons.restaurant_rounded,
              size: 60, color: _typeColor)),
    );
  }
}