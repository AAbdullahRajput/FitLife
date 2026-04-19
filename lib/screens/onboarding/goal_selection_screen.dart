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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050A05),
      body: Stack(
        children: [
          // Background glow
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
                    (_selectedGoal != null
                            ? _goals
                                .firstWhere((g) => g.title == _selectedGoal)
                                .color
                            : AppColors.primary)
                        .withOpacity(0.08),
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

                    // Progress bar
                    _buildProgressBar(2, 3),

                    const SizedBox(height: 32),

                    // Title
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

                    // Goal cards
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
                                  // Emoji circle
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

                                  // Text
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

                                  // Check icon
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
                                        ? const Icon(
                                            Icons.check,
                                            size: 14,
                                            color: Colors.white,
                                          )
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

                    // Continue button
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
                                    _goals
                                        .firstWhere(
                                            (g) => g.title == _selectedGoal)
                                        .color,
                                    _goals
                                        .firstWhere(
                                            (g) => g.title == _selectedGoal)
                                        .color
                                        .withOpacity(0.7),
                                  ]
                                : [
                                    AppColors.surface,
                                    AppColors.surface,
                                  ],
                          ),
                          boxShadow: _selectedGoal != null
                              ? [
                                  BoxShadow(
                                    color: _goals
                                        .firstWhere(
                                            (g) => g.title == _selectedGoal)
                                        .color
                                        .withOpacity(0.4),
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