import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';

class WebSidebar extends StatefulWidget {
  final bool isLoggedIn;
  final String webSection;
  final String userName;
  final String? profilePhotoUrl;
  final void Function(String section) onSectionTap;
  final VoidCallback onJoinFreeTap;

  const WebSidebar({
    super.key,
    required this.isLoggedIn,
    required this.webSection,
    required this.userName,
    required this.onSectionTap,
    required this.onJoinFreeTap,
    this.profilePhotoUrl,
  });

  @override
  State<WebSidebar> createState() => _WebSidebarState();
}

class _WebSidebarState extends State<WebSidebar>
    with SingleTickerProviderStateMixin {
  String? _hoveredItem;
  late AnimationController _glowController;
  late Animation<double> _glowAnim;

  // ── Unsplash image URLs ──────────────────────────────────────────────────
  static const _avatarImageUrl =
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d'
      '?w=100&q=80&auto=format&fit=crop&facepad=3';

  // Section banner images shown at top of sidebar per active section
  static const _sectionImages = {
    'Dashboard':
        'https://images.unsplash.com/photo-1534438327276-14e5300c3a48'
        '?w=300&q=70&auto=format&fit=crop',
    'Workouts':
        'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e'
        '?w=300&q=70&auto=format&fit=crop',
    'Diet Plan':
        'https://images.unsplash.com/photo-1547592180-85f173990554'
        '?w=300&q=70&auto=format&fit=crop',
    'Progress':
        'https://images.unsplash.com/photo-1549576490-b0b4831ef60a'
        '?w=300&q=70&auto=format&fit=crop',
    'Reminders':
        'https://images.unsplash.com/photo-1506126613408-eca07ce68773'
        '?w=300&q=70&auto=format&fit=crop',
    'Profile':
        'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b'
        '?w=300&q=70&auto=format&fit=crop',
    'Settings':
        'https://images.unsplash.com/photo-1517963879433-6ad2b056d712'
        '?w=300&q=70&auto=format&fit=crop',
  };

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppColors.of(context);

    final items = widget.isLoggedIn
        ? [
            {
              'icon': Icons.dashboard_rounded,
              'label': 'Dashboard',
              'locked': false,
            },
            {
              'icon': Icons.fitness_center_rounded,
              'label': 'Workouts',
              'locked': false,
            },
            {
              'icon': Icons.restaurant_rounded,
              'label': 'Diet Plan',
              'locked': false,
            },
            {
              'icon': Icons.bar_chart_rounded,
              'label': 'Progress',
              'locked': false,
            },
            {
              'icon': Icons.notifications_rounded,
              'label': 'Reminders',
              'locked': false,
            },
            {
              'icon': Icons.person_rounded,
              'label': 'Profile',
              'locked': false,
            },
            {
              'icon': Icons.settings_rounded,
              'label': 'Settings',
              'locked': false,
            },
          ]
        : [
            {
              'icon': Icons.dashboard_rounded,
              'label': 'Dashboard',
              'locked': false,
            },
            {
              'icon': Icons.lock_rounded,
              'label': 'Workouts',
              'locked': true,
            },
            {
              'icon': Icons.lock_rounded,
              'label': 'Diet Plan',
              'locked': true,
            },
            {
              'icon': Icons.lock_rounded,
              'label': 'Progress',
              'locked': true,
            },
          ];

    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (context, child) {
        return Container(
          width: 220,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withOpacity(0.5)
                : Colors.white.withOpacity(0.85),
            border: Border(
              right: BorderSide(
                color: isDark
                    ? accent.withOpacity(0.12 * _glowAnim.value)
                    : const Color(0xFFE0E0E0),
                width: 1,
              ),
            ),
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: accent.withOpacity(0.05 * _glowAnim.value),
                      blurRadius: 20,
                      offset: const Offset(4, 0),
                    ),
                  ]
                : null,
          ),
          child: child,
        );
      },
      child: Column(
        children: [
          // ── Section banner image ─────────────────────────────────────
          _SectionBanner(
            imageUrl: _sectionImages[widget.webSection] ??
                _sectionImages['Dashboard']!,
            section: widget.webSection,
            accent: accent,
          ),

          const SizedBox(height: 12),

          // ── User avatar card ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Consumer<ThemeProvider>(
              builder: (context, theme, _) => Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: accent.withOpacity(0.08),
                  border: Border.all(
                      color: accent.withOpacity(0.2), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withOpacity(0.1),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Real avatar photo with gradient ring
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: accent.withOpacity(0.6),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withOpacity(0.35),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.network(
                          widget.profilePhotoUrl ?? _avatarImageUrl,
                          width: 38,
                          height: 38,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: theme.accentGradient,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.person_rounded,
                                size: 18,
                                color: theme.onAccent,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.userName,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : const Color(0xFF0A0A0A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: widget.isLoggedIn
                                      ? accent
                                      : Colors.grey,
                                  boxShadow: widget.isLoggedIn
                                      ? [
                                          BoxShadow(
                                            color:
                                                accent.withOpacity(0.6),
                                            blurRadius: 4,
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                widget.isLoggedIn ? 'Member' : 'Guest',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: widget.isLoggedIn
                                      ? accent
                                      : Colors.grey,
                                  fontWeight: FontWeight.w500,
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
            ),
          ),

          const SizedBox(height: 12),

          // ── Divider with glow ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    accent.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Nav items ────────────────────────────────────────────────
          ...items.map((item) {
            final label = item['label'] as String;
            final isLocked = item['locked'] as bool;
            final isActive = label == widget.webSection;
            final isHovered = _hoveredItem == label && !isLocked;

            return _SidebarItem(
              icon: item['icon'] as IconData,
              label: label,
              isActive: isActive,
              isLocked: isLocked,
              isHovered: isHovered,
              accent: accent,
              isDark: Theme.of(context).brightness == Brightness.dark,
              onEnter: () {
                if (!isLocked) setState(() => _hoveredItem = label);
              },
              onExit: () => setState(() => _hoveredItem = null),
              onTap: isLocked
                  ? null
                  : () => widget.onSectionTap(label),
            );
          }),

          const Spacer(),

          // ── Join Free button ─────────────────────────────────────────
          if (!widget.isLoggedIn)
            Padding(
              padding: const EdgeInsets.all(12),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: widget.onJoinFreeTap,
                  child: Consumer<ThemeProvider>(
                    builder: (context, theme, _) => Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: theme.accentGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: 14,
                            color: theme.onAccent,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Join Free',
                            style: TextStyle(
                              color: theme.onAccent,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Section banner image at top of sidebar ───────────────────────────────────
class _SectionBanner extends StatelessWidget {
  final String imageUrl;
  final String section;
  final Color accent;

  const _SectionBanner({
    required this.imageUrl,
    required this.section,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 100,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Real section image
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (_, __, ___) => Container(
              color: accent.withOpacity(0.08),
              child: Center(
                child: Icon(
                  Icons.fitness_center_rounded,
                  color: accent.withOpacity(0.3),
                  size: 32,
                ),
              ),
            ),
          ),
          // Dark gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.75),
                ],
              ),
            ),
          ),
          // Section label
          Positioned(
            bottom: 10,
            left: 14,
            right: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                    border:
                        Border.all(color: accent.withOpacity(0.4), width: 1),
                  ),
                  child: Text(
                    section.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: accent,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Left accent bar
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    accent.withOpacity(0.1),
                    accent,
                    accent.withOpacity(0.1),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Individual sidebar item ───────────────────────────────────────────────────
class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isLocked;
  final bool isHovered;
  final Color accent;
  final bool isDark;
  final VoidCallback? onTap;
  final VoidCallback onEnter;
  final VoidCallback onExit;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.isLocked,
    required this.isHovered,
    required this.accent,
    required this.isDark,
    required this.onTap,
    required this.onEnter,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isActive
        ? accent
        : isHovered
            ? accent.withOpacity(0.9)
            : isLocked
                ? Colors.white.withOpacity(0.18)
                : isDark
                    ? Colors.white.withOpacity(0.5)
                    : Colors.black.withOpacity(0.4);

    final textColor = isActive
        ? accent
        : isHovered
            ? accent.withOpacity(0.9)
            : isLocked
                ? Colors.white.withOpacity(0.18)
                : isDark
                    ? Colors.white.withOpacity(0.6)
                    : Colors.black.withOpacity(0.55);

    return MouseRegion(
      cursor: isLocked
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      onEnter: (_) => onEnter(),
      onExit: (_) => onExit(),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isActive
                ? accent.withOpacity(0.15)
                : isHovered
                    ? accent.withOpacity(0.08)
                    : Colors.transparent,
            border: isActive
                ? Border.all(color: accent.withOpacity(0.3), width: 1)
                : Border.all(color: Colors.transparent, width: 1),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: accent.withOpacity(0.2),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // Icon with glow when active
              Container(
                width: 28,
                height: 28,
                decoration: isActive
                    ? BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent.withOpacity(0.15),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withOpacity(0.3),
                            blurRadius: 8,
                          ),
                        ],
                      )
                    : null,
                child: Center(
                  child: Icon(icon, size: 17, color: iconColor),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive
                        ? FontWeight.w700
                        : FontWeight.w400,
                    color: textColor,
                  ),
                ),
              ),
              if (isLocked)
                Icon(
                  Icons.lock_outline_rounded,
                  size: 12,
                  color: Colors.white.withOpacity(0.2),
                ),
              if (isActive && !isLocked)
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent,
                    boxShadow: [
                      BoxShadow(
                        color: accent.withOpacity(0.6),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
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