import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;

import 'exceptions.dart';
import 'logger.dart';

/// File manager for CLI operations.
class FileManager {
  final String projectPath;

  FileManager([String? projectPath])
    : projectPath = projectPath ?? Directory.current.path;

  /// Get absolute path from relative.
  String absolutePath(String relativePath) {
    return path.join(projectPath, relativePath);
  }

  /// Check if file exists.
  Future<bool> fileExists(String relativePath) async {
    return File(absolutePath(relativePath)).exists();
  }

  /// Check if directory exists.
  Future<bool> directoryExists(String relativePath) async {
    return Directory(absolutePath(relativePath)).exists();
  }

  /// Create directory recursively.
  Future<void> createDirectory(String relativePath) async {
    await Directory(absolutePath(relativePath)).create(recursive: true);
    Logger.debug('Created directory: $relativePath');
  }

  /// Read file content.
  Future<String> readFile(String relativePath) async {
    final file = File(absolutePath(relativePath));
    if (!await file.exists()) {
      throw FileOperationException("File not found: $relativePath");
    }
    return file.readAsString();
  }

  /// Write file content.
  Future<void> writeFile(String relativePath, String content) async {
    final file = File(absolutePath(relativePath));
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
    Logger.debug('Created file: $relativePath');
  }

  /// Copy file.
  Future<void> copyFile(String from, String to) async {
    final source = File(absolutePath(from));
    if (!await source.exists()) {
      throw FileOperationException("Source file not found: $from");
    }
    final target = File(absolutePath(to));
    await target.parent.create(recursive: true);
    await source.copy(target.path);
    Logger.debug('Copied: $from -> $to');
  }

  /// Copy directory recursively.
  Future<List<String>> copyDirectory(String from, String to) async {
    final source = Directory(absolutePath(from));
    if (!await source.exists()) {
      throw FileOperationException("Source directory not found: $from");
    }

    final copiedFiles = <String>[];
    await for (final entity in source.list(recursive: true)) {
      final relativePath = path.relative(entity.path, from: source.path);
      final targetPath = path.join(to, relativePath);

      if (entity is File) {
        final target = File(absolutePath(targetPath));
        await target.parent.create(recursive: true);
        await entity.copy(target.path);
        copiedFiles.add(targetPath);
        Logger.debug('Copied: $relativePath');
      }
    }

    return copiedFiles;
  }

  /// Delete file.
  Future<void> deleteFile(String relativePath) async {
    final file = File(absolutePath(relativePath));
    if (await file.exists()) {
      await file.delete();
      Logger.debug('Deleted file: $relativePath');
    }
  }

  /// Delete directory recursively.
  Future<void> deleteDirectory(String relativePath) async {
    final dir = Directory(absolutePath(relativePath));
    if (await dir.exists()) {
      await dir.delete(recursive: true);
      Logger.debug('Deleted directory: $relativePath');
    }
  }

  /// Delete files from a list.
  Future<void> deleteFiles(List<String> files) async {
    for (final file in files) {
      await deleteFile(file);
    }
  }

  /// List files in directory.
  Future<List<String>> listFiles(
    String relativePath, {
    bool recursive = false,
  }) async {
    final dir = Directory(absolutePath(relativePath));
    if (!await dir.exists()) {
      return [];
    }

    final files = <String>[];
    await for (final entity in dir.list(recursive: recursive)) {
      if (entity is File) {
        files.add(path.relative(entity.path, from: projectPath));
      }
    }
    return files;
  }

  /// Extract zip archive.
  Future<List<String>> extractZip(List<int> bytes, String targetDir) async {
    final archive = ZipDecoder().decodeBytes(bytes);
    final extractedFiles = <String>[];

    for (final file in archive) {
      final filePath = path.join(targetDir, file.name);
      if (file.isFile) {
        final target = File(absolutePath(filePath));
        await target.parent.create(recursive: true);
        await target.writeAsBytes(file.content as List<int>);
        extractedFiles.add(filePath);
        Logger.debug('Extracted: ${file.name}');
      }
    }

    return extractedFiles;
  }

  /// Create zip archive.
  Future<List<int>> createZip(String sourceDir) async {
    final archive = Archive();
    final source = Directory(absolutePath(sourceDir));

    await for (final entity in source.list(recursive: true)) {
      if (entity is File) {
        final relativePath = path.relative(entity.path, from: source.path);
        final bytes = await entity.readAsBytes();
        archive.addFile(ArchiveFile(relativePath, bytes.length, bytes));
        Logger.debug('Added to zip: $relativePath');
      }
    }

    return ZipEncoder().encode(archive)!;
  }

  /// Check if project is a Flutter project.
  Future<bool> isFlutterProject() async {
    if (!await fileExists('pubspec.yaml')) {
      return false;
    }
    final content = await readFile('pubspec.yaml');
    return content.contains('flutter:');
  }

  /// Get pubspec.yaml content.
  Future<String> getPubspec() async {
    return readFile('pubspec.yaml');
  }

  /// Update pubspec.yaml content.
  Future<void> updatePubspec(String content) async {
    await writeFile('pubspec.yaml', content);
  }
}
