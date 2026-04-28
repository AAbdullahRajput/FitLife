// // lib/screens/profile/web/web_profile.dart
// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import '../../../core/theme/app_colors.dart';
// import '../../../core/data/app_data.dart';
// import '../../../core/utils/helpers.dart';
// import '../../../services/storage_service.dart';

// // ── Profile image URLs (unique, not used elsewhere in the app) ─────────────
// class _Imgs {
//   // Hero banner — wide gym with visible athlete face + body
//   static const heroBg =
//       'https://images.unsplash.com/photo-1517963879433-6ad2b056d712'
//       '?w=1200&q=80&auto=format&fit=crop';

//   // Avatar — athlete close-up face
//   static const avatarBg =
//       'https://images.unsplash.com/photo-1594381898411-846e7d193883'
//       '?w=300&q=80&auto=format&fit=crop';

//   // ── Per-stat card images (each unique) ─────────────────────────────────
//   static const statWeight =
//       'https://images.unsplash.com/photo-1549060279-7e168fcee0c2'
//       '?w=300&q=80&auto=format&fit=crop'; // dumbbell / scale

//   static const statHeight =
//       'https://images.unsplash.com/photo-1517836357463-d25dfeac3438'
//       '?w=300&q=80&auto=format&fit=crop'; // full-body standing gym

//   static const statAge =
//       'https://images.unsplash.com/photo-1530822847156-5df684ec5933'
//       '?w=300&q=80&auto=format&fit=crop'; // face / upper body

//   static const statBmi =
//       'https://images.unsplash.com/photo-1576678927484-cc907957088c'
//       '?w=300&q=80&auto=format&fit=crop'; // health / scale

//   static const statCategory =
//       'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b'
//       '?w=300&q=80&auto=format&fit=crop'; // fit person flexing

//   static const statGoal =
//       'https://images.unsplash.com/photo-1552674605-db6ffd4facb5'
//       '?w=300&q=80&auto=format&fit=crop'; // person achieving goal / finish line

//   // ── Body measurements bg ───────────────────────────────────────────────
//   static const statBody =
//       'https://images.unsplash.com/photo-1571731956672-f2b94d7dd0cb'
//       '?w=400&q=80&auto=format&fit=crop'; // body measurement tape

//   // ── Per-measurement images ─────────────────────────────────────────────
//   static const measChest =
//       'https://images.unsplash.com/photo-1571731956672-f2b94d7dd0cb'
//       '?w=200&q=80&auto=format&fit=crop'; // measurement tape / chest area

//   static const measWaist =
//       'https://images.unsplash.com/photo-1549060279-7e168fcee0c2'
//       '?w=200&q=80&auto=format&fit=crop'; // waist / fitness

//   static const measHips =
//       'https://images.unsplash.com/photo-1594381898411-846e7d193883'
//       '?w=200&q=80&auto=format&fit=crop'; // lower body athlete

//   static const measArms =
//       'https://images.unsplash.com/photo-1534438327276-14e5300c3a48'
//       '?w=200&q=80&auto=format&fit=crop'; // arms / bicep curl

//   // ── Achievement bg ─────────────────────────────────────────────────────
//   static const achievementBg =
//       'https://images.unsplash.com/photo-1552674605-db6ffd4facb5'
//       '?w=400&q=80&auto=format&fit=crop'; // trophy / medal

//   // ── Per-achievement images ─────────────────────────────────────────────
//   static const achFirstWorkout =
//       'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b'
//       '?w=200&q=80&auto=format&fit=crop'; // first gym day

//   static const achHydration =
//       'https://images.unsplash.com/photo-1548839140-29a749e1cf4d'
//       '?w=200&q=80&auto=format&fit=crop'; // water / hydration

//   static const achIronWill =
//       'https://images.unsplash.com/photo-1534438327276-14e5300c3a48'
//       '?w=200&q=80&auto=format&fit=crop'; // heavy barbell

//   static const achCleanEater =
//       'https://images.unsplash.com/photo-1490645935967-10de6ba17061'
//       '?w=200&q=80&auto=format&fit=crop'; // healthy food / salad

//   static const achOnTrack =
//       'https://images.unsplash.com/photo-1476480862126-209bfaa8edc8'
//       '?w=200&q=80&auto=format&fit=crop'; // person running / progress

//   static const achStreak =
//       'https://images.unsplash.com/photo-1506126613408-eca07ce68773'
//       '?w=200&q=80&auto=format&fit=crop'; // calendar / consistency

//   // ── Weekly summary bg ──────────────────────────────────────────────────
//   static const weeklyBg =
//       'https://images.unsplash.com/photo-1599058945522-28d584b6f0ff'
//       '?w=800&q=80&auto=format&fit=crop'; // gym calendar / planner
// }

// class WebProfile extends StatefulWidget {
//   const WebProfile({super.key});

//   @override
//   State<WebProfile> createState() => _WebProfileState();
// }

// class _WebProfileState extends State<WebProfile>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _animController;
//   late Animation<double> _fadeAnim;

//   final _supabase = Supabase.instance.client;
//   bool get _isLoggedIn => _supabase.auth.currentSession != null;
//   String get _userEmail =>
//       _supabase.auth.currentUser?.email ?? 'guest@fitlife.app';

//   String get _userName => AppData.userName;
//   double get _userWeight => AppData.userWeight;
//   double get _userHeight => AppData.userHeight;
//   int get _userAge => AppData.userAge;
//   String get _userGoal => AppData.userGoal;

//   double get _bmi => Helpers.calculateBMI(_userWeight, _userHeight);
//   String get _bmiCategory => Helpers.getBMICategory(_bmi);

//   bool _isLoggingOut = false;

//   final List<Map<String, dynamic>> _achievements = [
//     {
//       'icon': '🔥',
//       'title': 'First Workout',
//       'desc': 'Completed your first session',
//       'unlocked': true,
//       'img': _Imgs.achFirstWorkout,
//     },
//     {
//       'icon': '💧',
//       'title': 'Hydration Hero',
//       'desc': 'Hit water goal 7 days straight',
//       'unlocked': true,
//       'img': _Imgs.achHydration,
//     },
//     {
//       'icon': '🏋️',
//       'title': 'Iron Will',
//       'desc': 'Logged 10 workouts',
//       'unlocked': false,
//       'img': _Imgs.achIronWill,
//     },
//     {
//       'icon': '🥗',
//       'title': 'Clean Eater',
//       'desc': 'Logged meals for 5 days',
//       'unlocked': false,
//       'img': _Imgs.achCleanEater,
//     },
//     {
//       'icon': '📈',
//       'title': 'On Track',
//       'desc': 'Reached your weekly goal',
//       'unlocked': false,
//       'img': _Imgs.achOnTrack,
//     },
//     {
//       'icon': '⚡',
//       'title': 'Streak Master',
//       'desc': '30-day streak',
//       'unlocked': false,
//       'img': _Imgs.achStreak,
//     },
//   ];

//   final List<Map<String, dynamic>> _bodyStats = [
//     {
//       'label': 'Chest',
//       'value': '94 cm',
//       'icon': Icons.straighten_rounded,
//       'color': const Color(0xFF2979FF),
//       'img': _Imgs.measChest,
//     },
//     {
//       'label': 'Waist',
//       'value': '80 cm',
//       'icon': Icons.straighten_rounded,
//       'color': const Color(0xFFFF6D00),
//       'img': _Imgs.measWaist,
//     },
//     {
//       'label': 'Hips',
//       'value': '96 cm',
//       'icon': Icons.straighten_rounded,
//       'color': const Color(0xFFAA00FF),
//       'img': _Imgs.measHips,
//     },
//     {
//       'label': 'Arms',
//       'value': '35 cm',
//       'icon': Icons.straighten_rounded,
//       'color': const Color(0xFF00BCD4),
//       'img': _Imgs.measArms,
//     },
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _animController = AnimationController(
//         vsync: this, duration: const Duration(milliseconds: 700));
//     _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
//         CurvedAnimation(parent: _animController, curve: Curves.easeOut));
//     _animController.forward();
//   }

//   @override
//   void dispose() {
//     _animController.dispose();
//     super.dispose();
//   }

//   // ── Helpers ────────────────────────────────────────────────────────────────
//   void _showSnack(String msg, {bool isError = false}) {
//     if (!mounted) return;
//     final accent = AppColors.of(context, listen: false);
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(msg),
//         backgroundColor: isError ? const Color(0xFFFF1744) : accent,
//         behavior: SnackBarBehavior.floating,
//         shape:
//             RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//         margin: const EdgeInsets.all(16),
//       ),
//     );
//   }

//   Future<void> _handleLogout() async {
//     final confirmed = await _showConfirmDialog(
//       title: 'Sign Out',
//       message: 'Are you sure you want to sign out of FitLife?',
//       confirmLabel: 'Sign Out',
//       isDestructive: false,
//     );
//     if (!confirmed || !mounted) return;
//     setState(() => _isLoggingOut = true);
//     try {
//       await _supabase.auth.signOut();
//       await StorageService.setLoggedIn(false);
//       if (mounted) Navigator.pushReplacementNamed(context, '/login');
//     } catch (_) {
//       setState(() => _isLoggingOut = false);
//       _showSnack('Sign out failed. Please try again.', isError: true);
//     }
//   }

//   Future<bool> _showConfirmDialog({
//     required String title,
//     required String message,
//     required String confirmLabel,
//     required bool isDestructive,
//   }) async {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final accent = AppColors.of(context, listen: false);
//     final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
//     final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);
//     final textSecondary =
//         isDark ? const Color(0xFFB0B0B0) : const Color(0xFF555555);
//     final borderColor =
//         isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);

//     return await showDialog<bool>(
//           context: context,
//           barrierColor: Colors.black.withOpacity(0.6),
//           builder: (ctx) => Dialog(
//             backgroundColor: Colors.transparent,
//             child: Container(
//               width: 340,
//               padding: const EdgeInsets.all(24),
//               decoration: BoxDecoration(
//                 color: cardColor,
//                 borderRadius: BorderRadius.circular(20),
//                 border: Border.all(color: borderColor),
//                 boxShadow: [
//                   BoxShadow(
//                       color: Colors.black.withOpacity(0.4),
//                       blurRadius: 40,
//                       offset: const Offset(0, 12)),
//                 ],
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Container(
//                     width: 52,
//                     height: 52,
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       color: (isDestructive
//                               ? const Color(0xFFFF1744)
//                               : accent)
//                           .withOpacity(0.12),
//                     ),
//                     child: Center(
//                       child: Icon(
//                         isDestructive
//                             ? Icons.delete_forever_rounded
//                             : Icons.logout_rounded,
//                         color: isDestructive
//                             ? const Color(0xFFFF1744)
//                             : accent,
//                         size: 24,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   Text(title,
//                       style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.w800,
//                           color: textPrimary)),
//                   const SizedBox(height: 8),
//                   Text(message,
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                           fontSize: 13,
//                           color: textSecondary,
//                           height: 1.5)),
//                   const SizedBox(height: 24),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: GestureDetector(
//                           onTap: () => Navigator.pop(ctx, false),
//                           child: Container(
//                             height: 44,
//                             decoration: BoxDecoration(
//                               borderRadius: BorderRadius.circular(12),
//                               color: isDark
//                                   ? const Color(0xFF252525)
//                                   : const Color(0xFFF5F5F5),
//                               border: Border.all(color: borderColor),
//                             ),
//                             child: Center(
//                               child: Text('Cancel',
//                                   style: TextStyle(
//                                       fontSize: 14,
//                                       fontWeight: FontWeight.w600,
//                                       color: textSecondary)),
//                             ),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: GestureDetector(
//                           onTap: () => Navigator.pop(ctx, true),
//                           child: Container(
//                             height: 44,
//                             decoration: BoxDecoration(
//                               borderRadius: BorderRadius.circular(12),
//                               gradient: LinearGradient(
//                                 colors: isDestructive
//                                     ? [
//                                         const Color(0xFFFF1744),
//                                         const Color(0xFFD50000),
//                                       ]
//                                     : AppColors.gradientOf(context,
//                                         listen: false),
//                               ),
//                             ),
//                             child: Center(
//                               child: Text(confirmLabel,
//                                   style: TextStyle(
//                                       fontSize: 14,
//                                       fontWeight: FontWeight.w700,
//                                       color: isDestructive
//                                           ? Colors.white
//                                           : AppColors.onAccentOf(
//                                               context,
//                                               listen: false))),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ) ??
//         false;
//   }

//   // ── BUILD ──────────────────────────────────────────────────────────────────
//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final accent = AppColors.of(context);
//     final gradient = AppColors.gradientOf(context);
//     final onAccent = AppColors.onAccentOf(context);
//     final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);
//     final textSecondary =
//         isDark ? const Color(0xFFB0B0B0) : const Color(0xFF555555);
//     final cardColor = isDark ? const Color(0xFF141414) : Colors.white;
//     final borderColor =
//         isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);

//     return FadeTransition(
//       opacity: _fadeAnim,
//       child: SingleChildScrollView(
//         padding: const EdgeInsets.all(28),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // ── Hero banner ──────────────────────────────────────────────
//             _buildHeroBanner(isDark, accent, gradient, onAccent,
//                 textPrimary, textSecondary, borderColor),
//             const SizedBox(height: 24),

//             // ── Stats + Body measurements ────────────────────────────────
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Expanded(
//                   flex: 3,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       _sectionHeader('Fitness Stats',
//                           Icons.monitor_heart_rounded, accent, textPrimary),
//                       const SizedBox(height: 12),
//                       _buildStatsGrid(isDark, accent, textPrimary,
//                           cardColor, borderColor),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(width: 20),
//                 Expanded(
//                   flex: 2,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       _sectionHeader('Body Measurements',
//                           Icons.straighten_rounded, accent, textPrimary),
//                       const SizedBox(height: 12),
//                       _buildMeasurements(isDark, accent, textPrimary,
//                           textSecondary, cardColor, borderColor),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 24),

//             // ── Achievements + Weekly ────────────────────────────────────
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Expanded(
//                   flex: 3,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       _sectionHeader('Achievements',
//                           Icons.emoji_events_rounded, accent, textPrimary),
//                       const SizedBox(height: 12),
//                       _buildAchievements(isDark, accent, textPrimary,
//                           textSecondary, cardColor, borderColor),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(width: 20),
//                 Expanded(
//                   flex: 2,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       _sectionHeader('This Week',
//                           Icons.bar_chart_rounded, accent, textPrimary),
//                       const SizedBox(height: 12),
//                       _buildWeeklySummary(isDark, accent, gradient,
//                           onAccent, textPrimary, textSecondary,
//                           cardColor, borderColor),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 24),

//             // ── Account actions ──────────────────────────────────────────
//             _sectionHeader('Account',
//                 Icons.manage_accounts_rounded, accent, textPrimary),
//             const SizedBox(height: 12),
//             _buildAccountActions(isDark, accent, gradient, onAccent,
//                 textPrimary, textSecondary, cardColor, borderColor),
//             const SizedBox(height: 12),
//             _buildSignOutButton(isDark, borderColor),
//             const SizedBox(height: 32),
//           ],
//         ),
//       ),
//     );
//   }

//   // ── Hero banner ────────────────────────────────────────────────────────────
//   Widget _buildHeroBanner(
//     bool isDark,
//     Color accent,
//     List<Color> gradient,
//     Color onAccent,
//     Color textPrimary,
//     Color textSecondary,
//     Color borderColor,
//   ) {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(24),
//       child: SizedBox(
//         width: double.infinity,
//         child: Stack(
//           children: [
//             // Athlete background — face + body centered
//             Positioned.fill(
//               child: Image.network(
//                 _Imgs.heroBg,
//                 fit: BoxFit.cover,
//                 alignment: Alignment.center,
//                 errorBuilder: (_, __, ___) =>
//                     Container(color: accent.withOpacity(0.08)),
//               ),
//             ),
//             // Dark gradient overlay — readable text on left
//             Positioned.fill(
//               child: Container(
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [
//                       Colors.black.withOpacity(0.92),
//                       Colors.black.withOpacity(0.72),
//                       Colors.black.withOpacity(0.25),
//                     ],
//                     begin: Alignment.centerLeft,
//                     end: Alignment.centerRight,
//                   ),
//                 ),
//               ),
//             ),
//             // Accent border
//             Positioned.fill(
//               child: Container(
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(24),
//                   border:
//                       Border.all(color: accent.withOpacity(0.3), width: 1.5),
//                 ),
//               ),
//             ),
//             // Content
//             Padding(
//               padding: const EdgeInsets.all(28),
//               child: Row(
//                 children: [
//                   // Avatar circle
//                   Stack(
//                     children: [
//                       Container(
//                         width: 90,
//                         height: 90,
//                         decoration: BoxDecoration(
//                           shape: BoxShape.circle,
//                           border: Border.all(
//                               color: accent.withOpacity(0.55), width: 2.5),
//                           boxShadow: [
//                             BoxShadow(
//                                 color: accent.withOpacity(0.4),
//                                 blurRadius: 20,
//                                 offset: const Offset(0, 4)),
//                           ],
//                         ),
//                         child: ClipOval(
//                           child: Stack(
//                             fit: StackFit.expand,
//                             children: [
//                               Image.network(
//                                 _Imgs.avatarBg,
//                                 fit: BoxFit.cover,
//                                 alignment: Alignment.center,
//                                 errorBuilder: (_, __, ___) => Container(
//                                     color: accent.withOpacity(0.2)),
//                               ),
//                               Container(color: accent.withOpacity(0.12)),
//                               Center(
//                                 child: Text(
//                                   _userName.isNotEmpty
//                                       ? _userName[0].toUpperCase()
//                                       : '?',
//                                   style: const TextStyle(
//                                       fontSize: 34,
//                                       fontWeight: FontWeight.w900,
//                                       color: Colors.white),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                       Positioned(
//                         bottom: 4,
//                         right: 4,
//                         child: Container(
//                           width: 18,
//                           height: 18,
//                           decoration: BoxDecoration(
//                             shape: BoxShape.circle,
//                             color: const Color(0xFF00C853),
//                             border:
//                                 Border.all(color: Colors.black, width: 2),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(width: 20),
//                   // User info
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(_userName,
//                             style: const TextStyle(
//                                 fontSize: 28,
//                                 fontWeight: FontWeight.w900,
//                                 color: Colors.white)),
//                         const SizedBox(height: 4),
//                         Text(_userEmail,
//                             style: TextStyle(
//                                 fontSize: 13,
//                                 color: Colors.white.withOpacity(0.50))),
//                         const SizedBox(height: 10),
//                         Wrap(
//                           spacing: 8,
//                           runSpacing: 6,
//                           children: [
//                             _miniChip(
//                                 _isLoggedIn ? '✅ Free Plan' : '👤 Guest',
//                                 accent),
//                             _miniChip(_userGoal, accent),
//                             _miniChip(
//                                 'BMI ${_bmi.toStringAsFixed(1)} · $_bmiCategory',
//                                 const Color(0xFF2979FF)),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(width: 20),
//                   // Edit profile button
//                   MouseRegion(
//                     cursor: SystemMouseCursors.click,
//                     child: GestureDetector(
//                       onTap: () => _showSnack('Edit profile coming soon!'),
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 20, vertical: 12),
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(12),
//                           border: Border.all(
//                               color: accent.withOpacity(0.5), width: 1.5),
//                           color: accent.withOpacity(0.10),
//                         ),
//                         child: Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Icon(Icons.edit_rounded, size: 16, color: accent),
//                             const SizedBox(width: 8),
//                             Text('Edit Profile',
//                                 style: TextStyle(
//                                     fontSize: 13,
//                                     fontWeight: FontWeight.w700,
//                                     color: accent)),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ── Stats grid — each card has its own photo bg ────────────────────────────
//   Widget _buildStatsGrid(bool isDark, Color accent, Color textPrimary,
//       Color cardColor, Color borderColor) {
//     final stats = [
//       {
//         'label': 'Weight',
//         'value': '${_userWeight}kg',
//         'icon': Icons.monitor_weight_rounded,
//         'color': const Color(0xFF2979FF),
//         'img': _Imgs.statWeight,
//       },
//       {
//         'label': 'Height',
//         'value': '${_userHeight}cm',
//         'icon': Icons.height_rounded,
//         'color': const Color(0xFFFF6D00),
//         'img': _Imgs.statHeight,
//       },
//       {
//         'label': 'Age',
//         'value': '$_userAge yrs',
//         'icon': Icons.cake_rounded,
//         'color': const Color(0xFFAA00FF),
//         'img': _Imgs.statAge,
//       },
//       {
//         'label': 'BMI',
//         'value': _bmi.toStringAsFixed(1),
//         'icon': Icons.analytics_rounded,
//         'color': accent,
//         'img': _Imgs.statBmi,
//       },
//       {
//         'label': 'Category',
//         'value': _bmiCategory,
//         'icon': Icons.flag_rounded,
//         'color': const Color(0xFFFFD600),
//         'img': _Imgs.statCategory,
//       },
//       {
//         'label': 'Goal',
//         'value': _userGoal.split(' ').first,
//         'icon': Icons.emoji_events_rounded,
//         'color': const Color(0xFF00BCD4),
//         'img': _Imgs.statGoal,
//       },
//     ];

//     return Wrap(
//       spacing: 12,
//       runSpacing: 12,
//       children: stats.map((stat) {
//         final color = stat['color'] as Color;
//         final icon = stat['icon'] as IconData;
//         final imgUrl = stat['img'] as String;
//         return MouseRegion(
//           cursor: SystemMouseCursors.click,
//           child: ClipRRect(
//             borderRadius: BorderRadius.circular(16),
//             child: SizedBox(
//               width: 155,
//               child: Stack(
//                 children: [
//                   // Per-stat image
//                   Positioned.fill(
//                     child: Image.network(
//                       imgUrl,
//                       fit: BoxFit.cover,
//                       alignment: Alignment.center,
//                       errorBuilder: (_, __, ___) =>
//                           Container(color: color.withOpacity(0.10)),
//                     ),
//                   ),
//                   // Dark overlay
//                   Positioned.fill(
//                     child: Container(
//                       color: Colors.black.withOpacity(0.65),
//                     ),
//                   ),
//                   // Colored border
//                   Positioned.fill(
//                     child: Container(
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(16),
//                         border:
//                             Border.all(color: color.withOpacity(0.35)),
//                       ),
//                     ),
//                   ),
//                   // Content
//                   Padding(
//                     padding: const EdgeInsets.all(16),
//                     child: Row(
//                       children: [
//                         Container(
//                           width: 38,
//                           height: 38,
//                           decoration: BoxDecoration(
//                             shape: BoxShape.circle,
//                             color: color.withOpacity(0.18),
//                             border: Border.all(
//                                 color: color.withOpacity(0.4), width: 1),
//                           ),
//                           child:
//                               Center(child: Icon(icon, size: 18, color: color)),
//                         ),
//                         const SizedBox(width: 10),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(stat['value'] as String,
//                                   style: TextStyle(
//                                       fontSize: 14,
//                                       fontWeight: FontWeight.w800,
//                                       color: color)),
//                               const SizedBox(height: 2),
//                               Text(stat['label'] as String,
//                                   style: TextStyle(
//                                       fontSize: 10,
//                                       color:
//                                           Colors.white.withOpacity(0.50))),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       }).toList(),
//     );
//   }

//   // ── Body measurements — each row item has its own image ───────────────────
//   Widget _buildMeasurements(
//     bool isDark,
//     Color accent,
//     Color textPrimary,
//     Color textSecondary,
//     Color cardColor,
//     Color borderColor,
//   ) {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(16),
//       child: Stack(
//         children: [
//           // Section-level measurement bg
//           Positioned.fill(
//             child: Image.network(
//               _Imgs.statBody,
//               fit: BoxFit.cover,
//               alignment: Alignment.center,
//               errorBuilder: (_, __, ___) =>
//                   Container(color: accent.withOpacity(0.05)),
//             ),
//           ),
//           Positioned.fill(
//             child: Container(
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.topCenter,
//                   end: Alignment.bottomCenter,
//                   colors: [
//                     Colors.black.withOpacity(0.72),
//                     Colors.black.withOpacity(0.90),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(14),
//             child: Column(
//               children: _bodyStats.asMap().entries.map((entry) {
//                 final i = entry.key;
//                 final stat = entry.value;
//                 final color = stat['color'] as Color;
//                 final imgUrl = stat['img'] as String;
//                 return Container(
//                   margin: EdgeInsets.only(
//                       bottom: i < _bodyStats.length - 1 ? 10 : 0),
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(12),
//                     border: Border.all(color: color.withOpacity(0.35)),
//                   ),
//                   child: ClipRRect(
//                     borderRadius: BorderRadius.circular(12),
//                     child: Stack(
//                       children: [
//                         // Per-measurement image
//                         Positioned.fill(
//                           child: Image.network(
//                             imgUrl,
//                             fit: BoxFit.cover,
//                             alignment: Alignment.center,
//                             errorBuilder: (_, __, ___) =>
//                                 Container(color: color.withOpacity(0.10)),
//                           ),
//                         ),
//                         Positioned.fill(
//                           child: Container(
//                             color: Colors.black.withOpacity(0.58),
//                           ),
//                         ),
//                         Padding(
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 14, vertical: 12),
//                           child: Row(
//                             children: [
//                               Icon(stat['icon'] as IconData,
//                                   size: 16, color: color),
//                               const SizedBox(width: 10),
//                               Expanded(
//                                 child: Text(stat['label'] as String,
//                                     style: TextStyle(
//                                         fontSize: 13,
//                                         color:
//                                             Colors.white.withOpacity(0.75))),
//                               ),
//                               Text(stat['value'] as String,
//                                   style: TextStyle(
//                                       fontSize: 13,
//                                       fontWeight: FontWeight.w800,
//                                       color: color)),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               }).toList(),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ── Achievements — each badge has its own image ────────────────────────────
//   Widget _buildAchievements(
//     bool isDark,
//     Color accent,
//     Color textPrimary,
//     Color textSecondary,
//     Color cardColor,
//     Color borderColor,
//   ) {
//     return Wrap(
//       spacing: 10,
//       runSpacing: 10,
//       children: _achievements.map((a) {
//         final unlocked = a['unlocked'] as bool;
//         final imgUrl = a['img'] as String;
//         return MouseRegion(
//           cursor: SystemMouseCursors.click,
//           child: AnimatedContainer(
//             duration: const Duration(milliseconds: 200),
//             width: 145,
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(16),
//               border: Border.all(
//                   color: unlocked
//                       ? accent.withOpacity(0.45)
//                       : borderColor),
//               boxShadow: unlocked
//                   ? [
//                       BoxShadow(
//                           color: accent.withOpacity(0.12),
//                           blurRadius: 12)
//                     ]
//                   : null,
//             ),
//             child: ClipRRect(
//               borderRadius: BorderRadius.circular(16),
//               child: Stack(
//                 children: [
//                   // Per-achievement image (unlocked) or muted bg (locked)
//                   Positioned.fill(
//                     child: unlocked
//                         ? Image.network(
//                             imgUrl,
//                             fit: BoxFit.cover,
//                             alignment: Alignment.center,
//                             errorBuilder: (_, __, ___) => Container(
//                                 color: accent.withOpacity(0.10)),
//                           )
//                         : Container(
//                             color: isDark
//                                 ? const Color(0xFF1A1A1A)
//                                 : const Color(0xFFF0F0F0)),
//                   ),
//                   // Overlay — heavier for unlocked to keep text readable
//                   Positioned.fill(
//                     child: Container(
//                       color: unlocked
//                           ? Colors.black.withOpacity(0.52)
//                           : Colors.black.withOpacity(0.08),
//                     ),
//                   ),
//                   // Accent tint for unlocked
//                   if (unlocked)
//                     Positioned.fill(
//                       child: Container(
//                         color: accent.withOpacity(0.10),
//                       ),
//                     ),
//                   // Content
//                   Padding(
//                     padding: const EdgeInsets.all(14),
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         // Icon image or lock
//                         ClipRRect(
//                           borderRadius: BorderRadius.circular(10),
//                           child: unlocked
//                               ? Image.network(
//                                   imgUrl,
//                                   width: 42,
//                                   height: 42,
//                                   fit: BoxFit.cover,
//                                   alignment: Alignment.center,
//                                   errorBuilder: (_, __, ___) => Text(
//                                     a['icon'] as String,
//                                     style:
//                                         const TextStyle(fontSize: 28),
//                                   ),
//                                 )
//                               : Container(
//                                   width: 42,
//                                   height: 42,
//                                   decoration: BoxDecoration(
//                                     borderRadius:
//                                         BorderRadius.circular(10),
//                                     color: isDark
//                                         ? const Color(0xFF252525)
//                                         : const Color(0xFFE8E8E8),
//                                   ),
//                                   child: Icon(Icons.lock_rounded,
//                                       size: 22,
//                                       color: isDark
//                                           ? Colors.white.withOpacity(0.22)
//                                           : Colors.black.withOpacity(0.18)),
//                                 ),
//                         ),
//                         const SizedBox(height: 8),
//                         Text(a['title'] as String,
//                             textAlign: TextAlign.center,
//                             style: TextStyle(
//                                 fontSize: 12,
//                                 fontWeight: FontWeight.w700,
//                                 color: unlocked
//                                     ? Colors.white
//                                     : textPrimary.withOpacity(0.30))),
//                         const SizedBox(height: 3),
//                         Text(a['desc'] as String,
//                             textAlign: TextAlign.center,
//                             style: TextStyle(
//                                 fontSize: 10,
//                                 color: unlocked
//                                     ? Colors.white.withOpacity(0.65)
//                                     : textSecondary.withOpacity(0.30))),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       }).toList(),
//     );
//   }

//   // ── Weekly summary ─────────────────────────────────────────────────────────
//   Widget _buildWeeklySummary(
//     bool isDark,
//     Color accent,
//     List<Color> gradient,
//     Color onAccent,
//     Color textPrimary,
//     Color textSecondary,
//     Color cardColor,
//     Color borderColor,
//   ) {
//     final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
//     final completed = [true, true, false, true, false, false, false];

//     return ClipRRect(
//       borderRadius: BorderRadius.circular(16),
//       child: Stack(
//         children: [
//           Positioned.fill(
//             child: Image.network(
//               _Imgs.weeklyBg,
//               fit: BoxFit.cover,
//               alignment: Alignment.center,
//               errorBuilder: (_, __, ___) =>
//                   Container(color: accent.withOpacity(0.05)),
//             ),
//           ),
//           Positioned.fill(
//             child: Container(
//               color: isDark
//                   ? Colors.black.withOpacity(0.80)
//                   : Colors.white.withOpacity(0.92),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(18),
//             child: Column(
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text('Weekly Workouts',
//                         style: TextStyle(
//                             fontSize: 14,
//                             fontWeight: FontWeight.w700,
//                             color: textPrimary)),
//                     Text('3/7 days',
//                         style: TextStyle(
//                             fontSize: 13,
//                             color: accent,
//                             fontWeight: FontWeight.w700)),
//                   ],
//                 ),
//                 const SizedBox(height: 16),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: List.generate(7, (i) {
//                     final done = completed[i];
//                     return Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         AnimatedContainer(
//                           duration: const Duration(milliseconds: 300),
//                           width: 36,
//                           height: 36,
//                           decoration: BoxDecoration(
//                             shape: BoxShape.circle,
//                             gradient:
//                                 done ? LinearGradient(colors: gradient) : null,
//                             color: done
//                                 ? null
//                                 : (isDark
//                                     ? const Color(0xFF1A1A1A)
//                                     : const Color(0xFFF0F0F0)),
//                             border: Border.all(
//                                 color: done
//                                     ? Colors.transparent
//                                     : borderColor),
//                             boxShadow: done
//                                 ? [
//                                     BoxShadow(
//                                         color: accent.withOpacity(0.3),
//                                         blurRadius: 8)
//                                   ]
//                                 : null,
//                           ),
//                           child: Center(
//                             child: done
//                                 ? Icon(Icons.check_rounded,
//                                     size: 16, color: onAccent)
//                                 : Text(days[i],
//                                     style: TextStyle(
//                                         fontSize: 11,
//                                         fontWeight: FontWeight.w600,
//                                         color: textSecondary)),
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         if (done)
//                           Text(days[i],
//                               style:
//                                   TextStyle(fontSize: 9, color: accent)),
//                       ],
//                     );
//                   }),
//                 ),
//                 const SizedBox(height: 16),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text('Avg. Calories',
//                         style: TextStyle(
//                             fontSize: 11, color: textSecondary)),
//                     Text('1,840 / 2,000 kcal',
//                         style: TextStyle(
//                             fontSize: 11,
//                             color: accent,
//                             fontWeight: FontWeight.w600)),
//                   ],
//                 ),
//                 const SizedBox(height: 6),
//                 ClipRRect(
//                   borderRadius: BorderRadius.circular(4),
//                   child: LinearProgressIndicator(
//                     value: 1840 / 2000,
//                     minHeight: 6,
//                     backgroundColor: accent.withOpacity(0.12),
//                     valueColor: AlwaysStoppedAnimation<Color>(accent),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ── Account actions ────────────────────────────────────────────────────────
//   Widget _buildAccountActions(
//     bool isDark,
//     Color accent,
//     List<Color> gradient,
//     Color onAccent,
//     Color textPrimary,
//     Color textSecondary,
//     Color cardColor,
//     Color borderColor,
//   ) {
//     final actions = [
//       {
//         'icon': Icons.settings_rounded,
//         'label': 'Settings',
//         'subtitle': 'Appearance, notifications & more',
//         'color': accent,
//         'onTap': () => Navigator.pushNamed(context, '/settings'),
//       },
//       {
//         'icon': Icons.lock_outline_rounded,
//         'label': 'Change Password',
//         'subtitle': 'Update your account password',
//         'color': const Color(0xFF2979FF),
//         'onTap': () async {
//           if (!_isLoggedIn) {
//             _showSnack('Sign in to change password.', isError: true);
//             return;
//           }
//           final email = _supabase.auth.currentUser?.email;
//           if (email != null) {
//             try {
//               await _supabase.auth.resetPasswordForEmail(email);
//               _showSnack('Password reset email sent!');
//             } on AuthException catch (e) {
//               _showSnack(e.message, isError: true);
//             } catch (_) {
//               _showSnack('Failed to send reset email.', isError: true);
//             }
//           }
//         },
//       },
//       {
//         'icon': Icons.download_rounded,
//         'label': 'Export Data',
//         'subtitle': 'Download your fitness data',
//         'color': const Color(0xFFFF6D00),
//         'onTap': () => _showSnack('Export coming soon!'),
//       },
//       {
//         'icon': Icons.help_outline_rounded,
//         'label': 'Help & Support',
//         'subtitle': 'Get help or contact us',
//         'color': const Color(0xFFAA00FF),
//         'onTap': () => _showSnack('Support coming soon!'),
//       },
//     ];

//     return Container(
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(16),
//         color: cardColor,
//         border: Border.all(color: borderColor),
//       ),
//       child: Column(
//         children: actions.asMap().entries.map((entry) {
//           final i = entry.key;
//           final action = entry.value;
//           final color = action['color'] as Color;
//           return Column(
//             children: [
//               _WebActionTile(
//                 icon: action['icon'] as IconData,
//                 label: action['label'] as String,
//                 subtitle: action['subtitle'] as String,
//                 color: color,
//                 textPrimary: textPrimary,
//                 textSecondary: textSecondary,
//                 borderColor: borderColor,
//                 onTap: action['onTap'] as VoidCallback,
//               ),
//               if (i < actions.length - 1)
//                 Divider(
//                     height: 1,
//                     color: borderColor,
//                     indent: 68,
//                     endIndent: 16),
//             ],
//           );
//         }).toList(),
//       ),
//     );
//   }

//   // ── Sign out button ────────────────────────────────────────────────────────
//   Widget _buildSignOutButton(bool isDark, Color borderColor) {
//     return MouseRegion(
//       cursor: SystemMouseCursors.click,
//       child: GestureDetector(
//         onTap: _isLoggingOut ? null : _handleLogout,
//         child: AnimatedContainer(
//           duration: const Duration(milliseconds: 150),
//           width: double.infinity,
//           height: 52,
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(14),
//             color: isDark
//                 ? const Color(0xFF1A0A0A)
//                 : const Color(0xFFFFF0F0),
//             border: Border.all(
//                 color: const Color(0xFFFF1744).withOpacity(0.4)),
//           ),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               _isLoggingOut
//                   ? const SizedBox(
//                       width: 16,
//                       height: 16,
//                       child: CircularProgressIndicator(
//                           color: Color(0xFFFF1744), strokeWidth: 2))
//                   : const Icon(Icons.logout_rounded,
//                       size: 18, color: Color(0xFFFF1744)),
//               const SizedBox(width: 10),
//               const Text('Sign Out',
//                   style: TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w700,
//                       color: Color(0xFFFF1744))),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // ── Shared small widgets ───────────────────────────────────────────────────
//   Widget _sectionHeader(
//       String title, IconData icon, Color accent, Color textPrimary) {
//     return Row(
//       children: [
//         Container(
//           width: 30,
//           height: 30,
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(8),
//             color: accent.withOpacity(0.12),
//           ),
//           child: Center(child: Icon(icon, size: 16, color: accent)),
//         ),
//         const SizedBox(width: 10),
//         Text(title,
//             style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w800,
//                 color: textPrimary)),
//       ],
//     );
//   }

//   Widget _miniChip(String text, Color accent) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(6),
//         color: accent.withOpacity(0.15),
//         border: Border.all(color: accent.withOpacity(0.3)),
//       ),
//       child: Text(text,
//           style: TextStyle(
//               fontSize: 11,
//               color: accent,
//               fontWeight: FontWeight.w700)),
//     );
//   }
// }

// // ── Web action tile with hover ─────────────────────────────────────────────
// class _WebActionTile extends StatefulWidget {
//   final IconData icon;
//   final String label;
//   final String subtitle;
//   final Color color;
//   final Color textPrimary;
//   final Color textSecondary;
//   final Color borderColor;
//   final VoidCallback onTap;

//   const _WebActionTile({
//     required this.icon,
//     required this.label,
//     required this.subtitle,
//     required this.color,
//     required this.textPrimary,
//     required this.textSecondary,
//     required this.borderColor,
//     required this.onTap,
//   });

//   @override
//   State<_WebActionTile> createState() => _WebActionTileState();
// }

// class _WebActionTileState extends State<_WebActionTile> {
//   bool _hovered = false;

//   @override
//   Widget build(BuildContext context) {
//     return MouseRegion(
//       cursor: SystemMouseCursors.click,
//       onEnter: (_) => setState(() => _hovered = true),
//       onExit: (_) => setState(() => _hovered = false),
//       child: GestureDetector(
//         onTap: widget.onTap,
//         behavior: HitTestBehavior.opaque,
//         child: AnimatedContainer(
//           duration: const Duration(milliseconds: 150),
//           padding:
//               const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//           color: _hovered
//               ? widget.color.withOpacity(0.05)
//               : Colors.transparent,
//           child: Row(
//             children: [
//               Container(
//                 width: 40,
//                 height: 40,
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(10),
//                   color: widget.color.withOpacity(0.12),
//                 ),
//                 child: Center(
//                     child: Icon(widget.icon,
//                         size: 18, color: widget.color)),
//               ),
//               const SizedBox(width: 14),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(widget.label,
//                         style: TextStyle(
//                             fontSize: 14,
//                             fontWeight: FontWeight.w600,
//                             color: widget.textPrimary)),
//                     Text(widget.subtitle,
//                         style: TextStyle(
//                             fontSize: 11,
//                             color: widget.textSecondary)),
//                   ],
//                 ),
//               ),
//               Icon(Icons.chevron_right_rounded,
//                   size: 18,
//                   color: _hovered
//                       ? widget.color
//                       : widget.textSecondary.withOpacity(0.5)),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }