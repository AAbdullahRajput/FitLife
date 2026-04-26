import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../services/storage_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Controllers ────────────────────────────────────────────────────────────
  late AnimationController _logoController;
  late AnimationController _ringController;
  late AnimationController _textController;
  late AnimationController _loadingController;
  late AnimationController _bgCrossfadeController;
  late AnimationController _shimmerController;
  late AnimationController _particleController;

  // ── Animations ─────────────────────────────────────────────────────────────
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _logoRotate;
  late Animation<double> _ringExpand;
  late Animation<double> _textFade;
  late Animation<double> _textSlide;
  late Animation<double> _bgCrossfade;
  late Animation<double> _shimmer;
  late Animation<double> _taglineFade;
  late Animation<double> _taglineSlide;

  // ── Multiple gym background images ────────────────────────────────────────
  final List<String> _bgImages = [
    'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=1200&q=90&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=1200&q=90&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=1200&q=90&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=1200&q=90&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1526506118085-60ce8714f8c5?w=1200&q=90&auto=format&fit=crop',
  ];

  int _currentBg = 0;
  int _nextBg = 1;
  Timer? _bgTimer;

  // ── Image loaded flags ─────────────────────────────────────────────────────
  bool _imagesPreloaded = false;

  @override
  void initState() {
    super.initState();
    _setupControllers();
    _setupAnimations();
    _startSequence();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pre-cache all background images so they appear instantly
    if (!_imagesPreloaded) {
      _imagesPreloaded = true;
      for (final url in _bgImages) {
        precacheImage(NetworkImage(url), context);
      }
    }
  }

  void _setupControllers() {
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    // ✅ Increased duration to match the new 4500ms navigation timer
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );
    _bgCrossfadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  void _setupAnimations() {
    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.15, end: 0.95)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.95, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
    ]).animate(_logoController);

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _logoRotate = Tween<double>(begin: -0.08, end: 0.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );

    _ringExpand = Tween<double>(begin: 0.7, end: 1.35).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.easeInOut),
    );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );
    _textSlide = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );
    _taglineSlide = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _bgCrossfade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _bgCrossfadeController, curve: Curves.easeInOut),
    );

    _shimmer = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
  }

  void _startSequence() {
    // Kick off logo + loading bar
    _logoController.forward().then((_) {
      if (mounted) _textController.forward();
    });

    // ✅ Small delay before loading bar starts for a polished feel
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _loadingController.forward();
    });

    // Cycle bg images with crossfade every 1.4 s
    _bgTimer = Timer.periodic(const Duration(milliseconds: 1400), (_) {
      if (!mounted) return;
      _nextBg = (_currentBg + 1) % _bgImages.length;
      _bgCrossfadeController.forward(from: 0).then((_) {
        if (mounted) {
          setState(() => _currentBg = _nextBg);
          _bgCrossfadeController.reset();
        }
      });
    });

    // ✅ Increased from 3000ms to 4500ms so all animations complete fully
    // and background images have time to load from network
    Timer(const Duration(milliseconds: 4500), () async {
      if (mounted) {
        final setupDone = await StorageService.isSetupDone();
        if (mounted) {
          Navigator.pushReplacementNamed(
              context, setupDone ? '/home' : '/onboarding');
        }
      }
    });
  }

  @override
  void dispose() {
    _bgTimer?.cancel();
    _logoController.dispose();
    _ringController.dispose();
    _textController.dispose();
    _loadingController.dispose();
    _bgCrossfadeController.dispose();
    _shimmerController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF030806),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Layer 1: Current gym photo ──────────────────────────────────
          Image.network(
            _bgImages[_currentBg],
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            // ✅ Show a dark placeholder while image loads
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded || frame != null) return child;
              return Container(color: const Color(0xFF030806));
            },
            errorBuilder: (_, __, ___) =>
                Container(color: const Color(0xFF030806)),
          ),

          // ── Layer 2: Next photo crossfade ───────────────────────────────
          AnimatedBuilder(
            animation: _bgCrossfade,
            builder: (_, __) => Opacity(
              opacity: _bgCrossfade.value,
              child: Image.network(
                _bgImages[_nextBg],
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded || frame != null) return child;
                  return Container(color: const Color(0xFF030806));
                },
                errorBuilder: (_, __, ___) =>
                    Container(color: const Color(0xFF030806)),
              ),
            ),
          ),

          // ── Layer 3: Rich dark gradient overlay ─────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xCC030806),
                  Color(0x99030806),
                  Color(0xBB030806),
                  Color(0xF5030806),
                ],
                stops: [0.0, 0.3, 0.6, 1.0],
              ),
            ),
          ),

          // ── Layer 4: Radial green glow from center ───────────────────────
          Center(
            child: Container(
              width: size.width * 1.2,
              height: size.width * 1.2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.18),
                    AppColors.primary.withOpacity(0.06),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),

          // ── Layer 5: Grid ───────────────────────────────────────────────
          CustomPaint(
            size: size,
            painter: _GridPainter(),
          ),

          // ── Layer 6: Floating particles ─────────────────────────────────
          AnimatedBuilder(
            animation: _particleController,
            builder: (_, __) => CustomPaint(
              size: size,
              painter: _ParticlePainter(_particleController.value),
            ),
          ),

          // ── Layer 7: Main content ───────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),

                // ── Logo ring stack ───────────────────────────────────────
                AnimatedBuilder(
                  animation: Listenable.merge(
                      [_ringController, _logoController]),
                  builder: (_, __) => SizedBox(
                    width: 260,
                    height: 260,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outermost pulsing ring
                        _PulsingRing(
                          size: 240,
                          scale: _ringExpand.value * 1.05,
                          opacity: 0.06 * (2 - _ringExpand.value),
                          strokeWidth: 1,
                          color: AppColors.primary,
                        ),
                        // Middle ring
                        _PulsingRing(
                          size: 210,
                          scale: _ringExpand.value * 0.88,
                          opacity: 0.14 * (2 - _ringExpand.value),
                          strokeWidth: 1.5,
                          color: AppColors.primary,
                        ),
                        // Inner ring
                        _PulsingRing(
                          size: 175,
                          scale: _ringExpand.value * 0.70,
                          opacity: 0.30 * (2 - _ringExpand.value),
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                        // Extra accent ring (purple tint)
                        _PulsingRing(
                          size: 140,
                          scale: _ringExpand.value * 0.55,
                          opacity: 0.18 * (2 - _ringExpand.value),
                          strokeWidth: 1,
                          color: const Color(0xFF7C4DFF),
                        ),

                        // Large outer glow blob
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.28),
                                blurRadius: 70,
                                spreadRadius: 20,
                              ),
                            ],
                          ),
                        ),

                        // Logo circle
                        Transform.scale(
                          scale: _logoScale.value,
                          child: Transform.rotate(
                            angle: _logoRotate.value,
                            child: FadeTransition(
                              opacity: _logoFade,
                              child: _LogoCircle(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ── App name + tagline ────────────────────────────────────
                AnimatedBuilder(
                  animation: _textController,
                  builder: (_, __) => Column(
                    children: [
                      // "FitLife" with shimmer
                      FadeTransition(
                        opacity: _textFade,
                        child: Transform.translate(
                          offset: Offset(0, _textSlide.value),
                          child: AnimatedBuilder(
                            animation: _shimmer,
                            builder: (_, child) => ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: const [
                                  Color(0xFF00C853),
                                  Color(0xFF5EFC82),
                                  Color(0xFFFFFFFF),
                                  Color(0xFF5EFC82),
                                  Color(0xFF00C853),
                                ],
                                stops: [
                                  0.0,
                                  (_shimmer.value - 0.3).clamp(0.0, 1.0),
                                  _shimmer.value.clamp(0.0, 1.0),
                                  (_shimmer.value + 0.3).clamp(0.0, 1.0),
                                  1.0,
                                ],
                              ).createShader(bounds),
                              child: child,
                            ),
                            child: const Text(
                              'FitLife',
                              style: TextStyle(
                                fontSize: 58,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 5,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Tagline badge
                      FadeTransition(
                        opacity: _taglineFade,
                        child: Transform.translate(
                          offset: Offset(0, _taglineSlide.value),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 7),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.35),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(30),
                              color: AppColors.primary.withOpacity(0.08),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.15),
                                  blurRadius: 16,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primary,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary
                                            .withOpacity(0.8),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  AppStrings.splashTagline.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.primary.withOpacity(0.85),
                                    letterSpacing: 3.5,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primary,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary
                                            .withOpacity(0.8),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 3),

                // ── Loading bar ───────────────────────────────────────────
                AnimatedBuilder(
                  animation: _loadingController,
                  builder: (_, __) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Column(
                      children: [
                        // Track
                        Container(
                          width: double.infinity,
                          height: 2,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: AppColors.primary.withOpacity(0.12),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _loadingController.value,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF00C853),
                                    Color(0xFF5EFC82),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        AppColors.primary.withOpacity(0.7),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'INITIALIZING',
                              style: TextStyle(
                                fontSize: 9,
                                color: AppColors.primary.withOpacity(0.35),
                                letterSpacing: 3,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${(_loadingController.value * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: 9,
                                color: AppColors.primary.withOpacity(0.5),
                                letterSpacing: 1,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ── Image dot indicators ──────────────────────────────────
                SetStateBuilder(
                  listenable: _bgCrossfadeController,
                  builder: (context) => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_bgImages.length, (i) {
                      final isActive = _currentBg == i;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: isActive ? 22 : 5,
                        height: 3,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: isActive
                              ? AppColors.primary
                              : AppColors.primary.withOpacity(0.2),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.6),
                                    blurRadius: 6,
                                  ),
                                ]
                              : null,
                        ),
                      );
                    }),
                  ),
                ),

                const SizedBox(height: 36),
              ],
            ),
          ),

          // ── Layer 8: Top-left corner accent ─────────────────────────────
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Layer 9: Bottom-right corner accent ──────────────────────────
          Positioned(
            bottom: -80,
            right: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF7C4DFF).withOpacity(0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HELPER: SetStateBuilder — rebuilds on listenable tick without full setState
// ═══════════════════════════════════════════════════════════════════════════
class SetStateBuilder extends StatefulWidget {
  final Listenable listenable;
  final Widget Function(BuildContext context) builder;

  const SetStateBuilder({
    super.key,
    required this.listenable,
    required this.builder,
  });

  @override
  State<SetStateBuilder> createState() => _SetStateBuilderState();
}

class _SetStateBuilderState extends State<SetStateBuilder> {
  @override
  void initState() {
    super.initState();
    widget.listenable.addListener(_rebuild);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.listenable.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}

// ═══════════════════════════════════════════════════════════════════════════
// LOGO CIRCLE
// ═══════════════════════════════════════════════════════════════════════════
class _LogoCircle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.primary.withOpacity(0.30),
            AppColors.primary.withOpacity(0.08),
          ],
        ),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.75),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.55),
            blurRadius: 40,
            spreadRadius: 6,
          ),
          BoxShadow(
            color: AppColors.primary.withOpacity(0.20),
            blurRadius: 80,
            spreadRadius: 20,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Inner glow ring
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withOpacity(0.20),
                width: 1,
              ),
            ),
          ),
          const Text('🏋️', style: TextStyle(fontSize: 52)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PULSING RING
// ═══════════════════════════════════════════════════════════════════════════
class _PulsingRing extends StatelessWidget {
  final double size;
  final double scale;
  final double opacity;
  final double strokeWidth;
  final Color color;

  const _PulsingRing({
    required this.size,
    required this.scale,
    required this.opacity,
    required this.strokeWidth,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: color.withOpacity(opacity.clamp(0.0, 1.0)),
            width: strokeWidth,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// GRID PAINTER
// ═══════════════════════════════════════════════════════════════════════════
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00C853).withOpacity(0.035)
      ..strokeWidth = 0.6;

    for (double x = 0; x < size.width; x += 38) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 38) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Center radial glow overlay
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF00C853).withOpacity(0.09),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width / 2, size.height * 0.42),
        radius: size.width * 0.55,
      ));
    canvas.drawCircle(
      Offset(size.width / 2, size.height * 0.42),
      size.width * 0.55,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════════════════
// PARTICLE PAINTER
// ✅ Fixed: _rng is now static so it is NOT recreated on every repaint
// ═══════════════════════════════════════════════════════════════════════════
class _ParticlePainter extends CustomPainter {
  final double progress;

  // ✅ Static Random — created once, reused across all repaints
  static final Random _rng = Random(42);

  // ✅ Pre-generated particle data so _rng isn't called in paint()
  static final List<_ParticleData> _particles = List.generate(35, (_) {
    return _ParticleData(
      x: _rng.nextDouble(),
      baseY: _rng.nextDouble(),
      speed: 0.25 + _rng.nextDouble() * 0.75,
      radius: 0.8 + _rng.nextDouble() * 2.2,
      opacity: 0.06 + _rng.nextDouble() * 0.22,
      isGreen: _rng.nextBool(),
    );
  });

  _ParticlePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;

    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in _particles) {
      final x = p.x * size.width;
      final baseY = p.baseY * size.height;
      final y = (baseY - progress * p.speed * 100) % size.height;

      paint.color = (p.isGreen
              ? const Color(0xFF00C853)
              : const Color(0xFF7C4DFF))
          .withOpacity(p.opacity);

      canvas.drawCircle(Offset(x, y), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) =>
      old.progress != progress;
}

// ═══════════════════════════════════════════════════════════════════════════
// PARTICLE DATA MODEL
// ═══════════════════════════════════════════════════════════════════════════
class _ParticleData {
  final double x;
  final double baseY;
  final double speed;
  final double radius;
  final double opacity;
  final bool isGreen;

  const _ParticleData({
    required this.x,
    required this.baseY,
    required this.speed,
    required this.radius,
    required this.opacity,
    required this.isGreen,
  });
}