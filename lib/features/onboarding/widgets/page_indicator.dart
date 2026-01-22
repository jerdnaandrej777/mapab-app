import 'package:flutter/material.dart';

/// Animierter Page-Indicator für das Onboarding
/// Zeigt die aktuelle Seite als länglichen Balken, inaktive als Punkte
class PageIndicator extends StatelessWidget {
  final int currentPage;
  final int pageCount;
  final Color activeColor;
  final Color inactiveColor;

  const PageIndicator({
    super.key,
    required this.currentPage,
    required this.pageCount,
    this.activeColor = const Color(0xFF3B82F6),
    this.inactiveColor = const Color(0xFF475569),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (index) {
        final isActive = index == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 28 : 10,
          height: 10,
          decoration: BoxDecoration(
            color: isActive ? activeColor : inactiveColor.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(5),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}
