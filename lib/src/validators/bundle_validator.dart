import 'dart:io';

import 'package:path/path.dart' as path;

import '../core/exceptions.dart';
import '../models/ui_manifest.dart';

/// Validator for UI pack bundle structure.
class BundleValidator {
  /// Required directories in a pack.
  static const requiredDirs = ['screens'];

  /// Optional but recommended directories.
  static const optionalDirs = ['components', 'theme', 'assets', 'previews'];

  /// Validate pack directory structure.
  static Future<void> validate(String packPath, UIManifest manifest) async {
    final dir = Directory(packPath);

    if (!await dir.exists()) {
      throw FileOperationException("Pack directory not found: $packPath");
    }

    final errors = <String>[];

    // Check required directories
    for (final requiredDir in requiredDirs) {
      final dirPath = path.join(packPath, requiredDir);
      if (!await Directory(dirPath).exists()) {
        errors.add("Missing required directory: $requiredDir/");
      }
    }

    // Check screen files exist
    for (final screen in manifest.screens) {
      final screenPath = path.join(packPath, screen.file);
      if (!await File(screenPath).exists()) {
        errors.add(
          "Missing screen file: ${screen.file} (referenced in manifest)",
        );
      }
    }

    // Check asset directories exist
    for (final asset in manifest.assets) {
      final assetPath = path.join(packPath, asset);
      final isDir = asset.endsWith('/');

      if (isDir) {
        if (!await Directory(assetPath).exists()) {
          errors.add("Missing asset directory: $asset");
        }
      } else {
        if (!await File(assetPath).exists()) {
          errors.add("Missing asset file: $asset");
        }
      }
    }

    // Check preview images exist
    final previewsDir = Directory(path.join(packPath, 'previews'));
    if (await previewsDir.exists()) {
      final previews = await previewsDir
          .list()
          .where((e) => e is File)
          .map((e) => e.path)
          .toList();

      if (previews.isEmpty) {
        errors.add("previews/ directory exists but contains no images");
      }

      // Validate preview images are valid formats
      for (final preview in previews) {
        final ext = path.extension(preview).toLowerCase();
        if (!['.png', '.jpg', '.jpeg', '.webp', '.gif'].contains(ext)) {
          errors.add(
            "Invalid preview image format: ${path.basename(preview)} "
            "(use .png, .jpg, .webp, or .gif)",
          );
        }
      }
    }

    // Validate no prohibited files
    await _checkProhibitedFiles(packPath, errors);

    if (errors.isNotEmpty) {
      throw ValidationException(
        'Bundle structure validation failed',
        errors: errors,
      );
    }
  }

  static Future<void> _checkProhibitedFiles(
    String packPath,
    List<String> errors,
  ) async {
    final prohibitedPatterns = [
      '.git',
      '.gitignore',
      '.DS_Store',
      'pubspec.yaml',
      'pubspec.lock',
      '.dart_tool',
      'build',
      '.idea',
      '.vscode',
    ];

    final dir = Directory(packPath);
    await for (final entity in dir.list()) {
      final name = path.basename(entity.path);
      if (prohibitedPatterns.contains(name)) {
        errors.add(
          "Prohibited file/directory found: $name (remove before upload)",
        );
      }
    }
  }

  /// Get list of preview images.
  static Future<List<String>> getPreviewImages(String packPath) async {
    final previewsDir = Directory(path.join(packPath, 'previews'));
    if (!await previewsDir.exists()) {
      return [];
    }

    final previews = <String>[];
    await for (final entity in previewsDir.list()) {
      if (entity is File) {
        final ext = path.extension(entity.path).toLowerCase();
        if (['.png', '.jpg', '.jpeg', '.webp', '.gif'].contains(ext)) {
          previews.add(entity.path);
        }
      }
    }

    // Sort by name for consistent ordering
    previews.sort();
    return previews;
  }

  /// Get all Dart files in pack.
  static Future<List<String>> getDartFiles(String packPath) async {
    final dartFiles = <String>[];
    final dir = Directory(packPath);

    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        dartFiles.add(entity.path);
      }
    }

    return dartFiles;
  }
}
