import 'screen_info.dart';

/// UI Pack manifest model (ui_manifest.json).
///
/// Defines the structure and metadata for a UI pack.
class UIManifest {
  /// Unique pack identifier (e.g., 'onboarding_pack').
  final String id;

  /// Human-readable pack name.
  final String name;

  /// Semantic version (e.g., '1.0.0').
  final String version;

  /// Pack description.
  final String description;

  /// Author name.
  final String author;

  /// Optional author URL.
  final String? authorUrl;

  /// License identifier (e.g., 'MIT').
  final String license;

  /// Flutter version constraint (e.g., '>=3.10.0 <4.0.0').
  final String flutter;

  /// List of screens in this pack.
  final List<ScreenInfo> screens;

  /// External dependencies (package: version constraint).
  final Map<String, String> dependencies;

  /// Asset paths to include.
  final List<String> assets;

  /// Searchable tags.
  final List<String> tags;

  const UIManifest({
    required this.id,
    required this.name,
    required this.version,
    required this.description,
    required this.author,
    this.authorUrl,
    required this.license,
    required this.flutter,
    required this.screens,
    this.dependencies = const {},
    this.assets = const [],
    this.tags = const [],
  });

  factory UIManifest.fromJson(Map<String, dynamic> json) {
    return UIManifest(
      id: json['id'] as String,
      name: json['name'] as String,
      version: json['version'] as String,
      description: json['description'] as String,
      author: json['author'] as String,
      authorUrl: json['authorUrl'] as String?,
      license: json['license'] as String,
      flutter: json['flutter'] as String,
      screens: (json['screens'] as List<dynamic>)
          .map((e) => ScreenInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      dependencies: (json['dependencies'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as String),
          ) ??
          {},
      assets: (json['assets'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'version': version,
      'description': description,
      'author': author,
      if (authorUrl != null) 'authorUrl': authorUrl,
      'license': license,
      'flutter': flutter,
      'screens': screens.map((e) => e.toJson()).toList(),
      'dependencies': dependencies,
      'assets': assets,
      'tags': tags,
    };
  }

  @override
  String toString() => 'UIManifest(id: $id, name: $name, version: $version)';
}
