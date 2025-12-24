import 'dart:io';

import 'package:path/path.dart' as path;

import '../core/logger.dart';
import '../models/config.dart';
import '../models/screen_info.dart';

/// Route code generator for installed UI packs.
class RouteGenerator {
  /// Generate routes file from installed packs.
  static Future<void> generate(
    UIMarketConfig config, [
    String? projectPath,
  ]) async {
    final basePath = projectPath ?? Directory.current.path;
    final screens = <_RouteEntry>[];

    // Collect screens from all installed packs
    for (final pack in config.installedPacks.values) {
      // We need to read the manifest from each pack
      // For now, we'll generate based on file names
      for (final file in pack.files) {
        if (file.contains('/screens/') && file.endsWith('.dart')) {
          final className = _fileToClassName(file);
          final route = _fileToRoute(file);
          screens.add(
            _RouteEntry(
              className: className,
              route: route,
              file: file,
              packId: pack.id,
            ),
          );
        }
      }
    }

    // Generate code
    final code = _generateCode(screens, config.outputDir);

    // Write to file
    final routesPath = path.join(basePath, config.routesFile);
    final routesFile = File(routesPath);
    await routesFile.parent.create(recursive: true);
    await routesFile.writeAsString(code);

    Logger.success(
      'Generated ${screens.length} routes in ${config.routesFile}',
    );
  }

  /// Generate routes from manifest screens.
  static Future<void> generateFromScreens(
    List<ScreenInfo> screens,
    String packId,
    UIMarketConfig config, [
    String? projectPath,
  ]) async {
    final basePath = projectPath ?? Directory.current.path;

    // Collect all screens from all packs
    final allScreens = <_RouteEntry>[];

    // Add existing pack screens
    for (final pack in config.installedPacks.values) {
      for (final file in pack.files) {
        if (file.contains('/screens/') && file.endsWith('.dart')) {
          final className = _fileToClassName(file);
          final route = _fileToRoute(file);
          allScreens.add(
            _RouteEntry(
              className: className,
              route: route,
              file: file,
              packId: pack.id,
            ),
          );
        }
      }
    }

    // Add new pack screens
    for (final screen in screens) {
      final file = '${config.outputDir}/${packId}/${screen.file}';
      allScreens.add(
        _RouteEntry(
          className: screen.name,
          route: screen.route,
          file: file,
          packId: packId,
        ),
      );
    }

    // Generate code
    final code = _generateCode(allScreens, config.outputDir);

    // Write to file
    final routesPath = path.join(basePath, config.routesFile);
    final routesFile = File(routesPath);
    await routesFile.parent.create(recursive: true);
    await routesFile.writeAsString(code);

    Logger.success(
      'Generated ${allScreens.length} routes in ${config.routesFile}',
    );
  }

  static String _generateCode(List<_RouteEntry> screens, String outputDir) {
    final buffer = StringBuffer();

    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln('// ui_market route generator');
    buffer.writeln('// Generated at: ${DateTime.now().toIso8601String()}');
    buffer.writeln();
    buffer.writeln("import 'package:flutter/material.dart';");
    buffer.writeln();

    // Generate imports
    for (final screen in screens) {
      final importPath = _getImportPath(screen.file, outputDir);
      buffer.writeln("import '$importPath';");
    }

    buffer.writeln();
    buffer.writeln('/// Generated UI routes from installed packs.');
    buffer.writeln('class UIRoutes {');
    buffer.writeln('  UIRoutes._();');
    buffer.writeln();

    // Generate route constants
    buffer.writeln('  // Route constants');
    for (final screen in screens) {
      final constName = _routeToConstName(screen.route);
      buffer.writeln("  static const String $constName = '${screen.route}';");
    }

    buffer.writeln();

    // Generate routes map
    buffer.writeln('  /// All UI routes mapped to their widgets.');
    buffer.writeln('  static Map<String, WidgetBuilder> get routes => {');
    for (final screen in screens) {
      final constName = _routeToConstName(screen.route);
      buffer.writeln(
        '    $constName: (context) => const ${screen.className}(),',
      );
    }
    buffer.writeln('  };');

    buffer.writeln();

    // Generate onGenerateRoute
    buffer.writeln('  /// Route generator for Navigator.');
    buffer.writeln(
      '  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {',
    );
    buffer.writeln('    final builder = routes[settings.name];');
    buffer.writeln('    if (builder != null) {');
    buffer.writeln('      return MaterialPageRoute(');
    buffer.writeln('        builder: builder,');
    buffer.writeln('        settings: settings,');
    buffer.writeln('      );');
    buffer.writeln('    }');
    buffer.writeln('    return null;');
    buffer.writeln('  }');

    buffer.writeln();

    // Generate route list by pack
    buffer.writeln('  /// Routes grouped by pack ID.');
    buffer.writeln('  static Map<String, List<String>> get routesByPack => {');
    final packRoutes = <String, List<String>>{};
    for (final screen in screens) {
      packRoutes.putIfAbsent(screen.packId, () => []).add(screen.route);
    }
    for (final entry in packRoutes.entries) {
      buffer.writeln("    '${entry.key}': [");
      for (final route in entry.value) {
        buffer.writeln("      '$route',");
      }
      buffer.writeln('    ],');
    }
    buffer.writeln('  };');

    buffer.writeln('}');

    return buffer.toString();
  }

  static String _fileToClassName(String file) {
    final baseName = path.basenameWithoutExtension(file);
    // Convert snake_case to PascalCase
    return baseName
        .split('_')
        .map(
          (word) => word.isEmpty
              ? ''
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join();
  }

  static String _fileToRoute(String file) {
    final baseName = path.basenameWithoutExtension(file);
    // Convert snake_case to kebab-case route
    final routeName = baseName.replaceAll('_screen', '').replaceAll('_', '-');
    return '/$routeName';
  }

  static String _routeToConstName(String route) {
    // Convert /welcome-screen to welcomeScreen
    final name = route
        .substring(1) // Remove leading /
        .split('-')
        .asMap()
        .entries
        .map(
          (e) => e.key == 0
              ? e.value.toLowerCase()
              : '${e.value[0].toUpperCase()}${e.value.substring(1)}',
        )
        .join();
    return name;
  }

  static String _getImportPath(String file, String outputDir) {
    // Convert lib/ui/pack_id/screens/file.dart to relative import
    final parts = file.split('/');
    final fromLib = parts.skipWhile((p) => p != 'lib').skip(1).join('/');
    return '../${fromLib.replaceFirst('ui/generated/', '')}';
  }
}

class _RouteEntry {
  final String className;
  final String route;
  final String file;
  final String packId;

  _RouteEntry({
    required this.className,
    required this.route,
    required this.file,
    required this.packId,
  });
}
