import 'package:args/command_runner.dart';

import '../core/file_manager.dart';
import '../core/logger.dart';
import '../models/config.dart';

/// Initialize a Flutter project for ui_market.
class InitCommand extends Command<int> {
  @override
  String get name => 'init';

  @override
  String get description => 'Initialize ui_market in a Flutter project';

  InitCommand() {
    argParser.addOption(
      'registry',
      abbr: 'r',
      help: 'Custom registry URL',
      defaultsTo: UIMarketConfig.defaultConfig.registry,
    );
    argParser.addOption(
      'output-dir',
      abbr: 'o',
      help: 'Output directory for UI files',
      defaultsTo: UIMarketConfig.defaultConfig.outputDir,
    );
  }

  @override
  Future<int> run() async {
    final fileManager = FileManager();

    // Check if this is a Flutter project
    if (!await fileManager.isFlutterProject()) {
      Logger.error('Not a Flutter project');
      Logger.info(
        'Run this command from a Flutter project root (directory containing pubspec.yaml with flutter dependency).',
      );
      return 1;
    }

    // Check if already initialized
    if (await fileManager.fileExists(UIMarketConfig.fileName)) {
      Logger.warning('ui_market is already initialized in this project.');
      final overwrite = await Logger.confirm('Reinitialize?');
      if (!overwrite) {
        return 0;
      }
    }

    Logger.header('Initializing ui_market');

    final registry = argResults!['registry'] as String;
    final outputDir = argResults!['output-dir'] as String;

    try {
      // Create directory structure
      Logger.step(1, 'Creating directory structure...');
      await _createDirectories(fileManager, outputDir);

      // Create config file
      Logger.step(2, 'Creating configuration file...');
      final config = UIMarketConfig(registry: registry, outputDir: outputDir);
      await config.save();

      // Create empty routes file
      Logger.step(3, 'Creating routes file...');
      await _createRoutesFile(fileManager, config.routesFile);

      // Create .gitkeep files
      Logger.step(4, 'Finalizing...');
      await _createGitkeepFiles(fileManager, outputDir);

      Logger.newLine();
      Logger.success('ui_market initialized successfully!');
      Logger.newLine();
      Logger.info('Created structure:');
      Logger.info('  $outputDir/');
      Logger.info('  ├── screens/');
      Logger.info('  ├── components/');
      Logger.info('  ├── theme/');
      Logger.info('  └── generated/');
      Logger.info('       └── ui_routes.g.dart');
      Logger.info('  ${UIMarketConfig.fileName}');
      Logger.newLine();
      Logger.info('Next steps:');
      Logger.info(
        "  1. Run 'dart run ui_market search <keyword>' to find UI packs",
      );
      Logger.info(
        "  2. Run 'dart run ui_market add <pack_id>' to install a pack",
      );
      Logger.newLine();

      return 0;
    } catch (e) {
      Logger.error('Initialization failed: $e');
      return 1;
    }
  }

  Future<void> _createDirectories(FileManager fm, String outputDir) async {
    await fm.createDirectory('$outputDir/screens');
    await fm.createDirectory('$outputDir/components');
    await fm.createDirectory('$outputDir/theme');
    await fm.createDirectory('$outputDir/generated');
  }

  Future<void> _createRoutesFile(FileManager fm, String routesFile) async {
    const content = '''
// GENERATED CODE - DO NOT MODIFY BY HAND
// ui_market route generator
// Run 'dart run ui_market build' to regenerate

import 'package:flutter/material.dart';

/// Generated UI routes from installed packs.
class UIRoutes {
  UIRoutes._();

  /// All UI routes mapped to their widgets.
  static Map<String, WidgetBuilder> get routes => {};

  /// Route generator for Navigator.
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final builder = routes[settings.name];
    if (builder != null) {
      return MaterialPageRoute(
        builder: builder,
        settings: settings,
      );
    }
    return null;
  }

  /// Routes grouped by pack ID.
  static Map<String, List<String>> get routesByPack => {};
}
''';
    await fm.writeFile(routesFile, content);
  }

  Future<void> _createGitkeepFiles(FileManager fm, String outputDir) async {
    const gitkeep = '# Placeholder file for git\n';
    await fm.writeFile('$outputDir/screens/.gitkeep', gitkeep);
    await fm.writeFile('$outputDir/components/.gitkeep', gitkeep);
    await fm.writeFile('$outputDir/theme/.gitkeep', gitkeep);
  }
}
