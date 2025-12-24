import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as path;
import 'package:yaml_edit/yaml_edit.dart';
import '../core/file_manager.dart';
import '../core/logger.dart';
import '../generator/route_generator.dart';
import '../models/config.dart';
import '../registry/github_release_client.dart';
import '../registry/registry_client.dart';
import '../validators/code_validator.dart';

/// Install a UI pack from the marketplace.
class AddCommand extends Command<int> {
  @override
  String get name => 'add';

  @override
  String get description => 'Install a UI pack from the marketplace';

  @override
  String get invocation => '${runner!.executableName} $name <pack_id>';

  AddCommand() {
    argParser.addOption(
      'version',
      abbr: 'v',
      help: 'Specific version to install',
    );
    argParser.addFlag(
      'skip-validation',
      help: 'Skip code validation (not recommended)',
      negatable: false,
    );
    argParser.addFlag(
      'dry-run',
      help: 'Show what would be installed without making changes',
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
    final skipValidation = argResults!['skip-validation'] as bool;
    final dryRun = argResults!['dry-run'] as bool;

    // Load config
    final config = await UIMarketConfig.load();
    if (config == null) {
      Logger.error('ui_market not initialized');
      Logger.info("Run 'dart run ui_market init' first.");
      return 1;
    }

    // Check if already installed
    if (config.hasPack(packId)) {
      final installed = config.getPack(packId)!;
      Logger.warning(
        "Pack '$packId' is already installed (v${installed.version}).",
      );
      final reinstall = await Logger.confirm('Reinstall?');
      if (!reinstall) return 0;
    }

    final registryClient = RegistryClient(registryUrl: config.registry);
    final releaseClient = GitHubReleaseClient();
    final fileManager = FileManager();

    try {
      Logger.header('Installing $packId');

      // Step 1: Fetch pack metadata
      Logger.step(1, 'Fetching pack metadata...');
      final pack = await registryClient.getPackOrThrow(packId);
      Logger.info('  Found: ${pack.name} v${pack.version}');
      Logger.info('  Author: ${pack.author}');
      Logger.info('  License: ${pack.license}');

      if (dryRun) {
        Logger.newLine();
        Logger.info('Dry run - no changes made.');
        _printWouldInstall(pack, config);
        return 0;
      }

      // Step 2: Download bundle
      Logger.step(2, 'Downloading bundle...');
      final zipPath = await releaseClient.downloadToTemp(pack);
      Logger.debug('Downloaded to: $zipPath');

      // Step 3: Extract to temp
      Logger.step(3, 'Extracting files...');
      final zipBytes = await File(zipPath).readAsBytes();
      final tempDir =
          '${Directory.systemTemp.path}/ui_market_extract_${pack.id}';
      await fileManager.createDirectory(tempDir);
      final extractedFiles = await fileManager.extractZip(zipBytes, tempDir);
      Logger.debug('Extracted ${extractedFiles.length} files');

      // Step 4: Validate code (unless skipped)
      if (!skipValidation) {
        Logger.step(4, 'Validating code...');
        await CodeValidator.validateOrThrow(tempDir);
        Logger.success('Code validation passed');
      } else {
        Logger.step(4, 'Skipping validation (--skip-validation)');
        Logger.warning(
          'Skipping validation is not recommended for security reasons.',
        );
      }

      // Step 5: Copy files to project
      Logger.step(5, 'Installing files...');
      final packDir = '${config.outputDir}/${pack.id}';
      final installedFiles = await _copyPackFiles(
        fileManager,
        tempDir,
        packDir,
      );
      Logger.info('  Installed ${installedFiles.length} files to $packDir/');

      // Step 6: Update pubspec.yaml dependencies
      Logger.step(6, 'Updating dependencies...');
      if (pack.dependencies.isNotEmpty) {
        await _updatePubspec(fileManager, pack.dependencies);
        Logger.info('  Added ${pack.dependencies.length} dependencies');
      } else {
        Logger.info('  No additional dependencies required');
      }

      // Step 7: Update config
      Logger.step(7, 'Updating configuration...');
      final installedPack = InstalledPack(
        id: pack.id,
        version: pack.version,
        files: installedFiles,
        installedAt: DateTime.now(),
      );
      final updatedConfig = config.addPack(installedPack);
      await updatedConfig.save();

      // Step 8: Generate routes
      Logger.step(8, 'Generating routes...');
      await RouteGenerator.generateFromScreens(
        pack.screens,
        pack.id,
        updatedConfig,
      );

      // Step 9: Run flutter pub get
      Logger.step(9, 'Running flutter pub get...');
      final result = await Process.run('flutter', ['pub', 'get']);
      if (result.exitCode != 0) {
        Logger.warning('flutter pub get had issues: ${result.stderr}');
      }

      // Cleanup temp files
      await Directory(tempDir).delete(recursive: true);
      await File(zipPath).delete();

      Logger.newLine();
      Logger.success("Successfully installed '${pack.name}' v${pack.version}!");
      Logger.newLine();
      Logger.info('Installed screens:');
      for (final screen in pack.screens) {
        Logger.info('  • ${screen.name} → ${screen.route}');
      }
      Logger.newLine();
      Logger.info('Usage in your app:');
      Logger.info(
        "  import 'package:your_app/${config.routesFile.replaceFirst('lib/', '')}';",
      );
      Logger.info('  // Use UIRoutes.routes in your MaterialApp');
      Logger.newLine();

      return 0;
    } catch (e) {
      Logger.error('Installation failed: $e');
      return 1;
    } finally {
      registryClient.dispose();
      releaseClient.dispose();
    }
  }

  Future<List<String>> _copyPackFiles(
    FileManager fm,
    String from,
    String to,
  ) async {
    final installedFiles = <String>[];
    final sourceDir = Directory(from);

    await for (final entity in sourceDir.list(recursive: true)) {
      if (entity is File) {
        final relativePath = path.relative(entity.path, from: from);
        final targetPath = '$to/$relativePath';

        // Skip manifest and previews
        if (relativePath == 'ui_manifest.json' ||
            relativePath.startsWith('previews/')) {
          continue;
        }

        final targetFile = File(fm.absolutePath(targetPath));
        await targetFile.parent.create(recursive: true);
        await entity.copy(targetFile.path);
        installedFiles.add(targetPath);
      }
    }

    return installedFiles;
  }

  Future<void> _updatePubspec(
    FileManager fm,
    Map<String, String> dependencies,
  ) async {
    final content = await fm.getPubspec();
    final editor = YamlEditor(content);

    for (final entry in dependencies.entries) {
      // Check if dependency already exists
      try {
        final existing = editor.parseAt(['dependencies', entry.key]);
        if (existing.value != null) {
          Logger.debug('Dependency ${entry.key} already exists, skipping');
          continue;
        }
      } catch (_) {
        // Dependency doesn't exist, add it
      }

      editor.update(['dependencies', entry.key], entry.value);
    }

    await fm.updatePubspec(editor.toString());
  }

  void _printWouldInstall(dynamic pack, UIMarketConfig config) {
    Logger.info('Would install:');
    Logger.info('  Pack: ${pack.id} v${pack.version}');
    Logger.info('  Destination: ${config.outputDir}/${pack.id}/');
    Logger.info('  Screens:');
    for (final screen in pack.screens) {
      Logger.info('    • ${screen.name} → ${screen.route}');
    }
    if (pack.dependencies.isNotEmpty) {
      Logger.info('  Dependencies:');
      for (final dep in pack.dependencies.entries) {
        Logger.info('    • ${dep.key}: ${dep.value}');
      }
    }
  }
}
