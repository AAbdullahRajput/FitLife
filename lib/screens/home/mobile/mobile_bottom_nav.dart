import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';

class MobileBottomNav extends StatelessWidget {
  final int selectedTab;
  final bool isLoggedIn;
  final void Function(int index) onTabTap;

  const MobileBottomNav({
    super.key,
    required this.selectedTab,
    required this.isLoggedIn,
    required this.onTabTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final accent  = AppColors.of(context);

    final tabs = [
      {'icon': Icons.dashboard_rounded,      'label': 'Home'},
      {'icon': Icons.fitness_center_rounded, 'label': 'Workouts'},
      {'icon': Icons.restaurant_rounded,     'label': 'Diet'},
      {'icon': Icons.bar_chart_rounded,      'label': 'Progress'},
      {'icon': Icons.person_rounded,         'label': 'Profile'},
    ];

    return Consumer<ThemeProvider>(
      builder: (context, theme, _) {
        return Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withOpacity(0.85)
                : Colors.white.withOpacity(0.97),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? accent.withOpacity(0.12)
                    : const Color(0xFFE0E0E0),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? accent.withOpacity(0.07)
                    : Colors.black.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 62,
              child: Row(
                children: List.generate(tabs.length, (i) {
                  final isActive = selectedTab == i;
                  final isLocked = !isLoggedIn && i != 0;
                  final icon     = tabs[i]['icon']  as IconData;
                  final label    = tabs[i]['label'] as String;

                  return _NavTab(
                    icon: icon,
                    label: label,
                    isActive: isActive,
                    isLocked: isLocked,
                    accent: accent,
                    isDark: isDark,
                    theme: theme,
                    onTap: isLocked ? null : () => onTabTap(i),
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// INDIVIDUAL NAV TAB
// ═══════════════════════════════════════════════════════════════════════════
class _NavTab extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isLocked;
  final Color accent;
  final bool isDark;
  final ThemeProvider theme;
  final VoidCallback? onTap;

  const _NavTab({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.isLocked,
    required this.accent,
    required this.isDark,
    required this.theme,
    required this.onTap,
  });

  @override
  State<_NavTab> createState() => _NavTabState();
}

class _NavTabState extends State<_NavTab>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.85,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnim = _scaleController;
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.onTap != null) _scaleController.reverse();
  }

  void _onTapUp(TapUpDetails _) {
    _scaleController.forward();
    widget.onTap?.call();
  }

  void _onTapCancel() => _scaleController.forward();

  @override
  Widget build(BuildContext context) {
    final iconColor = widget.isActive
        ? widget.accent
        : widget.isLocked
            ? (widget.isDark
                ? Colors.white.withOpacity(0.18)
                : Colors.black.withOpacity(0.18))
            : (widget.isDark
                ? Colors.white.withOpacity(0.45)
                : Colors.black.withOpacity(0.45));

    final labelColor = widget.isActive
        ? widget.accent
        : widget.isLocked
            ? (widget.isDark
                ? Colors.white.withOpacity(0.18)
                : Colors.black.withOpacity(0.18))
            : (widget.isDark
                ? Colors.white.withOpacity(0.45)
                : Colors.black.withOpacity(0.45));

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedBuilder(
          animation: _scaleAnim,
          builder: (_, child) =>
              Transform.scale(scale: _scaleAnim.value, child: child),
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              // ── Top glow indicator bar ──────────────────────────────
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                height: 3,
                width: widget.isActive ? 28 : 0,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(4)),
                  gradient: widget.isActive
                      ? LinearGradient(colors: widget.theme.accentGradient)
                      : null,
                  boxShadow: widget.isActive
                      ? [
                          BoxShadow(
                            color: widget.accent.withOpacity(0.6),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              ),

              // ── Icon + label ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Active pill background with glow
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: widget.isActive
                            ? widget.accent.withOpacity(0.14)
                            : Colors.transparent,
                        boxShadow: widget.isActive
                            ? [
                                BoxShadow(
                                  color:
                                      widget.accent.withOpacity(0.18),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                        border: widget.isActive
                            ? Border.all(
                                color: widget.accent.withOpacity(0.25),
                                width: 1,
                              )
                            : null,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(widget.icon, size: 22, color: iconColor),
                          // Lock overlay badge
                          if (widget.isLocked)
                            Positioned(
                              right: -4,
                              top: -4,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: widget.isDark
                                      ? const Color(0xFF1A1A1A)
                                      : Colors.white,
                                  border: Border.all(
                                    color: widget.isDark
                                        ? const Color(0xFF2A2A2A)
                                        : const Color(0xFFE0E0E0),
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.lock_rounded,
                                    size: 7,
                                    color: widget.isDark
                                        ? Colors.white.withOpacity(0.25)
                                        : Colors.black.withOpacity(0.25),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Label
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: widget.isActive
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: labelColor,
                      ),
                      child: Text(widget.label),
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