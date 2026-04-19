import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_strings.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _ringController;
  late AnimationController _textController;
  late AnimationController _loadingController;
  late AnimationController _bgController;

  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _ringExpand;
  late Animation<double> _textFade;
  late Animation<double> _textSlide;
  late Animation<double> _bgFade;

  // Background gym image URLs (free Unsplash)
  final List<String> _bgImages = [
    'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=1200&q=80',
  ];

  int _currentBg = 0;
  Timer? _bgTimer;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..forward();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _ringExpand = Tween<double>(begin: 0.8, end: 1.4).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.easeInOut),
    );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );

    _textSlide = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    _bgFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bgController, curve: Curves.easeInOut),
    );

    // Start animations
    _bgController.forward();
    _logoController.forward().then((_) => _textController.forward());

    // Cycle background images
    _bgTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (mounted) {
        _bgController.reverse().then((_) {
          setState(() {
            _currentBg = (_currentBg + 1) % _bgImages.length;
          });
          _bgController.forward();
        });
      }
    });

    // Navigate after 4 seconds
    Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/onboarding');
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
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF050A05),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // --- Layer 1: Cycling gym background image ---
          AnimatedBuilder(
            animation: _bgFade,
            builder: (context, child) {
              return Opacity(
                opacity: _bgFade.value * 0.35,
                child: Image.network(
                  _bgImages[_currentBg],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(color: const Color(0xFF050A05)),
                ),
              );
            },
          ),

          // --- Layer 2: Dark gradient overlay ---
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF050A05).withOpacity(0.7),
                  const Color(0xFF050A05).withOpacity(0.5),
                  const Color(0xFF050A05).withOpacity(0.85),
                  const Color(0xFF050A05),
                ],
              ),
            ),
          ),

          // --- Layer 3: Grid lines ---
          CustomPaint(
            size: Size(size.width, size.height),
            painter: GridPainter(),
          ),

          // --- Layer 4: Floating particles ---
          AnimatedBuilder(
            animation: _ringController,
            builder: (context, child) {
              return CustomPaint(
                size: Size(size.width, size.height),
                painter: ParticlePainter(_ringController.value),
              );
            },
          ),

          // --- Layer 5: Main content ---
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Pulsing rings + logo
                AnimatedBuilder(
                  animation: Listenable.merge(
                      [_ringController, _logoController]),
                  builder: (context, child) {
                    return SizedBox(
                      width: 240,
                      height: 240,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Ring 3 - outermost
                          Transform.scale(
                            scale: _ringExpand.value * 1.1,
                            child: Container(
                              width: 210,
                              height: 210,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(
                                    0.08 * (2 - _ringExpand.value),
                                  ),
                                  width: 1,
                                ),
                              ),
                            ),
                          ),

                          // Ring 2
                          Transform.scale(
                            scale: _ringExpand.value * 0.85,
                            child: Container(
                              width: 210,
                              height: 210,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(
                                    0.18 * (2 - _ringExpand.value),
                                  ),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),

                          // Ring 1 - innermost
                          Transform.scale(
                            scale: _ringExpand.value * 0.65,
                            child: Container(
                              width: 210,
                              height: 210,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(
                                    0.35 * (2 - _ringExpand.value),
                                  ),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),

                          // Outer glow
                          Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.25),
                                  blurRadius: 50,
                                  spreadRadius: 15,
                                ),
                              ],
                            ),
                          ),

                          // Logo
                          Transform.scale(
                            scale: _logoScale.value,
                            child: FadeTransition(
                              opacity: _logoFade,
                              child: Container(
                                width: 115,
                                height: 115,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      AppColors.primary.withOpacity(0.35),
                                      AppColors.primary.withOpacity(0.05),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: AppColors.primary.withOpacity(0.7),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          AppColors.primary.withOpacity(0.5),
                                      blurRadius: 30,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Text(
                                    '🏋️',
                                    style: TextStyle(fontSize: 54),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 28),

                // App name
                AnimatedBuilder(
                  animation: _textController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _textFade,
                      child: Transform.translate(
                        offset: Offset(0, _textSlide.value),
                        child: Column(
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) =>
                                  const LinearGradient(
                                colors: [
                                  Color(0xFF5EFC82),
                                  Color(0xFF00C853),
                                  Color(0xFF009624),
                                ],
                              ).createShader(bounds),
                              child: const Text(
                                'FitLife',
                                style: TextStyle(
                                  fontSize: 52,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 4,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.3),
                                ),
                                borderRadius: BorderRadius.circular(20),
                                color: AppColors.primary.withOpacity(0.08),
                              ),
                              child: Text(
                                AppStrings.splashTagline.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  color:
                                      AppColors.textSecondary.withOpacity(0.8),
                                  letterSpacing: 3,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 70),

                // Progress bar
                AnimatedBuilder(
                  animation: _loadingController,
                  builder: (context, child) {
                    return Column(
                      children: [
                        Container(
                          width: 160,
                          height: 2,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: AppColors.primary.withOpacity(0.15),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _loadingController.value,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF5EFC82),
                                    Color(0xFF00C853),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.7),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'LOADING...',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textHint.withOpacity(0.4),
                            letterSpacing: 3,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          // --- Layer 6: Image indicator dots ---
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _bgImages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentBg == index ? 20 : 6,
                  height: 3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: _currentBg == index
                        ? AppColors.primary
                        : AppColors.primary.withOpacity(0.25),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Grid background
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00C853).withOpacity(0.04)
      ..strokeWidth = 0.5;

    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF00C853).withOpacity(0.07),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width / 2, size.height / 2),
          radius: size.width * 0.6,
        ),
      );

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.6,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Floating particles
class ParticlePainter extends CustomPainter {
  final double progress;
  final Random random = Random(42);

  ParticlePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 25; i++) {
      final x = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      final speed = 0.3 + random.nextDouble() * 0.7;
      final y = (baseY - progress * speed * 80) % size.height;
      final radius = 1.0 + random.nextDouble() * 2;
      final opacity = 0.08 + random.nextDouble() * 0.25;

      paint.color = const Color(0xFF00C853).withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) =>
      oldDelegate.progress != progress;
}