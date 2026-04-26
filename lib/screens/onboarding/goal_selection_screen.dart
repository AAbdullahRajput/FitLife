import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_constants.dart';

class GoalSelectionScreen extends StatefulWidget {
  const GoalSelectionScreen({super.key});

  @override
  State<GoalSelectionScreen> createState() => _GoalSelectionScreenState();
}

class _GoalSelectionScreenState extends State<GoalSelectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;

  String? _selectedGoal;

  final List<GoalData> _goals = [
    GoalData(
      title: 'Lose Weight',
      description: 'Burn fat and get lean',
      emoji: '🔥',
      color: const Color(0xFFFF6D00),
    ),
    GoalData(
      title: 'Build Muscle',
      description: 'Gain strength and size',
      emoji: '💪',
      color: const Color(0xFF2979FF),
    ),
    GoalData(
      title: 'Stay Fit',
      description: 'Maintain a healthy body',
      emoji: '⚡',
      color: const Color(0xFF00C853),
    ),
    GoalData(
      title: 'Increase Strength',
      description: 'Lift heavier, get stronger',
      emoji: '🏋️',
      color: const Color(0xFFAA00FF),
    ),
    GoalData(
      title: 'Improve Endurance',
      description: 'Run longer, last harder',
      emoji: '🏃',
      color: const Color(0xFFFFD600),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );
    _slideAnim = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(
      const NetworkImage(
          'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=1200&q=80'),
      context,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _continue() {
    if (_selectedGoal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a goal'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }
    Navigator.pushReplacementNamed(context, '/equipment-selection');
  }

  Color get _accentColor => _selectedGoal != null
      ? _goals.firstWhere((g) => g.title == _selectedGoal).color
      : AppColors.primary;

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 600;
    return isWeb ? _buildWebLayout() : _buildMobileLayout();
  }

  // ═══════════════════════════════════════════════════════
  // WEB LAYOUT — left = decorative panel, right = goal list
  // ═══════════════════════════════════════════════════════
  Widget _buildWebLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFF030806),
      body: Row(
        children: [
          // ── Left decorative panel ──────────────────────────────────
          Expanded(
            flex: 45,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=1200&q=80',
                  fit: BoxFit.cover,
                  frameBuilder: (ctx, child, frame, wasSynchronouslyLoaded) {
                    if (wasSynchronouslyLoaded || frame != null) return child;
                    return Container(color: const Color(0xFF0A1A0A));
                  },
                  errorBuilder: (c, e, s) =>
                      Container(color: const Color(0xFF030806)),
                ),
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [
                        const Color(0xFF030806),
                        Colors.transparent,
                        Colors.transparent,
                        const Color(0xFF030806).withOpacity(0.4),
                      ],
                      stops: const [0.0, 0.15, 0.7, 1.0],
                    ),
                  ),
                ),
                // Color tint based on selected goal
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        _accentColor.withOpacity(0.25),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                // Grid painter
                CustomPaint(painter: _WebGridPainter(_accentColor)),
                // Bottom content on image
                Positioned(
                  bottom: 48,
                  left: 40,
                  right: 40,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _accentColor,
                              boxShadow: [
                                BoxShadow(
                                  color: _accentColor.withOpacity(0.6),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'STEP 2 OF 3  ·  YOUR GOAL',
                            style: TextStyle(
                              fontSize: 11,
                              color: _accentColor,
                              letterSpacing: 2.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'What Do You\nWant to Achieve?',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Your goal shapes every workout,\nevery rep, every session.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.6),
                          height: 1.65,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _webChip('🎯', 'Goal-driven'),
                          _webChip('📈', 'Progress tracked'),
                          _webChip('🔄', 'Adapts to you'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Right: goal selection card ─────────────────────────────
          Expanded(
            flex: 55,
            child: Container(
              color: const Color(0xFF030806),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 48, vertical: 40),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: AnimatedBuilder(
                      animation: _animController,
                      builder: (_, child) => FadeTransition(
                        opacity: _fadeAnim,
                        child: Transform.translate(
                          offset: Offset(0, _slideAnim.value),
                          child: child,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProgressBar(2, 3),
                          const SizedBox(height: 32),
                          Text(
                            AppStrings.goalTitle,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            AppStrings.goalSubtitle,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Goal cards — web uses a fixed list, no Expanded
                          ...List.generate(_goals.length, (index) {
                            final goal = _goals[index];
                            final isSelected = _selectedGoal == goal.title;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: GestureDetector(
                                onTap: () => setState(
                                    () => _selectedGoal = goal.title),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    color: isSelected
                                        ? goal.color.withOpacity(0.12)
                                        : const Color(0xFF0E1A0E),
                                    border: Border.all(
                                      color: isSelected
                                          ? goal.color
                                          : AppColors.border,
                                      width: isSelected ? 2 : 1,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color:
                                                  goal.color.withOpacity(0.2),
                                              blurRadius: 16,
                                              spreadRadius: 1,
                                            )
                                          ]
                                        : [],
                                  ),
                                  child: Row(
                                    children: [
                                      // Emoji circle
                                      AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 250),
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: goal.color.withOpacity(
                                              isSelected ? 0.2 : 0.08),
                                        ),
                                        child: Center(
                                          child: Text(
                                            goal.emoji,
                                            style: const TextStyle(
                                                fontSize: 22),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      // Text
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              goal.title,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: isSelected
                                                    ? goal.color
                                                    : AppColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              goal.description,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary
                                                    .withOpacity(0.55),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Check icon
                                      AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 250),
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isSelected
                                              ? goal.color
                                              : Colors.transparent,
                                          border: Border.all(
                                            color: isSelected
                                                ? goal.color
                                                : AppColors.borderLight,
                                            width: 2,
                                          ),
                                        ),
                                        child: isSelected
                                            ? const Icon(Icons.check,
                                                size: 13, color: Colors.white)
                                            : null,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),

                          const SizedBox(height: 8),

                          // Continue button
                          GestureDetector(
                            onTap: _continue,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: double.infinity,
                              height: 52,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: LinearGradient(
                                  colors: _selectedGoal != null
                                      ? [
                                          _accentColor,
                                          _accentColor.withOpacity(0.75),
                                        ]
                                      : [
                                          AppColors.surface,
                                          AppColors.surface,
                                        ],
                                ),
                                boxShadow: _selectedGoal != null
                                    ? [
                                        BoxShadow(
                                          color: _accentColor.withOpacity(0.35),
                                          blurRadius: 20,
                                          spreadRadius: 1,
                                          offset: const Offset(0, 6),
                                        )
                                      ]
                                    : [],
                              ),
                              child: Center(
                                child: Text(
                                  AppStrings.btnContinue,
                                  style: TextStyle(
                                    color: _selectedGoal != null
                                        ? Colors.black
                                        : AppColors.textHint,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _webChip(String emoji, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.08),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // MOBILE LAYOUT — original unchanged
  // ═══════════════════════════════════════════════════════
  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFF050A05),
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _accentColor.withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnim,
                  child: Transform.translate(
                    offset: Offset(0, _slideAnim.value),
                    child: child,
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingLG),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildProgressBar(2, 3),
                    const SizedBox(height: 32),
                    Text(
                      AppStrings.goalTitle,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.goalSubtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Expanded(
                      child: ListView.separated(
                        itemCount: _goals.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final goal = _goals[index];
                          final isSelected = _selectedGoal == goal.title;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedGoal = goal.title),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: isSelected
                                    ? goal.color.withOpacity(0.12)
                                    : AppColors.surface,
                                border: Border.all(
                                  color: isSelected
                                      ? goal.color
                                      : AppColors.border,
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: goal.color.withOpacity(0.25),
                                          blurRadius: 16,
                                          spreadRadius: 1,
                                        )
                                      ]
                                    : [],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: goal.color.withOpacity(
                                          isSelected ? 0.2 : 0.08),
                                    ),
                                    child: Center(
                                      child: Text(
                                        goal.emoji,
                                        style:
                                            const TextStyle(fontSize: 24),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          goal.title,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: isSelected
                                                ? goal.color
                                                : AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          goal.description,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textSecondary
                                                .withOpacity(0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 250),
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? goal.color
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: isSelected
                                            ? goal.color
                                            : AppColors.borderLight,
                                        width: 2,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Icon(Icons.check,
                                            size: 14, color: Colors.white)
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _continue,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: _selectedGoal != null
                                ? [
                                    _accentColor,
                                    _accentColor.withOpacity(0.7),
                                  ]
                                : [AppColors.surface, AppColors.surface],
                          ),
                          boxShadow: _selectedGoal != null
                              ? [
                                  BoxShadow(
                                    color: _accentColor.withOpacity(0.4),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 6),
                                  )
                                ]
                              : [],
                        ),
                        child: Center(
                          child: Text(
                            AppStrings.btnContinue,
                            style: TextStyle(
                              color: _selectedGoal != null
                                  ? Colors.black
                                  : AppColors.textHint,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared widgets ──────────────────────────────────────────────────────────
  Widget _buildProgressBar(int current, int total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step $current of $total',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textHint.withOpacity(0.6),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 3,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: AppColors.border,
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: current / total,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: const LinearGradient(
                  colors: [Color(0xFF5EFC82), Color(0xFF00C853)],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class GoalData {
  final String title;
  final String description;
  final String emoji;
  final Color color;

  GoalData({
    required this.title,
    required this.description,
    required this.emoji,
    required this.color,
  });
}

// ── Web grid painter ─────────────────────────────────────────────────────────
class _WebGridPainter extends CustomPainter {
  final Color color;
  _WebGridPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.03)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WebGridPainter old) => old.color != color;
}