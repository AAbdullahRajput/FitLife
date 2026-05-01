// lib/screens/profile/mobile/mobile_profile.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/app_data.dart';
import '../../../core/utils/helpers.dart';
import '../../../services/storage_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

// ── Mobile-only image URLs (different from web_profile.dart) ──────────────
class _MImgs {
  // Full-body athlete centered — hero card bg
  static const heroBg =
      'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61'
      '?w=800&q=80&auto=format&fit=crop';

  // Overhead flat-lay of fitness gear (shoes, bands, water bottle)
  static const gearFlatlay =
      'https://images.unsplash.com/photo-1519505907962-0a6cb0167c73'
      '?w=600&q=80&auto=format&fit=crop';

  // Body measurement / physique — measurements bg
  static const yogaGolden =
      'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b'
      '?w=600&q=80&auto=format&fit=crop';

  // Trophy / medal — achievements bg
  static const smoothieBowl =
      'https://images.unsplash.com/photo-1552674605-db6ffd4facb5'
      '?w=600&q=80&auto=format&fit=crop';

  // Gym / fitness equipment — stats bg
  static const barbellDark =
      'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e'
      '?w=600&q=80&auto=format&fit=crop';

  // Gym calendar / planner — weekly summary bg
  static const trackAerial =
      'https://images.unsplash.com/photo-1599058945522-28d584b6f0ff'
      '?w=800&q=80&auto=format&fit=crop';

  // ── Per-achievement images ──────────────────────────────────────────────
  // First Workout — person at gym first day
  static const achFirstWorkout =
      'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b'
      '?w=200&q=80&auto=format&fit=crop';

  // Hydration Hero — water / hydration
  static const achHydration =
      'https://images.unsplash.com/photo-1548839140-29a749e1cf4d'
      '?w=200&q=80&auto=format&fit=crop';

  // Iron Will — heavy weights / barbell
  static const achIronWill =
      'https://images.unsplash.com/photo-1534438327276-14e5300c3a48'
      '?w=200&q=80&auto=format&fit=crop';

  // Clean Eater — healthy food / salad
  static const achCleanEater =
      'https://images.unsplash.com/photo-1490645935967-10de6ba17061'
      '?w=200&q=80&auto=format&fit=crop';

  // On Track — person running / progress
  static const achOnTrack =
      'https://images.unsplash.com/photo-1476480862126-209bfaa8edc8'
      '?w=200&q=80&auto=format&fit=crop';

  // Streak Master — calendar / consistency
  static const achStreak =
      'https://images.unsplash.com/photo-1506126613408-eca07ce68773'
      '?w=200&q=80&auto=format&fit=crop';
}

class MobileProfile extends StatefulWidget {
  const MobileProfile({super.key});

  @override
  State<MobileProfile> createState() => _MobileProfileState();
}

class _MobileProfileState extends State<MobileProfile>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

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

  final List<Map<String, dynamic>> _achievements = [
    {
      'icon': '🔥',
      'title': 'First Workout',
      'desc': 'Completed your first session',
      'unlocked': true,
      'img': _MImgs.achFirstWorkout,
    },
    {
      'icon': '💧',
      'title': 'Hydration Hero',
      'desc': 'Hit water goal 7 days straight',
      'unlocked': true,
      'img': _MImgs.achHydration,
    },
    {
      'icon': '🏋️',
      'title': 'Iron Will',
      'desc': 'Logged 10 workouts',
      'unlocked': false,
      'img': _MImgs.achIronWill,
    },
    {
      'icon': '🥗',
      'title': 'Clean Eater',
      'desc': 'Logged meals for 5 days',
      'unlocked': false,
      'img': _MImgs.achCleanEater,
    },
    {
      'icon': '📈',
      'title': 'On Track',
      'desc': 'Reached your weekly goal',
      'unlocked': false,
      'img': _MImgs.achOnTrack,
    },
    {
      'icon': '⚡',
      'title': 'Streak Master',
      'desc': '30-day streak',
      'unlocked': false,
      'img': _MImgs.achStreak,
    },
  ];

  final List<Map<String, dynamic>> _bodyStats = [
    {
      'label': 'Chest',
      'value': '94 cm',
      'icon': Icons.straighten_rounded,
      'color': const Color(0xFF2979FF),
    },
    {
      'label': 'Waist',
      'value': '80 cm',
      'icon': Icons.straighten_rounded,
      'color': const Color(0xFFFF6D00),
    },
    {
      'label': 'Hips',
      'value': '96 cm',
      'icon': Icons.straighten_rounded,
      'color': const Color(0xFFAA00FF),
    },
    {
      'label': 'Arms',
      'value': '35 cm',
      'icon': Icons.straighten_rounded,
      'color': const Color(0xFF00BCD4),
    },
  ];
  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
    _loadProfilePhoto();
  }

  Future<void> _loadProfilePhoto() async {
    final path = await StorageService.getProfilePhoto();
    if (mounted) setState(() => _profilePhotoPath = path);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }


  // ── Profile Photo Picker ──────────────────────────────────────────────────
  Future<void> _pickProfilePhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      await StorageService.saveProfilePhoto(picked.path);
      if (mounted) setState(() => _profilePhotoPath = picked.path);
    }
  }

  // ── Edit Profile Bottom Sheet ─────────────────────────────────────────────
  void _showEditProfileSheet() {
    final nameCtrl = TextEditingController(text: AppData.userName);
    final weightCtrl =
        TextEditingController(text: AppData.userWeight.toString());
    final heightCtrl =
        TextEditingController(text: AppData.userHeight.toString());
    final ageCtrl = TextEditingController(text: AppData.userAge.toString());

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppColors.of(context, listen: false);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: borderColor),
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
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: textPrimary)),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Icon(Icons.close_rounded, color: textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Profile photo picker
                Center(
                  child: GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(
                          source: ImageSource.gallery, imageQuality: 80);
                      if (picked != null) {
                        await StorageService.saveProfilePhoto(picked.path);
                        if (mounted) {
                          setState(() => _profilePhotoPath = picked.path);
                          setSheetState(() {});
                        }
                      }
                    },
                    child: Stack(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: accent, width: 2.5),
                          ),
                          child: ClipOval(
                            child: _profilePhotoPath != null
                                ? Image.file(
                                    File(_profilePhotoPath!),
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    color: accent.withOpacity(0.15),
                                    child: Center(
                                      child: Text(
                                        AppData.userName.isNotEmpty
                                            ? AppData.userName[0]
                                                .toUpperCase()
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
                              border: Border.all(
                                  color: cardColor, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt_rounded,
                                size: 13, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text('Tap to change photo',
                      style:
                          TextStyle(fontSize: 12, color: accent)),
                ),
                const SizedBox(height: 20),

                // Name
                _editField('Name', nameCtrl, textPrimary, borderColor,
                    cardColor),
                const SizedBox(height: 12),

                // Weight + Height row
                Row(
                  children: [
                    Expanded(
                      child: _editField('Weight (kg)', weightCtrl,
                          textPrimary, borderColor, cardColor,
                          isNumber: true),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _editField('Height (cm)', heightCtrl,
                          textPrimary, borderColor, cardColor,
                          isNumber: true),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Age
                _editField(
                    'Age', ageCtrl, textPrimary, borderColor, cardColor,
                    isNumber: true),
                const SizedBox(height: 24),

                // Save button
                GestureDetector(
                  onTap: () async {
                    await StorageService.updateUserField(
                        'name', nameCtrl.text.trim());
                    await StorageService.updateUserField(
                        'weight',
                        double.tryParse(weightCtrl.text) ??
                            AppData.userWeight);
                    await StorageService.updateUserField(
                        'height',
                        double.tryParse(heightCtrl.text) ??
                            AppData.userHeight);
                    await StorageService.updateUserField('age',
                        int.tryParse(ageCtrl.text) ?? AppData.userAge);
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
                          colors: AppColors.gradientOf(context,
                              listen: false)),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Edit field helper ─────────────────────────────────────────────────────
  Widget _editField(
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
            keyboardType:
                isNumber ? TextInputType.number : TextInputType.text,
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

  // ── Helpers ──────────────────────────────────────────────────────────────

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
              width: 320,
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

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppColors.of(context);
    final gradient = AppColors.gradientOf(context);
    final onAccent = AppColors.onAccentOf(context);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final textSecondary =
        isDark ? const Color(0xFFB0B0B0) : const Color(0xFF555555);
    final bgColor =
        isDark ? const Color(0xFF050A05) : const Color(0xFFF5F5F5);
    final cardColor = isDark ? const Color(0xFF141414) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);

    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0D0D0D) : Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: canPop
            ? GestureDetector(
                onTap: () => Navigator.maybePop(context),
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
              )
            : null,
        title: Text('Profile',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: textPrimary)),
        actions: [
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/settings'),
            child: Container(
              margin: const EdgeInsets.only(right: 14),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withOpacity(0.12),
                border: Border.all(color: accent.withOpacity(0.3)),
              ),
              child: Center(
                  child: Icon(Icons.settings_rounded, size: 17, color: accent)),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: borderColor),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hero card with photo bg ──────────────────────────────────
              _buildHeroCard(isDark, accent, gradient, onAccent, textPrimary,
                  textSecondary, cardColor, borderColor),
              const SizedBox(height: 20),

              // ── Fitness Stats ────────────────────────────────────────────
              _buildSectionHeader('Fitness Stats',
                  Icons.monitor_heart_rounded, accent, textPrimary),
              const SizedBox(height: 12),
              _buildMobileStatsGrid(
                  isDark, accent, textPrimary, cardColor, borderColor),
              const SizedBox(height: 20),

              // ── Body Measurements ────────────────────────────────────────
              _buildSectionHeader('Body Measurements',
                  Icons.straighten_rounded, accent, textPrimary),
              const SizedBox(height: 12),
              _buildMeasurementsRow(
                  isDark, textPrimary, textSecondary, cardColor, borderColor),
              const SizedBox(height: 20),

              // ── Achievements ─────────────────────────────────────────────
              _buildSectionHeader('Achievements',
                  Icons.emoji_events_rounded, accent, textPrimary),
              const SizedBox(height: 12),
              _buildMobileAchievementsGrid(isDark, accent, textPrimary,
                  textSecondary, cardColor, borderColor),
              const SizedBox(height: 20),

              // ── This Week ────────────────────────────────────────────────
              _buildSectionHeader(
                  'This Week', Icons.bar_chart_rounded, accent, textPrimary),
              const SizedBox(height: 12),
              _buildWeeklySummary(isDark, accent, gradient, onAccent,
                  textPrimary, textSecondary, cardColor, borderColor),
              const SizedBox(height: 20),

              // ── Account ──────────────────────────────────────────────────
              _buildSectionHeader('Account',
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
      ),
    );
  }

  // ── Hero card — full-body athlete bg ──────────────────────────────────────
  Widget _buildHeroCard(
    bool isDark,
    Color accent,
    List<Color> gradient,
    Color onAccent,
    Color textPrimary,
    Color textSecondary,
    Color cardColor,
    Color borderColor,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          // Photo background
          SizedBox(
            width: double.infinity,
            height: 180,
            child: Image.network(
              _MImgs.heroBg,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (_, __, ___) =>
                  Container(color: accent.withOpacity(0.08)),
            ),
          ),
          // Gradient overlay — heavy on bottom so text reads
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.20),
                    Colors.black.withOpacity(0.82),
                  ],
                ),
              ),
            ),
          ),
          // Accent border ring
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: accent.withOpacity(0.35), width: 1.5),
              ),
            ),
          ),
          // Content pinned to bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Avatar
                  Stack(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: accent.withOpacity(0.6), width: 2.5),
                          boxShadow: [
                            BoxShadow(
                                color: accent.withOpacity(0.45),
                                blurRadius: 14,
                                offset: const Offset(0, 4)),
                          ],
                        ),
                        child: ClipOval(
                          child: _profilePhotoPath != null
                              ? Image.file(
                                  File(_profilePhotoPath!),
                                  fit: BoxFit.cover,
                                  width: 64,
                                  height: 64,
                                )
                              : Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                            colors: gradient),
                                      ),
                                    ),
                                    Center(
                                      child: Text(
                                        _userName.isNotEmpty
                                            ? _userName[0].toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                            fontSize: 26,
                                            fontWeight: FontWeight.w900,
                                            color: onAccent),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      Positioned(
                        bottom: 2,
                        right: 2,
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
                  const SizedBox(width: 14),
                  // Name / email / chips
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_userName,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Colors.white)),
                        const SizedBox(height: 2),
                        Text(_userEmail,
                            style: TextStyle(
                                fontSize: 11,
                                color:
                                    Colors.white.withOpacity(0.55))),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _miniChip(
                                _isLoggedIn
                                    ? '✅ Free Plan'
                                    : '👤 Guest',
                                accent),
                            _miniChip(_userGoal, accent),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Edit button
                  GestureDetector(
                    onTap: () => _showEditProfileSheet(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent.withOpacity(0.18),
                        border: Border.all(
                            color: accent.withOpacity(0.5), width: 1.5),
                      ),
                      child: Icon(Icons.edit_rounded,
                          size: 15, color: accent),
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

  // ── Mobile stats grid — 3 columns with photo bg card ─────────────────────
  Widget _buildMobileStatsGrid(bool isDark, Color accent, Color textPrimary,
      Color cardColor, Color borderColor) {
    final stats = [
      {
        'label': 'Weight',
        'value': '${_userWeight}kg',
        'icon': Icons.monitor_weight_rounded,
        'color': const Color(0xFF2979FF),
      },
      {
        'label': 'Height',
        'value': '${_userHeight}cm',
        'icon': Icons.height_rounded,
        'color': const Color(0xFFFF6D00),
      },
      {
        'label': 'Age',
        'value': '$_userAge yrs',
        'icon': Icons.cake_rounded,
        'color': const Color(0xFFAA00FF),
      },
      {
        'label': 'BMI',
        'value': _bmi.toStringAsFixed(1),
        'icon': Icons.analytics_rounded,
        'color': accent,
      },
      {
        'label': 'Category',
        'value': _bmiCategory,
        'icon': Icons.flag_rounded,
        'color': const Color(0xFFFFD600),
      },
      {
        'label': 'Goal',
        'value': _userGoal.split(' ').first,
        'icon': Icons.emoji_events_rounded,
        'color': const Color(0xFF00BCD4),
      },
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          // Gym equipment bg image
          Positioned.fill(
            child: Image.network(
              _MImgs.barbellDark,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (_, __, ___) =>
                  Container(color: accent.withOpacity(0.05)),
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.72),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.1,
              children: stats.map((stat) {
                final color = stat['color'] as Color;
                final icon = stat['icon'] as IconData;
                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white.withOpacity(0.06),
                    border: Border.all(color: color.withOpacity(0.35)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, size: 16, color: color),
                      const SizedBox(height: 5),
                      Text(stat['value'] as String,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: color)),
                      const SizedBox(height: 2),
                      Text(stat['label'] as String,
                          style: TextStyle(
                              fontSize: 9,
                              color: Colors.white.withOpacity(0.45))),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Body measurements — horizontal row with measurement bg ────────────────
  Widget _buildMeasurementsRow(bool isDark, Color textPrimary,
      Color textSecondary, Color cardColor, Color borderColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          // Body measurement bg
          SizedBox(
            width: double.infinity,
            height: 110,
            child: Image.network(
              _MImgs.yogaGolden,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (_, __, ___) =>
                  Container(color: const Color(0xFF1A1A1A)),
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.68),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              children: _bodyStats.asMap().entries.map((entry) {
                final i = entry.key;
                final stat = entry.value;
                final color = stat['color'] as Color;
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(
                        right: i < _bodyStats.length - 1 ? 8 : 0),
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white.withOpacity(0.06),
                      border:
                          Border.all(color: color.withOpacity(0.35)),
                    ),
                    child: Column(
                      children: [
                        Icon(stat['icon'] as IconData,
                            size: 14, color: color),
                        const SizedBox(height: 5),
                        Text(stat['value'] as String,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: color)),
                        const SizedBox(height: 2),
                        Text(stat['label'] as String,
                            style: TextStyle(
                                fontSize: 8,
                                color:
                                    Colors.white.withOpacity(0.45))),
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

  // ── Achievements grid — each badge has its own image ──────────────────────
  Widget _buildMobileAchievementsGrid(
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
          // Achievements section bg
          Positioned.fill(
            child: Image.network(
              _MImgs.smoothieBowl,
              fit: BoxFit.cover,
              alignment: const Alignment(0, -0.5),
              errorBuilder: (_, __, ___) =>
                  Container(color: accent.withOpacity(0.05)),
            ),
          ),
          Positioned.fill(
            child: Container(
              color: isDark
                  ? Colors.black.withOpacity(0.82)
                  : Colors.black.withOpacity(0.70),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 0.95,
              children: _achievements.map((a) {
                final unlocked = a['unlocked'] as bool;
                final imgUrl = a['img'] as String;
                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: unlocked
                        ? accent.withOpacity(0.18)
                        : Colors.white.withOpacity(0.06),
                    border: Border.all(
                        color: unlocked
                            ? accent.withOpacity(0.45)
                            : Colors.white.withOpacity(0.12)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ── Per-achievement image (unlocked) or lock icon ──
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: unlocked
                            ? Image.network(
                                imgUrl,
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
                                alignment: Alignment.center,
                                errorBuilder: (_, __, ___) => Text(
                                  a['icon'] as String,
                                  style: const TextStyle(fontSize: 22),
                                ),
                              )
                            : Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.white.withOpacity(0.06),
                                ),
                                child: Icon(
                                  Icons.lock_rounded,
                                  size: 20,
                                  color: Colors.white.withOpacity(0.25),
                                ),
                              ),
                      ),
                      const SizedBox(height: 6),
                      Text(a['title'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: unlocked
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.3))),
                      const SizedBox(height: 2),
                      Text(a['desc'] as String,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 8,
                              color: unlocked
                                  ? Colors.white.withOpacity(0.65)
                                  : Colors.white.withOpacity(0.2))),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Weekly summary — gym planner bg ───────────────────────────────────────
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          // Gym planner bg
          Positioned.fill(
            child: Image.network(
              _MImgs.trackAerial,
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
                  : Colors.white.withOpacity(0.90),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Weekly Workouts',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: textPrimary)),
                    Text('3/7 days',
                        style: TextStyle(
                            fontSize: 12,
                            color: accent,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (i) {
                    final done = completed[i];
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: done
                                ? LinearGradient(colors: gradient)
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
                            boxShadow: done
                                ? [
                                    BoxShadow(
                                        color: accent.withOpacity(0.3),
                                        blurRadius: 8)
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: done
                                ? Icon(Icons.check_rounded,
                                    size: 14, color: onAccent)
                                : Text(days[i],
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: textSecondary)),
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (done)
                          Text(days[i],
                              style: TextStyle(
                                  fontSize: 9, color: accent)),
                      ],
                    );
                  }),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Avg. Calories',
                        style: TextStyle(
                            fontSize: 11, color: textSecondary)),
                    Text('1,840 / 2,000 kcal',
                        style: TextStyle(
                            fontSize: 11,
                            color: accent,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 1840 / 2000,
                    minHeight: 6,
                    backgroundColor: accent.withOpacity(0.12),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(accent),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Account actions ────────────────────────────────────────────────────────
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
        'icon': Icons.settings_rounded,
        'label': 'Settings',
        'subtitle': 'Appearance, notifications & more',
        'color': accent,
        'onTap': () => Navigator.pushNamed(context, '/settings'),
      },
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
              _showSnack(
                  'Failed to send reset email. Please try again later.',
                  isError: true);
            }
          }
        },
      },
      {
        'icon': Icons.download_rounded,
        'label': 'Export Data',
        'subtitle': 'Download your fitness data',
        'color': const Color(0xFFFF6D00),
        'onTap': () => _showSnack('Export coming soon!'),
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
              GestureDetector(
                onTap: action['onTap'] as VoidCallback,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: color.withOpacity(0.12),
                        ),
                        child: Center(
                            child: Icon(action['icon'] as IconData,
                                size: 18, color: color)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(action['label'] as String,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary)),
                            Text(action['subtitle'] as String,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: textSecondary)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          size: 18,
                          color: textSecondary.withOpacity(0.5)),
                    ],
                  ),
                ),
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
    return GestureDetector(
      onTap: _isLoggingOut ? null : _handleLogout,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isDark
              ? const Color(0xFF1A0A0A)
              : const Color(0xFFFFF0F0),
          border:
              Border.all(color: const Color(0xFFFF1744).withOpacity(0.4)),
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
    );
  }

  // ── Shared small widgets ───────────────────────────────────────────────────
  Widget _buildSectionHeader(
      String title, IconData icon, Color accent, Color textPrimary) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: accent.withOpacity(0.12),
          ),
          child: Center(child: Icon(icon, size: 15, color: accent)),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: accent.withOpacity(0.18),
        border: Border.all(color: accent.withOpacity(0.35)),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 10,
              color: accent,
              fontWeight: FontWeight.w700)),
    );
  }
}