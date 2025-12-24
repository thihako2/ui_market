import 'package:flutter/material.dart';

/// Onboarding theme configuration.
///
/// Provides consistent styling for onboarding screens.
class OnboardingTheme {
  /// Primary gradient colors.
  static const List<Color> gradientColors = [
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
  ];

  /// Get gradient decoration.
  static BoxDecoration get gradientDecoration => const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: gradientColors,
    ),
  );

  /// Button style for primary actions.
  static ButtonStyle primaryButtonStyle(BuildContext context) {
    final theme = Theme.of(context);
    return ElevatedButton.styleFrom(
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      minimumSize: const Size(double.infinity, 56),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    );
  }

  /// Button style for secondary actions.
  static ButtonStyle secondaryButtonStyle(BuildContext context) {
    final theme = Theme.of(context);
    return OutlinedButton.styleFrom(
      foregroundColor: theme.colorScheme.primary,
      minimumSize: const Size(double.infinity, 56),
      side: BorderSide(color: theme.colorScheme.primary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    );
  }

  /// Title text style.
  static TextStyle titleStyle(BuildContext context) {
    final theme = Theme.of(context);
    return TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: theme.colorScheme.onSurface,
    );
  }

  /// Subtitle text style.
  static TextStyle subtitleStyle(BuildContext context) {
    final theme = Theme.of(context);
    return TextStyle(
      fontSize: 16,
      color: theme.colorScheme.onSurface.withOpacity(0.7),
      height: 1.5,
    );
  }
}
