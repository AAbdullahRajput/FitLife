import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';

class WebTopNav extends StatefulWidget {
  final bool isLoggedIn;
  final bool sidebarExpanded;
  final String webSection;
  final void Function(String) onNavigate;
  final VoidCallback onToggleSidebar;
  final VoidCallback onToggleTheme;
  final VoidCallback onLogin;
  final VoidCallback onLogout;
  final String? profilePhotoUrl;

  const WebTopNav({
    super.key,
    required this.isLoggedIn,
    required this.sidebarExpanded,
    required this.webSection,
    required this.onNavigate,
    required this.onToggleSidebar,
    required this.onToggleTheme,
    required this.onLogin,
    required this.onLogout,
    this.profilePhotoUrl,
  });

  @override
  State<WebTopNav> createState() => _WebTopNavState();
}

class _WebTopNavState extends State<WebTopNav> {
  String? _hoveredItem;

  // ── A bright, clearly visible dumbbell / gym logo image ──────────────
  // White dumbbell on dark background — instantly recognisable
  static const _logoImg =
      'https://images.unsplash.com/photo-1526506118085-60ce8714f8c5'
      '?w=120&q=90&auto=format&fit=crop'; // close-up dumbbells, bright + sharp

  // Profile avatar fallback image
  static const _avatarImg =
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb'
      '?w=120&q=80&auto=format&fit=crop';

  static const _navItems = ['Dashboard', 'Workouts', 'Diet', 'Progress'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppColors.of(context);

    return Consumer<ThemeProvider>(
      builder: (context, theme, _) {
        return Container(
          height: 60,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withOpacity(0.75)
                : Colors.white.withOpacity(0.92),
            border: Border(
              bottom: BorderSide(
                color: accent.withOpacity(0.15),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // ── Hamburger ────────────────────────────────────────
                _NavIconButton(
                  icon: widget.sidebarExpanded
                      ? Icons.menu_open_rounded
                      : Icons.menu_rounded,
                  accent: accent,
                  isDark: isDark,
                  onTap: widget.onToggleSidebar,
                ),
                const SizedBox(width: 12),

                // ── Logo ─────────────────────────────────────────────
                _LogoWidget(
                  logoImg: _logoImg,
                  accent: accent,
                  theme: theme,
                ),
                const SizedBox(width: 8),
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: theme.accentGradient,
                  ).createShader(bounds),
                  child: const Text(
                    'FitLife',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

                const Spacer(),

                // ── Nav items ────────────────────────────────────────
                Row(
                  children: _navItems.map((item) {
                    final isActive = widget.webSection == item;
                    final isHovered = _hoveredItem == item;
                    return MouseRegion(
                      cursor: SystemMouseCursors.click,
                      onEnter: (_) => setState(() => _hoveredItem = item),
                      onExit: (_) => setState(() => _hoveredItem = null),
                      child: GestureDetector(
                        onTap: () => widget.onNavigate(item),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: isActive
                                ? accent.withOpacity(0.15)
                                : isHovered
                                    ? accent.withOpacity(0.07)
                                    : Colors.transparent,
                            border: isActive
                                ? Border.all(
                                    color: accent.withOpacity(0.4), width: 1)
                                : null,
                          ),
                          child: Text(
                            item,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isActive
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isActive
                                  ? accent
                                  : isDark
                                      ? Colors.white.withOpacity(0.65)
                                      : Colors.black.withOpacity(0.6),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(width: 16),

                // ── Theme toggle ─────────────────────────────────────
                _NavIconButton(
                  icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  accent: accent,
                  isDark: isDark,
                  onTap: widget.onToggleTheme,
                ),
                const SizedBox(width: 8),

                // ── Online indicator dot ─────────────────────────────
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF00C853),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00C853).withOpacity(0.6),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // ── Profile avatar ───────────────────────────────────
                _ProfileAvatar(
                  avatarImg: widget.profilePhotoUrl ?? _avatarImg,
                  isLoggedIn: widget.isLoggedIn,
                  accent: accent,
                  theme: theme,
                  onLogin: widget.onLogin,
                  onLogout: widget.onLogout,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LOGO WIDGET
// ═══════════════════════════════════════════════════════════════════════════
class _LogoWidget extends StatefulWidget {
  final String logoImg;
  final Color accent;
  final ThemeProvider theme;

  const _LogoWidget({
    required this.logoImg,
    required this.accent,
    required this.theme,
  });

  @override
  State<_LogoWidget> createState() => _LogoWidgetState();
}

class _LogoWidgetState extends State<_LogoWidget> {
  bool _imgLoaded = false;
  bool _imgError = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: _imgError || !_imgLoaded
            ? LinearGradient(
                colors: widget.theme.accentGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        border: Border.all(
          color: widget.accent.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.accent.withOpacity(0.4),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipOval(
        child: _imgError
            // ── Fallback: gradient circle with dumbbell icon ──────────
            ? Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.theme.accentGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.fitness_center_rounded,
                    size: 18,
                    color: widget.theme.onAccent,
                  ),
                ),
              )
            // ── Real image ────────────────────────────────────────────
            : Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.logoImg,
                    fit: BoxFit.cover,
                    // Show center of the dumbbell image
                    alignment: Alignment.center,
                    loadingBuilder: (ctx, child, progress) {
                      if (progress == null) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) setState(() => _imgLoaded = true);
                        });
                        return child;
                      }
                      // While loading — show gradient placeholder
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: widget.theme.accentGradient,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.fitness_center_rounded,
                            size: 16,
                            color: widget.theme.onAccent,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) setState(() => _imgError = true);
                      });
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: widget.theme.accentGradient,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.fitness_center_rounded,
                            size: 16,
                            color: widget.theme.onAccent,
                          ),
                        ),
                      );
                    },
                  ),
                  // Subtle green tint overlay to brand it
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.accent.withOpacity(0.25),
                          Colors.transparent,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PROFILE AVATAR
// ═══════════════════════════════════════════════════════════════════════════
class _ProfileAvatar extends StatefulWidget {
  final String avatarImg;
  final bool isLoggedIn;
  final Color accent;
  final ThemeProvider theme;
  final VoidCallback onLogin;
  final VoidCallback onLogout;

  const _ProfileAvatar({
    required this.avatarImg,
    required this.isLoggedIn,
    required this.accent,
    required this.theme,
    required this.onLogin,
    required this.onLogout,
  });

  @override
  State<_ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<_ProfileAvatar> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.isLoggedIn ? widget.onLogout : widget.onLogin,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: _hovered
                  ? widget.accent.withOpacity(0.8)
                  : widget.accent.withOpacity(0.35),
              width: _hovered ? 2 : 1.5,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: widget.accent.withOpacity(0.4),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: ClipOval(
            child: widget.avatarImg.startsWith('http') &&
                    widget.avatarImg != 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=120&q=80&auto=format&fit=crop'
                ? Image.network(
                    widget.avatarImg,
                    fit: BoxFit.cover,
                    width: 36,
                    height: 36,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: BoxDecoration(
                        color: widget.accent.withOpacity(0.1),
                      ),
                      child: Center(
                        child: Icon(Icons.person_rounded,
                            size: 18, color: widget.accent),
                      ),
                    ),
                  )
                : widget.isLoggedIn
                    ? Image.network(
                        widget.avatarImg,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                        errorBuilder: (_, __, ___) => Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: widget.theme.accentGradient,
                            ),
                          ),
                          child: Center(
                            child: Icon(Icons.person_rounded,
                                size: 18, color: widget.theme.onAccent),
                          ),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: widget.accent.withOpacity(0.1),
                        ),
                        child: Center(
                          child: Icon(Icons.person_rounded,
                              size: 18, color: widget.accent),
                        ),
                      ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// NAV ICON BUTTON
// ═══════════════════════════════════════════════════════════════════════════
class _NavIconButton extends StatefulWidget {
  final IconData icon;
  final Color accent;
  final bool isDark;
  final VoidCallback onTap;

  const _NavIconButton({
    required this.icon,
    required this.accent,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_NavIconButton> createState() => _NavIconButtonState();
}

class _NavIconButtonState extends State<_NavIconButton> {
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
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: _hovered
                ? widget.accent.withOpacity(0.12)
                : Colors.transparent,
            border: _hovered
                ? Border.all(color: widget.accent.withOpacity(0.3), width: 1)
                : null,
          ),
          child: Center(
            child: Icon(
              widget.icon,
              size: 18,
              color: _hovered
                  ? widget.accent
                  : widget.isDark
                      ? Colors.white.withOpacity(0.6)
                      : Colors.black.withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }
}