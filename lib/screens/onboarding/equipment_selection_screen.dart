import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_constants.dart';

class EquipmentSelectionScreen extends StatefulWidget {
  const EquipmentSelectionScreen({super.key});

  @override
  State<EquipmentSelectionScreen> createState() =>
      _EquipmentSelectionScreenState();
}

class _EquipmentSelectionScreenState extends State<EquipmentSelectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;

  String? _selectedEquipment;

  final List<EquipmentData> _equipments = [
    EquipmentData(
      title: 'No Equipment',
      subtitle: 'Home',
      description: 'Bodyweight exercises only\nNo gym needed',
      emoji: '🏠',
      color: const Color(0xFF00C853),
      bgImage:
          'https://images.unsplash.com/photo-1599058945522-28d584b6f0ff?w=600&q=80',
      features: ['Push-ups', 'Squats', 'Planks', 'Burpees'],
    ),
    EquipmentData(
      title: 'Full Gym',
      subtitle: 'Gym',
      description: 'Full access to machines\nand free weights',
      emoji: '🏋️',
      color: const Color(0xFF2979FF),
      bgImage:
          'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=600&q=80',
      features: ['Barbells', 'Machines', 'Cables', 'Dumbbells'],
    ),
    EquipmentData(
      title: 'Home with Dumbbells',
      subtitle: 'Home + Weights',
      description: 'Dumbbells and basic\nhome equipment',
      emoji: '🥊',
      color: const Color(0xFFFF6D00),
      bgImage:
          'https://images.unsplash.com/photo-1574680096145-d05b474e2155?w=600&q=80',
      features: ['Dumbbells', 'Resistance bands', 'Pull-up bar', 'Bench'],
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
    if (_selectedEquipment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select your equipment'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050A05),
      body: Stack(
        children: [
          // Background glow
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (_selectedEquipment != null
                            ? _equipments
                                .firstWhere(
                                    (e) => e.title == _selectedEquipment)
                                .color
                            : AppColors.primary)
                        .withOpacity(0.07),
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
                    _buildProgressBar(3, 3),

                    const SizedBox(height: 32),

                    // Title
                    Text(
                      AppStrings.equipmentTitle,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.equipmentSubtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary.withOpacity(0.7),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Equipment cards
                    Expanded(
                      child: ListView.separated(
                        itemCount: _equipments.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final eq = _equipments[index];
                          final isSelected = _selectedEquipment == eq.title;

                          return GestureDetector(
                            onTap: () => setState(
                                () => _selectedEquipment = eq.title),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              height: 150,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? eq.color
                                      : AppColors.border,
                                  width: isSelected ? 2.5 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: eq.color.withOpacity(0.3),
                                          blurRadius: 20,
                                          spreadRadius: 2,
                                        )
                                      ]
                                    : [],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    // Background image
                                    Image.network(
                                      eq.bgImage,
                                      fit: BoxFit.cover,
                                      opacity: AlwaysStoppedAnimation(
                                          isSelected ? 0.35 : 0.2),
                                      errorBuilder: (c, e, s) => Container(
                                          color: AppColors.surface),
                                    ),

                                    // Color overlay
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                          colors: [
                                            eq.color.withOpacity(
                                                isSelected ? 0.3 : 0.1),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                    ),

                                    // Content
                                    Padding(
                                      padding: const EdgeInsets.all(18),
                                      child: Row(
                                        children: [
                                          // Left: emoji + text
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      eq.emoji,
                                                      style: const TextStyle(
                                                          fontSize: 28),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          eq.title,
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.w800,
                                                            color: isSelected
                                                                ? eq.color
                                                                : AppColors
                                                                    .textPrimary,
                                                          ),
                                                        ),
                                                        Text(
                                                          eq.subtitle,
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color: eq.color
                                                                .withOpacity(
                                                                    0.7),
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            letterSpacing: 1,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 10),
                                                // Feature tags
                                                Wrap(
                                                  spacing: 6,
                                                  runSpacing: 6,
                                                  children: eq.features
                                                      .map(
                                                        (f) => Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                            horizontal: 8,
                                                            vertical: 3,
                                                          ),
                                                          decoration:
                                                              BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        6),
                                                            color: eq.color
                                                                .withOpacity(
                                                                    0.15),
                                                          ),
                                                          child: Text(
                                                            f,
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              color: eq.color,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                        ),
                                                      )
                                                      .toList(),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Check circle
                                          AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 250),
                                            width: 28,
                                            height: 28,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: isSelected
                                                  ? eq.color
                                                  : Colors.transparent,
                                              border: Border.all(
                                                color: isSelected
                                                    ? eq.color
                                                    : AppColors.borderLight,
                                                width: 2,
                                              ),
                                            ),
                                            child: isSelected
                                                ? const Icon(
                                                    Icons.check,
                                                    size: 16,
                                                    color: Colors.white,
                                                  )
                                                : null,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
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
                            colors: _selectedEquipment != null
                                ? [
                                    _equipments
                                        .firstWhere((e) =>
                                            e.title == _selectedEquipment)
                                        .color,
                                    _equipments
                                        .firstWhere((e) =>
                                            e.title == _selectedEquipment)
                                        .color
                                        .withOpacity(0.7),
                                  ]
                                : [AppColors.surface, AppColors.surface],
                          ),
                          boxShadow: _selectedEquipment != null
                              ? [
                                  BoxShadow(
                                    color: _equipments
                                        .firstWhere((e) =>
                                            e.title == _selectedEquipment)
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
                            "Let's Go! 🚀",
                            style: TextStyle(
                              color: _selectedEquipment != null
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

class EquipmentData {
  final String title;
  final String subtitle;
  final String description;
  final String emoji;
  final Color color;
  final String bgImage;
  final List<String> features;

  EquipmentData({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.emoji,
    required this.color,
    required this.bgImage,
    required this.features,
  });
}