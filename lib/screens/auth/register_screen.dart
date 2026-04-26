// lib/screens/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _agreedToTerms = false;
  String? _errorMessage;
  String? _successMessage;

  String _selectedGoal = 'Build Muscle';

  final _supabase = Supabase.instance.client;

  // ── Photos ──────────────────────────────────────────────────────────────
  static const String _mobileBg =
      'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=900&q=80';

  static const List<_GoalPhoto> _goalPhotos = [
    _GoalPhoto(
      goal: 'Build Muscle',
      image: 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=1400&q=80',
      color: Color(0xFF2979FF),
    ),
    _GoalPhoto(
      goal: 'Lose Weight',
      image: 'https://images.unsplash.com/photo-1476480862126-209bfaa8edc8?w=1400&q=80',
      color: Color(0xFFFF6D00),
    ),
    _GoalPhoto(
      goal: 'Stay Fit',
      image: 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=1400&q=80',
      color: Color(0xFF00C853),
    ),
    _GoalPhoto(
      goal: 'Improve Endurance',
      image: 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=1400&q=80',
      color: Color(0xFFFFD600),
    ),
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const NetworkImage(_mobileBg), context);
    for (final g in _goalPhotos) {
      precacheImage(NetworkImage(g.image), context);
    }
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
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────
  // AUTH LOGIC
  // ─────────────────────────────────────────

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields.');
      return;
    }
    if (name.length < 2) {
      setState(() => _errorMessage = 'Name must be at least 2 characters.');
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }
    if (password != confirm) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }
    if (!_agreedToTerms) {
      setState(() => _errorMessage = 'Please agree to the Terms & Privacy Policy.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name, 'goal': _selectedGoal},
      );
      if (!mounted) return;
      if (response.user == null) {
        setState(() => _errorMessage = 'Registration failed. Please try again.');
        return;
      }
      final user = response.user!;
      if (user.identities != null && user.identities!.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'An account with this email already exists. Try signing in.';
        });
        return;
      }
      try {
        await _supabase.from('profiles').upsert({
          'id': user.id,
          'full_name': name,
          'email': email,
          'goal': _selectedGoal,
          'tier': 'free',
          'created_at': DateTime.now().toIso8601String(),
        }, onConflict: 'id');
      } catch (profileError) {
        debugPrint('Profile upsert error (non-fatal): $profileError');
      }
      if (mounted) {
        _nameController.clear();
        _emailController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();
        setState(() => _agreedToTerms = false);
        setState(() {
          _successMessage = 'Account created! You can now sign in.';
        });
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
      }
    } on AuthException catch (e) {
      setState(() => _errorMessage = _mapAuthError(e.message));
    } catch (e) {
      setState(() => _errorMessage = 'Something went wrong. Please try again.');
      debugPrint('Register error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _mapAuthError(String message) {
    final msg = message.toLowerCase();
    if (msg.contains('user already registered') ||
        msg.contains('already registered') ||
        msg.contains('already exists'))
      return 'An account with this email already exists. Try signing in.';
    if (msg.contains('invalid email') || msg.contains('email is invalid'))
      return 'Please enter a valid email address (e.g. you@gmail.com).';
    if (msg.contains('password should be at least'))
      return 'Password must be at least 6 characters.';
    if (msg.contains('too many requests') || msg.contains('email rate limit'))
      return 'Too many attempts. Please wait a moment and try again.';
    if (msg.contains('network') || msg.contains('connection'))
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
  // SHARED WIDGETS
  // ─────────────────────────────────────────

  Widget _buildLogo({double size = 44, double fontSize = 20}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: AppColors.primary.withOpacity(0.5), width: 2),
          ),
          child: ClipOval(
            child: Image.network(
              'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=100&q=60',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                  color: AppColors.primary.withOpacity(0.2),
                  child: Icon(Icons.fitness_center,
                      color: AppColors.primary, size: size * 0.45)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF5EFC82), Color(0xFF00C853)])
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
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textPrimary)),
        const SizedBox(height: 6),
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
            onSubmitted:
                onSubmitted != null ? (_) => onSubmitted() : null,
            style: TextStyle(fontSize: 14, color: textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                  fontSize: 14,
                  color: textSecondary.withOpacity(0.5)),
              prefixIcon:
                  Icon(icon, size: 18, color: textSecondary),
              suffixIcon: suffix,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  vertical: 14, horizontal: 4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalSelector({required Color textPrimary}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your Goal',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textPrimary)),
        const SizedBox(height: 10),
        Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildGoalChip(_goalPhotos[0])),
                const SizedBox(width: 8),
                Expanded(child: _buildGoalChip(_goalPhotos[1])),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildGoalChip(_goalPhotos[2])),
                const SizedBox(width: 8),
                Expanded(child: _buildGoalChip(_goalPhotos[3])),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGoalChip(_GoalPhoto gp) {
    final isSel = _selectedGoal == gp.goal;
    return GestureDetector(
      onTap: () => setState(() => _selectedGoal = gp.goal),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 62,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSel ? gp.color : Colors.white.withOpacity(0.15),
            width: isSel ? 2.5 : 1,
          ),
          boxShadow: isSel
              ? [BoxShadow(color: gp.color.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 4))]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                gp.image,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (_, __, ___) => Container(color: gp.color.withOpacity(0.3)),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.25),
                      isSel ? gp.color.withOpacity(0.65) : Colors.black.withOpacity(0.55),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 9,
                left: 6,
                right: 6,
                child: Center(
                  child: Text(
                    gp.goal,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isSel ? gp.color : Colors.white,
                      letterSpacing: 0.2,
                      shadows: const [Shadow(blurRadius: 6, color: Colors.black)],
                    ),
                  ),
                ),
              ),
              if (isSel)
                Positioned(
                  top: 7,
                  right: 7,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: gp.color),
                    child: const Icon(Icons.check_rounded, size: 12, color: Colors.black),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTermsRow({required Color textPrimary, required Color textSecondary}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: _agreedToTerms ? AppColors.primary : Colors.transparent,
              border: Border.all(
                color: _agreedToTerms ? AppColors.primary : textSecondary.withOpacity(0.4),
                width: 2,
              ),
            ),
            child: _agreedToTerms
                ? const Icon(Icons.check_rounded, size: 13, color: Colors.black)
                : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 12, color: textSecondary, height: 1.5),
              children: const [
                TextSpan(text: 'I agree to the '),
                TextSpan(
                    text: 'Terms of Service',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                TextSpan(text: ' and '),
                TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBox(String message, {bool isError = true}) {
    final color = isError ? const Color(0xFFFF1744) : AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                      fontSize: 12, color: color, fontWeight: FontWeight.w500, height: 1.4))),
        ],
      ),
    );
  }

  Widget _buildRegisterButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _handleRegister,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 50,
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
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
              : const Text('Create Free Account',
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

  Widget _buildGoogleButton({
    required Color cardColor,
    required Color borderColor,
    required Color textPrimary,
  }) {
    return GestureDetector(
      onTap: _isLoading ? null : () {},
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: cardColor,
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('G',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF4285F4))),
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
    bool compact = false,
  }) {
    final gap = compact ? 10.0 : 14.0;
    final sg = compact ? 12.0 : 16.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputField(
            controller: _nameController,
            label: 'Full Name',
            hint: 'Abdullah Khan',
            icon: Icons.person_outline_rounded,
            cardColor: cardColor,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary),
        SizedBox(height: gap),
        _buildInputField(
            controller: _emailController,
            label: 'Email',
            hint: 'you@example.com',
            icon: Icons.email_outlined,
            cardColor: cardColor,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            keyboardType: TextInputType.emailAddress),
        SizedBox(height: gap),
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
            onTap: () => setState(() => _obscurePassword = !_obscurePassword),
            child: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 18, color: textSecondary),
          ),
        ),
        SizedBox(height: gap),
        _buildInputField(
          controller: _confirmPasswordController,
          label: 'Confirm Password',
          hint: '••••••••',
          icon: Icons.lock_outline_rounded,
          cardColor: cardColor,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          obscure: _obscureConfirm,
          textInputAction: TextInputAction.done,
          onSubmitted: _handleRegister,
          suffix: GestureDetector(
            onTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
            child: Icon(
                _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 18, color: textSecondary),
          ),
        ),
        SizedBox(height: sg),
        _buildGoalSelector(textPrimary: textPrimary),
        SizedBox(height: sg),
        _buildTermsRow(textPrimary: textPrimary, textSecondary: textSecondary),
        SizedBox(height: sg),
        if (_errorMessage != null) ...[
          _buildMessageBox(_errorMessage!, isError: true),
          SizedBox(height: gap)
        ],
        if (_successMessage != null) ...[
          _buildMessageBox(_successMessage!, isError: false),
          SizedBox(height: gap)
        ],
        _buildRegisterButton(),
        SizedBox(height: sg),
        _buildDivider(textSecondary),
        SizedBox(height: sg),
        _buildGoogleButton(cardColor: cardColor, borderColor: borderColor, textPrimary: textPrimary),
        SizedBox(height: compact ? 16 : 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Already have an account? ',
                style: TextStyle(fontSize: 13, color: textSecondary)),
            GestureDetector(
              onTap: () => Navigator.pushReplacementNamed(context, '/login'),
              child: const Text('Sign In',
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
    final inputCardColor = Colors.white.withOpacity(0.08);
    final borderColor = Colors.white.withOpacity(0.15);

    return Scaffold(
      backgroundColor: const Color(0xFF050A05),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(_mobileBg,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              frameBuilder: (ctx, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded || frame != null) return child;
                return Container(color: const Color(0xFF050A05));
              },
              errorBuilder: (_, __, ___) => Container(color: const Color(0xFF050A05))),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xDD000000),
                  Color(0x33000000),
                  Color(0x55000000),
                  Color(0xEE050A05),
                ],
                stops: [0.0, 0.2, 0.5, 1.0],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [AppColors.primary.withOpacity(0.15), Colors.transparent],
                stops: const [0.0, 0.55],
              ),
            ),
          ),
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
                          width: 38, height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withOpacity(0.4),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded,
                              size: 15, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 28),
                      _buildLogo(size: 44, fontSize: 20),
                      const SizedBox(height: 20),
                      const Text('Create your account',
                          style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.1)),
                      const SizedBox(height: 6),
                      Text('Join FitLife free and start your journey today.',
                          style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.6))),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(20),
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
                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.pushReplacementNamed(context, '/home'),
                          child: Text('Continue as Guest →',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.4),
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

  // ─────────────────────────────────────────
  // WEB LAYOUT — KEY FIX: Positioned.fill on AnimatedSwitcher
  // ─────────────────────────────────────────
  Widget _buildWebLayout() {
    const textPrimary = Colors.white;
    const textSecondary = Color(0xFFB0B0B0);
    final cardColor = Colors.white.withOpacity(0.07);
    final borderColor = Colors.white.withOpacity(0.12);
    final inputCardColor = Colors.white.withOpacity(0.08);

    final activeGoal = _goalPhotos.firstWhere((g) => g.goal == _selectedGoal);

    return Scaffold(
      backgroundColor: const Color(0xFF030806),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Row(
          children: [
            // ── Left: animated goal photo showcase — FULL HEIGHT ───────────
            Expanded(
              flex: 52,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // KEY FIX: Positioned.fill + SizedBox.expand so the
                  // AnimatedSwitcher and its children fill the entire panel
                  Positioned.fill(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 600),
                      child: SizedBox.expand(
                        key: ValueKey(activeGoal.goal),
                        child: Image.network(
                          activeGoal.image,
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                          frameBuilder: (ctx, child, frame, wasSynchronouslyLoaded) {
                            if (wasSynchronouslyLoaded || frame != null) return child;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              color: activeGoal.color.withOpacity(0.1),
                            );
                          },
                          errorBuilder: (_, __, ___) =>
                              Container(color: const Color(0xFF030806)),
                        ),
                      ),
                    ),
                  ),

                  // Right-edge blend into the dark right panel
                  Positioned.fill(
                    child: Container(
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
                  ),

                  // Animated accent tint from bottom
                  Positioned.fill(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 450),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            activeGoal.color.withOpacity(0.55),
                            activeGoal.color.withOpacity(0.0),
                          ],
                          stops: const [0.0, 0.65],
                        ),
                      ),
                    ),
                  ),

                  // Top dark gradient for logo readability
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xBB000000), Colors.transparent],
                          stops: [0.0, 0.3],
                        ),
                      ),
                    ),
                  ),

                  // Subtle grid overlay
                  Positioned.fill(
                    child: CustomPaint(
                        painter: _WebGridPainter(activeGoal.color)),
                  ),

                  // Logo — top left
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
                          colors: [
                            Colors.black.withOpacity(0.92),
                            Colors.transparent,
                          ],
                        ),
                      ),
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
                                  color: activeGoal.color,
                                  boxShadow: [
                                    BoxShadow(
                                        color: activeGoal.color.withOpacity(0.7),
                                        blurRadius: 10)
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'CREATE ACCOUNT  ·  FITLIFE',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: activeGoal.color,
                                    letterSpacing: 2.5,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Your fitness\njourney starts here.',
                            style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.15),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Create your free account and get access to\nworkouts, meal plans and progress tracking.',
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.6),
                                height: 1.6),
                          ),
                          const SizedBox(height: 24),
                          // Goal thumbnail strip
                          Row(
                            children: _goalPhotos.map((gp) {
                              final isSel = _selectedGoal == gp.goal;
                              return GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedGoal = gp.goal),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  margin: const EdgeInsets.only(right: 10),
                                  width: isSel ? 110 : 80,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: isSel
                                            ? gp.color
                                            : Colors.white.withOpacity(0.2),
                                        width: isSel ? 2.5 : 1),
                                    boxShadow: isSel
                                        ? [BoxShadow(color: gp.color.withOpacity(0.4), blurRadius: 12)]
                                        : [],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.network(gp.image,
                                            fit: BoxFit.cover,
                                            opacity: AlwaysStoppedAnimation(isSel ? 0.8 : 0.5),
                                            errorBuilder: (_, __, ___) =>
                                                Container(color: gp.color.withOpacity(0.2))),
                                        Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.bottomCenter,
                                              end: Alignment.topCenter,
                                              colors: [
                                                gp.color.withOpacity(isSel ? 0.55 : 0.25),
                                                Colors.transparent,
                                              ],
                                            ),
                                          ),
                                        ),
                                        if (isSel)
                                          Positioned(
                                            bottom: 6,
                                            left: 0,
                                            right: 0,
                                            child: Center(
                                              child: Text(gp.goal,
                                                  style: TextStyle(
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.w700,
                                                      color: gp.color)),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Right: form panel ───────────────────────────────────────────
            Expanded(
              flex: 48,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Solid dark background
                  Container(color: const Color(0xFF030806)),
                  // Subtle green tint from bottom
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          AppColors.primary.withOpacity(0.07),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  // Form content
                  LayoutBuilder(builder: (context, constraints) {
                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.arrow_back_ios_new_rounded,
                                        size: 13, color: textSecondary),
                                    const SizedBox(width: 6),
                                    Text('Back',
                                        style: TextStyle(fontSize: 13, color: textSecondary)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text('Create your account',
                                  style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      height: 1.1)),
                              const SizedBox(height: 6),
                              Text('Join FitLife free and start your journey today.',
                                  style: TextStyle(fontSize: 13, color: textSecondary)),
                              const SizedBox(height: 16),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: cardColor,
                                    border: Border.all(color: borderColor),
                                  ),
                                  child: ScrollConfiguration(
                                    behavior: _NoScrollbarBehavior(),
                                    child: SingleChildScrollView(
                                      child: _buildFormContent(
                                        textPrimary: textPrimary,
                                        textSecondary: textSecondary,
                                        cardColor: inputCardColor,
                                        borderColor: Colors.white.withOpacity(0.12),
                                        compact: true,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Center(
                                child: GestureDetector(
                                  onTap: () =>
                                      Navigator.pushReplacementNamed(context, '/home'),
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
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Data model ──────────────────────────────────────────────────────────────
class _GoalPhoto {
  final String goal;
  final String image;
  final Color color;
  const _GoalPhoto({required this.goal, required this.image, required this.color});
}

// ── Suppress scrollbar ───────────────────────────────────────────────────────
class _NoScrollbarBehavior extends ScrollBehavior {
  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) => child;
}

// ── Grid painter ─────────────────────────────────────────────────────────────
class _WebGridPainter extends CustomPainter {
  final Color color;
  _WebGridPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.04)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 40)
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    for (double y = 0; y < size.height; y += 40)
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }

  @override
  bool shouldRepaint(covariant _WebGridPainter old) => old.color != color;
}