import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
 
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
 
  final Map<String, Map<String, dynamic>> _extendedData = {
    'Breakfast': {
      'fullItems': ['Rolled oats (80g)', 'Whole eggs (2)', 'Full-fat milk (200ml)', 'Banana (1 medium)', 'Honey (1 tsp)'],
      'steps': [
        'Cook oats in milk over medium heat for 5 minutes, stirring constantly.',
        'Scramble or fry eggs separately with a pinch of salt.',
        'Slice banana and place on top of oats.',
        'Drizzle honey over the oats for natural sweetness.',
        'Serve eggs alongside the oat bowl.',
      ],
      'prepTime': '10 min', 'goal': 'Muscle Gain',
      'tags': ['High Protein', 'Complex Carbs', 'Morning Fuel'],
      'protein': 28, 'carbs': 52, 'fat': 12,
    },
    'Lunch': {
      'fullItems': ['Chicken breast (180g)', 'White rice (150g cooked)', 'Broccoli (100g)', 'Olive oil (1 tbsp)', 'Garlic (2 cloves)'],
      'steps': [
        'Season chicken breast with salt, pepper and garlic.',
        'Grill or pan-fry chicken for 6–7 minutes each side.',
        'Steam broccoli for 5 minutes until tender-crisp.',
        'Cook rice as per packet instructions.',
        'Plate everything and drizzle olive oil over broccoli.',
      ],
      'prepTime': '25 min', 'goal': 'Muscle Gain',
      'tags': ['Lean Protein', 'Complex Carbs', 'Meal Prep'],
      'protein': 45, 'carbs': 70, 'fat': 15,
    },
    'Snack': {
      'fullItems': ['Whey protein (1 scoop)', 'Almond milk (300ml)', 'Banana (½)', 'Ice cubes'],
      'steps': [
        'Add almond milk to a blender.',
        'Add protein scoop and banana.',
        'Add a handful of ice cubes.',
        'Blend for 30 seconds until smooth.',
        'Drink within 30 minutes post-workout.',
      ],
      'prepTime': '3 min', 'goal': 'Recovery',
      'tags': ['Post-Workout', 'Fast Absorbing', 'Simple'],
      'protein': 25, 'carbs': 35, 'fat': 4,
    },
    'Dinner': {
      'fullItems': ['Salmon fillet (180g)', 'Sweet potato (150g)', 'Broccoli (100g)', 'Lemon (½)', 'Olive oil (1 tbsp)'],
      'steps': [
        'Preheat oven to 200°C. Cube sweet potato and roast for 25 min.',
        'Season salmon with lemon juice, salt and olive oil.',
        'Pan-sear salmon skin-down for 4 minutes, flip for 2 more.',
        'Steam broccoli while salmon cooks.',
        'Plate sweet potato, broccoli and salmon together.',
      ],
      'prepTime': '30 min', 'goal': 'Recovery',
      'tags': ['Omega-3', 'Anti-Inflammatory', 'Light'],
      'protein': 38, 'carbs': 48, 'fat': 14,
    },
    'Oatmeal Bowl': {
      'fullItems': ['Rolled oats (80g)', 'Whole milk (200ml)', 'Banana (1)', 'Honey (1 tsp)'],
      'steps': [
        'Bring milk to a gentle simmer in a saucepan.',
        'Add rolled oats and stir continuously for 4–5 minutes.',
        'Remove from heat and let stand for 1 minute to thicken.',
        'Top with sliced banana and drizzle honey.',
      ],
      'prepTime': '8 min', 'goal': 'General Health',
      'tags': ['High Carbs', 'Slow Release', 'Vegetarian'],
      'protein': 12, 'carbs': 58, 'fat': 6,
    },
    'Egg White Omelette': {
      'fullItems': ['Egg whites (4)', 'Spinach (handful)', 'Bell pepper (½)', 'Feta cheese (30g)', 'Olive oil (1 tsp)'],
      'steps': [
        'Whisk egg whites with a pinch of salt and pepper.',
        'Heat olive oil in a non-stick pan over medium heat.',
        'Add spinach and bell pepper, sauté for 2 minutes.',
        'Pour in egg whites and cook until edges set.',
        'Add feta, fold omelette, cook 1 more minute.',
      ],
      'prepTime': '12 min', 'goal': 'Fat Loss',
      'tags': ['Low Fat', 'High Protein', 'Cutting'],
      'protein': 30, 'carbs': 5, 'fat': 8,
    },
    'Avocado Toast': {
      'fullItems': ['Sourdough bread (2 slices)', 'Ripe avocado (1)', 'Eggs (2 poached)', 'Chilli flakes', 'Lemon juice (½)'],
      'steps': [
        'Toast sourdough slices until golden and firm.',
        'Mash avocado with lemon juice, salt and pepper.',
        'Spread avocado generously on each toast slice.',
        'Poach eggs for 3 minutes in simmering water.',
        'Place poached eggs on top, sprinkle chilli flakes.',
      ],
      'prepTime': '15 min', 'goal': 'General Health',
      'tags': ['Healthy Fats', 'Complex Carbs', 'Brunch'],
      'protein': 18, 'carbs': 38, 'fat': 22,
    },
    'Chicken Rice Bowl': {
      'fullItems': ['Chicken breast (180g)', 'White rice (150g)', 'Broccoli (100g)', 'Olive oil (1 tbsp)', 'Garlic (2 cloves)'],
      'steps': [
        'Season chicken with salt, pepper and garlic powder.',
        'Grill chicken for 6–7 min each side until cooked through.',
        'Steam broccoli for 5 minutes.',
        'Cook rice and fluff with a fork.',
        'Combine in a bowl and drizzle olive oil.',
      ],
      'prepTime': '25 min', 'goal': 'Muscle Gain',
      'tags': ['Lean Protein', 'Complex Carbs', 'Classic'],
      'protein': 45, 'carbs': 70, 'fat': 15,
    },
    'Tuna Pasta': {
      'fullItems': ['Whole wheat pasta (120g)', 'Canned tuna (1 tin)', 'Cherry tomatoes (100g)', 'Fresh basil', 'Olive oil (1 tbsp)'],
      'steps': [
        'Cook pasta in salted boiling water per packet instructions.',
        'Halve cherry tomatoes and sauté in olive oil for 3 minutes.',
        'Drain pasta and add to the pan with tomatoes.',
        'Flake in tuna and toss everything together.',
        'Tear in fresh basil and serve.',
      ],
      'prepTime': '20 min', 'goal': 'Lean Bulk',
      'tags': ['Omega-3', 'Whole Wheat', 'Quick'],
      'protein': 40, 'carbs': 65, 'fat': 10,
    },
    'Steak Salad': {
      'fullItems': ['Sirloin steak (200g)', 'Mixed greens (80g)', 'Cherry tomatoes (80g)', 'Blue cheese dressing (2 tbsp)', 'Red onion (¼)'],
      'steps': [
        'Season steak with salt, pepper and garlic.',
        'Sear on high heat 3 min each side for medium-rare.',
        'Rest steak for 5 minutes, then slice thinly.',
        'Arrange greens, tomatoes and onion in a bowl.',
        'Top with steak slices and drizzle dressing.',
      ],
      'prepTime': '20 min', 'goal': 'Fat Loss / Keto',
      'tags': ['Keto-Friendly', 'High Protein', 'Low Carb'],
      'protein': 48, 'carbs': 8, 'fat': 28,
    },
    'Protein Shake': {
      'fullItems': ['Whey protein (1 scoop)', 'Almond milk (300ml)', 'Banana (½)', 'Ice cubes'],
      'steps': [
        'Pour almond milk into blender.',
        'Add protein powder and banana.',
        'Drop in ice cubes.',
        'Blend 30 seconds until smooth and frothy.',
      ],
      'prepTime': '3 min', 'goal': 'Recovery',
      'tags': ['Post-Workout', 'Fast Absorbing'],
      'protein': 25, 'carbs': 20, 'fat': 3,
    },
    'Greek Yogurt + Nuts': {
      'fullItems': ['Greek yogurt (200g)', 'Mixed nuts (30g)', 'Honey (1 tsp)', 'Mixed berries (50g)'],
      'steps': [
        'Spoon Greek yogurt into a bowl.',
        'Scatter mixed nuts over the top.',
        'Add fresh or frozen berries.',
        'Drizzle honey to finish.',
      ],
      'prepTime': '3 min', 'goal': 'General Health',
      'tags': ['Probiotics', 'Healthy Fats', 'No Cook'],
      'protein': 18, 'carbs': 22, 'fat': 14,
    },
    'Rice Cake + Peanut Butter': {
      'fullItems': ['Rice cakes (3)', 'Natural peanut butter (2 tbsp)', 'Banana slices'],
      'steps': [
        'Lay rice cakes flat on a plate.',
        'Spread peanut butter evenly on each cake.',
        'Slice banana and layer on top.',
        'Optionally sprinkle with cinnamon.',
      ],
      'prepTime': '4 min', 'goal': 'Pre-Workout',
      'tags': ['Pre-Workout', 'Quick Energy', 'Simple'],
      'protein': 10, 'carbs': 42, 'fat': 12,
    },
    'Grilled Fish + Veg': {
      'fullItems': ['Salmon fillet (180g)', 'Sweet potato (150g)', 'Broccoli (100g)', 'Lemon (½)', 'Olive oil'],
      'steps': [
        'Roast sweet potato cubes at 200°C for 25 minutes.',
        'Season salmon with lemon, salt and olive oil.',
        'Pan-sear salmon 4 min skin-side down, flip 2 min.',
        'Steam broccoli for 5 minutes.',
        'Plate and squeeze remaining lemon over fish.',
      ],
      'prepTime': '30 min', 'goal': 'Recovery',
      'tags': ['Omega-3', 'Light', 'Anti-Inflammatory'],
      'protein': 38, 'carbs': 48, 'fat': 14,
    },
    'Chicken Stir-fry': {
      'fullItems': ['Chicken breast (180g)', 'Egg noodles (100g)', 'Mixed veg (150g)', 'Soy sauce (2 tbsp)', 'Sesame oil (1 tsp)'],
      'steps': [
        'Cook noodles as per packet, drain and set aside.',
        'Slice chicken into strips and stir-fry 5–6 minutes.',
        'Add mixed vegetables and cook 3 more minutes.',
        'Add noodles, soy sauce and sesame oil.',
        'Toss everything together on high heat for 1 minute.',
      ],
      'prepTime': '20 min', 'goal': 'Muscle Gain',
      'tags': ['High Protein', 'Asian Style', 'Quick'],
      'protein': 42, 'carbs': 55, 'fat': 12,
    },
    'Beef & Sweet Potato': {
      'fullItems': ['Lean beef mince (200g)', 'Sweet potato (180g)', 'Spinach (80g)', 'Garlic (3 cloves)', 'Olive oil'],
      'steps': [
        'Dice sweet potato and roast at 200°C for 25 minutes.',
        'Brown beef mince with garlic in olive oil, 8 minutes.',
        'Add spinach to the pan, wilt for 2 minutes.',
        'Combine mince mix with roasted sweet potato.',
        'Season and serve hot.',
      ],
      'prepTime': '30 min', 'goal': 'Muscle Gain',
      'tags': ['High Protein', 'Complex Carbs', 'Bulking'],
      'protein': 44, 'carbs': 52, 'fat': 18,
    },
  };
 
  Map<String, dynamic> get _extra {
    final name = (widget.meal['meal'] ?? widget.meal['name']) as String? ?? '';
    return _extendedData[name] ?? {
      'fullItems': [widget.meal['items'] ?? 'See ingredients list'],
      'steps': ['Prepare ingredients as listed.', 'Cook and serve.'],
      'prepTime': (widget.meal['prepTime'] as String?) ?? '20 min',
      'goal': (widget.meal['goal'] as String?) ?? 'General Health',
      'tags': ['Balanced'],
      'protein': (widget.meal['protein'] as int?) ?? 0,
      'carbs': (widget.meal['carbs'] as int?) ?? 0,
      'fat': (widget.meal['fat'] as int?) ?? 0,
    };
  }
 
  int get _calories => (widget.meal['calories'] as int?) ?? 0;
  int get _protein => (widget.meal['protein'] as int?) ?? (_extra['protein'] as int? ?? 0);
  int get _carbs => (widget.meal['carbs'] as int?) ?? (_extra['carbs'] as int? ?? 0);
  int get _fat => (widget.meal['fat'] as int?) ?? (_extra['fat'] as int? ?? 0);
 
  @override
  void initState() {
    super.initState();
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
 
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final textSecondary = isDark ? const Color(0xFFB0B0B0) : const Color(0xFF555555);
    final bgColor = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF0F2F5);
    final cardColor = isDark ? const Color(0xFF141414) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);
 
    return Scaffold(
      backgroundColor: bgColor,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Back button ────────────────────────────────────
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: textSecondary),
                        const SizedBox(width: 6),
                        Text('Back', style: TextStyle(fontSize: 13, color: textSecondary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildBody(
                    isDark: isDark,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    cardColor: cardColor,
                    borderColor: borderColor,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
 
  Widget _buildBody({
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color cardColor,
    required Color borderColor,
  }) {
    final meal = widget.meal;
    final color = meal['color'] as Color;
    final extra = _extra;
    final tags = extra['tags'] as List<dynamic>;
    final steps = extra['steps'] as List<dynamic>;
    final fullItems = extra['fullItems'] as List<dynamic>;
 
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Hero card ──────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: color.withOpacity(isDark ? 0.12 : 0.07),
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.15),
                  border: Border.all(color: color.withOpacity(0.4), width: 2),
                ),
                child: Center(
                  child: Text(meal['emoji'] as String, style: const TextStyle(fontSize: 30)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (meal['meal'] ?? meal['name']) as String? ?? '',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textPrimary),
                    ),
                    const SizedBox(height: 4),
                    if ((meal['desc'] as String?) != null)
                      Text(meal['desc'] as String,
                          style: TextStyle(fontSize: 12, color: textSecondary)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6, runSpacing: 4,
                      children: [
                        _buildTag('🎯 ${extra['goal']}', color),
                        _buildTag('⏱ ${extra['prepTime']}', AppColors.primary),
                        if ((meal['time'] as String?) != null)
                          _buildTag('🕐 ${meal['time']}', textSecondary),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
 
        // ── Macros ─────────────────────────────────────────────────
        Row(
          children: [
            _buildMacroCard('Calories', '$_calories', 'kcal', color, textPrimary, textSecondary),
            const SizedBox(width: 8),
            _buildMacroCard('Protein', '$_protein', 'g', const Color(0xFF2979FF), textPrimary, textSecondary),
            const SizedBox(width: 8),
            _buildMacroCard('Carbs', '$_carbs', 'g', const Color(0xFFFF6D00), textPrimary, textSecondary),
            const SizedBox(width: 8),
            _buildMacroCard('Fat', '$_fat', 'g', const Color(0xFFFFD600), textPrimary, textSecondary),
          ],
        ),
        const SizedBox(height: 16),
 
        // ── Tags ───────────────────────────────────────────────────
        Wrap(
          spacing: 8, runSpacing: 6,
          children: tags.map((t) => _buildTag(t as String, AppColors.primary)).toList(),
        ),
        const SizedBox(height: 20),
 
        // ── Ingredients ────────────────────────────────────────────
        _buildSectionHeader('🛒 Ingredients', textPrimary),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: cardColor,
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: fullItems.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(width: 8, height: 8,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(item as String,
                      style: TextStyle(fontSize: 13, color: textPrimary))),
                ],
              ),
            )).toList(),
          ),
        ),
        const SizedBox(height: 20),
 
        // ── Steps ──────────────────────────────────────────────────
        _buildSectionHeader('👨‍🍳 How to Prepare', textPrimary),
        const SizedBox(height: 10),
        ...steps.asMap().entries.map((entry) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: cardColor,
            border: Border.all(color: borderColor),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26, height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.15),
                  border: Border.all(color: color.withOpacity(0.4)),
                ),
                child: Center(
                  child: Text('${entry.key + 1}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(entry.value as String,
                  style: TextStyle(fontSize: 13, color: textSecondary))),
            ],
          ),
        )),
 
        // ── Nutrition tip ──────────────────────────────────────────
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: AppColors.primary.withOpacity(isDark ? 0.1 : 0.06),
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
                    const Text('Nutrition Tip',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                    const SizedBox(height: 3),
                    Text(
                      'Meal prep this on Sundays to stay consistent with your nutrition goals throughout the week.',
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }
 
  Widget _buildMacroCard(String label, String value, String unit, Color color,
      Color textPrimary, Color textSecondary) {
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
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(unit, style: TextStyle(fontSize: 9, color: textSecondary)),
            Text(label, style: TextStyle(fontSize: 9, color: textSecondary)),
          ],
        ),
      ),
    );
  }
 
  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }
 
  Widget _buildSectionHeader(String title, Color textPrimary) {
    return Text(title,
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textPrimary));
  }
}