import 'package:args/command_runner.dart';

import '../core/logger.dart';
import '../generator/route_generator.dart';
import '../models/config.dart';

/// Rebuild routes from installed packs.
class BuildCommand extends Command<int> {
  @override
  String get name => 'build';

  @override
  String get description => 'Rebuild routes from installed UI packs';

  BuildCommand() {
    argParser.addFlag(
      'verbose',
      abbr: 'v',
      help: 'Show detailed output',
      negatable: false,
    );
  }

  @override
  Future<int> run() async {
    final verbose = argResults!['verbose'] as bool;
    if (verbose) Logger.verbose = true;

    // Load config
    final config = await UIMarketConfig.load();
    if (config == null) {
      Logger.error('ui_market not initialized');
      Logger.info("Run 'dart run ui_market init' first.");
      return 1;
    }

    try {
      Logger.info('Rebuilding routes...');

      if (config.installedPacks.isEmpty) {
        Logger.warning('No packs installed. Routes file will be empty.');
      } else {
        Logger.info('Found ${config.installedPacks.length} installed pack(s):');
        for (final pack in config.installedPacks.values) {
          Logger.info(
            '  • ${pack.id} v${pack.version} (${pack.files.length} files)',
          );
        }
      }

      await RouteGenerator.generate(config);

      Logger.newLine();
      Logger.info('Routes file: ${config.routesFile}');

      return 0;
    } catch (e) {
      Logger.error('Build failed: $e');
      return 1;
    }
  }
}
