// lib/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_provider.dart';
import '../../services/storage_service.dart';

// ── Accent colours the user can choose from ──────────────────────────────────
const List<Color> _kAccentColors = [
  Color(0xFF00C853), // Default green
  Color(0xFF2979FF), // Blue
  Color(0xFFFF6D00), // Orange
  Color(0xFFAA00FF), // Purple
  Color(0xFFFF1744), // Red
  Color(0xFF00BCD4), // Cyan
  Color(0xFFFFD600), // Yellow
  Color(0xFFE91E63), // Pink
];

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // ── Supabase ──────────────────────────────────────────────────────────────
  final _supabase = Supabase.instance.client;
  bool get _isLoggedIn => _supabase.auth.currentSession != null;
  String get _userEmail =>
      _supabase.auth.currentUser?.email ?? 'Guest User';
  String get _userName =>
      (_supabase.auth.currentUser?.userMetadata?['full_name'] as String?) ??
      'Guest';

  // ── Notification toggles (UI only) ───────────────────────────────────────
  bool _workoutReminders = true;
  bool _mealReminders = true;
  bool _progressReminders = false;
  bool _weeklyReport = true;
  bool _achievementAlerts = true;

  // ── Workout preferences ───────────────────────────────────────────────────
  String _preferredWorkoutTime = 'Morning';
  int _workoutDuration = 45;
  String _fitnessLevel = 'Intermediate';
  bool _restDayReminder = true;
  bool _warmupReminder = true;

  // ── Diet preferences ──────────────────────────────────────────────────────
  String _dietType = 'Balanced';
  int _dailyCalorieGoal = 2000;
  bool _mealPrepMode = false;
  bool _waterReminder = true;
  int _waterGoalLiters = 3;

  // ── Privacy ───────────────────────────────────────────────────────────────
  bool _shareProgress = false;
  bool _analyticsEnabled = true;
  bool _crashReporting = true;

  // ── Accent colour ─────────────────────────────────────────────────────────
  Color _selectedAccent = _kAccentColors[0];

  // ── Loading / section state ───────────────────────────────────────────────
  bool _isLoggingOut = false;
  bool _isDeletingAccount = false;
  String? _expandedSection; // which section card is open on mobile

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LOGOUT
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _handleLogout() async {
    final confirmed = await _showConfirmDialog(
      title: 'Sign Out',
      message: 'Are you sure you want to sign out of FitLife?',
      confirmLabel: 'Sign Out',
      isDestructive: false,
    );
    if (!confirmed || !mounted) return;

    setState(() => _isLoggingOut = true);
    try {
      await _supabase.auth.signOut();
      await StorageService.setLoggedIn(false);
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (_) {
      setState(() => _isLoggingOut = false);
      if (mounted) _showSnack('Sign out failed. Please try again.', isError: true);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DELETE ACCOUNT
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _handleDeleteAccount() async {
    final confirmed = await _showConfirmDialog(
      title: 'Delete Account',
      message:
          'This will permanently delete your account and all data. This action cannot be undone.',
      confirmLabel: 'Delete Forever',
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;

    setState(() => _isDeletingAccount = true);
    try {
      // Delete profile row first
      if (_isLoggedIn) {
        await _supabase
            .from('profiles')
            .delete()
            .eq('id', _supabase.auth.currentUser!.id);
      }
      await _supabase.auth.signOut();
      await StorageService.clearAll();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/register');
      }
    } catch (_) {
      setState(() => _isDeletingAccount = false);
      if (mounted) {
        _showSnack('Could not delete account. Please try again.', isError: true);
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────────────
  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required bool isDestructive,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final textSecondary =
        isDark ? const Color(0xFFB0B0B0) : const Color(0xFF555555);
    final borderColor =
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);

    return await showDialog<bool>(
          context: context,
          barrierColor: Colors.black.withOpacity(0.6),
          builder: (ctx) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: 340,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 40,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (isDestructive
                              ? const Color(0xFFFF1744)
                              : AppColors.primary)
                          .withOpacity(0.12),
                    ),
                    child: Center(
                      child: Icon(
                        isDestructive
                            ? Icons.delete_forever_rounded
                            : Icons.logout_rounded,
                        color: isDestructive
                            ? const Color(0xFFFF1744)
                            : AppColors.primary,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(title,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: textPrimary)),
                  const SizedBox(height: 8),
                  Text(message,
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 13, color: textSecondary, height: 1.5)),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(ctx, false),
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: isDark
                                  ? const Color(0xFF252525)
                                  : const Color(0xFFF5F5F5),
                              border: Border.all(color: borderColor),
                            ),
                            child: Center(
                              child: Text('Cancel',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: textSecondary)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(ctx, true),
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                colors: isDestructive
                                    ? [
                                        const Color(0xFFFF1744),
                                        const Color(0xFFD50000)
                                      ]
                                    : [
                                        AppColors.primary,
                                        const Color(0xFF00C853)
                                      ],
                              ),
                            ),
                            child: Center(
                              child: Text(confirmLabel,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ) ??
        false;
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? const Color(0xFFFF1744) : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _saveSettings() {
    _showSnack('Settings saved successfully!');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (kIsWeb) return _buildWebLayout(isDark);
    return _buildMobileLayout(isDark);
  }

  // ═════════════════════════════════════════════════════════════════════════
  // WEB LAYOUT — two-column: left nav + right content
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildWebLayout(bool isDark) {
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final textSecondary =
        isDark ? const Color(0xFFB0B0B0) : const Color(0xFF555555);
    final bgColor =
        isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF0F2F5);
    final cardColor = isDark ? const Color(0xFF141414) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);
    final sidebarColor =
        isDark ? const Color(0xFF0D0D0D) : const Color(0xFF1A1A2E);

    _expandedSection ??= 'Account';

    return FadeTransition(
      opacity: _fadeAnim,
      child: Row(
        children: [
          // ── Left settings nav ────────────────────────────────────────────
          Container(
            width: 220,
            color: sidebarColor,
            child: Column(
              children: [
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: AppColors.primary.withOpacity(0.15),
                          border: Border.all(
                              color: AppColors.primary.withOpacity(0.4)),
                        ),
                        child: const Center(
                            child: Icon(Icons.settings_rounded,
                                size: 17, color: AppColors.primary)),
                      ),
                      const SizedBox(width: 10),
                      const Text('Settings',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Divider(color: Colors.white.withOpacity(0.08), height: 1),
                const SizedBox(height: 12),
                ..._settingsSections.map((s) {
                  final isActive = _expandedSection == s['label'];
                  return _WebSettingsNavItem(
                    icon: s['icon'] as IconData,
                    label: s['label'] as String,
                    isActive: isActive,
                    onTap: () =>
                        setState(() => _expandedSection = s['label'] as String),
                  );
                }),
                const Spacer(),
                // Logout button in sidebar
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: GestureDetector(
                    onTap: _isLoggingOut ? null : _handleLogout,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: const Color(0xFFFF1744).withOpacity(0.1),
                        border: Border.all(
                            color: const Color(0xFFFF1744).withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _isLoggingOut
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                      color: Color(0xFFFF1744), strokeWidth: 2))
                              : const Icon(Icons.logout_rounded,
                                  size: 15, color: Color(0xFFFF1744)),
                          const SizedBox(width: 8),
                          const Text('Sign Out',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFFF1744))),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          // ── Right content ────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: _buildSectionContent(
                    section: _expandedSection ?? 'Account',
                    isDark: isDark,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    cardColor: cardColor,
                    borderColor: borderColor,
                    webMode: true,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // MOBILE LAYOUT — scrollable sections with accordion cards
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildMobileLayout(bool isDark) {
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final textSecondary =
        isDark ? const Color(0xFFB0B0B0) : const Color(0xFF555555);
    final bgColor =
        isDark ? const Color(0xFF050A05) : const Color(0xFFF5F5F5);
    final cardColor = isDark ? const Color(0xFF141414) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);

    return Scaffold(
      backgroundColor: bgColor,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            // ── App bar ───────────────────────────────────────────────────
            SliverAppBar(
              pinned: true,
              backgroundColor: isDark ? const Color(0xFF0D0D0D) : Colors.white,
              elevation: 0,
              leading: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cardColor,
                    border: Border.all(color: borderColor),
                  ),
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      size: 15, color: textPrimary),
                ),
              ),
              title: Text('Settings',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: textPrimary)),
              actions: [
                GestureDetector(
                  onTap: _saveSettings,
                  child: Container(
                    margin: const EdgeInsets.only(right: 14),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                          colors: [Color(0xFF5EFC82), Color(0xFF00C853)]),
                    ),
                    child: const Text('Save',
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Divider(height: 1, color: borderColor),
              ),
            ),

            // ── User header ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: _buildUserHeader(
                    isDark, textPrimary, textSecondary, cardColor, borderColor),
              ),
            ),

            // ── Accordion sections ────────────────────────────────────────
            SliverList(
              delegate: SliverChildListDelegate([
                ..._settingsSections.map((s) => Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: _MobileAccordionSection(
                        icon: s['icon'] as IconData,
                        label: s['label'] as String,
                        color: s['color'] as Color,
                        isExpanded:
                            _expandedSection == s['label'],
                        onToggle: () => setState(() {
                          _expandedSection =
                              _expandedSection == s['label']
                                  ? null
                                  : s['label'] as String;
                        }),
                        child: _buildSectionContent(
                          section: s['label'] as String,
                          isDark: isDark,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          cardColor: isDark
                              ? const Color(0xFF1E1E1E)
                              : const Color(0xFFF8F8F8),
                          borderColor: borderColor,
                          webMode: false,
                        ),
                      ),
                    )),

                // Logout & Delete buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: _buildDangerZone(
                      isDark, textPrimary, textSecondary, cardColor, borderColor),
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SECTION ROUTER
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSectionContent({
    required String section,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color cardColor,
    required Color borderColor,
    required bool webMode,
  }) {
    switch (section) {
      case 'Account':
        return _buildAccountSection(
            isDark, textPrimary, textSecondary, cardColor, borderColor,
            webMode: webMode);
      case 'Appearance':
        return _buildAppearanceSection(
            isDark, textPrimary, textSecondary, cardColor, borderColor,
            webMode: webMode);
      case 'Notifications':
        return _buildNotificationsSection(
            isDark, textPrimary, textSecondary, cardColor, borderColor,
            webMode: webMode);
      case 'Workout Preferences':
        return _buildWorkoutPrefsSection(
            isDark, textPrimary, textSecondary, cardColor, borderColor,
            webMode: webMode);
      case 'Diet Preferences':
        return _buildDietPrefsSection(
            isDark, textPrimary, textSecondary, cardColor, borderColor,
            webMode: webMode);
      case 'Privacy':
        return _buildPrivacySection(
            isDark, textPrimary, textSecondary, cardColor, borderColor,
            webMode: webMode);
      case 'App Info':
        return _buildAppInfoSection(
            isDark, textPrimary, textSecondary, cardColor, borderColor,
            webMode: webMode);
      default:
        return const SizedBox.shrink();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // USER HEADER (mobile only)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildUserHeader(bool isDark, Color textPrimary, Color textSecondary,
      Color cardColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: cardColor,
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.15),
              border:
                  Border.all(color: AppColors.primary.withOpacity(0.4), width: 2),
            ),
            child: const Center(
                child: Icon(Icons.person_rounded,
                    size: 26, color: AppColors.primary)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_userName,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: textPrimary)),
                const SizedBox(height: 2),
                Text(_userEmail,
                    style: TextStyle(fontSize: 12, color: textSecondary)),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: AppColors.primary.withOpacity(0.15),
                  ),
                  child: Text(
                    _isLoggedIn ? '✅ Free Plan' : '👤 Guest',
                    style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ACCOUNT SECTION
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildAccountSection(bool isDark, Color textPrimary,
      Color textSecondary, Color cardColor, Color borderColor,
      {required bool webMode}) {
    return _SettingsGroup(
      webMode: webMode,
      isDark: isDark,
      cardColor: cardColor,
      borderColor: borderColor,
      title: webMode ? 'Account' : null,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      children: [
        if (webMode)
          _buildUserHeader(
              isDark, textPrimary, textSecondary, cardColor, borderColor),
        if (webMode) const SizedBox(height: 16),
        _SettingsItem(
          icon: Icons.person_outline_rounded,
          label: 'Display Name',
          value: _userName,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          borderColor: borderColor,
          onTap: () => _showSnack('Edit profile coming soon!'),
        ),
        _SettingsItem(
          icon: Icons.email_outlined,
          label: 'Email Address',
          value: _userEmail,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          borderColor: borderColor,
          onTap: () => _showSnack('Email change coming soon!'),
        ),
        _SettingsItem(
          icon: Icons.lock_outline_rounded,
          label: 'Change Password',
          value: '••••••••',
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          borderColor: borderColor,
          onTap: () async {
            if (!_isLoggedIn) {
              _showSnack('Sign in to change password.', isError: true);
              return;
            }
            final email = _supabase.auth.currentUser?.email;
            if (email != null) {
              await _supabase.auth.resetPasswordForEmail(email);
              _showSnack('Password reset email sent!');
            }
          },
        ),
        _SettingsItem(
          icon: Icons.workspace_premium_rounded,
          label: 'Subscription Plan',
          value: _isLoggedIn ? 'Free Plan' : 'Guest',
          valueColor: AppColors.primary,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          borderColor: borderColor,
          onTap: () => _showSnack('Upgrade coming soon!'),
        ),
        if (!_isLoggedIn)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/login'),
              child: Container(
                width: double.infinity,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                      colors: [Color(0xFF5EFC82), Color(0xFF00C853)]),
                ),
                child: const Center(
                    child: Text('Sign In to Unlock All Features',
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 13,
                            fontWeight: FontWeight.w700))),
              ),
            ),
          ),
        if (webMode) ...[
          const SizedBox(height: 20),
          _buildDangerZone(
              isDark, textPrimary, textSecondary, cardColor, borderColor),
        ],
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // APPEARANCE SECTION
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildAppearanceSection(bool isDark, Color textPrimary,
      Color textSecondary, Color cardColor, Color borderColor,
      {required bool webMode}) {
    return Consumer<ThemeProvider>(builder: (context, theme, _) {
      return _SettingsGroup(
        webMode: webMode,
        isDark: isDark,
        cardColor: cardColor,
        borderColor: borderColor,
        title: webMode ? 'Appearance' : null,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        children: [
          // Dark / Light mode
          _SettingsToggleItem(
            icon: isDark ? Icons.dark_mode_rounded : Icons.wb_sunny_rounded,
            iconColor: const Color(0xFFFFD600),
            label: 'Dark Mode',
            subtitle: 'Switch between dark and light theme',
            value: theme.isDark,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            borderColor: borderColor,
            onChanged: (_) => theme.toggleTheme(),
          ),

          // Theme color
          _SettingsRow(
            icon: Icons.palette_rounded,
            iconColor: _selectedAccent,
            label: 'Accent Colour',
            subtitle: 'Choose your app accent colour',
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            borderColor: borderColor,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _kAccentColors.map((color) {
                final isSelected = _selectedAccent == color;
                return GestureDetector(
                  onTap: () => setState(() => _selectedAccent = color),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                  color: color.withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 1)
                            ]
                          : [],
                    ),
                    child: isSelected
                        ? const Icon(Icons.check_rounded,
                            size: 14, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ),

          // Display density
          _SettingsRow(
            icon: Icons.density_medium_rounded,
            iconColor: const Color(0xFF2979FF),
            label: 'Display Density',
            subtitle: 'Comfortable spacing between items',
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            borderColor: borderColor,
            child: _buildChipRow(
              options: ['Compact', 'Normal', 'Comfortable'],
              selected: 'Normal',
              onSelect: (_) => _showSnack('Density setting saved!'),
              accentColor: const Color(0xFF2979FF),
              isDark: isDark,
              borderColor: borderColor,
            ),
          ),
        ],
      );
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // NOTIFICATIONS SECTION
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildNotificationsSection(bool isDark, Color textPrimary,
      Color textSecondary, Color cardColor, Color borderColor,
      {required bool webMode}) {
    return _SettingsGroup(
      webMode: webMode,
      isDark: isDark,
      cardColor: cardColor,
      borderColor: borderColor,
      title: webMode ? 'Notifications' : null,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      children: [
        _buildSettingsBadge(
          'UI Only — Notifications will be wired in a future update',
          Icons.info_outline_rounded,
          const Color(0xFF2979FF),
          isDark,
        ),
        const SizedBox(height: 12),
        _SettingsToggleItem(
          icon: Icons.fitness_center_rounded,
          iconColor: AppColors.primary,
          label: 'Workout Reminders',
          subtitle: 'Daily push notification for your workout',
          value: _workoutReminders,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          borderColor: borderColor,
          onChanged: (v) => setState(() => _workoutReminders = v),
        ),
        _SettingsToggleItem(
          icon: Icons.restaurant_rounded,
          iconColor: const Color(0xFFFF6D00),
          label: 'Meal Reminders',
          subtitle: 'Remind to log meals at breakfast, lunch & dinner',
          value: _mealReminders,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          borderColor: borderColor,
          onChanged: (v) => setState(() => _mealReminders = v),
        ),
        _SettingsToggleItem(
          icon: Icons.local_drink_rounded,
          iconColor: const Color(0xFF00BCD4),
          label: 'Water Reminders',
          subtitle: 'Hourly hydration reminders',
          value: _waterReminder,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          borderColor: borderColor,
          onChanged: (v) => setState(() => _waterReminder = v),
        ),
        _SettingsToggleItem(
          icon: Icons.bar_chart_rounded,
          iconColor: const Color(0xFFAA00FF),
          label: 'Progress Reminders',
          subtitle: 'Remind to log weight & measurements weekly',
          value: _progressReminders,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          borderColor: borderColor,
          onChanged: (v) => setState(() => _progressReminders = v),
        ),
        _SettingsToggleItem(
          icon: Icons.summarize_rounded,
          iconColor: const Color(0xFF2979FF),
          label: 'Weekly Report',
          subtitle: 'Get a summary of your week every Sunday',
          value: _weeklyReport,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          borderColor: borderColor,
          onChanged: (v) => setState(() => _weeklyReport = v),
        ),
        _SettingsToggleItem(
          icon: Icons.emoji_events_rounded,
          iconColor: const Color(0xFFFFD600),
          label: 'Achievement Alerts',
          subtitle: 'Celebrate when you hit a new milestone',
          value: _achievementAlerts,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          borderColor: borderColor,
          onChanged: (v) => setState(() => _achievementAlerts = v),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // WORKOUT PREFERENCES
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildWorkoutPrefsSection(bool isDark, Color textPrimary,
      Color textSecondary, Color cardColor, Color borderColor,
      {required bool webMode}) {
    return _SettingsGroup(
      webMode: webMode,
      isDark: isDark,
      cardColor: cardColor,
      borderColor: borderColor,
      title: webMode ? 'Workout Preferences' : null,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      children: [
        // Preferred time
        _SettingsRow(
          icon: Icons.schedule_rounded,
          iconColor: AppColors.primary,
          label: 'Preferred Workout Time',
          subtitle: 'When do you usually train?',
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          borderColor: borderColor,
          child: _buildChipRow(
            options: ['Morning', 'Afternoon', 'Evening', 'Night'],
            selected: _preferredWorkoutTime,
            onSelect: (v) => setState(() => _preferredWorkoutTime = v),
            accentColor: AppColors.primary,
            isDark: isDark,
            borderColor: borderColor,
          ),
        ),

        // Fitness level
        _SettingsRow(
          icon: Icons.trending_up_rounded,
          iconColor: const Color(0xFF2979FF),
          label: 'Fitness Level',
          subtitle: 'Adjusts workout difficulty',
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          borderColor: borderColor,
          child: _buildChipRow(
            options: ['Beginner', 'Intermediate', 'Advanced'],
            selected: _fitnessLevel,
            onSelect: (v) => setState(() => _fitnessLevel = v),
            accentColor: const Color(0xFF2979FF),
            isDark: isDark,
            borderColor: borderColor,
          ),
        ),

        // Workout duration slider
        _SettingsSliderItem(
          icon: Icons.timer_rounded,
          iconColor: const Color(0xFFFF6D00),
          label: 'Default Workout Duration',
          subtitle: '$_workoutDuration minutes per session',
          value: _workoutDuration.toDouble(),
          min: 15,
          max: 120,
          divisions: 21,
          accentColor: const Color(0xFFFF6D00),
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          borderColor: borderColor,
          onChanged: (v) => setState(() => _workoutDuration = v.round()),
          formatValue: (v) => '${v.round()} min',
        ),

        _SettingsToggleItem(
          icon: Icons.self_improvement_rounded,
          iconColor: AppColors.primary,
          label: 'Warmup Reminder',
          subtitle: 'Remind to warm up before starting',
          value: _warmupReminder,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          borderColor: borderColor,
          onChanged: (v) => setState(() => _warmupReminder = v),
        ),
        _SettingsToggleItem(
          icon: Icons.weekend_rounded,
          iconColor: const Color(0xFFAA00FF),
          label: 'Rest Day Reminder',
          subtitle: 'Get notified on scheduled rest days',
          value: _restDayReminder,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          borderColor: borderColor,
          onChanged: (v) => setState(() => _restDayReminder = v),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DIET PREFERENCES
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildDietPrefsSection(bool isDark, Color textPrimary,
      Color textSecondary, Color cardColor, Color borderColor,
      {required bool webMode}) {
    return _SettingsGroup(
      webMode: webMode,
      isDark: isDark,
      cardColor: cardColor,
      borderColor: borderColor,
      title: webMode ? 'Diet Preferences' : null,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      children: [
        // Diet type
        _SettingsRow(
          icon: Icons.restaurant_menu_rounded,
          iconColor: const Color(0xFFFF6D00),
          label: 'Diet Type',
          subtitle: 'Used to filter meal suggestions',
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          borderColor: borderColor,
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: ['Balanced', 'Keto', 'Vegan', 'Vegetarian', 'Paleo']
                .map((d) {
              final sel = _dietType == d;
              return GestureDetector(
                onTap: () => setState(() => _dietType = d),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: sel
                        ? const Color(0xFFFF6D00).withOpacity(0.15)
                        : Colors.transparent,
                    border: Border.all(
                      color: sel
                          ? const Color(0xFFFF6D00)
                          : borderColor,
                    ),
                  ),
                  child: Text(d,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: sel
                              ? const Color(0xFFFF6D00)
                              : textSecondary)),
                ),
              );
            }).toList(),
          ),
        ),

        // Daily calorie goal
        _SettingsSliderItem(
          icon: Icons.local_fire_department_rounded,
          iconColor: const Color(0xFFFF1744),
          label: 'Daily Calorie Goal',
          subtitle: '$_dailyCalorieGoal kcal / day',
          value: _dailyCalorieGoal.toDouble(),
          min: 1200,
          max: 4000,
          divisions: 56,
          accentColor: const Color(0xFFFF1744),
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          borderColor: borderColor,
          onChanged: (v) =>
              setState(() => _dailyCalorieGoal = (v / 50).round() * 50),
          formatValue: (v) => '${((v / 50).round() * 50).toInt()} kcal',
        ),

        // Water goal
        _SettingsSliderItem(
          icon: Icons.local_drink_rounded,
          iconColor: const Color(0xFF00BCD4),
          label: 'Daily Water Goal',
          subtitle: '$_waterGoalLiters litres / day',
          value: _waterGoalLiters.toDouble(),
          min: 1,
          max: 6,
          divisions: 10,
          accentColor: const Color(0xFF00BCD4),
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          borderColor: borderColor,
          onChanged: (v) => setState(() => _waterGoalLiters = v.round()),
          formatValue: (v) => '${v.toStringAsFixed(1)} L',
        ),

        _SettingsToggleItem(
          icon: Icons.food_bank_rounded,
          iconColor: AppColors.primary,
          label: 'Meal Prep Mode',
          subtitle: 'Show bulk-prep friendly recipes',
          value: _mealPrepMode,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          borderColor: borderColor,
          onChanged: (v) => setState(() => _mealPrepMode = v),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PRIVACY SECTION
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildPrivacySection(bool isDark, Color textPrimary,
      Color textSecondary, Color cardColor, Color borderColor,
      {required bool webMode}) {
    return _SettingsGroup(
      webMode: webMode,
      isDark: isDark,
      cardColor: cardColor,
      borderColor: borderColor,
      title: webMode ? 'Privacy & Security' : null,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      children: [
        _SettingsToggleItem(
          icon: Icons.share_rounded,
          iconColor: const Color(0xFF2979FF),
          label: 'Share Progress Publicly',
          subtitle: 'Let others see your workout streaks',
          value: _shareProgress,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          borderColor: borderColor,
          onChanged: (v) => setState(() => _shareProgress = v),
        ),
        _SettingsToggleItem(
          icon: Icons.analytics_rounded,
          iconColor: AppColors.primary,
          label: 'Analytics',
          subtitle: 'Help improve FitLife with anonymous usage data',
          value: _analyticsEnabled,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          borderColor: borderColor,
          onChanged: (v) => setState(() => _analyticsEnabled = v),
        ),
        _SettingsToggleItem(
          icon: Icons.bug_report_rounded,
          iconColor: const Color(0xFFFF6D00),
          label: 'Crash Reporting',
          subtitle: 'Automatically send crash reports',
          value: _crashReporting,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          borderColor: borderColor,
          onChanged: (v) => setState(() => _crashReporting = v),
        ),
        _SettingsItem(
          icon: Icons.privacy_tip_outlined,
          label: 'Privacy Policy',
          value: 'View →',
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          borderColor: borderColor,
          onTap: () => _showSnack('Privacy policy coming soon!'),
        ),
        _SettingsItem(
          icon: Icons.description_outlined,
          label: 'Terms of Service',
          value: 'View →',
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          borderColor: borderColor,
          onTap: () => _showSnack('Terms coming soon!'),
        ),
        _SettingsItem(
          icon: Icons.download_rounded,
          label: 'Export My Data',
          value: 'Download →',
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          borderColor: borderColor,
          onTap: () => _showSnack('Data export coming soon!'),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // APP INFO SECTION
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildAppInfoSection(bool isDark, Color textPrimary,
      Color textSecondary, Color cardColor, Color borderColor,
      {required bool webMode}) {
    return _SettingsGroup(
      webMode: webMode,
      isDark: isDark,
      cardColor: cardColor,
      borderColor: borderColor,
      title: webMode ? 'App Info' : null,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      children: [
        _SettingsItem(
          icon: Icons.info_outline_rounded,
          label: 'App Version',
          value: '1.0.0 (Beta)',
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          borderColor: borderColor,
        ),
        _SettingsItem(
          icon: Icons.build_circle_outlined,
          label: 'Build Number',
          value: '2025.04.21',
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          borderColor: borderColor,
        ),
        _SettingsItem(
          icon: Icons.cloud_outlined,
          label: 'Backend',
          value: 'Supabase (Connected)',
          valueColor: AppColors.primary,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          borderColor: borderColor,
        ),
        _SettingsItem(
          icon: Icons.star_rate_rounded,
          label: 'Rate FitLife',
          value: '⭐ Leave a review',
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          borderColor: borderColor,
          onTap: () => _showSnack('Thanks for the love! ❤️'),
        ),
        _SettingsItem(
          icon: Icons.share_rounded,
          label: 'Share with Friends',
          value: 'Share →',
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          borderColor: borderColor,
          onTap: () => _showSnack('Share feature coming soon!'),
        ),
        _SettingsItem(
          icon: Icons.help_outline_rounded,
          label: 'Help & Support',
          value: 'Contact us →',
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          borderColor: borderColor,
          onTap: () => _showSnack('Support coming soon!'),
        ),
        const SizedBox(height: 8),
        Center(
          child: Column(
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF5EFC82), Color(0xFF00C853)],
                ).createShader(bounds),
                child: const Text('FitLife',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1)),
              ),
              const SizedBox(height: 4),
              Text('Built with ❤️ · Free forever',
                  style: TextStyle(fontSize: 11, color: textSecondary)),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DANGER ZONE (logout + delete)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildDangerZone(bool isDark, Color textPrimary, Color textSecondary,
      Color cardColor, Color borderColor) {
    return Column(
      children: [
        // Logout
        GestureDetector(
          onTap: _isLoggingOut ? null : _handleLogout,
          child: Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: isDark
                  ? const Color(0xFF1A0A0A)
                  : const Color(0xFFFFF0F0),
              border: Border.all(
                  color: const Color(0xFFFF1744).withOpacity(0.4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _isLoggingOut
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: Color(0xFFFF1744), strokeWidth: 2))
                    : const Icon(Icons.logout_rounded,
                        size: 18, color: Color(0xFFFF1744)),
                const SizedBox(width: 10),
                const Text('Sign Out',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFF1744))),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Delete account
        if (_isLoggedIn)
          GestureDetector(
            onTap: _isDeletingAccount ? null : _handleDeleteAccount,
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: Colors.transparent,
                border: Border.all(
                    color: const Color(0xFFFF1744).withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _isDeletingAccount
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: Color(0xFFFF1744), strokeWidth: 2))
                      : const Icon(Icons.delete_forever_rounded,
                          size: 18, color: Color(0xFFFF1744)),
                  const SizedBox(width: 10),
                  Text('Delete Account',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFFF1744).withOpacity(0.7))),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildChipRow({
    required List<String> options,
    required String selected,
    required void Function(String) onSelect,
    required Color accentColor,
    required bool isDark,
    required Color borderColor,
  }) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: options.map((o) {
        final sel = selected == o;
        return GestureDetector(
          onTap: () => onSelect(o),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: sel ? accentColor.withOpacity(0.15) : Colors.transparent,
              border: Border.all(color: sel ? accentColor : borderColor),
            ),
            child: Text(o,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: sel ? accentColor : Colors.grey)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSettingsBadge(
      String text, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: color.withOpacity(0.08),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: TextStyle(fontSize: 11, color: color, height: 1.4))),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SECTIONS METADATA
  // ─────────────────────────────────────────────────────────────────────────
  static const List<Map<String, dynamic>> _settingsSections = [
    {'icon': Icons.person_rounded, 'label': 'Account', 'color': Color(0xFF00C853)},
    {'icon': Icons.palette_rounded, 'label': 'Appearance', 'color': Color(0xFFFFD600)},
    {'icon': Icons.notifications_rounded, 'label': 'Notifications', 'color': Color(0xFF2979FF)},
    {'icon': Icons.fitness_center_rounded, 'label': 'Workout Preferences', 'color': Color(0xFFFF6D00)},
    {'icon': Icons.restaurant_rounded, 'label': 'Diet Preferences', 'color': Color(0xFF00BCD4)},
    {'icon': Icons.shield_rounded, 'label': 'Privacy', 'color': Color(0xFFAA00FF)},
    {'icon': Icons.info_rounded, 'label': 'App Info', 'color': Color(0xFF2979FF)},
  ];
}

// ═══════════════════════════════════════════════════════════════════════════
// REUSABLE WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

/// Groups a list of settings items with optional title
class _SettingsGroup extends StatelessWidget {
  final bool webMode;
  final bool isDark;
  final Color cardColor;
  final Color borderColor;
  final String? title;
  final Color textPrimary;
  final Color textSecondary;
  final List<Widget> children;

  const _SettingsGroup({
    required this.webMode,
    required this.isDark,
    required this.cardColor,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.children,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null && webMode) ...[
          Text(title!,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: textPrimary)),
          const SizedBox(height: 16),
        ],
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: cardColor,
            border: Border.all(color: borderColor),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4))
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i < children.length - 1 &&
                      children[i] is! SizedBox &&
                      children[i + 1] is! SizedBox)
                    Divider(
                        height: 1,
                        color: borderColor,
                        indent: 52,
                        endIndent: 16),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Simple tappable row: icon | label + subtitle | value + chevron
class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Color? valueColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color borderColor;
  final VoidCallback? onTap;

  const _SettingsItem({
    required this.icon,
    required this.label,
    this.value,
    this.valueColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textPrimary)),
            ),
            if (value != null)
              Text(value!,
                  style: TextStyle(
                      fontSize: 13,
                      color: valueColor ?? textSecondary,
                      fontWeight: valueColor != null
                          ? FontWeight.w600
                          : FontWeight.w400)),
            if (onTap != null) ...[
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: textSecondary.withOpacity(0.5)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Row with icon | label + subtitle | custom child widget below
class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final Color textPrimary;
  final Color textSecondary;
  final Color borderColor;
  final Widget child;

  const _SettingsRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.textPrimary,
    required this.textSecondary,
    required this.borderColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textPrimary)),
                  Text(subtitle,
                      style:
                          TextStyle(fontSize: 11, color: textSecondary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(padding: const EdgeInsets.only(left: 34), child: child),
        ],
      ),
    );
  }
}

/// Toggle row
class _SettingsToggleItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final bool value;
  final Color textPrimary;
  final Color textSecondary;
  final Color borderColor;
  final void Function(bool) onChanged;

  const _SettingsToggleItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.textPrimary,
    required this.textSecondary,
    required this.borderColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimary)),
                Text(subtitle,
                    style: TextStyle(fontSize: 11, color: textSecondary)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
}

/// Slider row
class _SettingsSliderItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final Color accentColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color borderColor;
  final void Function(double) onChanged;
  final String Function(double) formatValue;

  const _SettingsSliderItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    required this.accentColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.borderColor,
    required this.onChanged,
    required this.formatValue,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textPrimary)),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 11, color: accentColor, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: accentColor.withOpacity(0.12),
                ),
                child: Text(formatValue(value),
                    style: TextStyle(
                        fontSize: 12,
                        color: accentColor,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: accentColor,
              inactiveTrackColor: accentColor.withOpacity(0.15),
              thumbColor: accentColor,
              overlayColor: accentColor.withOpacity(0.15),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

/// Web left-nav item
class _WebSettingsNavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _WebSettingsNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_WebSettingsNavItem> createState() => _WebSettingsNavItemState();
}

class _WebSettingsNavItemState extends State<_WebSettingsNavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isActive;
    final isHovered = _hovered;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: isActive
                ? AppColors.primary.withOpacity(0.18)
                : isHovered
                    ? AppColors.primary.withOpacity(0.09)
                    : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(widget.icon,
                  size: 17,
                  color: isActive || isHovered
                      ? AppColors.primary
                      : Colors.white.withOpacity(0.5)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(widget.label,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w400,
                        color: isActive || isHovered
                            ? AppColors.primary
                            : Colors.white.withOpacity(0.6))),
              ),
              if (isActive)
                Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: AppColors.primary)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mobile accordion wrapper
class _MobileAccordionSection extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Widget child;

  const _MobileAccordionSection({
    required this.icon,
    required this.label,
    required this.color,
    required this.isExpanded,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF141414) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: cardColor,
        border: Border.all(
            color: isExpanded ? color.withOpacity(0.4) : borderColor,
            width: isExpanded ? 1.5 : 1),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 3))
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            // Header
            GestureDetector(
              onTap: onToggle,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: color.withOpacity(0.13),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Center(
                          child:
                              Icon(icon, size: 17, color: color)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(label,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: textPrimary)),
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.expand_more_rounded,
                          size: 20,
                          color: isExpanded ? color : Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            // Content
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 220),
              crossFadeState: isExpanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: Column(
                children: [
                  Divider(height: 1, color: borderColor),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: child,
                  ),
                ],
              ),
              secondChild: const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}