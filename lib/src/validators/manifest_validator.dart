import 'dart:convert';
import 'dart:io';

import 'package:pub_semver/pub_semver.dart';

import '../core/exceptions.dart';
import '../models/ui_manifest.dart';

/// Validator for UI pack manifests.
class ManifestValidator {
  /// Required fields in manifest.
  static const requiredFields = [
    'id',
    'name',
    'version',
    'description',
    'author',
    'license',
    'flutter',
    'screens',
  ];

  /// Validate manifest file exists and parse it.
  static Future<UIManifest> validate(String manifestPath) async {
    final file = File(manifestPath);

    if (!await file.exists()) {
      throw const ManifestException(
        'Missing required file: ui_manifest.json',
        'Every UI pack must have a ui_manifest.json in its root directory.',
      );
    }

    final content = await file.readAsString();
    final Map<String, dynamic> json;

    try {
      json = jsonDecode(content) as Map<String, dynamic>;
    } catch (e) {
      throw ManifestException('Invalid JSON in ui_manifest.json', e.toString());
    }

    // Validate required fields
    final missingFields = <String>[];
    for (final field in requiredFields) {
      if (!json.containsKey(field) || json[field] == null) {
        missingFields.add(field);
      }
    }

    if (missingFields.isNotEmpty) {
      throw ValidationException(
        'Missing required fields in ui_manifest.json',
        errors: missingFields.map((f) => "Missing field: '$f'").toList(),
      );
    }

    // Validate id format (lowercase, underscores, no spaces)
    final id = json['id'] as String;
    if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(id)) {
      throw const ManifestException(
        'Invalid pack id format',
        "Pack id must be lowercase, start with a letter, and contain only letters, numbers, and underscores.",
      );
    }

    // Validate version format (semver)
    final version = json['version'] as String;
    try {
      Version.parse(version);
    } catch (e) {
      throw ManifestException(
        'Invalid version format: $version',
        'Version must follow semantic versioning (e.g., 1.0.0, 2.1.3-beta)',
      );
    }

    // Validate flutter version constraint
    final flutter = json['flutter'] as String;
    try {
      VersionConstraint.parse(flutter);
    } catch (e) {
      throw ManifestException(
        'Invalid flutter version constraint: $flutter',
        "Use semver constraint format (e.g., '>=3.10.0 <4.0.0')",
      );
    }

    // Validate screens array
    final screens = json['screens'] as List<dynamic>;
    if (screens.isEmpty) {
      throw const ManifestException(
        'Pack must have at least one screen',
        'Add screen entries to the "screens" array.',
      );
    }

    for (var i = 0; i < screens.length; i++) {
      final screen = screens[i] as Map<String, dynamic>;
      _validateScreen(screen, i);
    }

    // Validate dependencies format
    if (json.containsKey('dependencies')) {
      final deps = json['dependencies'] as Map<String, dynamic>;
      for (final entry in deps.entries) {
        try {
          VersionConstraint.parse(entry.value as String);
        } catch (e) {
          throw ManifestException(
            'Invalid dependency version: ${entry.key}: ${entry.value}',
            'Use semver constraint format (e.g., "^2.0.0", ">=1.0.0 <2.0.0")',
          );
        }
      }
    }

    // Validate license
    final license = json['license'] as String;
    if (!_validLicenses.contains(license.toUpperCase())) {
      throw ManifestException(
        'Unknown license: $license',
        'Use a recognized license identifier (MIT, Apache-2.0, BSD-3-Clause, etc.)',
      );
    }

    return UIManifest.fromJson(json);
  }

  static void _validateScreen(Map<String, dynamic> screen, int index) {
    final requiredScreenFields = ['name', 'route', 'file'];
    for (final field in requiredScreenFields) {
      if (!screen.containsKey(field) || screen[field] == null) {
        throw ManifestException(
          "Screen at index $index missing required field: '$field'",
          'Each screen must have name, route, and file fields.',
        );
      }
    }

    final route = screen['route'] as String;
    if (!route.startsWith('/')) {
      throw ManifestException(
        "Invalid route '${route}' for screen at index $index",
        'Routes must start with "/" (e.g., "/welcome")',
      );
    }

    final file = screen['file'] as String;
    if (!file.endsWith('.dart')) {
      throw ManifestException(
        "Invalid file path '$file' for screen at index $index",
        'Screen file must be a .dart file.',
      );
    }
  }

  static const _validLicenses = [
    'MIT',
    'APACHE-2.0',
    'BSD-2-CLAUSE',
    'BSD-3-CLAUSE',
    'GPL-2.0',
    'GPL-3.0',
    'LGPL-2.1',
    'LGPL-3.0',
    'MPL-2.0',
    'ISC',
    'UNLICENSE',
    'CC0-1.0',
  ];
}
