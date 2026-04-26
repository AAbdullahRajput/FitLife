import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';

class WebTopNav extends StatefulWidget {
  final bool isLoggedIn;
  final bool sidebarExpanded;
  final String webSection;
  final bool showProfileDropdown;
  final String userName;
  final VoidCallback onHamburgerTap;
  final VoidCallback onLogoDashboardTap;
  final VoidCallback onProfileTap;
  final void Function(String section) onNavTap;

  const WebTopNav({
    super.key,
    required this.isLoggedIn,
    required this.sidebarExpanded,
    required this.webSection,
    required this.showProfileDropdown,
    required this.userName,
    required this.onHamburgerTap,
    required this.onLogoDashboardTap,
    required this.onProfileTap,
    required this.onNavTap,
  });

  @override
  State<WebTopNav> createState() => _WebTopNavState();
}

class _WebTopNavState extends State<WebTopNav> {
  String? _hoveredNavLink;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppColors.of(context);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        // ── Glassmorphism navbar ───────────────────────────────────────
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.white.withOpacity(0.75),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? accent.withOpacity(0.15)
                : const Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: accent.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          // ── Hamburger ────────────────────────────────────────────────
          _NavButton(
            onTap: widget.onHamburgerTap,
            accent: accent,
            isDark: isDark,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                widget.sidebarExpanded
                    ? Icons.close_rounded
                    : Icons.menu_rounded,
                key: ValueKey(widget.sidebarExpanded),
                size: 20,
                color: accent,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // ── Logo ─────────────────────────────────────────────────────
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: widget.onLogoDashboardTap,
              child: Row(
                children: [
                  // Glowing logo icon
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: AppColors.gradientOf(context),
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withOpacity(0.5),
                          blurRadius: 12,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.fitness_center_rounded,
                        size: 17,
                        color: AppColors.onAccentOf(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Consumer<ThemeProvider>(
                    builder: (context, theme, _) => ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: theme.accentGradient,
                      ).createShader(bounds),
                      child: const Text(
                        'FitLife',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // ── Nav links ────────────────────────────────────────────────
          if (widget.isLoggedIn) ...[
            _buildNavLink('Dashboard',
                widget.webSection == 'Dashboard', textPrimary, accent),
            const SizedBox(width: 2),
            _buildNavLink('Workouts',
                widget.webSection == 'Workouts', textPrimary, accent),
            const SizedBox(width: 2),
            _buildNavLink('Diet',
                widget.webSection == 'Diet Plan', textPrimary, accent),
            const SizedBox(width: 2),
            _buildNavLink('Progress',
                widget.webSection == 'Progress', textPrimary, accent),
            const SizedBox(width: 16),
          ],

          // ── Theme toggle ─────────────────────────────────────────────
          Consumer<ThemeProvider>(
            builder: (context, theme, _) => _NavButton(
              onTap: () =>
                  Provider.of<ThemeProvider>(context, listen: false)
                      .toggleTheme(),
              accent: accent,
              isDark: isDark,
              child: Icon(
                theme.isDark
                    ? Icons.wb_sunny_rounded
                    : Icons.dark_mode_rounded,
                size: 17,
                color: accent,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // ── Auth buttons or profile ───────────────────────────────────
          if (!widget.isLoggedIn) ...[
            // Sign In button
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/login'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: accent.withOpacity(0.4), width: 1.5),
                    color: accent.withOpacity(0.06),
                  ),
                  child: Text(
                    'Sign In',
                    style: TextStyle(
                      color: accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Get Started button — glowing gradient
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/register'),
                child: Consumer<ThemeProvider>(
                  builder: (context, theme, _) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(
                          colors: theme.accentGradient),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withOpacity(0.4),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      'Get Started Free',
                      style: TextStyle(
                        color: theme.onAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ] else ...[
            // Profile avatar with glow
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: widget.onProfileTap,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: widget.showProfileDropdown
                        ? LinearGradient(
                            colors: AppColors.gradientOf(context))
                        : null,
                    color: widget.showProfileDropdown
                        ? null
                        : accent.withOpacity(0.15),
                    border: Border.all(
                      color: widget.showProfileDropdown
                          ? accent
                          : accent.withOpacity(0.4),
                      width: widget.showProfileDropdown ? 2 : 1.5,
                    ),
                    boxShadow: widget.showProfileDropdown
                        ? [
                            BoxShadow(
                              color: accent.withOpacity(0.4),
                              blurRadius: 12,
                              spreadRadius: 0,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.person_rounded,
                      size: 18,
                      color: widget.showProfileDropdown
                          ? AppColors.onAccentOf(context)
                          : accent,
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildNavLink(
      String label, bool isActive, Color textPrimary, Color accent) {
    final isHovered = _hoveredNavLink == label;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoveredNavLink = label),
      onExit: (_) => setState(() => _hoveredNavLink = null),
      child: GestureDetector(
        onTap: () {
          if (label == 'Dashboard') widget.onNavTap('Dashboard');
          else if (label == 'Workouts') widget.onNavTap('Workouts');
          else if (label == 'Diet') widget.onNavTap('Diet Plan');
          else if (label == 'Progress') widget.onNavTap('Progress');
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: isActive
                ? accent.withOpacity(0.15)
                : isHovered
                    ? accent.withOpacity(0.08)
                    : Colors.transparent,
            border: isActive
                ? Border.all(color: accent.withOpacity(0.3), width: 1)
                : null,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: accent.withOpacity(0.2),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive || isHovered
                  ? accent
                  : textPrimary.withOpacity(0.55),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Reusable nav icon button ─────────────────────────────────────────────────
class _NavButton extends StatefulWidget {
  final VoidCallback onTap;
  final Color accent;
  final bool isDark;
  final Widget child;

  const _NavButton({
    required this.onTap,
    required this.accent,
    required this.isDark,
    required this.child,
  });

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> {
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
          duration: const Duration(milliseconds: 150),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: _hovered
                ? widget.accent.withOpacity(0.15)
                : widget.accent.withOpacity(0.07),
            border: Border.all(
              color: _hovered
                  ? widget.accent.withOpacity(0.4)
                  : widget.accent.withOpacity(0.15),
              width: 1,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: widget.accent.withOpacity(0.2),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}