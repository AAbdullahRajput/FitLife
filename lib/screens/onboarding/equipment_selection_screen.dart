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
      description: 'Bodyweight exercises only. No gym needed — train anywhere.',
      emoji: '🏠',
      color: const Color(0xFF00C853),
      bgImage:
          'https://images.unsplash.com/photo-1599058945522-28d584b6f0ff?w=1200&q=80',
      features: ['Push-ups', 'Squats', 'Planks', 'Burpees'],
    ),
    EquipmentData(
      title: 'Full Gym',
      subtitle: 'Gym',
      description: 'Full access to machines and free weights for max results.',
      emoji: '🏋️',
      color: const Color(0xFF2979FF),
      bgImage:
          'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=1200&q=80',
      features: ['Barbells', 'Machines', 'Cables', 'Dumbbells'],
    ),
    EquipmentData(
      title: 'Home + Weights',
      subtitle: 'Dumbbells',
      description: 'Dumbbells and basic home equipment for a solid home gym.',
      emoji: '🥊',
      color: const Color(0xFFFF6D00),
      bgImage:
          'https://images.unsplash.com/photo-1574680096145-d05b474e2155?w=1200&q=80',
      features: ['Dumbbells', 'Resistance bands', 'Pull-up bar', 'Bench'],
    ),
  ];

  int _hoveredIndex = -1;

  // Default bg — unique, not shared with any equipment image
  static const String _defaultBg =
      'https://images.unsplash.com/photo-1571902943202-507ec2618e8f?w=1200&q=80';

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
    for (final eq in _equipments) {
      precacheImage(NetworkImage(eq.bgImage), context);
    }
    precacheImage(const NetworkImage(_defaultBg), context);
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

  EquipmentData? get _activeEquipment => _selectedEquipment != null
      ? _equipments.firstWhere((e) => e.title == _selectedEquipment)
      : (_hoveredIndex >= 0 ? _equipments[_hoveredIndex] : null);

  // Key based on title, NOT image URL — prevents duplicate key crash
  String get _activeBgKey => _activeEquipment?.title ?? '__default__';
  String get _activeBgImage => _activeEquipment?.bgImage ?? _defaultBg;

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 600;
    return isWeb ? _buildWebLayout() : _buildMobileLayout();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WEB LAYOUT
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildWebLayout() {
    final active = _activeEquipment;

    return Scaffold(
      backgroundColor: const Color(0xFF030806),
      extendBodyBehindAppBar: true,
      body: Row(
        children: [
          // ── Left: full-height IMAGE SHOWCASE panel ─────────────────────────
          Expanded(
            flex: 52,
            child: ClipRect(
              child: Container(
                color: const Color(0xFF030806),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Main background — switches based on hover/selection
                    // KEY FIX: ValueKey uses title, not image URL
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      child: SizedBox.expand(
                        key: ValueKey(_activeBgKey),
                        child: Image.network(
                          _activeBgImage,
                          fit: BoxFit.fitHeight,
                          alignment: Alignment.center,
                          frameBuilder:
                              (ctx, child, frame, wasSynchronouslyLoaded) {
                            if (wasSynchronouslyLoaded || frame != null) return child;
                            return Container(color: const Color(0xFF0A1A0A));
                          },
                          errorBuilder: (c, e, s) =>
                              Container(color: const Color(0xFF030806)),
                        ),
                      ),
                    ),

                    // Gradient — blends right edge into dark right panel
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                          colors: [
                            const Color(0xFF030806),
                            Colors.transparent,
                            Colors.transparent,
                            const Color(0xFF030806).withOpacity(0.35),
                          ],
                          stops: const [0.0, 0.12, 0.72, 1.0],
                        ),
                      ),
                    ),

                    // Animated accent tint from bottom
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 450),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            (active?.color ?? AppColors.primary).withOpacity(0.45),
                            (active?.color ?? AppColors.primary).withOpacity(0.0),
                          ],
                          stops: const [0.0, 0.6],
                        ),
                      ),
                    ),

                    // Grid overlay
                    CustomPaint(
                        painter: _WebGridPainter(
                            active?.color ?? AppColors.primary)),

                    // ── Bottom info overlay on the image ──────────────────────────
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        child: Container(
                          key: ValueKey('overlay_${active?.title ?? '__default__'}'),
                          padding: const EdgeInsets.fromLTRB(40, 40, 40, 48),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.85),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Step badge
                              Row(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 400),
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: active?.color ?? AppColors.primary,
                                      boxShadow: [
                                        BoxShadow(
                                          color: (active?.color ?? AppColors.primary)
                                              .withOpacity(0.7),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'STEP 3 OF 3  ·  YOUR SETUP',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: active?.color ?? AppColors.primary,
                                      letterSpacing: 2.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // Active equipment name — big display text
                              if (active != null) ...[
                                Text(
                                  active.emoji,
                                  style: const TextStyle(fontSize: 40),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  active.title,
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  active.description,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.7),
                                    height: 1.6,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Feature chips
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: active.features
                                      .map((f) => Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              color: active.color.withOpacity(0.2),
                                              border: Border.all(
                                                  color: active.color
                                                      .withOpacity(0.5)),
                                            ),
                                            child: Text(
                                              f,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: active.color,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ))
                                      .toList(),
                                ),
                              ] else ...[
                                const Text(
                                  'Choose Your\nTraining Setup',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Hover or select an option to preview\nyour training environment.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.55),
                                    height: 1.65,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Right: selection cards ─────────────────────────────────────────
          Expanded(
            flex: 48,
            child: Container(
              color: const Color(0xFF030806),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 44, vertical: 40),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
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
                              color: AppColors.textSecondary.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 28),

                          // ── Equipment cards ──
                          ...List.generate(_equipments.length, (index) {
                            final eq = _equipments[index];
                            final isSelected = _selectedEquipment == eq.title;
                            final isHovered = _hoveredIndex == index;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: MouseRegion(
                                onEnter: (_) =>
                                    setState(() => _hoveredIndex = index),
                                onExit: (_) =>
                                    setState(() => _hoveredIndex = -1),
                                child: GestureDetector(
                                  onTap: () => setState(
                                      () => _selectedEquipment = eq.title),
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 300),
                                    height: 175,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected
                                            ? eq.color
                                            : (isHovered
                                                ? eq.color.withOpacity(0.5)
                                                : AppColors.border),
                                        width: isSelected ? 2.5 : 1.5,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color:
                                                    eq.color.withOpacity(0.35),
                                                blurRadius: 28,
                                                spreadRadius: 2,
                                              )
                                            ]
                                          : (isHovered
                                              ? [
                                                  BoxShadow(
                                                    color: eq.color
                                                        .withOpacity(0.15),
                                                    blurRadius: 16,
                                                  )
                                                ]
                                              : []),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(18),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          // Real background photo
                                          Image.network(
                                            eq.bgImage,
                                            fit: BoxFit.cover,
                                            alignment: Alignment.center,
                                            opacity: AlwaysStoppedAnimation(
                                                isSelected
                                                    ? 0.55
                                                    : (isHovered ? 0.45 : 0.3)),
                                            frameBuilder: (ctx, child, frame,
                                                wasSynchronouslyLoaded) {
                                              if (wasSynchronouslyLoaded ||
                                                  frame != null) return child;
                                              return Container(
                                                  color: const Color(0xFF0E1A0E));
                                            },
                                            errorBuilder: (c, e, s) =>
                                                Container(
                                                    color:
                                                        const Color(0xFF0E1A0E)),
                                          ),

                                          // Dark gradient for readability
                                          Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.centerRight,
                                                end: Alignment.centerLeft,
                                                colors: [
                                                  Colors.black.withOpacity(
                                                      isSelected ? 0.45 : 0.6),
                                                  Colors.black.withOpacity(
                                                      isSelected ? 0.15 : 0.35),
                                                ],
                                              ),
                                            ),
                                          ),

                                          // Accent tint overlay
                                          AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 300),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.bottomLeft,
                                                end: Alignment.topRight,
                                                colors: [
                                                  eq.color.withOpacity(
                                                      isSelected
                                                          ? 0.4
                                                          : (isHovered
                                                              ? 0.2
                                                              : 0.08)),
                                                  Colors.transparent,
                                                ],
                                              ),
                                            ),
                                          ),

                                          // Card content
                                          Padding(
                                            padding: const EdgeInsets.all(20),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.center,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Container(
                                                            width: 46,
                                                            height: 46,
                                                            decoration:
                                                                BoxDecoration(
                                                              shape: BoxShape
                                                                  .circle,
                                                              color: Colors.black
                                                                  .withOpacity(
                                                                      0.5),
                                                              border:
                                                                  Border.all(
                                                                color: eq.color
                                                                    .withOpacity(
                                                                        isSelected
                                                                            ? 0.8
                                                                            : 0.4),
                                                                width: 1.5,
                                                              ),
                                                            ),
                                                            child: Center(
                                                              child: Text(
                                                                eq.emoji,
                                                                style:
                                                                    const TextStyle(
                                                                        fontSize:
                                                                            22),
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 12),
                                                          Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                eq.title,
                                                                style: TextStyle(
                                                                  fontSize: 17,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w800,
                                                                  color: isSelected
                                                                      ? Colors
                                                                          .white
                                                                      : Colors.white
                                                                          .withOpacity(
                                                                              0.9),
                                                                ),
                                                              ),
                                                              Text(
                                                                eq.subtitle,
                                                                style: TextStyle(
                                                                  fontSize: 10,
                                                                  color: eq.color,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                  letterSpacing:
                                                                      1.5,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 14),
                                                      Wrap(
                                                        spacing: 6,
                                                        runSpacing: 6,
                                                        children: eq.features
                                                            .map(
                                                              (f) => Container(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .symmetric(
                                                                  horizontal: 9,
                                                                  vertical: 4,
                                                                ),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              8),
                                                                  color: Colors
                                                                      .black
                                                                      .withOpacity(
                                                                          0.4),
                                                                  border: Border.all(
                                                                      color: eq
                                                                          .color
                                                                          .withOpacity(
                                                                              0.5)),
                                                                ),
                                                                child: Text(
                                                                  f,
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize: 10,
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
                                                  width: 30,
                                                  height: 30,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: isSelected
                                                        ? eq.color
                                                        : Colors.black
                                                            .withOpacity(0.4),
                                                    border: Border.all(
                                                      color: isSelected
                                                          ? eq.color
                                                          : Colors.white
                                                              .withOpacity(0.25),
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
                              ),
                            );
                          }),

                          const SizedBox(height: 8),

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

  // ═══════════════════════════════════════════════════════════════════════════
  // MOBILE LAYOUT
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFF050A05),
      body: Stack(
        children: [
          // Ambient glow
          Positioned(
            bottom: -100,
            left: -100,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
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

                    // Equipment cards
                    Expanded(
                      child: ListView.separated(
                        itemCount: _equipments.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final eq = _equipments[index];
                          final isSelected = _selectedEquipment == eq.title;
                          return GestureDetector(
                            onTap: () => setState(
                                () => _selectedEquipment = eq.title),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              height: 155,
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
                                          color: eq.color.withOpacity(0.35),
                                          blurRadius: 24,
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
                                    // Real photo background
                                    Image.network(
                                      eq.bgImage,
                                      fit: BoxFit.cover,
                                      alignment: Alignment.center,
                                      opacity: AlwaysStoppedAnimation(
                                          isSelected ? 0.5 : 0.3),
                                      frameBuilder: (ctx, child, frame,
                                          wasSynchronouslyLoaded) {
                                        if (wasSynchronouslyLoaded ||
                                            frame != null) return child;
                                        return Container(
                                            color: AppColors.surface);
                                      },
                                      errorBuilder: (c, e, s) =>
                                          Container(color: AppColors.surface),
                                    ),

                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.centerRight,
                                          end: Alignment.centerLeft,
                                          colors: [
                                            Colors.black.withOpacity(
                                                isSelected ? 0.4 : 0.6),
                                            Colors.black.withOpacity(0.2),
                                          ],
                                        ),
                                      ),
                                    ),

                                    AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.bottomLeft,
                                          end: Alignment.topRight,
                                          colors: [
                                            eq.color.withOpacity(
                                                isSelected ? 0.35 : 0.1),
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
                                                    Container(
                                                      width: 44,
                                                      height: 44,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: Colors.black
                                                            .withOpacity(0.5),
                                                        border: Border.all(
                                                          color: eq.color
                                                              .withOpacity(
                                                                  isSelected
                                                                      ? 0.8
                                                                      : 0.4),
                                                          width: 1.5,
                                                        ),
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          eq.emoji,
                                                          style: const TextStyle(
                                                              fontSize: 20),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
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
                                                                ? Colors.white
                                                                : Colors.white
                                                                    .withOpacity(
                                                                        0.9),
                                                          ),
                                                        ),
                                                        Text(
                                                          eq.subtitle,
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            color: eq.color,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            letterSpacing: 1.5,
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
                                                            color: Colors.black
                                                                .withOpacity(
                                                                    0.4),
                                                            border: Border.all(
                                                                color: eq.color
                                                                    .withOpacity(
                                                                        0.5)),
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
                                                  : Colors.black
                                                      .withOpacity(0.4),
                                              border: Border.all(
                                                color: isSelected
                                                    ? eq.color
                                                    : Colors.white
                                                        .withOpacity(0.25),
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

                    // Let's Go button
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

// ── Web grid painter ──────────────────────────────────────────────────────────
class _WebGridPainter extends CustomPainter {
  final Color color;
  _WebGridPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.04)
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