import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/data/app_data.dart';
import '../detail/meal_detail_screen.dart';

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
  String _selectedMealTime = 'All';

  final List<String> _mealTimes = ['All', 'Breakfast', 'Lunch', 'Snack', 'Dinner'];

  late final List<Map<String, dynamic>> _mealPlan;

  final List<Map<String, dynamic>> _foodLibrary = [
    {
      'name': 'Oatmeal Bowl',
      'meal': 'Oatmeal Bowl',
      'mealTime': 'Breakfast',
      'calories': 320,
      'protein': 12,
      'carbs': 58,
      'fat': 6,
      'emoji': '🥣',
      'color': const Color(0xFFFFD600),
      'tier': 'guest',
      'desc': 'Slow-releasing oats with milk — ideal morning base.',
      'items': 'Rolled oats, whole milk, banana, honey',
    },
    {
      'name': 'Egg White Omelette',
      'meal': 'Egg White Omelette',
      'mealTime': 'Breakfast',
      'calories': 180,
      'protein': 26,
      'carbs': 4,
      'fat': 5,
      'emoji': '🍳',
      'color': const Color(0xFFFFD600),
      'tier': 'free',
      'desc': 'Low-fat, high-protein start ideal for cutting.',
      'items': '4 egg whites, spinach, bell peppers, feta',
    },
    {
      'name': 'Avocado Toast',
      'meal': 'Avocado Toast',
      'mealTime': 'Breakfast',
      'calories': 420,
      'protein': 14,
      'carbs': 44,
      'fat': 22,
      'emoji': '🥑',
      'color': const Color(0xFF00C853),
      'tier': 'premium',
      'desc': 'Healthy fats and complex carbs for sustained focus.',
      'items': 'Sourdough, avocado, eggs, chilli flakes, lemon',
    },
    {
      'name': 'Chicken Rice Bowl',
      'meal': 'Chicken Rice Bowl',
      'mealTime': 'Lunch',
      'calories': 580,
      'protein': 42,
      'carbs': 65,
      'fat': 12,
      'emoji': '🍗',
      'color': const Color(0xFF00C853),
      'tier': 'guest',
      'desc': 'Classic lean protein + complex carb meal.',
      'items': 'Grilled chicken, white rice, broccoli, olive oil',
    },
    {
      'name': 'Tuna Pasta',
      'meal': 'Tuna Pasta',
      'mealTime': 'Lunch',
      'calories': 520,
      'protein': 38,
      'carbs': 60,
      'fat': 8,
      'emoji': '🍝',
      'color': const Color(0xFF2979FF),
      'tier': 'free',
      'desc': 'High-protein pasta packed with omega-3s.',
      'items': 'Whole wheat pasta, canned tuna, cherry tomatoes, basil',
    },
    {
      'name': 'Steak Salad',
      'meal': 'Steak Salad',
      'mealTime': 'Lunch',
      'calories': 490,
      'protein': 48,
      'carbs': 18,
      'fat': 26,
      'emoji': '🥩',
      'color': const Color(0xFFFF1744),
      'tier': 'premium',
      'desc': 'High-protein, low-carb meal perfect for keto.',
      'items': 'Sirloin steak, mixed greens, cherry tomatoes, blue cheese dressing',
    },
    {
      'name': 'Protein Shake',
      'meal': 'Protein Shake',
      'mealTime': 'Snack',
      'calories': 200,
      'protein': 30,
      'carbs': 10,
      'fat': 4,
      'emoji': '🥤',
      'color': const Color(0xFFAA00FF),
      'tier': 'guest',
      'desc': 'Fast-absorbing protein shake for post-workout.',
      'items': 'Whey protein, almond milk, banana, ice',
    },
    {
      'name': 'Greek Yogurt + Nuts',
      'meal': 'Greek Yogurt + Nuts',
      'mealTime': 'Snack',
      'calories': 260,
      'protein': 18,
      'carbs': 22,
      'fat': 12,
      'emoji': '🫙',
      'color': const Color(0xFFFF6D00),
      'tier': 'free',
      'desc': 'Probiotics, protein and healthy fats combined.',
      'items': 'Greek yogurt, mixed nuts, honey, berries',
    },
    {
      'name': 'Rice Cake + Peanut Butter',
      'meal': 'Rice Cake + Peanut Butter',
      'mealTime': 'Snack',
      'calories': 220,
      'protein': 8,
      'carbs': 28,
      'fat': 10,
      'emoji': '🍞',
      'color': const Color(0xFFFFD600),
      'tier': 'premium',
      'desc': 'Light carb-protein combo for pre-training energy.',
      'items': 'Rice cakes, natural peanut butter, banana slices',
    },
    {
      'name': 'Grilled Fish + Veg',
      'meal': 'Grilled Fish + Veg',
      'mealTime': 'Dinner',
      'calories': 450,
      'protein': 38,
      'carbs': 30,
      'fat': 14,
      'emoji': '🐟',
      'color': const Color(0xFF2979FF),
      'tier': 'guest',
      'desc': 'Light omega-3-rich dinner for overnight recovery.',
      'items': 'Salmon fillet, steamed broccoli, sweet potato, lemon',
    },
    {
      'name': 'Chicken Stir-fry',
      'meal': 'Chicken Stir-fry',
      'mealTime': 'Dinner',
      'calories': 520,
      'protein': 44,
      'carbs': 42,
      'fat': 16,
      'emoji': '🍜',
      'color': const Color(0xFFFF6D00),
      'tier': 'free',
      'desc': 'High-protein stir-fry with vegetables and noodles.',
      'items': 'Chicken breast, noodles, mixed vegetables, soy sauce',
    },
    {
      'name': 'Beef & Sweet Potato',
      'meal': 'Beef & Sweet Potato',
      'mealTime': 'Dinner',
      'calories': 620,
      'protein': 50,
      'carbs': 55,
      'fat': 18,
      'emoji': '🥩',
      'color': const Color(0xFFFF1744),
      'tier': 'premium',
      'desc': 'Muscle-building dinner — maximum protein + carbs.',
      'items': 'Lean beef mince, sweet potato, spinach, garlic',
    },
  ];

  final List<String> _planDescs = [
    'High-protein morning start to fuel your day.',
    'Lean protein with complex carbs for sustained energy.',
    'Quick pre-workout fuel — fast carbs and protein.',
    'Light and nutrient-dense dinner for overnight recovery.',
  ];

  @override
  void initState() {
    super.initState();
    _mealPlan = AppData.getTodayMeals().asMap().entries.map((e) {
      const tiers = ['guest', 'free', 'free', 'premium'];
      return {...e.value, 'tier': tiers[e.key], 'desc': _planDescs[e.key]};
    }).toList();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeIn));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  bool _isTierUnlocked(String required) {
    const order = {'guest': 0, 'free': 1, 'premium': 2};
    return (order[widget.userTier] ?? 0) >= (order[required] ?? 0);
  }

  List<Map<String, dynamic>> get _filteredLibrary {
    if (_selectedMealTime == 'All') return _foodLibrary;
    return _foodLibrary.where((f) => f['mealTime'] == _selectedMealTime).toList();
  }

  int get _totalPlanCalories =>
      _mealPlan.fold(0, (s, m) => s + (m['calories'] as int));
  int get _totalPlanProtein =>
      _mealPlan.fold(0, (s, m) => s + (m['protein'] as int));

  void _onMealTap(Map<String, dynamic> meal) {
    if (!_isTierUnlocked(meal['tier'] as String)) {
      _showUpgradeDialog(meal['tier'] as String);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MealDetailScreen(meal: meal, userTier: widget.userTier),
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
              ? 'This meal requires a Premium account. Upgrade to unlock!'
              : 'This meal requires a free account. Sign up to unlock!',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary, foregroundColor: Colors.black),
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
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final textSecondary = isDark ? const Color(0xFFB0B0B0) : const Color(0xFF555555);
    final bgColor = isDark ? const Color(0xFF050A05) : const Color(0xFFF5F5F5);
    final cardColor = isDark ? const Color(0xFF141414) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);

    return Scaffold(
      backgroundColor: bgColor,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nutrition 🥗',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: textPrimary)),
                    const SizedBox(height: 14),
                    _buildTabToggle(cardColor, borderColor, textPrimary),
                    const SizedBox(height: 14),
                    if (_selectedTab == 'Plan')
                      _buildMacroSummary(cardColor, borderColor, textPrimary, textSecondary)
                    else
                      _buildMealTimeFilter(cardColor, borderColor, textPrimary),
                    const SizedBox(height: 14),
                  ],
                ),
              ),

              // ── List ─────────────────────────────────────────────────
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  color: AppColors.primary,
                  backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    children: (_selectedTab == 'Plan' ? _mealPlan : _filteredLibrary)
                        .map((m) => _buildMealCard(
                              meal: m,
                              cardColor: cardColor,
                              borderColor: borderColor,
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                            ))
                        .toList(),
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
  Widget _buildTabToggle(Color cardColor, Color borderColor, Color textPrimary) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: ['Plan', 'Library'].map((tab) {
          final isSelected = _selectedTab == tab;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = tab),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  color: isSelected ? AppColors.primary : Colors.transparent,
                ),
                child: Text(
                  tab == 'Plan' ? '📋 Today\'s Plan' : '📚 Food Library',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.black : textPrimary.withOpacity(0.6),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Macro summary ─────────────────────────────────────────────────────────
  Widget _buildMacroSummary(Color cardColor, Color borderColor,
      Color textPrimary, Color textSecondary) {
    final macros = [
      {'label': 'Calories', 'value': '$_totalPlanCalories', 'unit': 'kcal', 'color': const Color(0xFFFF6D00)},
      {'label': 'Protein', 'value': '$_totalPlanProtein', 'unit': 'g', 'color': const Color(0xFF2979FF)},
      {'label': 'Goal', 'value': '2000', 'unit': 'kcal', 'color': AppColors.primary},
    ];
    return Row(
      children: macros.asMap().entries.map((entry) {
        final i = entry.key;
        final m = entry.value;
        final color = m['color'] as Color;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < macros.length - 1 ? 8 : 0),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: color.withOpacity(0.08),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(m['value'] as String,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
                const SizedBox(height: 2),
                Text('${m['unit']}', style: TextStyle(fontSize: 9, color: textSecondary)),
                Text('${m['label']}', style: TextStyle(fontSize: 9, color: textSecondary)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Meal time filter ──────────────────────────────────────────────────────
  Widget _buildMealTimeFilter(Color cardColor, Color borderColor, Color textPrimary) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _mealTimes.map((t) {
          final isSelected = _selectedMealTime == t;
          return GestureDetector(
            onTap: () => setState(() => _selectedMealTime = t),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: isSelected ? AppColors.primary : cardColor,
                border: Border.all(color: isSelected ? AppColors.primary : borderColor),
              ),
              child: Text(t,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.black : textPrimary.withOpacity(0.7),
                  )),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Meal card ─────────────────────────────────────────────────────────────
  Widget _buildMealCard({
    required Map<String, dynamic> meal,
    required Color cardColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final color = meal['color'] as Color;
    final tier = (meal['tier'] as String?) ?? 'guest';
    final isUnlocked = _isTierUnlocked(tier);

    return GestureDetector(
      onTap: () => _onMealTap(meal),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: cardColor,
          border: Border.all(color: borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(isUnlocked ? 0.12 : 0.06),
                border: Border.all(color: color.withOpacity(0.25)),
              ),
              child: Center(
                child: isUnlocked
                    ? Text(meal['emoji'] as String, style: const TextStyle(fontSize: 20))
                    : Icon(Icons.lock_rounded, size: 18, color: textSecondary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          (meal['meal'] ?? meal['name']) as String? ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isUnlocked ? textPrimary : textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 5),
                      _buildTierBadge(tier),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    (meal['items'] as String?) ?? '',
                    style: TextStyle(fontSize: 10, color: textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 5,
                    runSpacing: 3,
                    children: [
                      _buildMiniChip('${meal['calories']} kcal', color),
                      _buildMiniChip('P: ${meal['protein']}g', const Color(0xFF2979FF)),
                      if ((meal['time'] as String?) != null)
                        _buildMiniChip(meal['time'] as String, textSecondary.withOpacity(0.8))
                      else if ((meal['mealTime'] as String?) != null)
                        _buildMiniChip(meal['mealTime'] as String, AppColors.primary),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isUnlocked ? Icons.arrow_forward_ios_rounded : Icons.lock_outline_rounded,
              size: 13,
              color: isUnlocked ? color : textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: color.withOpacity(0.12),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildTierBadge(String tier) {
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
          style: TextStyle(fontSize: 8, color: color, fontWeight: FontWeight.w700)),
    );
  }
}