import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';

class WebSidebar extends StatefulWidget {
  final bool isLoggedIn;
  final String webSection;
  final String userName;
  final void Function(String section) onSectionTap;
  final VoidCallback onJoinFreeTap;

  const WebSidebar({
    super.key,
    required this.isLoggedIn,
    required this.webSection,
    required this.userName,
    required this.onSectionTap,
    required this.onJoinFreeTap,
  });

  @override
  State<WebSidebar> createState() => _WebSidebarState();
}

class _WebSidebarState extends State<WebSidebar>
    with SingleTickerProviderStateMixin {
  String? _hoveredItem;
  late AnimationController _glowController;
  late Animation<double> _glowAnim;

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
              'locked': false
            },
            {
              'icon': Icons.fitness_center_rounded,
              'label': 'Workouts',
              'locked': false
            },
            {
              'icon': Icons.restaurant_rounded,
              'label': 'Diet Plan',
              'locked': false
            },
            {
              'icon': Icons.bar_chart_rounded,
              'label': 'Progress',
              'locked': false
            },
            {
              'icon': Icons.notifications_rounded,
              'label': 'Reminders',
              'locked': false
            },
            {
              'icon': Icons.person_rounded,
              'label': 'Profile',
              'locked': false
            },
            {
              'icon': Icons.settings_rounded,
              'label': 'Settings',
              'locked': false
            },
          ]
        : [
            {
              'icon': Icons.dashboard_rounded,
              'label': 'Dashboard',
              'locked': false
            },
            {
              'icon': Icons.lock_rounded,
              'label': 'Workouts',
              'locked': true
            },
            {
              'icon': Icons.lock_rounded,
              'label': 'Diet Plan',
              'locked': true
            },
            {
              'icon': Icons.lock_rounded,
              'label': 'Progress',
              'locked': true
            },
          ];

    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (context, child) {
        return Container(
          width: 220,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.03)
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
          const SizedBox(height: 20),

          // ── User avatar card ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Consumer<ThemeProvider>(
              builder: (context, theme, _) => Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: accent.withOpacity(0.08),
                  border:
                      Border.all(color: accent.withOpacity(0.2), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withOpacity(0.1),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Avatar with gradient ring
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: theme.accentGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withOpacity(0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.person_rounded,
                          size: 18,
                          color: theme.onAccent,
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

          const SizedBox(height: 16),

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

          const SizedBox(height: 12),

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
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
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
                // Active indicator dot with glow
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