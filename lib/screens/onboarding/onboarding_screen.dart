import 'package:flutter/material.dart';
import 'dart:math';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_strings.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      emoji: '🏋️',
      title: AppStrings.onboardingTitle1,
      description: AppStrings.onboardingDesc1,
      bgImage:
          'https://images.unsplash.com/photo-1605296867304-46d5465a13f1?w=1200&q=80',
      accentColor: const Color(0xFF00C853),
    ),
    OnboardingData(
      emoji: '📋',
      title: AppStrings.onboardingTitle2,
      description: AppStrings.onboardingDesc2,
      bgImage:
          'https://images.unsplash.com/photo-1574680096145-d05b474e2155?w=1200&q=80',
      accentColor: const Color(0xFF2979FF),
    ),
    OnboardingData(
      emoji: '📈',
      title: AppStrings.onboardingTitle3,
      description: AppStrings.onboardingDesc3,
      bgImage:
          'https://images.unsplash.com/photo-1549060279-7e168fcee0c2?w=1200&q=80',
      accentColor: const Color(0xFFFF6D00),
    ),
    OnboardingData(
      emoji: '🥗',
      title: AppStrings.onboardingTitle4,
      description: AppStrings.onboardingDesc4,
      bgImage:
          'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=1200&q=80',
      accentColor: const Color(0xFFFFD600),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );

    _slideAnim = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _animController.reset();
    _animController.forward();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacementNamed(context, '/user-info');
    }
  }

  void _skip() {
    Navigator.pushReplacementNamed(context, '/user-info');
  }

  @override
  Widget build(BuildContext context) {
    final current = _pages[_currentPage];

    return Scaffold(
      backgroundColor: const Color(0xFF050A05),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            child: Image.network(
              current.bgImage,
              key: ValueKey(current.bgImage),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              opacity: const AlwaysStoppedAnimation(0.25),
              errorBuilder: (c, e, s) =>
                  Container(color: const Color(0xFF050A05)),
            ),
          ),

          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF050A05).withOpacity(0.6),
                  const Color(0xFF050A05).withOpacity(0.4),
                  const Color(0xFF050A05).withOpacity(0.9),
                  const Color(0xFF050A05),
                ],
              ),
            ),
          ),

          // Grid painter
          CustomPaint(
            painter: _GridPainter(current.accentColor),
          ),

          // Page content
          PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return _buildPage(_pages[index]);
            },
          ),

          // Top skip button
          Positioned(
            top: 50,
            right: 24,
            child: _currentPage < _pages.length - 1
                ? TextButton(
                    onPressed: _skip,
                    child: Text(
                      AppStrings.btnSkip,
                      style: TextStyle(
                        color: AppColors.textSecondary.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 48),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    const Color(0xFF050A05).withOpacity(0.95),
                    const Color(0xFF050A05),
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Page dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: _currentPage == index
                              ? current.accentColor
                              : AppColors.textHint.withOpacity(0.4),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Next / Get Started button
                  AnimatedBuilder(
                    animation: _animController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnim,
                        child: GestureDetector(
                          onTap: _nextPage,
                          child: Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                colors: [
                                  current.accentColor,
                                  current.accentColor.withOpacity(0.7),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: current.accentColor.withOpacity(0.4),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                _currentPage == _pages.length - 1
                                    ? AppStrings.btnGetStarted
                                    : AppStrings.btnNext,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),

          // Emoji icon with glow
          AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnim,
                child: Transform.translate(
                  offset: Offset(0, _slideAnim.value),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: data.accentColor.withOpacity(0.12),
                      border: Border.all(
                        color: data.accentColor.withOpacity(0.4),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: data.accentColor.withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        data.emoji,
                        style: const TextStyle(fontSize: 52),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 40),

          // Title
          AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnim,
                child: Transform.translate(
                  offset: Offset(0, _slideAnim.value),
                  child: ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [
                        data.accentColor,
                        data.accentColor.withOpacity(0.7),
                      ],
                    ).createShader(bounds),
                    child: Text(
                      data.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Description
          AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnim,
                child: Transform.translate(
                  offset: Offset(0, _slideAnim.value * 1.5),
                  child: Text(
                    data.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary.withOpacity(0.8),
                      height: 1.6,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Data model for each onboarding page
class OnboardingData {
  final String emoji;
  final String title;
  final String description;
  final String bgImage;
  final Color accentColor;

  OnboardingData({
    required this.emoji,
    required this.title,
    required this.description,
    required this.bgImage,
    required this.accentColor,
  });
}

// Grid painter
class _GridPainter extends CustomPainter {
  final Color color;
  _GridPainter(this.color);

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
  bool shouldRepaint(covariant _GridPainter old) => old.color != color;
}