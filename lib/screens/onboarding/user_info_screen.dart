import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/helpers.dart';

class UserInfoScreen extends StatefulWidget {
  const UserInfoScreen({super.key});

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;

  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  String _selectedGender = 'Male';

  final _formKey = GlobalKey<FormState>();

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
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _continue() {
    if (_formKey.currentState!.validate()) {
      Navigator.pushReplacementNamed(context, '/goal-selection');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050A05),
      body: Stack(
        children: [
          // Background glow
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.08),
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppConstants.paddingLG),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // Progress indicator
                      _buildProgressBar(1, 3),

                      const SizedBox(height: 32),

                      // Title
                      Text(
                        AppStrings.userInfoTitle,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppStrings.userInfoSubtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary.withOpacity(0.7),
                        ),
                      ),

                      const SizedBox(height: 36),

                      // Gender selector
                      _buildSectionLabel('Gender'),
                      const SizedBox(height: 10),
                      _buildGenderSelector(),

                      const SizedBox(height: 24),

                      // Age
                      _buildSectionLabel(AppStrings.labelAge),
                      const SizedBox(height: 10),
                      _buildInputField(
                        controller: _ageController,
                        hint: AppStrings.hintAge,
                        suffix: 'yrs',
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return AppStrings.errorEmpty;
                          }
                          if (!Helpers.isValidAge(val)) {
                            return 'Enter a valid age (10-100)';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      // Weight & Height side by side
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionLabel(AppStrings.labelWeight),
                                const SizedBox(height: 10),
                                _buildInputField(
                                  controller: _weightController,
                                  hint: '70',
                                  suffix: 'kg',
                                  keyboardType: TextInputType.number,
                                  validator: (val) {
                                    if (val == null || val.isEmpty) {
                                      return AppStrings.errorEmpty;
                                    }
                                    if (!Helpers.isValidWeight(val)) {
                                      return 'Invalid weight';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionLabel(AppStrings.labelHeight),
                                const SizedBox(height: 10),
                                _buildInputField(
                                  controller: _heightController,
                                  hint: '175',
                                  suffix: 'cm',
                                  keyboardType: TextInputType.number,
                                  validator: (val) {
                                    if (val == null || val.isEmpty) {
                                      return AppStrings.errorEmpty;
                                    }
                                    if (!Helpers.isValidHeight(val)) {
                                      return 'Invalid height';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // BMI preview
                      _buildBMIPreview(),

                      const SizedBox(height: 32),

                      // Continue button
                      GestureDetector(
                        onTap: _continue,
                        child: Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF5EFC82),
                                Color(0xFF00C853),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.4),
                                blurRadius: 20,
                                spreadRadius: 2,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              AppStrings.btnContinue,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
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

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Row(
      children: ['Male', 'Female'].map((gender) {
        final isSelected = _selectedGender == gender;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedGender = gender),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: EdgeInsets.only(
                right: gender == 'Male' ? 8 : 0,
                left: gender == 'Female' ? 8 : 0,
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: isSelected
                    ? AppColors.primary.withOpacity(0.15)
                    : AppColors.surface,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.border,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.2),
                          blurRadius: 12,
                          spreadRadius: 1,
                        )
                      ]
                    : [],
              ),
              child: Column(
                children: [
                  Text(
                    gender == 'Male' ? '👨' : '👩',
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    gender,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required String suffix,
    required TextInputType keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hint,
        suffixText: suffix,
        suffixStyle: TextStyle(
          color: AppColors.primary.withOpacity(0.8),
          fontWeight: FontWeight.w600,
        ),
      ),
      validator: validator,
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildBMIPreview() {
    final weight = double.tryParse(_weightController.text);
    final height = double.tryParse(_heightController.text);

    if (weight == null || height == null || height == 0) {
      return const SizedBox.shrink();
    }

    final bmi = Helpers.calculateBMI(weight, height);
    final category = Helpers.getBMICategory(bmi);

    Color bmiColor;
    if (bmi < 18.5) {
      bmiColor = AppColors.accentBlue;
    } else if (bmi < 25) {
      bmiColor = AppColors.primary;
    } else if (bmi < 30) {
      bmiColor = AppColors.warning;
    } else {
      bmiColor = AppColors.error;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: bmiColor.withOpacity(0.08),
        border: Border.all(color: bmiColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bmiColor.withOpacity(0.15),
            ),
            child: Center(
              child: Text(
                bmi.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: bmiColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your BMI',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textHint.withOpacity(0.6),
                ),
              ),
              Text(
                category,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: bmiColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}