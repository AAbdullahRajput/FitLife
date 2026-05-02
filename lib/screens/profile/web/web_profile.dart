// lib/screens/profile/web/web_profile.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/app_data.dart';
import '../../../core/utils/helpers.dart';
import '../../../services/storage_service.dart';
import 'package:image_picker/image_picker.dart';


class _Imgs {
  static const heroBg =
      'https://images.unsplash.com/photo-1517963879433-6ad2b056d712'
      '?w=1400&q=85&auto=format&fit=crop';

  static const avatarBg =
      'https://images.unsplash.com/photo-1594381898411-846e7d193883'
      '?w=300&q=80&auto=format&fit=crop';

  static const statWeight =
      'https://images.unsplash.com/photo-1549060279-7e168fcee0c2'
      '?w=400&q=80&auto=format&fit=crop';
  static const statHeight =
      'https://images.unsplash.com/photo-1517836357463-d25dfeac3438'
      '?w=400&q=80&auto=format&fit=crop';
  static const statAge =
      'https://images.unsplash.com/photo-1530822847156-5df684ec5933'
      '?w=400&q=80&auto=format&fit=crop';
  static const statBmi =
      'https://images.unsplash.com/photo-1576678927484-cc907957088c'
      '?w=400&q=80&auto=format&fit=crop';
  static const statCategory =
      'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b'
      '?w=400&q=80&auto=format&fit=crop';
  static const statGoal =
      'https://images.unsplash.com/photo-1552674605-db6ffd4facb5'
      '?w=400&q=80&auto=format&fit=crop';

  static const statBody =
      'https://images.unsplash.com/photo-1571731956672-f2b94d7dd0cb'
      '?w=400&q=80&auto=format&fit=crop';

  static const measChest =
      'https://images.unsplash.com/photo-1571731956672-f2b94d7dd0cb'
      '?w=200&q=80&auto=format&fit=crop';
  static const measWaist =
      'https://images.unsplash.com/photo-1549060279-7e168fcee0c2'
      '?w=200&q=80&auto=format&fit=crop';
  static const measHips =
      'https://images.unsplash.com/photo-1594381898411-846e7d193883'
      '?w=200&q=80&auto=format&fit=crop';
  static const measArms =
      'https://images.unsplash.com/photo-1534438327276-14e5300c3a48'
      '?w=200&q=80&auto=format&fit=crop';

  static const achFirstWorkout =
      'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b'
      '?w=200&q=80&auto=format&fit=crop';
  static const achHydration =
      'https://images.unsplash.com/photo-1548839140-29a749e1cf4d'
      '?w=200&q=80&auto=format&fit=crop';
  static const achIronWill =
      'https://images.unsplash.com/photo-1534438327276-14e5300c3a48'
      '?w=200&q=80&auto=format&fit=crop';
  static const achCleanEater =
      'https://images.unsplash.com/photo-1490645935967-10de6ba17061'
      '?w=200&q=80&auto=format&fit=crop';
  static const achOnTrack =
      'https://images.unsplash.com/photo-1476480862126-209bfaa8edc8'
      '?w=200&q=80&auto=format&fit=crop';
  static const achStreak =
      'https://images.unsplash.com/photo-1506126613408-eca07ce68773'
      '?w=200&q=80&auto=format&fit=crop';

  static const weeklyBg =
      'https://images.unsplash.com/photo-1599058945522-28d584b6f0ff'
      '?w=800&q=80&auto=format&fit=crop';
}

class WebProfile extends StatefulWidget {
  const WebProfile({super.key});

  @override
  State<WebProfile> createState() => _WebProfileState();
}

class _WebProfileState extends State<WebProfile>
    with TickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late AnimationController _counterController;
  late Animation<double> _counterAnim;
  late AnimationController _bmiGaugeController;
  late Animation<double> _bmiGaugeAnim;

  final _supabase = Supabase.instance.client;
  bool get _isLoggedIn => _supabase.auth.currentSession != null;
  String get _userEmail =>
      _supabase.auth.currentUser?.email ?? 'guest@fitlife.app';

  String get _userName => AppData.userName;
  double get _userWeight => AppData.userWeight;
  double get _userHeight => AppData.userHeight;
  int get _userAge => AppData.userAge;
  String get _userGoal => AppData.userGoal;

  double get _bmi => Helpers.calculateBMI(_userWeight, _userHeight);
  String get _bmiCategory => Helpers.getBMICategory(_bmi);

  bool _isLoggingOut = false;
  String? _profilePhotoPath;

  // ── Profile completion ─────────────────────────────────────────────────────
  double get _profileCompletion {
    int filled = 0;
    if (_userName.isNotEmpty) filled++;
    if (_userWeight > 0) filled++;
    if (_userHeight > 0) filled++;
    if (_userAge > 0) filled++;
    if (_userGoal.isNotEmpty) filled++;
    if (_isLoggedIn) filled++;
    return filled / 6.0;
  }

  final List<Map<String, dynamic>> _achievements = [
    {
      'icon': '🔥',
      'title': 'First Workout',
      'desc': 'Completed your first session',
      'unlocked': true,
      'progress': 1.0,
      'img': _Imgs.achFirstWorkout,
    },
    {
      'icon': '💧',
      'title': 'Hydration Hero',
      'desc': 'Hit water goal 7 days straight',
      'unlocked': true,
      'progress': 1.0,
      'img': _Imgs.achHydration,
    },
    {
      'icon': '🏋️',
      'title': 'Iron Will',
      'desc': 'Logged 10 workouts',
      'unlocked': false,
      'progress': 0.4,
      'img': _Imgs.achIronWill,
    },
    {
      'icon': '🥗',
      'title': 'Clean Eater',
      'desc': 'Logged meals for 5 days',
      'unlocked': false,
      'progress': 0.2,
      'img': _Imgs.achCleanEater,
    },
    {
      'icon': '📈',
      'title': 'On Track',
      'desc': 'Reached your weekly goal',
      'unlocked': false,
      'progress': 0.57,
      'img': _Imgs.achOnTrack,
    },
    {
      'icon': '⚡',
      'title': 'Streak Master',
      'desc': '30-day streak',
      'unlocked': false,
      'progress': 0.1,
      'img': _Imgs.achStreak,
    },
  ];

  final List<Map<String, dynamic>> _bodyStats = [
    {
      'label': 'Chest',
      'value': '94 cm',
      'target': '98 cm',
      'progress': 0.80,
      'icon': Icons.straighten_rounded,
      'color': const Color(0xFF2979FF),
      'img': _Imgs.measChest,
    },
    {
      'label': 'Waist',
      'value': '80 cm',
      'target': '76 cm',
      'progress': 0.65,
      'icon': Icons.straighten_rounded,
      'color': const Color(0xFFFF6D00),
      'img': _Imgs.measWaist,
    },
    {
      'label': 'Hips',
      'value': '96 cm',
      'target': '94 cm',
      'progress': 0.72,
      'icon': Icons.straighten_rounded,
      'color': const Color(0xFFAA00FF),
      'img': _Imgs.measHips,
    },
    {
      'label': 'Arms',
      'value': '35 cm',
      'target': '38 cm',
      'progress': 0.55,
      'icon': Icons.straighten_rounded,
      'color': const Color(0xFF00BCD4),
      'img': _Imgs.measArms,
    },
  ];

  // ── Macros ─────────────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _macros = [
    {'label': 'Protein', 'value': 142, 'target': 160, 'color': const Color(0xFF2979FF)},
    {'label': 'Carbs', 'value': 210, 'target': 250, 'color': const Color(0xFFFF6D00)},
    {'label': 'Fat', 'value': 58, 'target': 65, 'color': const Color(0xFFAA00FF)},
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _counterController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _counterAnim = CurvedAnimation(
        parent: _counterController, curve: Curves.easeOutCubic);

    _bmiGaugeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _bmiGaugeAnim = CurvedAnimation(
        parent: _bmiGaugeController, curve: Curves.easeOutBack);

    _animController.forward();
    _loadProfilePhoto();
    Future.delayed(const Duration(milliseconds: 300), () {
      _counterController.forward();
      _bmiGaugeController.forward();
    });
  }


Future<void> _loadProfilePhoto() async {
    final path = await StorageService.getProfilePhoto();
    if (mounted) setState(() => _profilePhotoPath = path);
  }

  @override
  void dispose() {
    _animController.dispose();
    _counterController.dispose();
    _bmiGaugeController.dispose();
    super.dispose();
  }


// ── Edit Profile Dialog ────────────────────────────────────────────────────
  void _showEditProfileDialog() {
    final nameCtrl = TextEditingController(text: AppData.userName);
    final weightCtrl = TextEditingController(text: AppData.userWeight.toString());
    final heightCtrl = TextEditingController(text: AppData.userHeight.toString());
    final ageCtrl = TextEditingController(text: AppData.userAge.toString());

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppColors.of(context, listen: false);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 480,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 40,
                    offset: const Offset(0, 12)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Edit Profile',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: textPrimary)),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Icon(Icons.close_rounded, color: textPrimary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Profile photo + name row
                Row(
                  children: [
                    // Photo picker
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () async {
                          final picker = ImagePicker();
                          final picked = await picker.pickImage(
                              source: ImageSource.gallery, imageQuality: 80);
                          if (picked == null) return;
                          _showSnack('Uploading...');
                          final url = await StorageService
                              .uploadProfilePhotoAndGetUrl(picked);
                          if (url != null) {
                            await StorageService.saveProfilePhoto(url);
                            if (mounted) {
                              setState(() => _profilePhotoPath = url);
                            }
                            _showSnack('Photo updated!');
                          } else {
                            _showSnack('Upload failed. Try again.',
                                isError: true);
                          }
                        },
                        child: Stack(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: accent, width: 2.5),
                              ),
                              child: ClipOval(
                                child: _profilePhotoPath != null
                                    ? Image.network(
                                        _profilePhotoPath!,
                                        fit: BoxFit.cover,
                                        width: 80,
                                        height: 80,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: accent.withOpacity(0.15),
                                          child: Center(
                                            child: Text(
                                              AppData.userName.isNotEmpty
                                                  ? AppData.userName[0].toUpperCase()
                                                  : '?',
                                              style: TextStyle(
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.w900,
                                                  color: accent),
                                            ),
                                          ),
                                        ),
                                      )
                                    : Container(
                                        color: accent.withOpacity(0.15),
                                        child: Center(
                                          child: Text(
                                            AppData.userName.isNotEmpty
                                                ? AppData.userName[0].toUpperCase()
                                                : '?',
                                            style: TextStyle(
                                                fontSize: 28,
                                                fontWeight: FontWeight.w900,
                                                color: accent),
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: accent,
                                  border: Border.all(color: cardColor, width: 2),
                                ),
                                child: const Icon(Icons.camera_alt_rounded,
                                    size: 13, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _webEditField('Name', nameCtrl, textPrimary,
                          borderColor, cardColor),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Weight + Height row
                Row(
                  children: [
                    Expanded(
                      child: _webEditField('Weight (kg)', weightCtrl,
                          textPrimary, borderColor, cardColor,
                          isNumber: true),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _webEditField('Height (cm)', heightCtrl,
                          textPrimary, borderColor, cardColor,
                          isNumber: true),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _webEditField('Age', ageCtrl, textPrimary,
                          borderColor, cardColor,
                          isNumber: true),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Save button
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () async {
                      await StorageService.updateUserField(
                          'name', nameCtrl.text.trim());
                      await StorageService.updateUserField('weight',
                          double.tryParse(weightCtrl.text) ?? AppData.userWeight);
                      await StorageService.updateUserField('height',
                          double.tryParse(heightCtrl.text) ?? AppData.userHeight);
                      await StorageService.updateUserField(
                          'age', int.tryParse(ageCtrl.text) ?? AppData.userAge);
                      final info = await StorageService.getUserInfo();
                      if (info != null) AppData.loadFromMap(info);
                      if (mounted) {
                        Navigator.pop(ctx);
                        setState(() {});
                        _showSnack('Profile updated!');
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: LinearGradient(
                            colors: AppColors.gradientOf(context, listen: false)),
                      ),
                      child: Center(
                        child: Text('Save Changes',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onAccentOf(context,
                                    listen: false))),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _webEditField(
    String label,
    TextEditingController ctrl,
    Color textPrimary,
    Color borderColor,
    Color cardColor, {
    bool isNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textPrimary)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
            color: cardColor,
          ),
          child: TextField(
            controller: ctrl,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            style: TextStyle(fontSize: 14, color: textPrimary),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }


  // ── Helpers ────────────────────────────────────────────────────────────────
  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    final accent = AppColors.of(context, listen: false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? const Color(0xFFFF1744) : accent,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

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
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    } catch (_) {
      setState(() => _isLoggingOut = false);
      _showSnack('Sign out failed. Please try again.', isError: true);
    }
  }

  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required bool isDestructive,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppColors.of(context, listen: false);
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
                      offset: const Offset(0, 12)),
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
                              : accent)
                          .withOpacity(0.12),
                    ),
                    child: Center(
                      child: Icon(
                        isDestructive
                            ? Icons.delete_forever_rounded
                            : Icons.logout_rounded,
                        color: isDestructive
                            ? const Color(0xFFFF1744)
                            : accent,
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
                      style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                          height: 1.5)),
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
                                        const Color(0xFFD50000),
                                      ]
                                    : AppColors.gradientOf(context,
                                        listen: false),
                              ),
                            ),
                            child: Center(
                              child: Text(confirmLabel,
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: isDestructive
                                          ? Colors.white
                                          : AppColors.onAccentOf(
                                              context,
                                              listen: false))),
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

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppColors.of(context);
    final gradient = AppColors.gradientOf(context);
    final onAccent = AppColors.onAccentOf(context);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final textSecondary =
        isDark ? const Color(0xFFB0B0B0) : const Color(0xFF555555);
    final cardColor = isDark ? const Color(0xFF141414) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);

    return FadeTransition(
      opacity: _fadeAnim,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero banner ──────────────────────────────────────────────
            _buildHeroBanner(isDark, accent, gradient, onAccent,
                textPrimary, textSecondary, borderColor),
            const SizedBox(height: 16),

            // ── Quick Actions bar ────────────────────────────────────────
            _buildQuickActions(isDark, accent, gradient, onAccent,
                textPrimary, cardColor, borderColor),
            const SizedBox(height: 24),

            // ── Profile completion ───────────────────────────────────────
            _buildProfileCompletion(
                isDark, accent, gradient, textPrimary, textSecondary,
                cardColor, borderColor),
            const SizedBox(height: 24),

            // ── Stats + Body measurements ────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeader('Fitness Stats',
                          Icons.monitor_heart_rounded, accent, textPrimary),
                      const SizedBox(height: 12),
                      _buildStatsGrid(isDark, accent, textPrimary,
                          cardColor, borderColor),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeader('Body Measurements',
                          Icons.straighten_rounded, accent, textPrimary),
                      const SizedBox(height: 12),
                      _buildMeasurements(isDark, accent, textPrimary,
                          textSecondary, cardColor, borderColor),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Achievements + Weekly ────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeader('Achievements',
                          Icons.emoji_events_rounded, accent, textPrimary),
                      const SizedBox(height: 12),
                      _buildAchievements(isDark, accent, textPrimary,
                          textSecondary, cardColor, borderColor),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeader('This Week',
                          Icons.bar_chart_rounded, accent, textPrimary),
                      const SizedBox(height: 12),
                      _buildWeeklySummary(isDark, accent, gradient,
                          onAccent, textPrimary, textSecondary,
                          cardColor, borderColor),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Account actions ──────────────────────────────────────────
            _sectionHeader('Account',
                Icons.manage_accounts_rounded, accent, textPrimary),
            const SizedBox(height: 12),
            _buildAccountActions(isDark, accent, gradient, onAccent,
                textPrimary, textSecondary, cardColor, borderColor),
            const SizedBox(height: 12),
            _buildSignOutButton(isDark, borderColor),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Hero banner ────────────────────────────────────────────────────────────
  Widget _buildHeroBanner(
    bool isDark,
    Color accent,
    List<Color> gradient,
    Color onAccent,
    Color textPrimary,
    Color textSecondary,
    Color borderColor,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        width: double.infinity,
        height: 230,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Athlete background — PROPERLY centered
            Image.network(
              _Imgs.heroBg,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (_, __, ___) =>
                  Container(color: accent.withOpacity(0.08)),
            ),
            // Dark gradient overlay — left heavy for text, right reveals photo
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.95),
                    Colors.black.withOpacity(0.75),
                    Colors.black.withOpacity(0.30),
                    Colors.black.withOpacity(0.10),
                  ],
                  stops: const [0.0, 0.35, 0.65, 1.0],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
            // Subtle accent border
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border:
                    Border.all(color: accent.withOpacity(0.25), width: 1.5),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Row(
                children: [
                  // ── Avatar + BMI gauge ─────────────────────────────────
                  SizedBox(
                    width: 110,
                    height: 110,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // BMI arc gauge behind avatar
                        AnimatedBuilder(
                          animation: _bmiGaugeAnim,
                          builder: (context, _) => CustomPaint(
                            size: const Size(110, 110),
                            painter: _BmiGaugePainter(
                              bmi: _bmi,
                              accent: accent,
                              progress: _bmiGaugeAnim.value,
                            ),
                          ),
                        ),
                        // Avatar
                        Container(
                          width: 78,
                          height: 78,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: accent.withOpacity(0.6), width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                  color: accent.withOpacity(0.35),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4)),
                            ],
                          ),
                          child: ClipOval(
                            child: _profilePhotoPath != null
                                ? Image.network(
                                    _profilePhotoPath!,
                                    fit: BoxFit.cover,
                                    width: 78,
                                    height: 78,
                                    errorBuilder: (_, __, ___) => Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.network(_Imgs.avatarBg,
                                            fit: BoxFit.cover),
                                        Container(
                                            color: accent.withOpacity(0.10)),
                                        Center(
                                          child: Text(
                                            _userName.isNotEmpty
                                                ? _userName[0].toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                                fontSize: 32,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.network(
                                        _Imgs.avatarBg,
                                        fit: BoxFit.cover,
                                        alignment: Alignment.center,
                                        errorBuilder: (_, __, ___) =>
                                            Container(
                                                color:
                                                    accent.withOpacity(0.2)),
                                      ),
                                      Container(
                                          color: accent.withOpacity(0.10)),
                                      Center(
                                        child: Text(
                                          _userName.isNotEmpty
                                              ? _userName[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                              fontSize: 32,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        // Online dot
                        Positioned(
                          bottom: 14,
                          right: 14,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF00C853),
                              border:
                                  Border.all(color: Colors.black, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),

                  // ── User info ──────────────────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_userName,
                            style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.5)),
                        const SizedBox(height: 4),
                        Text(_userEmail,
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.50))),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _miniChip(
                                _isLoggedIn ? '✅ Free Plan' : '👤 Guest',
                                accent),
                            _miniChip(_userGoal, accent),
                            _miniChip(
                                'BMI ${_bmi.toStringAsFixed(1)} · $_bmiCategory',
                                const Color(0xFF2979FF)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // ── Streak badge ─────────────────────────────────
                        Row(
                          children: [
                            _streakBadge(accent),
                            const SizedBox(width: 12),
                            _heroBadge('🏅', '2 badges', accent),
                            const SizedBox(width: 12),
                            _heroBadge('🎯', '3/7 goals', accent),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── BMI label + Edit button ────────────────────────────
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // BMI label under gauge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.black.withOpacity(0.5),
                          border: Border.all(
                              color: accent.withOpacity(0.3), width: 1),
                        ),
                        child: Column(
                          children: [
                            Text('BMI',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white.withOpacity(0.55),
                                    fontWeight: FontWeight.w600)),
                            AnimatedBuilder(
                              animation: _counterAnim,
                              builder: (_, __) => Text(
                                (_bmi * _counterAnim.value)
                                    .toStringAsFixed(1),
                                style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: accent),
                              ),
                            ),
                            Text(_bmiCategory,
                                style: TextStyle(
                                    fontSize: 9,
                                    color: accent.withOpacity(0.8),
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Edit button
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => _showEditProfileDialog(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: accent.withOpacity(0.5),
                                  width: 1.5),
                              color: accent.withOpacity(0.10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit_rounded,
                                    size: 15, color: accent),
                                const SizedBox(width: 8),
                                Text('Edit Profile',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: accent)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _streakBadge(Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.orange.withOpacity(0.18),
        border: Border.all(color: Colors.orange.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          const Text('3-day streak',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.orange)),
        ],
      ),
    );
  }

  Widget _heroBadge(String emoji, String label, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.07),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.75))),
        ],
      ),
    );
  }

  // ── Quick Actions bar ──────────────────────────────────────────────────────
  Widget _buildQuickActions(
    bool isDark,
    Color accent,
    List<Color> gradient,
    Color onAccent,
    Color textPrimary,
    Color cardColor,
    Color borderColor,
  ) {
    final actions = [
      {
        'icon': Icons.fitness_center_rounded,
        'label': 'Log Workout',
        'color': accent,
        'gradient': gradient,
        'filled': true,
      },
      {
        'icon': Icons.restaurant_rounded,
        'label': 'Log Meal',
        'color': const Color(0xFFFF6D00),
        'gradient': [const Color(0xFFFF6D00), const Color(0xFFFF8F00)],
        'filled': false,
      },
      {
        'icon': Icons.water_drop_rounded,
        'label': 'Track Water',
        'color': const Color(0xFF2979FF),
        'gradient': [const Color(0xFF2979FF), const Color(0xFF448AFF)],
        'filled': false,
      },
      {
        'icon': Icons.monitor_weight_rounded,
        'label': 'Log Weight',
        'color': const Color(0xFFAA00FF),
        'gradient': [const Color(0xFFAA00FF), const Color(0xFFBF40BF)],
        'filled': false,
      },
    ];

    return Row(
      children: actions.map((a) {
        final color = a['color'] as Color;
        final grd = a['gradient'] as List<Color>;
        final filled = a['filled'] as bool;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
                right: actions.indexOf(a) < actions.length - 1 ? 10 : 0),
            child: _QuickActionButton(
              icon: a['icon'] as IconData,
              label: a['label'] as String,
              color: color,
              gradient: grd,
              filled: filled,
              onTap: () => _showSnack('${a['label']} coming soon!'),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Profile completion ─────────────────────────────────────────────────────
  Widget _buildProfileCompletion(
    bool isDark,
    Color accent,
    List<Color> gradient,
    Color textPrimary,
    Color textSecondary,
    Color cardColor,
    Color borderColor,
  ) {
    final pct = (_profileCompletion * 100).round();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: cardColor,
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: accent.withOpacity(0.12),
            ),
            child: Center(
                child:
                    Icon(Icons.person_rounded, size: 18, color: accent)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Profile Completion',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: textPrimary)),
                    Text('$pct%',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: accent)),
                  ],
                ),
                const SizedBox(height: 8),
                AnimatedBuilder(
                  animation: _counterAnim,
                  builder: (_, __) => ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _profileCompletion * _counterAnim.value,
                      minHeight: 6,
                      backgroundColor: accent.withOpacity(0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text('Add measurements\nto complete profile',
              style: TextStyle(
                  fontSize: 10,
                  color: textSecondary,
                  height: 1.5)),
        ],
      ),
    );
  }

  // ── Stats grid — responsive 3-column layout ────────────────────────────────
  Widget _buildStatsGrid(bool isDark, Color accent, Color textPrimary,
      Color cardColor, Color borderColor) {
    final stats = [
      {
        'label': 'Weight',
        'value': '${_userWeight}kg',
        'icon': Icons.monitor_weight_rounded,
        'color': const Color(0xFF2979FF),
        'img': _Imgs.statWeight,
      },
      {
        'label': 'Height',
        'value': '${_userHeight}cm',
        'icon': Icons.height_rounded,
        'color': const Color(0xFFFF6D00),
        'img': _Imgs.statHeight,
      },
      {
        'label': 'Age',
        'value': '$_userAge yrs',
        'icon': Icons.cake_rounded,
        'color': const Color(0xFFAA00FF),
        'img': _Imgs.statAge,
      },
      {
        'label': 'BMI',
        'value': _bmi.toStringAsFixed(1),
        'icon': Icons.analytics_rounded,
        'color': accent,
        'img': _Imgs.statBmi,
      },
      {
        'label': 'Category',
        'value': _bmiCategory,
        'icon': Icons.flag_rounded,
        'color': const Color(0xFFFFD600),
        'img': _Imgs.statCategory,
      },
      {
        'label': 'Goal',
        'value': _userGoal.split(' ').first,
        'icon': Icons.emoji_events_rounded,
        'color': const Color(0xFF00BCD4),
        'img': _Imgs.statGoal,
      },
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final cardWidth = (constraints.maxWidth - 24) / 3;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: stats.asMap().entries.map((entry) {
          final i = entry.key;
          final stat = entry.value;
          final color = stat['color'] as Color;
          final icon = stat['icon'] as IconData;
          final imgUrl = stat['img'] as String;
          return _StatCard(
            width: cardWidth,
            height: 90,
            imgUrl: imgUrl,
            color: color,
            icon: icon,
            value: stat['value'] as String,
            label: stat['label'] as String,
            counterAnim: _counterAnim,
            index: i,
          );
        }).toList(),
      );
    });
  }

  // ── Body measurements ──────────────────────────────────────────────────────
  Widget _buildMeasurements(
    bool isDark,
    Color accent,
    Color textPrimary,
    Color textSecondary,
    Color cardColor,
    Color borderColor,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              _Imgs.statBody,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (_, __, ___) =>
                  Container(color: accent.withOpacity(0.05)),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.75),
                    Colors.black.withOpacity(0.92),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: _bodyStats.asMap().entries.map((entry) {
                final i = entry.key;
                final stat = entry.value;
                final color = stat['color'] as Color;
                final imgUrl = stat['img'] as String;
                final progress = stat['progress'] as double;
                return Container(
                  margin: EdgeInsets.only(
                      bottom: i < _bodyStats.length - 1 ? 10 : 0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withOpacity(0.35)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.network(
                            imgUrl,
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                            errorBuilder: (_, __, ___) =>
                                Container(color: color.withOpacity(0.10)),
                          ),
                        ),
                        Positioned.fill(
                          child: Container(
                            color: Colors.black.withOpacity(0.60),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(stat['icon'] as IconData,
                                      size: 15, color: color),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(stat['label'] as String,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color:
                                                Colors.white.withOpacity(0.75))),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(stat['value'] as String,
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                              color: color)),
                                      Text('target: ${stat['target']}',
                                          style: TextStyle(
                                              fontSize: 9,
                                              color: Colors.white
                                                  .withOpacity(0.4))),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 7),
                              // Progress bar toward target
                              AnimatedBuilder(
                                animation: _counterAnim,
                                builder: (_, __) => ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: LinearProgressIndicator(
                                    value: progress * _counterAnim.value,
                                    minHeight: 4,
                                    backgroundColor:
                                        color.withOpacity(0.15),
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(color),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Achievements — flip on hover ───────────────────────────────────────────
  Widget _buildAchievements(
    bool isDark,
    Color accent,
    Color textPrimary,
    Color textSecondary,
    Color cardColor,
    Color borderColor,
  ) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _achievements.map((a) {
        final unlocked = a['unlocked'] as bool;
        final imgUrl = a['img'] as String;
        final progress = a['progress'] as double;
        return _AchievementCard(
          achievement: a,
          unlocked: unlocked,
          imgUrl: imgUrl,
          progress: progress,
          accent: accent,
          isDark: isDark,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          borderColor: borderColor,
          counterAnim: _counterAnim,
        );
      }).toList(),
    );
  }

  // ── Weekly summary ─────────────────────────────────────────────────────────
  Widget _buildWeeklySummary(
    bool isDark,
    Color accent,
    List<Color> gradient,
    Color onAccent,
    Color textPrimary,
    Color textSecondary,
    Color cardColor,
    Color borderColor,
  ) {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final completed = [true, true, false, true, false, false, false];
    // Duration in minutes per day (0 = not done)
    final durations = [45, 32, 0, 58, 0, 0, 0];
    final maxDur = 60;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              _Imgs.weeklyBg,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (_, __, ___) =>
                  Container(color: accent.withOpacity(0.05)),
            ),
          ),
          Positioned.fill(
            child: Container(
              color: isDark
                  ? Colors.black.withOpacity(0.82)
                  : Colors.white.withOpacity(0.94),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Weekly Workouts',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: textPrimary)),
                    Text('3/7 days',
                        style: TextStyle(
                            fontSize: 13,
                            color: accent,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 16),
                // Bar chart + day labels
                AnimatedBuilder(
                  animation: _counterAnim,
                  builder: (_, __) => Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (i) {
                      final done = completed[i];
                      final dur = durations[i];
                      final barH =
                          (dur / maxDur * 56 * _counterAnim.value)
                              .clamp(0.0, 56.0);
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (done)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Text('${dur}m',
                                  style: TextStyle(
                                      fontSize: 8,
                                      color: accent,
                                      fontWeight: FontWeight.w700)),
                            ),
                          Container(
                            width: 28,
                            height: done ? barH : 8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              gradient: done
                                  ? LinearGradient(
                                      colors: [
                                        accent.withOpacity(0.6),
                                        accent
                                      ],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                    )
                                  : null,
                              color: done
                                  ? null
                                  : (isDark
                                      ? const Color(0xFF1A1A1A)
                                      : const Color(0xFFF0F0F0)),
                              border: Border.all(
                                  color: done
                                      ? Colors.transparent
                                      : borderColor),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(days[i],
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: done
                                      ? accent
                                      : textSecondary.withOpacity(0.5))),
                        ],
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 16),
                // Calories row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Avg. Calories',
                        style:
                            TextStyle(fontSize: 11, color: textSecondary)),
                    Text('1,840 / 2,000 kcal',
                        style: TextStyle(
                            fontSize: 11,
                            color: accent,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 6),
                AnimatedBuilder(
                  animation: _counterAnim,
                  builder: (_, __) => ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (1840 / 2000) * _counterAnim.value,
                      minHeight: 6,
                      backgroundColor: accent.withOpacity(0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Macros breakdown
                Text('Macro Breakdown',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: textPrimary)),
                const SizedBox(height: 8),
                ..._macros.map((m) {
                  final color = m['color'] as Color;
                  final val = m['value'] as int;
                  final target = m['target'] as int;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 48,
                          child: Text(m['label'] as String,
                              style: TextStyle(
                                  fontSize: 10, color: textSecondary)),
                        ),
                        Expanded(
                          child: AnimatedBuilder(
                            animation: _counterAnim,
                            builder: (_, __) => ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: (val / target) * _counterAnim.value,
                                minHeight: 5,
                                backgroundColor: color.withOpacity(0.12),
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(color),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${val}g',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: color)),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Account actions (Settings tile REMOVED — lives in Settings page) ───────
  Widget _buildAccountActions(
    bool isDark,
    Color accent,
    List<Color> gradient,
    Color onAccent,
    Color textPrimary,
    Color textSecondary,
    Color cardColor,
    Color borderColor,
  ) {
    final actions = [
      {
        'icon': Icons.lock_outline_rounded,
        'label': 'Change Password',
        'subtitle': 'Update your account password',
        'color': const Color(0xFF2979FF),
        'onTap': () async {
          if (!_isLoggedIn) {
            _showSnack('Sign in to change password.', isError: true);
            return;
          }
          final email = _supabase.auth.currentUser?.email;
          if (email != null) {
            try {
              await _supabase.auth.resetPasswordForEmail(email);
              _showSnack('Password reset email sent!');
            } on AuthException catch (e) {
              _showSnack(e.message, isError: true);
            } catch (_) {
              _showSnack('Failed to send reset email.', isError: true);
            }
          }
        },
      },
      {
        'icon': Icons.download_rounded,
        'label': 'Export Data',
        'subtitle': 'Download your fitness data as CSV',
        'color': const Color(0xFFFF6D00),
        'onTap': () => _showSnack('Export coming soon!'),
      },
      {
        'icon': Icons.share_rounded,
        'label': 'Share Profile',
        'subtitle': 'Share your progress with friends',
        'color': const Color(0xFF00BCD4),
        'onTap': () => _showSnack('Share coming soon!'),
      },
      {
        'icon': Icons.help_outline_rounded,
        'label': 'Help & Support',
        'subtitle': 'Get help or contact us',
        'color': const Color(0xFFAA00FF),
        'onTap': () => _showSnack('Support coming soon!'),
      },
    ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: cardColor,
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: actions.asMap().entries.map((entry) {
          final i = entry.key;
          final action = entry.value;
          final color = action['color'] as Color;
          return Column(
            children: [
              _WebActionTile(
                icon: action['icon'] as IconData,
                label: action['label'] as String,
                subtitle: action['subtitle'] as String,
                color: color,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                borderColor: borderColor,
                onTap: action['onTap'] as VoidCallback,
              ),
              if (i < actions.length - 1)
                Divider(
                    height: 1,
                    color: borderColor,
                    indent: 68,
                    endIndent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── Sign out button ────────────────────────────────────────────────────────
  Widget _buildSignOutButton(bool isDark, Color borderColor) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _isLoggingOut ? null : _handleLogout,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          height: 52,
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
    );
  }

  // ── Shared small widgets ───────────────────────────────────────────────────
  Widget _sectionHeader(
      String title, IconData icon, Color accent, Color textPrimary) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: accent.withOpacity(0.12),
          ),
          child: Center(child: Icon(icon, size: 16, color: accent)),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: textPrimary)),
      ],
    );
  }

  Widget _miniChip(String text, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: accent.withOpacity(0.15),
        border: Border.all(color: accent.withOpacity(0.3)),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 11,
              color: accent,
              fontWeight: FontWeight.w700)),
    );
  }
}

// ── BMI Gauge Painter ──────────────────────────────────────────────────────
class _BmiGaugePainter extends CustomPainter {
  final double bmi;
  final Color accent;
  final double progress;

  _BmiGaugePainter(
      {required this.bmi, required this.accent, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    const startAngle = math.pi * 0.75;
    const sweepAngle = math.pi * 1.5;

    // Background arc
    final bgPaint = Paint()
      ..color = accent.withOpacity(0.12)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        startAngle, sweepAngle, false, bgPaint);

    // BMI range: underweight <18.5, normal 18.5-25, overweight 25-30, obese >30
    final normalizedBmi = ((bmi - 10) / 30).clamp(0.0, 1.0);
    Color gaugeColor;
    if (bmi < 18.5) {
      gaugeColor = const Color(0xFF2979FF);
    } else if (bmi < 25) {
      gaugeColor = const Color(0xFF00C853);
    } else if (bmi < 30) {
      gaugeColor = const Color(0xFFFF6D00);
    } else {
      gaugeColor = const Color(0xFFFF1744);
    }

    final fgPaint = Paint()
      ..color = gaugeColor
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle * normalizedBmi * progress,
        false,
        fgPaint);
  }

  @override
  bool shouldRepaint(_BmiGaugePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.bmi != bmi;
}

// ── Stat Card widget ───────────────────────────────────────────────────────
class _StatCard extends StatefulWidget {
  final double width;
  final double height;
  final String imgUrl;
  final Color color;
  final IconData icon;
  final String value;
  final String label;
  final Animation<double> counterAnim;
  final int index;

  const _StatCard({
    required this.width,
    required this.height,
    required this.imgUrl,
    required this.color,
    required this.icon,
    required this.value,
    required this.label,
    required this.counterAnim,
    required this.index,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.04 : 1.0,
        duration: const Duration(milliseconds: 180),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: widget.width,
            height: widget.height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Per-stat image
                Image.network(
                  widget.imgUrl,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  errorBuilder: (_, __, ___) =>
                      Container(color: widget.color.withOpacity(0.10)),
                ),
                // Dark overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.black.withOpacity(_hovered ? 0.55 : 0.70),
                        Colors.black.withOpacity(0.60),
                      ],
                    ),
                  ),
                ),
                // Colored border
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: widget.color
                            .withOpacity(_hovered ? 0.7 : 0.35),
                        width: _hovered ? 1.5 : 1),
                  ),
                ),
                // Glow on hover
                if (_hovered)
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: RadialGradient(
                        colors: [
                          widget.color.withOpacity(0.12),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.color
                              .withOpacity(_hovered ? 0.28 : 0.18),
                          border: Border.all(
                              color: widget.color.withOpacity(0.5),
                              width: 1),
                        ),
                        child: Center(
                            child: Icon(widget.icon,
                                size: 18, color: widget.color)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(widget.value,
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: widget.color)),
                            const SizedBox(height: 2),
                            Text(widget.label,
                                style: TextStyle(
                                    fontSize: 10,
                                    color:
                                        Colors.white.withOpacity(0.55))),
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
    );
  }
}

// ── Achievement Card with hover flip ──────────────────────────────────────
class _AchievementCard extends StatefulWidget {
  final Map<String, dynamic> achievement;
  final bool unlocked;
  final String imgUrl;
  final double progress;
  final Color accent;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final Color borderColor;
  final Animation<double> counterAnim;

  const _AchievementCard({
    required this.achievement,
    required this.unlocked,
    required this.imgUrl,
    required this.progress,
    required this.accent,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.borderColor,
    required this.counterAnim,
  });

  @override
  State<_AchievementCard> createState() => _AchievementCardState();
}

class _AchievementCardState extends State<_AchievementCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 148,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: widget.unlocked
                  ? widget.accent
                      .withOpacity(_hovered ? 0.75 : 0.45)
                  : widget.borderColor),
          boxShadow: widget.unlocked && _hovered
              ? [
                  BoxShadow(
                      color: widget.accent.withOpacity(0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 4))
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Background
              Positioned.fill(
                child: widget.unlocked
                    ? Image.network(
                        widget.imgUrl,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        errorBuilder: (_, __, ___) => Container(
                            color: widget.accent.withOpacity(0.10)),
                      )
                    : Container(
                        color: widget.isDark
                            ? const Color(0xFF1A1A1A)
                            : const Color(0xFFF0F0F0)),
              ),
              // Overlay
              Positioned.fill(
                child: Container(
                  color: widget.unlocked
                      ? Colors.black
                          .withOpacity(_hovered ? 0.40 : 0.55)
                      : Colors.black.withOpacity(0.05),
                ),
              ),
              // Accent tint unlocked
              if (widget.unlocked)
                Positioned.fill(
                  child: Container(
                    color: widget.accent
                        .withOpacity(_hovered ? 0.16 : 0.08),
                  ),
                ),
              // Content
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Badge image / lock
                    AnimatedScale(
                      scale: _hovered ? 1.12 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: widget.unlocked
                            ? Image.network(
                                widget.imgUrl,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                alignment: Alignment.center,
                                errorBuilder: (_, __, ___) => Text(
                                  widget.achievement['icon'] as String,
                                  style:
                                      const TextStyle(fontSize: 28),
                                ),
                              )
                            : Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.circular(10),
                                  color: widget.isDark
                                      ? const Color(0xFF252525)
                                      : const Color(0xFFE8E8E8),
                                ),
                                child: Icon(Icons.lock_rounded,
                                    size: 22,
                                    color: widget.isDark
                                        ? Colors.white
                                            .withOpacity(0.22)
                                        : Colors.black
                                            .withOpacity(0.18)),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(widget.achievement['title'] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: widget.unlocked
                                ? Colors.white
                                : widget.textPrimary
                                    .withOpacity(0.30))),
                    const SizedBox(height: 3),
                    Text(widget.achievement['desc'] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 10,
                            color: widget.unlocked
                                ? Colors.white.withOpacity(0.65)
                                : widget.textSecondary
                                    .withOpacity(0.30))),
                    // Progress bar for locked achievements
                    if (!widget.unlocked) ...[
                      const SizedBox(height: 8),
                      AnimatedBuilder(
                        animation: widget.counterAnim,
                        builder: (_, __) => Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: widget.progress *
                                    widget.counterAnim.value,
                                minHeight: 4,
                                backgroundColor: widget.isDark
                                    ? const Color(0xFF2A2A2A)
                                    : const Color(0xFFE0E0E0),
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(
                                        widget.accent.withOpacity(0.5)),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                                '${(widget.progress * 100).round()}%',
                                style: TextStyle(
                                    fontSize: 9,
                                    color: widget.textSecondary
                                        .withOpacity(0.5))),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Quick Action Button ────────────────────────────────────────────────────
class _QuickActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final List<Color> gradient;
  final bool filled;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.gradient,
    required this.filled,
    required this.onTap,
  });

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: widget.filled || _hovered
                ? LinearGradient(colors: widget.gradient)
                : null,
            color: widget.filled || _hovered
                ? null
                : widget.color.withOpacity(0.08),
            border: Border.all(
                color: widget.color
                    .withOpacity(_hovered ? 0.0 : 0.35),
                width: 1.5),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                        color: widget.color.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4))
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon,
                  size: 17,
                  color: widget.filled || _hovered
                      ? Colors.white
                      : widget.color),
              const SizedBox(width: 8),
              Text(widget.label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: widget.filled || _hovered
                          ? Colors.white
                          : widget.color)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Web action tile with hover ─────────────────────────────────────────────
class _WebActionTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final Color textPrimary;
  final Color textSecondary;
  final Color borderColor;
  final VoidCallback onTap;

  const _WebActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.textPrimary,
    required this.textSecondary,
    required this.borderColor,
    required this.onTap,
  });

  @override
  State<_WebActionTile> createState() => _WebActionTileState();
}

class _WebActionTileState extends State<_WebActionTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          color: _hovered
              ? widget.color.withOpacity(0.05)
              : Colors.transparent,
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: widget.color
                      .withOpacity(_hovered ? 0.20 : 0.12),
                ),
                child: Center(
                    child: Icon(widget.icon,
                        size: 18, color: widget.color)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.label,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: widget.textPrimary)),
                    Text(widget.subtitle,
                        style: TextStyle(
                            fontSize: 11,
                            color: widget.textSecondary)),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                child: Icon(Icons.chevron_right_rounded,
                    size: 18,
                    color: _hovered
                        ? widget.color
                        : widget.textSecondary.withOpacity(0.5)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}