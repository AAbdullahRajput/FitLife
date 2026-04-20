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
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (kIsWeb) return _buildWebLayout(isDark);
    return _buildMobileLayout(isDark);
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
            border:
                Border.all(color: AppColors.primary.withOpacity(0.5), width: 2),
          ),
          child: Center(
              child: Text('🏋️',
                  style: TextStyle(fontSize: size * 0.5))),
        ),
        const SizedBox(width: 10),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF5EFC82), Color(0xFF00C853)],
          ).createShader(bounds),
          child: Text(
            'FitLife',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textPrimary)),
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
            style: TextStyle(fontSize: 14, color: textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle:
                  TextStyle(fontSize: 14, color: textSecondary.withOpacity(0.5)),
              prefixIcon: Icon(icon, size: 18, color: textSecondary),
              suffixIcon: suffix,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBox(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFFF1744).withOpacity(0.08),
        border: Border.all(color: const Color(0xFFFF1744).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 16, color: Color(0xFFFF1744)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFFF1744),
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton({bool wide = false}) {
    return GestureDetector(
      onTap: _isLoading ? null : _handleLogin,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: wide ? double.infinity : double.infinity,
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: _isLoading
              ? LinearGradient(colors: [
                  AppColors.primary.withOpacity(0.5),
                  AppColors.primary.withOpacity(0.5),
                ])
              : const LinearGradient(
                  colors: [Color(0xFF5EFC82), Color(0xFF00C853)]),
          boxShadow: _isLoading
              ? []
              : [
                  BoxShadow(
                      color: AppColors.primary.withOpacity(0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 6))
                ],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.black, strokeWidth: 2))
              : const Text('Sign In',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3)),
        ),
      ),
    );
  }

  Widget _buildDivider(Color textSecondary) {
    return Row(
      children: [
        Expanded(
            child: Divider(color: textSecondary.withOpacity(0.2), height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text('or',
              style:
                  TextStyle(fontSize: 12, color: textSecondary.withOpacity(0.5))),
        ),
        Expanded(
            child: Divider(color: textSecondary.withOpacity(0.2), height: 1)),
      ],
    );
  }

  Widget _buildGoogleButton({
    required Color cardColor,
    required Color borderColor,
    required Color textPrimary,
  }) {
    return GestureDetector(
      onTap: () {}, // TODO: Google sign-in
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
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterLink(Color textSecondary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Don't have an account? ",
            style: TextStyle(fontSize: 13, color: textSecondary)),
        GestureDetector(
          onTap: () => Navigator.pushReplacementNamed(context, '/register'),
          child: const Text('Sign Up Free',
              style: TextStyle(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _buildForgotPassword(Color textSecondary) {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: () {}, // TODO: forgot password
        child: Text('Forgot password?',
            style: TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildFormContent({
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color cardColor,
    required Color borderColor,
  }) {
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
          suffix: GestureDetector(
            onTap: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            child: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 18,
                color: textSecondary),
          ),
        ),
        const SizedBox(height: 10),
        _buildForgotPassword(textSecondary),
        const SizedBox(height: 20),
        if (_errorMessage != null) ...[
          _buildErrorBox(_errorMessage!),
          const SizedBox(height: 16),
        ],
        _buildLoginButton(),
        const SizedBox(height: 20),
        _buildDivider(textSecondary),
        const SizedBox(height: 20),
        _buildGoogleButton(
            cardColor: cardColor,
            borderColor: borderColor,
            textPrimary: textPrimary),
        const SizedBox(height: 24),
        _buildRegisterLink(textSecondary),
      ],
    );
  }

  // ─────────────────────────────────────────
  // MOBILE LAYOUT
  // ─────────────────────────────────────────
  Widget _buildMobileLayout(bool isDark) {
    final textPrimary =
        isDark ? Colors.white : const Color(0xFF0A0A0A);
    final textSecondary =
        isDark ? const Color(0xFFB0B0B0) : const Color(0xFF555555);
    final bgColor =
        isDark ? const Color(0xFF050A05) : const Color(0xFFF5F5F5);
    final cardColor =
        isDark ? const Color(0xFF141414) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);

    return Scaffold(
      backgroundColor: bgColor,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cardColor,
                        border: Border.all(color: borderColor),
                      ),
                      child: Icon(Icons.arrow_back_ios_new_rounded,
                          size: 15, color: textPrimary),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Hero section
                  _buildLogo(size: 48, fontSize: 22),
                  const SizedBox(height: 28),

                  Text('Welcome back 👋',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                          height: 1.2)),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to continue your fitness journey.',
                    style: TextStyle(fontSize: 14, color: textSecondary),
                  ),

                  const SizedBox(height: 36),

                  // Stats strip
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: isDark
                          ? const Color(0xFF0D1F0D)
                          : const Color(0xFFE8F5E9),
                      border: Border.all(
                          color: AppColors.primary.withOpacity(0.25)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatPill('💪', '200+', 'Exercises'),
                        _buildStatDivider(),
                        _buildStatPill('🥗', '50+', 'Meal Plans'),
                        _buildStatDivider(),
                        _buildStatPill('📊', 'Live', 'Tracking'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Form card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: cardColor,
                      border: Border.all(color: borderColor),
                      boxShadow: isDark
                          ? []
                          : [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4))
                            ],
                    ),
                    child: _buildFormContent(
                      isDark: isDark,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      cardColor: isDark
                          ? const Color(0xFF1E1E1E)
                          : const Color(0xFFF8F8F8),
                      borderColor: borderColor,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Guest option
                  Center(
                    child: GestureDetector(
                      onTap: () =>
                          Navigator.pushReplacementNamed(context, '/home'),
                      child: Text(
                        'Continue as Guest →',
                        style: TextStyle(
                            fontSize: 13,
                            color: textSecondary,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatPill(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.primary)),
        Text(label,
            style: const TextStyle(fontSize: 10, color: AppColors.primary)),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
        width: 1, height: 36, color: AppColors.primary.withOpacity(0.2));
  }

  // ─────────────────────────────────────────
  // WEB LAYOUT
  // ─────────────────────────────────────────
  Widget _buildWebLayout(bool isDark) {
    final textPrimary =
        isDark ? Colors.white : const Color(0xFF0A0A0A);
    final textSecondary =
        isDark ? const Color(0xFFB0B0B0) : const Color(0xFF555555);
    final bgColor =
        isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF0F2F5);
    final cardColor =
        isDark ? const Color(0xFF141414) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);
    final sidebarColor =
        isDark ? const Color(0xFF0D0D0D) : const Color(0xFF1A1A2E);

    return Scaffold(
      backgroundColor: bgColor,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Row(
          children: [
            // ── Left panel — branding (flex: 1, properly centered) ──
            Expanded(
              flex: 1,
              child: Container(
                color: sidebarColor,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 48, vertical: 48),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLogo(size: 44, fontSize: 22),
                          const SizedBox(height: 56),

                          // Big headline
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Color(0xFF5EFC82), Color(0xFF00C853)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds),
                            child: const Text(
                              'Train smarter.\nEat better.\nLive stronger.',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.25,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),
                          Text(
                            'Join thousands of athletes tracking\ntheir fitness journey with FitLife.',
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.5),
                                height: 1.6),
                          ),

                          const SizedBox(height: 40),

                          // Feature list
                          ...[
                            ('💪', '200+ exercises with variations'),
                            ('🥗', 'Personalised daily meal plans'),
                            ('📊', 'Real-time progress tracking'),
                            ('☁️', 'Cloud sync across all devices'),
                          ].map((item) => Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.primary.withOpacity(0.1),
                                        border: Border.all(
                                            color: AppColors.primary.withOpacity(0.2)),
                                      ),
                                      child: Center(
                                          child: Text(item.$1,
                                              style: const TextStyle(fontSize: 16))),
                                    ),
                                    const SizedBox(width: 14),
                                    Text(item.$2,
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.white.withOpacity(0.7),
                                            fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              )),

                          const Spacer(),

                          // Social proof
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: Colors.white.withOpacity(0.04),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.08)),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 74,
                                  height: 32,
                                  child: Stack(
                                    children: [
                                      _buildAvatarCircle('🏋️', 0),
                                      _buildAvatarCircle('🧘', 24),
                                      _buildAvatarCircle('🚴', 48),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: List.generate(
                                            5,
                                            (_) => const Icon(Icons.star_rounded,
                                                size: 12,
                                                color: Color(0xFFFFD600))),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '10,000+ athletes trust FitLife',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.white.withOpacity(0.5)),
                                      ),
                                    ],
                                  ),
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
            ),

            // ── Right panel — form (flex: 1, properly centered) ──
            Expanded(
              flex: 1,
              child: Container(
                color: bgColor,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 48),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Back button
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.arrow_back_ios_new_rounded,
                                    size: 13, color: textSecondary),
                                const SizedBox(width: 6),
                                Text('Back',
                                    style: TextStyle(
                                        fontSize: 13, color: textSecondary)),
                              ],
                            ),
                          ),

                          const SizedBox(height: 40),

                          Text('Welcome back 👋',
                              style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                  height: 1.2)),
                          const SizedBox(height: 8),
                          Text('Sign in to your FitLife account.',
                              style: TextStyle(fontSize: 14, color: textSecondary)),

                          const SizedBox(height: 32),

                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: cardColor,
                              border: Border.all(color: borderColor),
                              boxShadow: isDark
                                  ? []
                                  : [
                                      BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 24,
                                          offset: const Offset(0, 4))
                                    ],
                            ),
                            child: _buildFormContent(
                              isDark: isDark,
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                              cardColor: isDark
                                  ? const Color(0xFF1E1E1E)
                                  : const Color(0xFFF8F8F8),
                              borderColor: borderColor,
                            ),
                          ),

                          const SizedBox(height: 24),

                          Center(
                            child: GestureDetector(
                              onTap: () => Navigator.pushReplacementNamed(
                                  context, '/home'),
                              child: Text(
                                'Continue as Guest →',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: textSecondary,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
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
      ),
    );
  }

  Widget _buildAvatarCircle(String emoji, double left) {
    return Positioned(
      left: left,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary.withOpacity(0.15),
          border:
              Border.all(color: const Color(0xFF1A1A2E), width: 2),
        ),
        child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 14))),
      ),
    );
  }
}