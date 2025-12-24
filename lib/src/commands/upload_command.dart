import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;

import '../core/exceptions.dart';
import '../core/file_manager.dart';
import '../core/logger.dart';
import '../core/token_manager.dart';
import '../models/config.dart';
import '../models/ui_manifest.dart';
import '../registry/github_release_client.dart';
import '../validators/bundle_validator.dart';
import '../validators/code_validator.dart';
import '../validators/dependency_validator.dart';
import '../validators/manifest_validator.dart';

/// Upload a UI pack to the marketplace.
class UploadCommand extends Command<int> {
  @override
  String get name => 'upload';

  @override
  String get description => 'Upload a UI pack to the marketplace';

  @override
  String get invocation => '${runner!.executableName} $name [path]';

  UploadCommand() {
    argParser.addFlag(
      'pr',
      help: 'Create a pull request instead of direct publish',
      negatable: false,
    );
    argParser.addFlag(
      'dry-run',
      help: 'Validate only, do not upload',
      negatable: false,
    );

    argParser.addFlag(
      'skip-format',
      help: 'Skip dart format check',
      negatable: false,
    );
    argParser.addOption(
      'token',
      help: 'GitHub token (or use GITHUB_TOKEN env var)',
    );
    argParser.addOption(
      'registry',
      abbr: 'r',
      help: 'Target GitHub repository URL for the registry',
    );
  }

  @override
  Future<int> run() async {
    final packPath = argResults!.rest.isNotEmpty
        ? argResults!.rest.first
        : Directory.current.path;

    final usePR = argResults!['pr'] as bool;
    final dryRun = argResults!['dry-run'] as bool;
    final skipFormat = argResults!['skip-format'] as bool;
    final tokenArg = argResults!['token'] as String?;
    final registryArg = argResults!['registry'] as String?;

    var token = tokenArg ?? Platform.environment['GITHUB_TOKEN'];

    if (!dryRun && token == null) {
      // Try to load from stored token
      token = await TokenManager.loadToken();
    }

    // Use default shared token if no custom token is provided
    if (!dryRun && token == null) {
      token = TokenManager.defaultToken;
      Logger.info('Using shared community token for upload.');
    }

    try {
      Logger.header('Validating UI Pack');

      // Step 1: Validate manifest
      Logger.step(1, 'Validating manifest...');
      final manifestPath = path.join(packPath, 'ui_manifest.json');
      final manifest = await ManifestValidator.validate(manifestPath);
      Logger.success('Manifest valid: ${manifest.name} v${manifest.version}');

      // Step 2: Validate bundle structure
      Logger.step(2, 'Validating bundle structure...');
      await BundleValidator.validate(packPath, manifest);
      Logger.success('Bundle structure valid');

      // Step 3: Validate code (AST)
      Logger.step(3, 'Validating code (AST analysis)...');
      await CodeValidator.validateOrThrow(packPath);
      Logger.success('Code validation passed');

      // Step 4: Check dependencies
      Logger.step(4, 'Checking dependencies...');
      DependencyValidator.checkProhibitedDependencies(manifest);
      Logger.success('Dependencies valid');

      // Step 5: Check dart format
      if (!skipFormat) {
        Logger.step(5, 'Checking dart format...');
        final formatResult = await _checkDartFormat(packPath);
        if (!formatResult) {
          throw ValidationException(
            'dart format check failed',
            errors: ["Run 'dart format .' to fix formatting issues."],
          );
        }
        Logger.success('dart format check passed');
      } else {
        Logger.step(5, 'Skipping dart format (--skip-format)');
      }

      // Get preview images
      final previews = await BundleValidator.getPreviewImages(packPath);
      Logger.info('  Found ${previews.length} preview image(s)');

      if (dryRun) {
        Logger.newLine();
        Logger.success('Validation passed! Pack is ready for upload.');
        _printPackSummary(manifest, previews);
        Logger.info('\nRun without --dry-run to upload.');
        return 0;
      }

      // Step 6: Create zip bundle
      Logger.step(6, 'Creating bundle...');
      final fileManager = FileManager();
      final zipBytes = await fileManager.createZip(packPath);
      Logger.info(
        '  Bundle size: ${(zipBytes.length / 1024).toStringAsFixed(1)} KB',
      );

      // Step 7: Upload to GitHub
      if (usePR) {
        Logger.step(7, 'Creating pull request...');
        await _createPullRequest(manifest, zipBytes, previews, token!);
      } else {
        Logger.step(7, 'Creating GitHub release...');
        await _createRelease(manifest, zipBytes, previews, token!, registryArg);
      }

      Logger.newLine();
      Logger.success(
        'Successfully uploaded ${manifest.name} v${manifest.version}!',
      );
      Logger.newLine();

      if (usePR) {
        Logger.info('A pull request has been created.');
        Logger.info('Once merged, your pack will appear in the marketplace.');
      } else {
        Logger.info(
          'Your pack should appear in the marketplace within 5 minutes.',
        );
      }

      return 0;
    } on ValidationException catch (e) {
      Logger.newLine();
      Logger.error(e.message);
      for (final error in e.errors) {
        Logger.error('  $error');
      }
      return 1;
    } on DuplicateVersionException catch (e) {
      Logger.newLine();
      Logger.error(e.message);
      Logger.info(e.details ?? '');
      return 1;
    } catch (e) {
      Logger.error('Upload failed: $e');
      return 1;
    }
  }

  Future<bool> _checkDartFormat(String packPath) async {
    final result = await Process.run('dart', [
      'format',
      '--set-exit-if-changed',
      '--output=none',
      packPath,
    ]);

    if (result.exitCode != 0) {
      Logger.error('Files need formatting:');
      Logger.error(result.stdout.toString());
      return false;
    }

    return true;
  }

  Future<void> _createRelease(
    UIManifest manifest,
    List<int> zipBytes,
    List<String> previews,
    String token, [
    String? registryUrl,
  ]) async {
    final config = await UIMarketConfig.load() ?? UIMarketConfig.defaultConfig;
    final targetRegistry = registryUrl ?? config.registry;
    final repoInfo = GitHubReleaseClient.parseRepoUrl(targetRegistry);

    if (repoInfo == null) {
      throw const UploadException(
        'Invalid registry URL',
        'Registry URL must be a GitHub repository.',
      );
    }

    final client = http.Client();

    try {
      // Check if version already exists
      final tagName = '${manifest.id}-${manifest.version}';

      // Create release
      final createResponse = await client.post(
        Uri.parse('${repoInfo.apiUrl}/releases'),
        headers: {
          'Authorization': 'token $token',
          'Accept': 'application/vnd.github.v3+json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'tag_name': tagName,
          'name': '${manifest.name} v${manifest.version}',
          'body': _generateReleaseNotes(manifest),
          'draft': false,
          'prerelease': false,
        }),
      );

      if (createResponse.statusCode == 422) {
        throw DuplicateVersionException(
          packId: manifest.id,
          version: manifest.version,
        );
      }

      if (createResponse.statusCode != 201) {
        throw UploadException(
          'Failed to create release',
          'Status: ${createResponse.statusCode}\n${createResponse.body}',
        );
      }

      final releaseData =
          jsonDecode(createResponse.body) as Map<String, dynamic>;
      final uploadUrl = (releaseData['upload_url'] as String).replaceAll(
        '{?name,label}',
        '',
      );

      // Upload zip bundle
      Logger.debug('Uploading bundle...');
      final bundleResponse = await client.post(
        Uri.parse('$uploadUrl?name=bundle.zip'),
        headers: {
          'Authorization': 'token $token',
          'Content-Type': 'application/zip',
        },
        body: zipBytes,
      );

      if (bundleResponse.statusCode != 201) {
        throw UploadException(
          'Failed to upload bundle',
          'Status: ${bundleResponse.statusCode}',
        );
      }

      // Upload preview images
      for (var i = 0; i < previews.length; i++) {
        final preview = previews[i];
        final previewBytes = await File(preview).readAsBytes();
        final previewName = 'preview_${i + 1}${path.extension(preview)}';

        Logger.debug('Uploading $previewName...');
        await client.post(
          Uri.parse('$uploadUrl?name=$previewName'),
          headers: {
            'Authorization': 'token $token',
            'Content-Type': 'image/${path.extension(preview).substring(1)}',
          },
          body: previewBytes,
        );
      }
    } finally {
      client.close();
    }
  }

  Future<void> _createPullRequest(
    UIManifest manifest,
    List<int> zipBytes,
    List<String> previews,
    String token,
  ) async {
    // For PR-based flow, we would:
    // 1. Fork the registry repo (if not already)
    // 2. Create a branch
    // 3. Add pack files
    // 4. Create PR

    // This is a simplified implementation
    Logger.warning('PR-based upload is not fully implemented yet.');
    Logger.info('Please create a PR manually:');
    Logger.info('  1. Fork the registry repository');
    Logger.info('  2. Add your pack to packs/${manifest.id}/');
    Logger.info('  3. Create a pull request');

    throw const UploadException(
      'PR-based upload not fully implemented',
      'Use direct upload (without --pr) or create PR manually.',
    );
  }

  String _generateReleaseNotes(UIManifest manifest) {
    final buffer = StringBuffer();
    buffer.writeln('## ${manifest.name}');
    buffer.writeln();
    buffer.writeln(manifest.description);
    buffer.writeln();
    buffer.writeln('### Screens');
    for (final screen in manifest.screens) {
      buffer.writeln('- **${screen.name}** (`${screen.route}`)');
    }
    if (manifest.dependencies.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('### Dependencies');
      for (final dep in manifest.dependencies.entries) {
        buffer.writeln('- `${dep.key}: ${dep.value}`');
      }
    }
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln('*Published via ui_market CLI*');
    return buffer.toString();
  }

  void _printPackSummary(UIManifest manifest, List<String> previews) {
    Logger.newLine();
    Logger.header('Pack Summary');
    Logger.keyValue('ID', manifest.id);
    Logger.keyValue('Name', manifest.name);
    Logger.keyValue('Version', manifest.version);
    Logger.keyValue('Author', manifest.author);
    Logger.keyValue('License', manifest.license);
    Logger.keyValue('Flutter', manifest.flutter);
    Logger.keyValue('Screens', manifest.screens.length.toString());
    Logger.keyValue('Previews', previews.length.toString());
    if (manifest.dependencies.isNotEmpty) {
      Logger.keyValue('Dependencies', manifest.dependencies.length.toString());
    }
    if (manifest.tags.isNotEmpty) {
      Logger.keyValue('Tags', manifest.tags.join(', '));
    }
  }
}
