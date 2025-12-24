// GENERATED CODE - DO NOT MODIFY BY HAND
// ui_market route generator
// Generated at: 2025-12-25T02:59:11.662847

import 'package:flutter/material.dart';
import 'package:ui_market_example/ui/onboarding_pack/screens/features_screen.dart';
import 'package:ui_market_example/ui/onboarding_pack/screens/get_started_screen.dart';
import 'package:ui_market_example/ui/onboarding_pack/screens/welcome_screen.dart';

/// Generated UI routes from installed packs.
class UIRoutes {
  UIRoutes._();

  // Route constants
  static const String features = '/features';
  static const String welcome = '/welcome';
  static const String getStarted = '/get-started';

  /// All UI routes mapped to their widgets.
  static Map<String, WidgetBuilder> get routes => {
        features: (context) => const FeaturesScreen(),
        welcome: (context) => const WelcomeScreen(),
        getStarted: (context) => const GetStartedScreen(),
      };

  /// Route generator for Navigator.
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final builder = routes[settings.name];
    if (builder != null) {
      return MaterialPageRoute(builder: builder, settings: settings);
    }
    return null;
  }

  /// Routes grouped by pack ID.
  static Map<String, List<String>> get routesByPack => {
        'onboarding_pack': [
          '/features',
          '/welcome',
          '/get-started',
          '/welcome',
          '/features',
          '/get-started',
        ],
      };
}
