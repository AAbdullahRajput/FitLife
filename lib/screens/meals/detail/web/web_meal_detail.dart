import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../services/supabase_service.dart';

class WebMealDetail extends StatefulWidget {
  final Map<String, dynamic> meal;
  final String userTier;

  const WebMealDetail({super.key, required this.meal, required this.userTier});

  @override
  State<WebMealDetail> createState() => _WebMealDetailState();
}

class _WebMealDetailState extends State<WebMealDetail>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  Map<String, dynamic>? _detail;
  bool _loading = true;
  String _userTier = 'guest';
  bool _addedToPlan = false;

  // ── Getters ──────────────────────────────────────────────────────────────
  String get _mealName => (widget.meal['name'] as String?) ?? '';
  String get _mealType => (widget.meal['type'] as String?) ?? '';
  String get _imageUrl => (widget.meal['image_url'] as String?) ?? '';
  int get _calories => (widget.meal['calories'] as int?) ?? 0;
  int get _protein => ((widget.meal['protein'] as double?) ?? 0).round();
  int get _carbs => ((widget.meal['carbs'] as double?) ?? 0).round();
  int get _fat => ((widget.meal['fat'] as double?) ?? 0).round();
  String get _tierRequired =>
      (widget.meal['tier_required'] as String?) ?? 'guest';

  bool get _isUnlocked {
    const order = {'guest': 0, 'free': 1, 'premium': 2};
    return (order[_userTier] ?? 0) >= (order[_tierRequired] ?? 0);
  }

  int get _prepTime => (_detail?['prep_time_minutes'] as int?) ?? 0;

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

  final Map<String, String> _typeLabels = {
    'breakfast': 'Breakfast',
    'lunch': 'Lunch',
    'snack': 'Snack',
    'dinner': 'Dinner',
  };

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

  // ── Lifecycle ────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _animController, curve: Curves.easeOut));
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

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? Colors.white : const Color(0xFF0A0A0A);
    final textSecondary =
        isDark ? const Color(0xFFB0B0B0) : const Color(0xFF555555);
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
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Full-bleed hero ────────────────────────
                      _buildHero(isDark, bgColor),

                      // ── Content body ───────────────────────────
                      Center(
                        child: ConstrainedBox(
                          constraints:
                              const BoxConstraints(maxWidth: 960),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                                40, 32, 40, 60),
                            child: _buildBody(
                              isDark: isDark,
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                              cardColor: cardColor,
                              borderColor: borderColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // ── Hero ─────────────────────────────────────────────────────────────────
  Widget _buildHero(bool isDark, Color bgColor) {
    return SizedBox(
      height: 420,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          _imageUrl.isNotEmpty
              ? Image.network(
                  _imageUrl,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  errorBuilder: (_, __, ___) => _imageFallback(),
                )
              : _imageFallback(),

          // Lock overlay
          if (!_isUnlocked)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_rounded,
                        size: 56, color: _tierColor(_tierRequired)),
                    const SizedBox(height: 12),
                    Text(
                      _tierRequired == 'premium'
                          ? 'Premium Content'
                          : 'Members Only',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: _tierColor(_tierRequired)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _tierRequired == 'premium'
                          ? 'Upgrade to Premium to unlock this recipe'
                          : 'Create a free account to access this recipe',
                      style: const TextStyle(
                          fontSize: 14, color: Colors.white54),
                    ),
                    const SizedBox(height: 20),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => Navigator.pushNamed(
                            context,
                            _tierRequired == 'premium'
                                ? '/premium'
                                : '/register'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: _tierColor(_tierRequired),
                            boxShadow: [
                              BoxShadow(
                                color: _tierColor(_tierRequired)
                                    .withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              )
                            ],
                          ),
                          child: Text(
                            _tierRequired == 'premium'
                                ? 'Go Premium'
                                : 'Sign Up Free',
                            style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black,
                                fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Bottom gradient fade into bg
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 160,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    bgColor,
                  ],
                ),
              ),
            ),
          ),

          // Top bar — back button + action
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 16),
                child: Row(
                  children: [
                    // Back button
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.black.withOpacity(0.5),
                            border: Border.all(
                                color: Colors.white24, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.arrow_back_ios_new_rounded,
                                  size: 12, color: Colors.white),
                              SizedBox(width: 6),
                              Text('Back',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),

                    // Add to Plan button
                    if (SupabaseService.isLoggedIn && _isUnlocked)
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: _onAddToPlan,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: _addedToPlan
                                  ? Colors.black.withOpacity(0.6)
                                  : AppColors.primary,
                              border: _addedToPlan
                                  ? Border.all(
                                      color: AppColors.primary
                                          .withOpacity(0.5))
                                  : null,
                              boxShadow: _addedToPlan
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: AppColors.primary
                                            .withOpacity(0.4),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      )
                                    ],
                            ),
                            child: Text(
                              _addedToPlan ? '✓ Added to Plan' : '+ Add to Plan',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: _addedToPlan
                                      ? AppColors.primary
                                      : Colors.black,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Badges bottom left (only if unlocked)
          if (_isUnlocked)
            Positioned(
              bottom: 24,
              left: 40,
              child: Row(children: [
                _heroBadge(
                    _typeLabels[_mealType] ?? _mealType, _typeColor),
                const SizedBox(width: 10),
                _heroBadge(
                    _tierLabel(_tierRequired), _tierColor(_tierRequired)),
                if (_prepTime > 0) ...[
                  const SizedBox(width: 10),
                  _heroBadge('⏱ ${_prepTime} min', Colors.white70),
                ],
              ]),
            ),
        ],
      ),
    );
  }

  // ── Body ─────────────────────────────────────────────────────────────────
  Widget _buildBody({
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color cardColor,
    required Color borderColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Two-column layout ──────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column — title + macros + ingredients
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Meal name
                  Text(
                    _mealName,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: textPrimary,
                      letterSpacing: -0.8,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Macro grid
                  _buildMacroGrid(isDark, textSecondary),
                  const SizedBox(height: 28),

                  // Ingredients
                  if (_isUnlocked) ...[
                    if (_ingredients.isNotEmpty) ...[
                      _sectionHeader('🛒  Ingredients', textPrimary),
                      const SizedBox(height: 14),
                      _buildIngredients(
                          isDark, textPrimary, cardColor, borderColor),
                    ] else
                      _buildNoDetail(textSecondary),
                  ] else
                    _buildLockedIngredients(
                        isDark, textPrimary, textSecondary),
                ],
              ),
            ),

            const SizedBox(width: 40),

            // Right column — recipe steps + tip
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isUnlocked) ...[
                    if (_recipeSteps.isNotEmpty) ...[
                      _sectionHeader('👨‍🍳  How to Prepare', textPrimary),
                      const SizedBox(height: 14),
                      _buildSteps(isDark, textPrimary, textSecondary,
                          cardColor, borderColor),
                      const SizedBox(height: 24),
                    ],
                    _buildNutritionTip(isDark, textSecondary),
                  ] else
                    _buildLockedRecipe(
                        isDark, textPrimary, textSecondary),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Macro grid ────────────────────────────────────────────────────────────
  Widget _buildMacroGrid(bool isDark, Color textSecondary) {
    final macros = [
      {
        'label': 'Calories',
        'value': '$_calories',
        'unit': 'kcal',
        'color': _typeColor,
        'icon': Icons.local_fire_department_rounded,
      },
      {
        'label': 'Protein',
        'value': '$_protein',
        'unit': 'g',
        'color': const Color(0xFF2979FF),
        'icon': Icons.fitness_center_rounded,
      },
      {
        'label': 'Carbs',
        'value': '$_carbs',
        'unit': 'g',
        'color': const Color(0xFFFF6D00),
        'icon': Icons.grain_rounded,
      },
      {
        'label': 'Fat',
        'value': '$_fat',
        'unit': 'g',
        'color': const Color(0xFFFFD600),
        'icon': Icons.water_drop_rounded,
      },
    ];

    return Row(
      children: macros.asMap().entries.map((e) {
        final i = e.key;
        final m = e.value;
        final color = m['color'] as Color;
        final icon = m['icon'] as IconData;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < 3 ? 10 : 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: color.withOpacity(0.07),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 18, color: color.withOpacity(0.7)),
                const SizedBox(height: 10),
                Text(m['value'] as String,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: color)),
                Text('${m['unit']}',
                    style: TextStyle(
                        fontSize: 10,
                        color: color.withOpacity(0.6))),
                Text(m['label'] as String,
                    style: TextStyle(
                        fontSize: 10,
                        color: color.withOpacity(0.6))),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: cardColor,
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: _ingredients.asMap().entries.map((e) {
          final i = e.key;
          final item = e.value;
          final isLast = i == _ingredients.length - 1;
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _typeColor,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(item,
                        style: TextStyle(
                            fontSize: 13,
                            color: textPrimary,
                            height: 1.4)),
                  ),
                ],
              ),
              if (!isLast)
                Divider(
                  height: 16,
                  color: _typeColor.withOpacity(0.1),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── Recipe Steps ─────────────────────────────────────────────────────────
  Widget _buildSteps(bool isDark, Color textPrimary,
      Color textSecondary, Color cardColor, Color borderColor) {
    return Column(
      children: _recipeSteps.asMap().entries.map((e) {
        final num = e.key + 1;
        final step = e.value;
        final isLast = num == _recipeSteps.length;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step number + line
            Column(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _typeColor.withOpacity(0.12),
                    border: Border.all(
                        color: _typeColor.withOpacity(0.4), width: 1.5),
                  ),
                  child: Center(
                    child: Text('$num',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: _typeColor)),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 1.5,
                    height: 28,
                    color: _typeColor.withOpacity(0.2),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: cardColor,
                    border: Border.all(color: borderColor),
                  ),
                  child: Text(step,
                      style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                          height: 1.5)),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  // ── Nutrition tip ─────────────────────────────────────────────────────────
  Widget _buildNutritionTip(bool isDark, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.primary.withOpacity(isDark ? 0.08 : 0.05),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.12),
            ),
            child: const Center(
              child: Text('💡', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nutrition Tip',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
                const SizedBox(height: 6),
                Text(
                  'Meal prep this on Sundays to stay consistent with your nutrition goals throughout the week. Portion into containers for easy grab-and-go access.',
                  style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                      height: 1.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Locked states ─────────────────────────────────────────────────────────
  Widget _buildLockedIngredients(
      bool isDark, Color textPrimary, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: _tierColor(_tierRequired).withOpacity(0.06),
        border: Border.all(
            color: _tierColor(_tierRequired).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.lock_rounded,
                size: 18, color: _tierColor(_tierRequired)),
            const SizedBox(width: 8),
            Text('Ingredients locked',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textPrimary)),
          ]),
          const SizedBox(height: 8),
          Text(
            _tierRequired == 'premium'
                ? 'Upgrade to Premium to see the full ingredients list.'
                : 'Create a free account to access all recipes.',
            style: TextStyle(fontSize: 12, color: textSecondary),
          ),
          const SizedBox(height: 16),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context,
                  _tierRequired == 'premium' ? '/premium' : '/register'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: _tierColor(_tierRequired),
                  boxShadow: [
                    BoxShadow(
                      color: _tierColor(_tierRequired).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: Text(
                  _tierRequired == 'premium'
                      ? 'Upgrade to Premium'
                      : 'Sign Up Free',
                  style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedRecipe(
      bool isDark, Color textPrimary, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: _tierColor(_tierRequired).withOpacity(0.06),
        border: Border.all(
            color: _tierColor(_tierRequired).withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(Icons.menu_book_rounded,
              size: 40, color: _tierColor(_tierRequired).withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            _tierRequired == 'premium'
                ? 'Full Recipe — Premium Only'
                : 'Full Recipe — Members Only',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _tierRequired == 'premium'
                ? 'Step-by-step preparation instructions are exclusive to Premium members.'
                : 'Sign up for free to unlock full recipe steps.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDetail(Color textSecondary) {
    return Text('No ingredient details available.',
        style: TextStyle(fontSize: 13, color: textSecondary));
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  Widget _sectionHeader(String title, Color textPrimary) {
    return Text(title,
        style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: textPrimary));
  }

  Widget _heroBadge(String label, Color color) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.black.withOpacity(0.6),
        border: Border.all(color: color.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
          )
        ],
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w700)),
    );
  }

  Widget _imageFallback() {
    return Container(
      color: _typeColor.withOpacity(0.15),
      child: Center(
          child: Icon(Icons.restaurant_rounded,
              size: 80, color: _typeColor.withOpacity(0.5))),
    );
  }
}