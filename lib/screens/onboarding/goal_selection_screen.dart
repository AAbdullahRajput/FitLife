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
  int _hoveredIndex = -1;

  final List<GoalData> _goals = [
    GoalData(
      title: 'Lose Weight',
      description: 'Burn fat and get lean',
      emoji: '🔥',
      color: const Color(0xFFFF6D00),
      bgImage:
          'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=1200&q=80',
    ),
    GoalData(
      title: 'Build Muscle',
      description: 'Gain strength and size',
      emoji: '💪',
      color: const Color(0xFF2979FF),
      bgImage:
          'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=1200&q=80',
    ),
    GoalData(
      title: 'Stay Fit',
      description: 'Maintain a healthy body',
      emoji: '⚡',
      color: const Color(0xFF00C853),
      bgImage:
          'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=1200&q=80',
    ),
    GoalData(
      title: 'Increase Strength',
      description: 'Lift heavier, get stronger',
      emoji: '🏋️',
      color: const Color(0xFFAA00FF),
      bgImage:
          'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=1200&q=80',
    ),
    GoalData(
      title: 'Improve Endurance',
      description: 'Run longer, last harder',
      emoji: '🏃',
      color: const Color(0xFFFFD600),
      bgImage:
          'https://images.unsplash.com/photo-1549060279-7e168fcee0c2?w=1200&q=80',
    ),
  ];

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
    for (final g in _goals) {
      precacheImage(NetworkImage(g.bgImage), context);
    }
    precacheImage(const NetworkImage(_defaultBg), context);
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    Navigator.pushReplacementNamed(context, '/equipment-selection');
  }

  Color get _accentColor => _selectedGoal != null
      ? _goals.firstWhere((g) => g.title == _selectedGoal).color
      : AppColors.primary;

  GoalData? get _activeGoal {
    if (_hoveredIndex >= 0) return _goals[_hoveredIndex];
    if (_selectedGoal != null) {
      return _goals.firstWhere((g) => g.title == _selectedGoal);
    }
    return null;
  }

  // FIX: prefix 'bg_' ensures these keys never collide with 'overlay_' keys
  // inside the same AnimatedSwitcher transition frame.
  String get _activeBgKey => 'bg_${_activeGoal?.title ?? '__default__'}';
  String get _activeBgImage => _activeGoal?.bgImage ?? _defaultBg;

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 600;
    return isWeb ? _buildWebLayout() : _buildMobileLayout();
  }

  Widget _buildWebLayout() {
    final active = _activeGoal;
    final accentColor = active?.color ?? AppColors.primary;

    return Scaffold(
      backgroundColor: const Color(0xFF030806),
      extendBodyBehindAppBar: true,
      body: Row(
        children: [
          // ── Left: image showcase ───────────────────────────────────────────
          Expanded(
            flex: 50,
            child: ClipRect(
              child: Container(
                color: const Color(0xFF030806),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Remove AnimatedSwitcher entirely — use AnimatedCrossFade instead
// which handles two explicit children with no key conflict.
AnimatedCrossFade(
  duration: const Duration(milliseconds: 500),
  crossFadeState: _activeGoal != null
      ? CrossFadeState.showSecond
      : CrossFadeState.showFirst,
  layoutBuilder: (top, topKey, bottom, bottomKey) => Stack(
    fit: StackFit.expand,
    children: [
      Positioned.fill(key: bottomKey, child: bottom),
      Positioned.fill(key: topKey, child: top),
    ],
  ),
  firstChild: Image.network(
    _defaultBg,
    fit: BoxFit.fitHeight,
    alignment: Alignment.center,
    errorBuilder: (c, e, s) =>
        Container(color: const Color(0xFF030806)),
  ),
  secondChild: Image.network(
    _activeGoal?.bgImage ?? _defaultBg,
    fit: BoxFit.fitHeight,
    alignment: Alignment.center,
    errorBuilder: (c, e, s) =>
        Container(color: const Color(0xFF030806)),
  ),
),

                    // Right-edge blend
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

                    // Accent tint
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 450),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            accentColor.withOpacity(0.5),
                            accentColor.withOpacity(0.0),
                          ],
                          stops: const [0.0, 0.65],
                        ),
                      ),
                    ),

                    // Grid
                    CustomPaint(painter: _WebGridPainter(accentColor)),

                    // Bottom overlay
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(40, 48, 40, 48),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.88),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
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
                                    color: accentColor,
                                    boxShadow: [
                                      BoxShadow(
                                        color: accentColor.withOpacity(0.7),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'STEP 2 OF 3  ·  YOUR GOAL',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: accentColor,
                                    letterSpacing: 2.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // FIX: overlay keys use 'overlay_' prefix — distinct namespace
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: active != null
                                  ? _GoalOverlayContent(
                                      key: ValueKey('overlay_${active.title}'),
                                      goal: active,
                                    )
                                  : const _DefaultOverlayContent(
                                      key: ValueKey('overlay___default__'),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Right: goal list ───────────────────────────────────────────────
          Expanded(
            flex: 50,
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

                          ...List.generate(_goals.length, (index) {
                            final goal = _goals[index];
                            final isSelected = _selectedGoal == goal.title;
                            final isHovered = _hoveredIndex == index;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: MouseRegion(
                                onEnter: (_) =>
                                    setState(() => _hoveredIndex = index),
                                onExit: (_) =>
                                    setState(() => _hoveredIndex = -1),
                                child: GestureDetector(
                                  onTap: () => setState(
                                      () => _selectedGoal = goal.title),
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 280),
                                    height: 96,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSelected
                                            ? goal.color
                                            : (isHovered
                                                ? goal.color.withOpacity(0.5)
                                                : AppColors.border),
                                        width: isSelected ? 2.5 : 1.5,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: goal.color
                                                    .withOpacity(0.3),
                                                blurRadius: 24,
                                                spreadRadius: 2,
                                              )
                                            ]
                                          : (isHovered
                                              ? [
                                                  BoxShadow(
                                                    color: goal.color
                                                        .withOpacity(0.12),
                                                    blurRadius: 14,
                                                  )
                                                ]
                                              : []),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Image.network(
                                            goal.bgImage,
                                            fit: BoxFit.cover,
                                            alignment: Alignment.center,
                                            opacity: AlwaysStoppedAnimation(
                                                isSelected
                                                    ? 0.5
                                                    : (isHovered
                                                        ? 0.4
                                                        : 0.25)),
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
                                          Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.centerRight,
                                                end: Alignment.centerLeft,
                                                colors: [
                                                  Colors.black.withOpacity(
                                                      isSelected ? 0.4 : 0.6),
                                                  Colors.black
                                                      .withOpacity(0.15),
                                                ],
                                              ),
                                            ),
                                          ),
                                          AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 280),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.centerLeft,
                                                end: Alignment.centerRight,
                                                colors: [
                                                  goal.color.withOpacity(
                                                      isSelected
                                                          ? 0.38
                                                          : (isHovered
                                                              ? 0.18
                                                              : 0.08)),
                                                  Colors.transparent,
                                                ],
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 18, vertical: 14),
                                            child: Row(
                                              children: [
                                                AnimatedContainer(
                                                  duration: const Duration(
                                                      milliseconds: 280),
                                                  width: 48,
                                                  height: 48,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: Colors.black
                                                        .withOpacity(0.5),
                                                    border: Border.all(
                                                      color: goal.color
                                                          .withOpacity(
                                                              isSelected
                                                                  ? 0.8
                                                                  : 0.4),
                                                      width: 1.5,
                                                    ),
                                                  ),
                                                  child: Center(
                                                    child: Text(goal.emoji,
                                                        style: const TextStyle(
                                                            fontSize: 22)),
                                                  ),
                                                ),
                                                const SizedBox(width: 14),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        goal.title,
                                                        style: TextStyle(
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          color: Colors.white
                                                              .withOpacity(
                                                                  isSelected
                                                                      ? 1.0
                                                                      : 0.88),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 3),
                                                      Text(
                                                        goal.description,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: isSelected
                                                              ? goal.color
                                                                  .withOpacity(
                                                                      0.85)
                                                              : Colors.white
                                                                  .withOpacity(
                                                                      0.45),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                AnimatedContainer(
                                                  duration: const Duration(
                                                      milliseconds: 250),
                                                  width: 26,
                                                  height: 26,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: isSelected
                                                        ? goal.color
                                                        : Colors.black
                                                            .withOpacity(0.45),
                                                    border: Border.all(
                                                      color: isSelected
                                                          ? goal.color
                                                          : Colors.white
                                                              .withOpacity(
                                                                  0.25),
                                                      width: 2,
                                                    ),
                                                  ),
                                                  child: isSelected
                                                      ? const Icon(Icons.check,
                                                          size: 14,
                                                          color: Colors.white)
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

                          const SizedBox(height: 12),

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

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFF050A05),
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -80,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
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
              builder: (context, child) => FadeTransition(
                opacity: _fadeAnim,
                child: Transform.translate(
                  offset: Offset(0, _slideAnim.value),
                  child: child,
                ),
              ),
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
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final goal = _goals[index];
                          final isSelected = _selectedGoal == goal.title;
                          return GestureDetector(
                            onTap: () => setState(
                                () => _selectedGoal = goal.title),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              height: 90,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isSelected
                                      ? goal.color
                                      : AppColors.border,
                                  width: isSelected ? 2.5 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: goal.color.withOpacity(0.3),
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
                                    Image.network(
                                      goal.bgImage,
                                      fit: BoxFit.cover,
                                      alignment: Alignment.center,
                                      opacity: AlwaysStoppedAnimation(
                                          isSelected ? 0.45 : 0.25),
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
                                          begin: Alignment.centerRight,
                                          end: Alignment.centerLeft,
                                          colors: [
                                            Colors.black.withOpacity(
                                                isSelected ? 0.35 : 0.6),
                                            Colors.black.withOpacity(0.1),
                                          ],
                                        ),
                                      ),
                                    ),
                                    AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 250),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                          colors: [
                                            goal.color.withOpacity(
                                                isSelected ? 0.35 : 0.1),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      child: Row(
                                        children: [
                                          AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 250),
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.black
                                                  .withOpacity(0.5),
                                              border: Border.all(
                                                color: goal.color.withOpacity(
                                                    isSelected ? 0.8 : 0.4),
                                                width: 1.5,
                                              ),
                                            ),
                                            child: Center(
                                              child: Text(goal.emoji,
                                                  style: const TextStyle(
                                                      fontSize: 22)),
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  goal.title,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w800,
                                                    color: Colors.white
                                                        .withOpacity(
                                                            isSelected
                                                                ? 1.0
                                                                : 0.88),
                                                  ),
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  goal.description,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: isSelected
                                                        ? goal.color
                                                            .withOpacity(0.85)
                                                        : Colors.white
                                                            .withOpacity(0.45),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 250),
                                            width: 26,
                                            height: 26,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: isSelected
                                                  ? goal.color
                                                  : Colors.black
                                                      .withOpacity(0.45),
                                              border: Border.all(
                                                color: isSelected
                                                    ? goal.color
                                                    : Colors.white
                                                        .withOpacity(0.25),
                                                width: 2,
                                              ),
                                            ),
                                            child: isSelected
                                                ? const Icon(Icons.check,
                                                    size: 14,
                                                    color: Colors.white)
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

// ── Overlay widgets ───────────────────────────────────────────────────────────

class _GoalOverlayContent extends StatelessWidget {
  final GoalData goal;
  const _GoalOverlayContent({required super.key, required this.goal});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(goal.emoji, style: const TextStyle(fontSize: 40)),
        const SizedBox(height: 8),
        Text(
          goal.title,
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          goal.description,
          style: TextStyle(
            fontSize: 15,
            color: Colors.white.withOpacity(0.7),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: goal.color.withOpacity(0.2),
            border: Border.all(color: goal.color.withOpacity(0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, size: 13, color: goal.color),
              const SizedBox(width: 6),
              Text(
                'AI-personalized plan',
                style: TextStyle(
                  fontSize: 12,
                  color: goal.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DefaultOverlayContent extends StatelessWidget {
  const _DefaultOverlayContent({required super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'What Do You\nWant to Achieve?',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Hover a goal to preview your\ntraining direction.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.55),
            height: 1.65,
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
  final String bgImage;

  GoalData({
    required this.title,
    required this.description,
    required this.emoji,
    required this.color,
    required this.bgImage,
  });
}

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