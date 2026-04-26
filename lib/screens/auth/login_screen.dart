// lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  final _supabase = Supabase.instance.client;

  // ── Hero images for left panel & mobile background ──
  static const String _heroBg =
      'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=1400&q=80';
  static const String _mobileBg =
      'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=900&q=80';

  // Small feature photos shown in the left panel
  static const List<_FeaturePhoto> _featurePhotos = [
    _FeaturePhoto(
      image: 'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=300&q=70',
      label: '200+ Exercises',
    ),
    _FeaturePhoto(
      image: 'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=300&q=70',
      label: 'Personalised Meals',
    ),
    _FeaturePhoto(
      image: 'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?w=300&q=70',
      label: 'Real-time Tracking',
    ),
    _FeaturePhoto(
      image: 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=300&q=70',
      label: 'Cloud Sync',
    ),
  ];

  // Avatar photos for social proof (no negative margin – use Stack instead)
  static const List<String> _avatarPhotos = [
    'https://images.unsplash.com/photo-1549060279-7e168fcee0c2?w=120&q=60',
    'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=120&q=60',
    'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=120&q=60',
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
            CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
    _redirectIfLoggedIn();
  }

  void _redirectIfLoggedIn() {
    final session = _supabase.auth.currentSession;
    if (session != null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/home');
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const NetworkImage(_heroBg), context);
    precacheImage(const NetworkImage(_mobileBg), context);
    for (final f in _featurePhotos) {
      precacheImage(NetworkImage(f.image), context);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────
  // AUTH LOGIC
  // ─────────────────────────────────────────

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields.');
      return;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (!mounted) return;
      if (response.user != null) {
        if (response.user!.emailConfirmedAt == null) {
          setState(() {
            _isLoading = false;
            _errorMessage =
                'Please verify your email first. Check your inbox and click the confirmation link.';
          });
          return;
        }
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on AuthException catch (e) {
      setState(() => _errorMessage = _mapAuthError(e.message));
    } catch (e) {
      setState(() => _errorMessage = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Enter your email above, then tap Forgot password.');
      return;
    }
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      if (mounted) setState(() => _errorMessage = 'Password reset email sent! Check your inbox.');
    } on AuthException catch (e) {
      setState(() => _errorMessage = _mapAuthError(e.message));
    } catch (_) {
      setState(() => _errorMessage = 'Could not send reset email. Try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _mapAuthError(String message) {
    final msg = message.toLowerCase();
    if (msg.contains('invalid login credentials') || msg.contains('invalid credentials'))
      return 'Incorrect email or password. Please try again.';
    if (msg.contains('email not confirmed'))
      return 'Please verify your email. Check your inbox for the confirmation link.';
    if (msg.contains('too many requests'))
      return 'Too many attempts. Please wait a moment and try again.';
    if (msg.contains('user not found'))
      return 'No account found with this email. Sign up first!';
    if (msg.contains('network'))
      return 'Network error. Check your internet connection.';
    return message;
  }

  // ─────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return _buildWebLayout();
    return _buildMobileLayout();
  }

  // ─────────────────────────────────────────
  // SHARED FORM WIDGETS
  // ─────────────────────────────────────────

  Widget _buildLogo({double size = 48, double fontSize = 20}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withOpacity(0.15),
            border: Border.all(color: AppColors.primary.withOpacity(0.5), width: 2),
          ),
          child: ClipOval(
            child: Image.network(
              'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=100&q=60',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Icon(Icons.fitness_center, size: size * 0.5, color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(width: 10),
        ShaderMask(
          shaderCallback: (bounds) =>
              const LinearGradient(colors: [Color(0xFF5EFC82), Color(0xFF00C853)])
                  .createShader(bounds),
          child: Text('FitLife',
              style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1)),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color cardColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    bool obscure = false,
    Widget? suffix,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    VoidCallback? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: cardColor,
            border: Border.all(color: borderColor),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            onSubmitted: onSubmitted != null ? (_) => onSubmitted() : null,
            style: TextStyle(fontSize: 14, color: textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(fontSize: 14, color: textSecondary.withOpacity(0.5)),
              prefixIcon: Icon(icon, size: 18, color: textSecondary),
              suffixIcon: suffix,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBox(String message, {bool isError = true}) {
    final color = isError ? const Color(0xFFFF1744) : AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withOpacity(0.08),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: TextStyle(
                    fontSize: 12, color: color, fontWeight: FontWeight.w500, height: 1.4)),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _handleLogin,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: _isLoading
              ? LinearGradient(colors: [
                  AppColors.primary.withOpacity(0.5),
                  AppColors.primary.withOpacity(0.5)
                ])
              : const LinearGradient(colors: [Color(0xFF5EFC82), Color(0xFF00C853)]),
          boxShadow: _isLoading
              ? []
              : [BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 6))],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
              : const Text('Sign In',
                  style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }

  Widget _buildDivider(Color textSecondary) {
    return Row(
      children: [
        Expanded(child: Divider(color: textSecondary.withOpacity(0.2), height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text('or', style: TextStyle(fontSize: 12, color: textSecondary.withOpacity(0.5))),
        ),
        Expanded(child: Divider(color: textSecondary.withOpacity(0.2), height: 1)),
      ],
    );
  }

  Widget _buildGoogleButton({required Color cardColor, required Color borderColor, required Color textPrimary}) {
    return GestureDetector(
      onTap: _isLoading ? null : () {},
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: cardColor,
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('G', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF4285F4))),
            const SizedBox(width: 10),
            Text('Continue with Google',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _buildFormContent({
    required Color textPrimary,
    required Color textSecondary,
    required Color cardColor,
    required Color borderColor,
  }) {
    final isSuccessMsg = _errorMessage != null &&
        _errorMessage!.contains('sent') &&
        !_errorMessage!.contains('not');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputField(
          controller: _emailController,
          label: 'Email',
          hint: 'you@example.com',
          icon: Icons.email_outlined,
          cardColor: cardColor,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _buildInputField(
          controller: _passwordController,
          label: 'Password',
          hint: '••••••••',
          icon: Icons.lock_outline_rounded,
          cardColor: cardColor,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          obscure: _obscurePassword,
          textInputAction: TextInputAction.done,
          onSubmitted: _handleLogin,
          suffix: GestureDetector(
            onTap: () => setState(() => _obscurePassword = !_obscurePassword),
            child: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 18, color: textSecondary),
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: _isLoading ? null : _handleForgotPassword,
            child: const Text('Forgot password?',
                style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 20),
        if (_errorMessage != null) ...[
          _buildMessageBox(_errorMessage!, isError: !isSuccessMsg),
          const SizedBox(height: 16),
        ],
        _buildLoginButton(),
        const SizedBox(height: 20),
        _buildDivider(textSecondary),
        const SizedBox(height: 20),
        _buildGoogleButton(cardColor: cardColor, borderColor: borderColor, textPrimary: textPrimary),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Don't have an account? ", style: TextStyle(fontSize: 13, color: textSecondary)),
            GestureDetector(
              onTap: () => Navigator.pushReplacementNamed(context, '/register'),
              child: const Text('Sign Up Free',
                  style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ],
    );
  }

  // ─────────────────────────────────────────
  // MOBILE LAYOUT
  // ─────────────────────────────────────────
  Widget _buildMobileLayout() {
    const textPrimary = Colors.white;
    const textSecondary = Color(0xFFB0B0B0);
    final cardColor = Colors.black.withOpacity(0.55);
    final borderColor = Colors.white.withOpacity(0.15);
    final inputCardColor = Colors.white.withOpacity(0.08);

    return Scaffold(
      backgroundColor: const Color(0xFF050A05),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full-bleed background photo
          Image.network(
            _mobileBg,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            frameBuilder: (ctx, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded || frame != null) return child;
              return Container(color: const Color(0xFF050A05));
            },
            errorBuilder: (_, __, ___) => Container(color: const Color(0xFF050A05)),
          ),

          // Dark gradient overlay
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xCC000000),
                  Color(0x44000000),
                  Color(0x44000000),
                  Color(0xEE050A05),
                ],
                stops: [0.0, 0.25, 0.45, 1.0],
              ),
            ),
          ),

          // Accent green tint from bottom
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  AppColors.primary.withOpacity(0.18),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5],
              ),
            ),
          ),

          // Content
          FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withOpacity(0.4),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded,
                              size: 15, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildLogo(size: 48, fontSize: 22),
                      const SizedBox(height: 24),
                      const Text('Welcome back',
                          style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.1)),
                      const SizedBox(height: 6),
                      Text('Sign in to continue your fitness journey.',
                          style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.6))),
                      const SizedBox(height: 32),

                      // Frosted glass form card
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          color: cardColor,
                          border: Border.all(color: borderColor),
                        ),
                        child: _buildFormContent(
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          cardColor: inputCardColor,
                          borderColor: Colors.white.withOpacity(0.12),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildMobilePhotoRow(),
                      const SizedBox(height: 24),
                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.pushReplacementNamed(context, '/home'),
                          child: Text('Continue as Guest →',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.45),
                                  fontWeight: FontWeight.w500)),
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
    );
  }

  Widget _buildMobilePhotoRow() {
    return Row(
      children: [
        // Overlapping avatars — Stack+Positioned (no negative margins)
        SizedBox(
          width: 76,
          height: 36,
          child: Stack(
            children: List.generate(_avatarPhotos.length, (i) => Positioned(
              left: i * 22.0,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF050A05), width: 2),
                ),
                child: ClipOval(
                  child: Image.network(
                    _avatarPhotos[i],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: AppColors.primary.withOpacity(0.3)),
                  ),
                ),
              ),
            )),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(5, (_) =>
                  const Icon(Icons.star_rounded, size: 12, color: Color(0xFFFFD600))),
            ),
            const SizedBox(height: 3),
            Text('10,000+ athletes trust FitLife',
                style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.45))),
          ],
        ),
      ],
    );
  }

  // ─────────────────────────────────────────
  // WEB LAYOUT
  // ─────────────────────────────────────────
  Widget _buildWebLayout() {
    const textPrimary = Colors.white;
    const textSecondary = Color(0xFFB0B0B0);
    final cardColor = Colors.white.withOpacity(0.06);
    final borderColor = Colors.white.withOpacity(0.1);
    final inputCardColor = Colors.white.withOpacity(0.07);

    return Scaffold(
      backgroundColor: const Color(0xFF030806),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Row(
          children: [
            // ── Left: full-height photo showcase ──────────────────────────
            Expanded(
              flex: 52,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Hero background photo — fills the entire left panel
                  Image.network(
                    _heroBg,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    frameBuilder: (ctx, child, frame, wasSynchronouslyLoaded) {
                      if (wasSynchronouslyLoaded || frame != null) return child;
                      return Container(color: const Color(0xFF0A1A0A));
                    },
                    errorBuilder: (_, __, ___) => Container(color: const Color(0xFF030806)),
                  ),

                  // Right-edge blend into the dark right panel
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
                        stops: const [0.0, 0.1, 0.7, 1.0],
                      ),
                    ),
                  ),

                  // Green accent tint from bottom
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          AppColors.primary.withOpacity(0.45),
                          AppColors.primary.withOpacity(0.0),
                        ],
                        stops: const [0.0, 0.6],
                      ),
                    ),
                  ),

                  // Dark top gradient for logo readability
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xBB000000), Colors.transparent],
                        stops: [0.0, 0.3],
                      ),
                    ),
                  ),

                  // Subtle grid
                  CustomPaint(painter: _WebGridPainter(AppColors.primary)),

                  // Top-left logo
                  Positioned(
                    top: 40,
                    left: 44,
                    child: _buildLogo(size: 44, fontSize: 20),
                  ),

                  // Bottom content overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(44, 48, 44, 48),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black.withOpacity(0.9), Colors.transparent],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Badge
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary,
                                  boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.7), blurRadius: 10)],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text('SIGN IN  ·  FITLIFE',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.primary,
                                      letterSpacing: 2.5,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 18),
                          const Text('Train Smarter.\nLive Stronger.',
                              style: TextStyle(
                                  fontSize: 38,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.15)),
                          const SizedBox(height: 12),
                          Text('Join thousands of athletes tracking\ntheir fitness journey with FitLife.',
                              style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.6), height: 1.6)),
                          const SizedBox(height: 24),

                          // Feature photo strip
                          _buildWebPhotoStrip(),

                          const SizedBox(height: 20),

                          // Social proof — Stack+Positioned overlapping avatars (NO negative margins)
                          Row(
                            children: [
                              SizedBox(
                                width: 76,
                                height: 32,
                                child: Stack(
                                  children: List.generate(_avatarPhotos.length, (i) => Positioned(
                                    left: i * 18.0,
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: const Color(0xFF030806), width: 2),
                                      ),
                                      child: ClipOval(
                                        child: Image.network(
                                          _avatarPhotos[i],
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              Container(color: AppColors.primary.withOpacity(0.3)),
                                        ),
                                      ),
                                    ),
                                  )),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: List.generate(5, (_) =>
                                      const Icon(Icons.star_rounded, size: 12, color: Color(0xFFFFD600)))),
                                  const SizedBox(height: 3),
                                  Text('10,000+ athletes trust FitLife',
                                      style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.5))),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Right: form panel ──────────────────────────────────────────
            Expanded(
              flex: 48,
              child: Container(
                color: const Color(0xFF030806),
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 48),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: SlideTransition(
                        position: _slideAnim,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.arrow_back_ios_new_rounded, size: 13, color: textSecondary),
                                  const SizedBox(width: 6),
                                  Text('Back', style: TextStyle(fontSize: 13, color: textSecondary)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 36),
                            const Text('Welcome back',
                                style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    height: 1.1)),
                            const SizedBox(height: 6),
                            Text('Sign in to your FitLife account.',
                                style: TextStyle(fontSize: 14, color: textSecondary)),
                            const SizedBox(height: 32),
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: cardColor,
                                border: Border.all(color: borderColor),
                              ),
                              child: _buildFormContent(
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                                cardColor: inputCardColor,
                                borderColor: Colors.white.withOpacity(0.12),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Center(
                              child: GestureDetector(
                                onTap: () => Navigator.pushReplacementNamed(context, '/home'),
                                child: Text('Continue as Guest →',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: textSecondary,
                                        fontWeight: FontWeight.w500)),
                              ),
                            ),
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
      ),
    );
  }

  Widget _buildWebPhotoStrip() {
    return Row(
      children: _featurePhotos.map((fp) => Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 90,
                height: 64,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(fp.image, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(color: AppColors.primary.withOpacity(0.2))),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black.withOpacity(0.5), Colors.transparent],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(fp.label,
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.55),
                    fontWeight: FontWeight.w600)),
          ],
        ),
      )).toList(),
    );
  }
}

// ── Data model ─────────────────────────────────────────────────────────────────
class _FeaturePhoto {
  final String image;
  final String label;
  const _FeaturePhoto({required this.image, required this.label});
}

// ── Grid painter ──────────────────────────────────────────────────────────────
class _WebGridPainter extends CustomPainter {
  final Color color;
  _WebGridPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withOpacity(0.04)..strokeWidth = 0.5;
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