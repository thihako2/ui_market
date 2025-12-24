import 'dart:io';

import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

import '../core/exceptions.dart';
import '../core/logger.dart';
import '../models/ui_manifest.dart';

/// Validator for UI pack dependencies.
class DependencyValidator {
  /// Validate Flutter version compatibility.
  static Future<void> validateFlutterVersion(
    UIManifest manifest, [
    String? projectPath,
  ]) async {
    final path = projectPath ?? Directory.current.path;
    final pubspecFile = File('$path/pubspec.yaml');

    if (!await pubspecFile.exists()) {
      throw const ConfigException(
        'pubspec.yaml not found',
        'Run this command from a Flutter project root.',
      );
    }

    // Get current Flutter version from pubspec
    final content = await pubspecFile.readAsString();
    final yaml = loadYaml(content) as Map;
    final environment = yaml['environment'] as Map?;
    final sdkConstraint = environment?['sdk'] as String?;

    if (sdkConstraint == null) {
      Logger.warning('No SDK constraint found in pubspec.yaml');
      return;
    }

    // Parse pack's Flutter requirement to validate format
    VersionConstraint.parse(manifest.flutter);

    // Note: We can't easily get the actual Flutter version without running
    // flutter --version, so we'll just log the requirement
    Logger.debug('Pack requires Flutter: ${manifest.flutter}');
    Logger.debug('Project SDK constraint: $sdkConstraint');
  }

  /// Validate dependency compatibility with current project.
  static Future<DependencyReport> validateDependencies(
    UIManifest manifest, [
    String? projectPath,
  ]) async {
    final path = projectPath ?? Directory.current.path;
    final pubspecFile = File('$path/pubspec.yaml');

    if (!await pubspecFile.exists()) {
      throw const ConfigException(
        'pubspec.yaml not found',
        'Run this command from a Flutter project root.',
      );
    }

    final content = await pubspecFile.readAsString();
    final yaml = loadYaml(content) as Map;
    final projectDeps = yaml['dependencies'] as Map? ?? {};

    final report = DependencyReport();

    for (final entry in manifest.dependencies.entries) {
      final depName = entry.key;
      final requiredVersion = entry.value;

      if (projectDeps.containsKey(depName)) {
        // Dependency exists in project
        final projectVersion = projectDeps[depName];
        if (projectVersion is String) {
          // Check for compatibility
          if (!_areVersionsCompatible(requiredVersion, projectVersion)) {
            report.conflicts.add(
              DependencyConflict(
                name: depName,
                required: requiredVersion,
                current: projectVersion,
              ),
            );
          } else {
            report.existing.add(depName);
          }
        } else {
          // Complex dependency (git, path, etc.)
          report.existing.add(depName);
        }
      } else {
        // New dependency to add
        report.toAdd[depName] = requiredVersion;
      }
    }

    return report;
  }

  /// Check if two version constraints are compatible.
  static bool _areVersionsCompatible(String required, String current) {
    try {
      final requiredConstraint = VersionConstraint.parse(required);
      final currentConstraint = VersionConstraint.parse(current);

      // Simple check: if either allows all of the other, they're compatible
      // This is a simplified check - in reality you'd want intersection
      return requiredConstraint.allowsAll(currentConstraint) ||
          currentConstraint.allowsAll(requiredConstraint) ||
          required == current;
    } catch (e) {
      // If parsing fails, assume compatible and let pub handle it
      return true;
    }
  }

  /// Check for prohibited dependencies.
  static void checkProhibitedDependencies(UIManifest manifest) {
    const prohibitedDeps = [
      // State management
      'provider',
      'bloc',
      'flutter_bloc',
      'riverpod',
      'flutter_riverpod',
      'get',
      'getx',
      'mobx',
      'flutter_mobx',
      'redux',
      'flutter_redux',
      'signals',

      // Networking
      'http',
      'dio',
      'chopper',
      'retrofit',
      'graphql',
      'graphql_flutter',

      // Storage
      'sqflite',
      'hive',
      'hive_flutter',
      'isar',
      'drift',
      'moor',
      'shared_preferences',
    ];

    final violations = <String>[];
    for (final dep in manifest.dependencies.keys) {
      if (prohibitedDeps.contains(dep)) {
        violations.add(dep);
      }
    }

    if (violations.isNotEmpty) {
      throw ValidationException(
        'Pack contains prohibited dependencies',
        errors: violations
            .map((d) => "'$d' is not allowed in UI packs (stateless UI only)")
            .toList(),
      );
    }
  }

  /// Generate pubspec additions for new dependencies.
  static String generateDependencyAdditions(Map<String, String> dependencies) {
    if (dependencies.isEmpty) return '';

    final buffer = StringBuffer();
    for (final entry in dependencies.entries) {
      buffer.writeln('  ${entry.key}: ${entry.value}');
    }
    return buffer.toString();
  }
}

/// Report of dependency validation.
class DependencyReport {
  /// Dependencies that already exist in project.
  final List<String> existing = [];

  /// Dependencies that need to be added.
  final Map<String, String> toAdd = {};

  /// Dependency version conflicts.
  final List<DependencyConflict> conflicts = [];

  bool get hasConflicts => conflicts.isNotEmpty;
  bool get hasNewDependencies => toAdd.isNotEmpty;
}

/// Dependency conflict record.
class DependencyConflict {
  final String name;
  final String required;
  final String current;

  DependencyConflict({
    required this.name,
    required this.required,
    required this.current,
  });

  @override
  String toString() =>
      "Conflict: '$name' requires $required but project uses $current";
}
