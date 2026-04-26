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
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final p in _pages) {
      precacheImage(NetworkImage(p.bgImage), context);
    }
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

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skip() => Navigator.pushReplacementNamed(context, '/user-info');

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 600;
    return isWeb ? _buildWebLayout() : _buildMobileLayout();
  }

  // ═══════════════════════════════════════════════════════
  // WEB LAYOUT
  // ═══════════════════════════════════════════════════════
  Widget _buildWebLayout() {
    final current = _pages[_currentPage];

    return Scaffold(
      backgroundColor: const Color(0xFF030806),
      body: Row(
        children: [
          // ── Left: full-height background image panel ──
          Expanded(
            flex: 55,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Swipeable page view for background images
                PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return Image.network(
                      _pages[index].bgImage,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      frameBuilder:
                          (ctx, child, frame, wasSynchronouslyLoaded) {
                        if (wasSynchronouslyLoaded || frame != null)
                          return child;
                        return Container(color: const Color(0xFF0A1A0A));
                      },
                      errorBuilder: (c, e, s) =>
                          Container(color: const Color(0xFF030806)),
                    );
                  },
                ),
                // Dark gradient blending into right panel
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [
                        const Color(0xFF030806),
                        Colors.transparent,
                        Colors.transparent,
                        const Color(0xFF030806).withOpacity(0.3),
                      ],
                      stops: const [0.0, 0.15, 0.75, 1.0],
                    ),
                  ),
                ),
                // Grid overlay
                CustomPaint(painter: _GridPainter(current.accentColor)),
                // Bottom text overlay
                Positioned(
                  bottom: 48,
                  left: 40,
                  right: 40,
                  child: AnimatedBuilder(
                    animation: _animController,
                    builder: (_, __) => FadeTransition(
                      opacity: _fadeAnim,
                      child: Transform.translate(
                        offset: Offset(0, _slideAnim.value),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: current.accentColor,
                                    boxShadow: [
                                      BoxShadow(
                                        color: current.accentColor
                                            .withOpacity(0.6),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'FitLife  ·  ${_currentPage + 1} of ${_pages.length}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: current.accentColor,
                                    letterSpacing: 2,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              current.title,
                              style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              current.description,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.6),
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Right: centered card ──
          Expanded(
            flex: 45,
            child: Container(
              color: const Color(0xFF030806),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 48, vertical: 40),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Brand name
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              current.accentColor,
                              current.accentColor.withOpacity(0.6),
                            ],
                          ).createShader(bounds),
                          child: const Text(
                            'FitLife',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 3,
                            ),
                          ),
                        ),

                        const SizedBox(height: 44),

                        // Animated illustration — actual image from bg with overlay
                        AnimatedBuilder(
                          animation: _animController,
                          builder: (_, __) => FadeTransition(
                            opacity: _fadeAnim,
                            child: Transform.translate(
                              offset: Offset(0, _slideAnim.value),
                              child: _buildIllustrationCard(current),
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Title
                        AnimatedBuilder(
                          animation: _animController,
                          builder: (_, __) => FadeTransition(
                            opacity: _fadeAnim,
                            child: Transform.translate(
                              offset: Offset(0, _slideAnim.value),
                              child: ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  colors: [
                                    current.accentColor,
                                    current.accentColor.withOpacity(0.7),
                                  ],
                                ).createShader(bounds),
                                child: Text(
                                  current.title,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    height: 1.25,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Description
                        AnimatedBuilder(
                          animation: _animController,
                          builder: (_, __) => FadeTransition(
                            opacity: _fadeAnim,
                            child: Text(
                              current.description,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color:
                                    AppColors.textSecondary.withOpacity(0.7),
                                height: 1.65,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Page dots
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _pages.length,
                            (i) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              width: _currentPage == i ? 24 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(3),
                                color: _currentPage == i
                                    ? current.accentColor
                                    : AppColors.textHint.withOpacity(0.3),
                                boxShadow: _currentPage == i
                                    ? [
                                        BoxShadow(
                                          color: current.accentColor
                                              .withOpacity(0.5),
                                          blurRadius: 8,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Next / Get Started button
                        GestureDetector(
                          onTap: _nextPage,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: double.infinity,
                            height: 52,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: LinearGradient(
                                colors: [
                                  current.accentColor,
                                  current.accentColor.withOpacity(0.75),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      current.accentColor.withOpacity(0.35),
                                  blurRadius: 20,
                                  spreadRadius: 1,
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
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Skip
                        if (_currentPage < _pages.length - 1)
                          TextButton(
                            onPressed: _skip,
                            child: Text(
                              AppStrings.btnSkip,
                              style: TextStyle(
                                color: AppColors.textSecondary
                                    .withOpacity(0.45),
                                fontSize: 13,
                              ),
                            ),
                          ),

                        const SizedBox(height: 16),

                        // Prev / Next arrow nav
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _currentPage > 0
                                ? GestureDetector(
                                    onTap: _prevPage,
                                    child: Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.border,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.arrow_back_ios_new_rounded,
                                        size: 15,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  )
                                : const SizedBox(width: 42),
                            Text(
                              '${_currentPage + 1} / ${_pages.length}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textHint.withOpacity(0.35),
                                letterSpacing: 1,
                              ),
                            ),
                            _currentPage < _pages.length - 1
                                ? GestureDetector(
                                    onTap: _nextPage,
                                    child: Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: current.accentColor
                                            .withOpacity(0.12),
                                        border: Border.all(
                                          color: current.accentColor
                                              .withOpacity(0.4),
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 15,
                                        color: current.accentColor,
                                      ),
                                    ),
                                  )
                                : const SizedBox(width: 42),
                          ],
                        ),
                      ],
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

  /// Beautiful image card shown in the right panel
  Widget _buildIllustrationCard(OnboardingData data) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: data.accentColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: data.accentColor.withOpacity(0.2),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              data.bgImage,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              frameBuilder: (ctx, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded || frame != null) return child;
                return Container(
                  color: const Color(0xFF0A1A0A),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: data.accentColor.withOpacity(0.5),
                      ),
                    ),
                  ),
                );
              },
              errorBuilder: (c, e, s) =>
                  Container(color: const Color(0xFF0A1A0A)),
            ),
            // Gradient overlay to darken & add accent
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    data.accentColor.withOpacity(0.4),
                  ],
                ),
              ),
            ),
            // Emoji + label centered
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.4),
                      border: Border.all(
                        color: data.accentColor.withOpacity(0.6),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        data.emoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Custom painter dots decoration
            CustomPaint(painter: _CardDotsPainter(data.accentColor)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // MOBILE LAYOUT — original unchanged
  // ═══════════════════════════════════════════════════════
  Widget _buildMobileLayout() {
    final current = _pages[_currentPage];

    return Scaffold(
      backgroundColor: const Color(0xFF050A05),
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            child: Image.network(
              current.bgImage,
              key: ValueKey(current.bgImage),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              alignment: Alignment.center,
              opacity: const AlwaysStoppedAnimation(0.25),
              errorBuilder: (c, e, s) =>
                  Container(color: const Color(0xFF050A05)),
            ),
          ),
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
          CustomPaint(painter: _GridPainter(current.accentColor)),
          PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: _pages.length,
            itemBuilder: (context, index) => _buildMobilePage(_pages[index]),
          ),
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
                  AnimatedBuilder(
                    animation: _animController,
                    builder: (_, __) => FadeTransition(
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
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobilePage(OnboardingData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          AnimatedBuilder(
            animation: _animController,
            builder: (_, __) => FadeTransition(
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
                    child: Text(data.emoji,
                        style: const TextStyle(fontSize: 52)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          AnimatedBuilder(
            animation: _animController,
            builder: (_, __) => FadeTransition(
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
            ),
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _animController,
            builder: (_, __) => FadeTransition(
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
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data model ───────────────────────────────────────────────────────────────
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

// ── Grid painter ─────────────────────────────────────────────────────────────
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

// ── Card dots decoration painter ─────────────────────────────────────────────
class _CardDotsPainter extends CustomPainter {
  final Color color;
  static final Random _rng = Random(99);
  static late final List<_Dot> _dots;
  static bool _initialized = false;

  _CardDotsPainter(this.color) {
    if (!_initialized) {
      _dots = List.generate(
        18,
        (_) => _Dot(
          x: _rng.nextDouble(),
          y: _rng.nextDouble(),
          r: _rng.nextDouble() * 2.5 + 0.5,
        ),
      );
      _initialized = true;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withOpacity(0.25);
    for (final d in _dots) {
      canvas.drawCircle(
        Offset(d.x * size.width, d.y * size.height),
        d.r,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CardDotsPainter old) => old.color != color;
}

class _Dot {
  final double x, y, r;
  _Dot({required this.x, required this.y, required this.r});
}