import 'package:flutter/material.dart';

/// Page indicator component for onboarding screens.
///
/// Shows dots for each page with the current page highlighted.
class PageIndicator extends StatelessWidget {
  /// Total number of pages.
  final int pageCount;

  /// Current page index (0-based).
  final int currentPage;

  /// Color for the active indicator.
  final Color? activeColor;

  /// Color for inactive indicators.
  final Color? inactiveColor;

  /// Size of each indicator dot.
  final double dotSize;

  /// Width of the active indicator.
  final double activeDotWidth;

  /// Spacing between dots.
  final double spacing;

  const PageIndicator({
    super.key,
    required this.pageCount,
    required this.currentPage,
    this.activeColor,
    this.inactiveColor,
    this.dotSize = 8,
    this.activeDotWidth = 24,
    this.spacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = activeColor ?? theme.colorScheme.primary;
    final inactive =
        inactiveColor ?? theme.colorScheme.primary.withOpacity(0.3);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(pageCount, (index) {
        final isActive = index == currentPage;
        return Container(
          margin: EdgeInsets.symmetric(horizontal: spacing / 2),
          width: isActive ? activeDotWidth : dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            color: isActive ? active : inactive,
            borderRadius: BorderRadius.circular(dotSize / 2),
          ),
        );
      }),
    );
  }
}
