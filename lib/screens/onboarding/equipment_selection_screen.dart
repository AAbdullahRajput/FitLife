import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_constants.dart';
import '../../services/storage_service.dart';

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pre-cache all equipment bg images so they appear instantly on web
    for (final eq in _equipments) {
      precacheImage(NetworkImage(eq.bgImage), context);
    }
    precacheImage(
      const NetworkImage(
          'https://images.unsplash.com/photo-1571902943202-507ec2618e8f?w=1200&q=80'),
      context,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _continue() async {
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

    await StorageService.saveUserInfo(
      name: 'Abdullah',
      age: 24,
      weight: 75.0,
      height: 175.0,
      gender: 'Male',
      goal: 'Build Muscle',
      equipment: _selectedEquipment!,
    );

    Navigator.pushReplacementNamed(context, '/home');
  }

  Color get _accentColor => _selectedEquipment != null
      ? _equipments.firstWhere((e) => e.title == _selectedEquipment).color
      : AppColors.primary;

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 600;
    return isWeb ? _buildWebLayout() : _buildMobileLayout();
  }

  // ═══════════════════════════════════════════════════════
  // WEB LAYOUT — left = decorative panel, right = cards
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
                // Background image — switches to selected equipment image
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: Image.network(
                    _selectedEquipment != null
                        ? _equipments
                            .firstWhere((e) => e.title == _selectedEquipment)
                            .bgImage
                            .replaceAll('w=600', 'w=1200')
                        : 'https://images.unsplash.com/photo-1571902943202-507ec2618e8f?w=1200&q=80',
                    key: ValueKey(_selectedEquipment ?? 'default'),
                    fit: BoxFit.cover,
                    frameBuilder:
                        (ctx, child, frame, wasSynchronouslyLoaded) {
                      if (wasSynchronouslyLoaded || frame != null) return child;
                      return Container(color: const Color(0xFF0A1A0A));
                    },
                    errorBuilder: (c, e, s) =>
                        Container(color: const Color(0xFF030806)),
                  ),
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
                // Animated color tint based on selection
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        _accentColor.withOpacity(0.3),
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
                            'STEP 3 OF 3  ·  YOUR SETUP',
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
                        'Choose Your\nTraining Setup',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Your equipment determines\nthe exercises we build for you.',
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
                          _webChip('🏠', 'Any location'),
                          _webChip('⚙️', 'Fully tailored'),
                          _webChip('🚀', 'Ready instantly'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Right: equipment selection card ───────────────────────
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
                          _buildProgressBar(3, 3),
                          const SizedBox(height: 32),
                          Text(
                            AppStrings.equipmentTitle,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            AppStrings.equipmentSubtitle,
                            style: TextStyle(
                              fontSize: 13,
                              color:
                                  AppColors.textSecondary.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Equipment cards — web uses fixed list (no Expanded)
                          ...List.generate(_equipments.length, (index) {
                            final eq = _equipments[index];
                            final isSelected =
                                _selectedEquipment == eq.title;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: GestureDetector(
                                onTap: () => setState(
                                    () => _selectedEquipment = eq.title),
                                child: AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 300),
                                  height: 160,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: isSelected
                                          ? eq.color
                                          : AppColors.border,
                                      width: isSelected ? 2.5 : 1,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color:
                                                  eq.color.withOpacity(0.3),
                                              blurRadius: 20,
                                              spreadRadius: 2,
                                            )
                                          ]
                                        : [],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        // Background image with frameBuilder
                                        Image.network(
                                          eq.bgImage,
                                          fit: BoxFit.cover,
                                          opacity: AlwaysStoppedAnimation(
                                              isSelected ? 0.4 : 0.25),
                                          frameBuilder: (ctx, child, frame,
                                              wasSynchronouslyLoaded) {
                                            if (wasSynchronouslyLoaded ||
                                                frame != null) return child;
                                            return Container(
                                                color: const Color(
                                                    0xFF0E1A0E));
                                          },
                                          errorBuilder: (c, e, s) =>
                                              Container(
                                                  color: const Color(
                                                      0xFF0E1A0E)),
                                        ),
                                        // Color gradient overlay
                                        Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                              colors: [
                                                eq.color.withOpacity(
                                                    isSelected ? 0.35 : 0.12),
                                                Colors.transparent,
                                              ],
                                            ),
                                          ),
                                        ),
                                        // Content
                                        Padding(
                                          padding: const EdgeInsets.all(20),
                                          child: Row(
                                            children: [
                                              // Left: emoji + text + tags
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .start,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .center,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Text(
                                                          eq.emoji,
                                                          style:
                                                              const TextStyle(
                                                                  fontSize:
                                                                      26),
                                                        ),
                                                        const SizedBox(
                                                            width: 10),
                                                        Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              eq.title,
                                                              style:
                                                                  TextStyle(
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w800,
                                                                color: isSelected
                                                                    ? eq.color
                                                                    : AppColors
                                                                        .textPrimary,
                                                              ),
                                                            ),
                                                            Text(
                                                              eq.subtitle,
                                                              style:
                                                                  TextStyle(
                                                                fontSize: 10,
                                                                color: eq.color
                                                                    .withOpacity(
                                                                        0.7),
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                letterSpacing:
                                                                    1,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 12),
                                                    Wrap(
                                                      spacing: 6,
                                                      runSpacing: 6,
                                                      children: eq.features
                                                          .map(
                                                            (f) => Container(
                                                              padding: const EdgeInsets
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
                                                                style:
                                                                    TextStyle(
                                                                  fontSize:
                                                                      10,
                                                                  color:
                                                                      eq.color,
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
                                                        : AppColors
                                                            .borderLight,
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
                              ),
                            );
                          }),

                          const SizedBox(height: 4),

                          // Let's Go button
                          GestureDetector(
                            onTap: _continue,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: double.infinity,
                              height: 52,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: LinearGradient(
                                  colors: _selectedEquipment != null
                                      ? [
                                          _accentColor,
                                          _accentColor.withOpacity(0.75),
                                        ]
                                      : [
                                          AppColors.surface,
                                          AppColors.surface,
                                        ],
                                ),
                                boxShadow: _selectedEquipment != null
                                    ? [
                                        BoxShadow(
                                          color:
                                              _accentColor.withOpacity(0.35),
                                          blurRadius: 20,
                                          spreadRadius: 1,
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
            bottom: -100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _accentColor.withOpacity(0.07),
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
                    _buildProgressBar(3, 3),
                    const SizedBox(height: 32),
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
                                    Image.network(
                                      eq.bgImage,
                                      fit: BoxFit.cover,
                                      opacity: AlwaysStoppedAnimation(
                                          isSelected ? 0.35 : 0.2),
                                      frameBuilder: (ctx, child, frame,
                                          wasSynchronouslyLoaded) {
                                        if (wasSynchronouslyLoaded ||
                                            frame != null) return child;
                                        return Container(
                                            color: AppColors.surface);
                                      },
                                      errorBuilder: (c, e, s) => Container(
                                          color: AppColors.surface),
                                    ),
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
                                    Padding(
                                      padding: const EdgeInsets.all(18),
                                      child: Row(
                                        children: [
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
                                    _accentColor,
                                    _accentColor.withOpacity(0.7),
                                  ]
                                : [AppColors.surface, AppColors.surface],
                          ),
                          boxShadow: _selectedEquipment != null
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