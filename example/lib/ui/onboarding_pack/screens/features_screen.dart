import 'package:flutter/material.dart';

/// Features screen showing app highlights.
///
/// Displays a horizontal page view of feature cards.
/// Customize by modifying the features list.
class FeaturesScreen extends StatelessWidget {
  /// Callback when user wants to proceed.
  final VoidCallback? onNext;

  /// Callback when user wants to go back.
  final VoidCallback? onBack;

  /// Callback when user wants to skip.
  final VoidCallback? onSkip;

  /// Current page index for the page indicator.
  final int currentPage;

  /// Callback when page changes.
  final ValueChanged<int>? onPageChanged;

  const FeaturesScreen({
    super.key,
    this.onNext,
    this.onBack,
    this.onSkip,
    this.currentPage = 0,
    this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header with skip button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_ios),
                  ),
                  TextButton(
                    onPressed: onSkip,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Feature cards
            Expanded(
              child: PageView.builder(
                onPageChanged: onPageChanged,
                itemCount: _features.length,
                itemBuilder: (context, index) {
                  return _FeatureCard(feature: _features[index]);
                },
              ),
            ),

            // Page indicator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _features.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: currentPage == index
                          ? theme.colorScheme.primary
                          : theme.colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
            ),

            // Next button
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(
                    currentPage == _features.length - 1 ? 'Continue' : 'Next',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final _Feature feature;

  const _FeatureCard({required this.feature});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              feature.icon,
              size: 60,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 48),
          Text(
            feature.title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            feature.description,
            style: TextStyle(
              fontSize: 16,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Feature {
  final IconData icon;
  final String title;
  final String description;

  const _Feature({
    required this.icon,
    required this.title,
    required this.description,
  });
}

const _features = [
  _Feature(
    icon: Icons.speed_rounded,
    title: 'Lightning Fast',
    description:
        'Experience blazing fast performance with our optimized architecture.',
  ),
  _Feature(
    icon: Icons.security_rounded,
    title: 'Secure & Private',
    description:
        'Your data is protected with end-to-end encryption and privacy controls.',
  ),
  _Feature(
    icon: Icons.palette_rounded,
    title: 'Beautiful Design',
    description:
        'Modern, clean interface designed for the best user experience.',
  ),
];
