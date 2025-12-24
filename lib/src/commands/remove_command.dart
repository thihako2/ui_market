import 'package:args/command_runner.dart';

import '../core/file_manager.dart';
import '../core/logger.dart';
import '../generator/route_generator.dart';
import '../models/config.dart';

/// Remove an installed UI pack.
class RemoveCommand extends Command<int> {
  @override
  String get name => 'remove';

  @override
  String get description => 'Remove an installed UI pack';

  @override
  String get invocation => '${runner!.executableName} $name <pack_id>';

  RemoveCommand() {
    argParser.addFlag(
      'keep-files',
      help: 'Keep the installed files but remove from tracking',
      negatable: false,
    );
    argParser.addFlag(
      'force',
      abbr: 'f',
      help: 'Skip confirmation prompt',
      negatable: false,
    );
  }

  @override
  Future<int> run() async {
    if (argResults!.rest.isEmpty) {
      Logger.error('Please specify a pack ID');
      Logger.info(usage);
      return 1;
    }

    final packId = argResults!.rest.first;
    final keepFiles = argResults!['keep-files'] as bool;
    final force = argResults!['force'] as bool;

    // Load config
    final config = await UIMarketConfig.load();
    if (config == null) {
      Logger.error('ui_market not initialized');
      Logger.info("Run 'dart run ui_market init' first.");
      return 1;
    }

    // Check if pack is installed
    if (!config.hasPack(packId)) {
      Logger.error("Pack '$packId' is not installed.");
      Logger.info('Installed packs:');
      if (config.installedPacks.isEmpty) {
        Logger.info('  (none)');
      } else {
        for (final pack in config.installedPacks.values) {
          Logger.info('  • ${pack.id} v${pack.version}');
        }
      }
      return 1;
    }

    final pack = config.getPack(packId)!;

    // Confirm removal
    if (!force) {
      Logger.warning("This will remove '${pack.id}' v${pack.version}");
      Logger.info('Files to be removed:');
      for (final file in pack.files.take(5)) {
        Logger.info('  • $file');
      }
      if (pack.files.length > 5) {
        Logger.info('  ... and ${pack.files.length - 5} more files');
      }

      final confirm = await Logger.confirm('Continue?');
      if (!confirm) {
        Logger.info('Aborted.');
        return 0;
      }
    }

    final fileManager = FileManager();

    try {
      Logger.header('Removing $packId');

      // Step 1: Remove files
      if (!keepFiles) {
        Logger.step(1, 'Removing files...');
        var removedCount = 0;
        for (final file in pack.files) {
          if (await fileManager.fileExists(file)) {
            await fileManager.deleteFile(file);
            removedCount++;
          }
        }
        Logger.info('  Removed $removedCount files');

        // Remove pack directory if empty
        final packDir = '${config.outputDir}/${pack.id}';
        if (await fileManager.directoryExists(packDir)) {
          final remaining = await fileManager.listFiles(
            packDir,
            recursive: true,
          );
          if (remaining.isEmpty) {
            await fileManager.deleteDirectory(packDir);
            Logger.debug('Removed empty pack directory');
          }
        }
      } else {
        Logger.step(1, 'Keeping files (--keep-files)');
      }

      // Step 2: Remove dependencies (TODO: only if not used by other packs)
      Logger.step(2, 'Checking dependencies...');
      Logger.info('  Dependencies preserved (may be used by other packs)');

      // Step 3: Update config
      Logger.step(3, 'Updating configuration...');
      final updatedConfig = config.removePack(packId);
      await updatedConfig.save();

      // Step 4: Regenerate routes
      Logger.step(4, 'Regenerating routes...');
      await RouteGenerator.generate(updatedConfig);

      Logger.newLine();
      Logger.success("Successfully removed '${pack.id}'!");
      Logger.newLine();

      if (updatedConfig.installedPacks.isNotEmpty) {
        Logger.info('Remaining installed packs:');
        for (final p in updatedConfig.installedPacks.values) {
          Logger.info('  • ${p.id} v${p.version}');
        }
      } else {
        Logger.info('No packs installed.');
      }

      return 0;
    } catch (e) {
      Logger.error('Removal failed: $e');
      return 1;
    }
  }
}
