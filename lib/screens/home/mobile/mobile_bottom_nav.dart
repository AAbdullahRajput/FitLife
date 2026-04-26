import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppColors.of(context);
    final bgColor = isDark ? const Color(0xFF141414) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);

    final tabs = [
      {'icon': Icons.dashboard_rounded, 'label': 'Home'},
      {'icon': Icons.fitness_center_rounded, 'label': 'Workouts'},
      {'icon': Icons.restaurant_rounded, 'label': 'Diet'},
      {'icon': Icons.bar_chart_rounded, 'label': 'Progress'},
      {'icon': Icons.person_rounded, 'label': 'Profile'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: borderColor, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(tabs.length, (i) {
              final isActive = selectedTab == i;
              final isLocked = !isLoggedIn && i != 0;
              final icon = tabs[i]['icon'] as IconData;
              final label = tabs[i]['label'] as String;

              return Expanded(
                child: GestureDetector(
                  onTap: isLocked ? null : () => onTabTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: isActive
                              ? accent.withOpacity(0.15)
                              : Colors.transparent,
                        ),
                        child: Icon(
                          icon,
                          size: 22,
                          color: isActive
                              ? accent
                              : isLocked
                                  ? (isDark
                                      ? Colors.white.withOpacity(0.2)
                                      : Colors.black.withOpacity(0.2))
                                  : (isDark
                                      ? Colors.white.withOpacity(0.45)
                                      : Colors.black.withOpacity(0.45)),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: isActive
                              ? accent
                              : isLocked
                                  ? (isDark
                                      ? Colors.white.withOpacity(0.2)
                                      : Colors.black.withOpacity(0.2))
                                  : (isDark
                                      ? Colors.white.withOpacity(0.45)
                                      : Colors.black.withOpacity(0.45)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}