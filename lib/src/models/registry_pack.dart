import 'screen_info.dart';

/// Registry pack model representing a pack in the marketplace index.
class RegistryPack {
  /// Unique pack identifier.
  final String id;

  /// Human-readable pack name.
  final String name;

  /// Pack description.
  final String description;

  /// Latest version.
  final String version;

  /// Author name.
  final String author;

  /// Optional author URL.
  final String? authorUrl;

  /// License identifier.
  final String license;

  /// Searchable tags.
  final List<String> tags;

  /// Download count.
  final int downloads;

  /// Direct download URL for the zip bundle.
  final String downloadUrl;

  /// List of preview image URLs.
  final List<String> previews;

  /// List of screens in this pack.
  final List<ScreenInfo> screens;

  /// Flutter version constraint.
  final String flutter;

  /// External dependencies.
  final Map<String, String> dependencies;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Last update timestamp.
  final DateTime updatedAt;

  const RegistryPack({
    required this.id,
    required this.name,
    required this.description,
    required this.version,
    required this.author,
    this.authorUrl,
    required this.license,
    required this.tags,
    required this.downloads,
    required this.downloadUrl,
    required this.previews,
    required this.screens,
    required this.flutter,
    this.dependencies = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  factory RegistryPack.fromJson(Map<String, dynamic> json) {
    return RegistryPack(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      version: json['version'] as String,
      author: json['author'] as String,
      authorUrl: json['authorUrl'] as String?,
      license: json['license'] as String,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          [],
      downloads: json['downloads'] as int? ?? 0,
      downloadUrl: json['downloadUrl'] as String,
      previews:
          (json['previews'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      screens:
          (json['screens'] as List<dynamic>?)
              ?.map((e) => ScreenInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      flutter: json['flutter'] as String? ?? '>=3.0.0',
      dependencies:
          (json['dependencies'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as String),
          ) ??
          {},
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'version': version,
      'author': author,
      if (authorUrl != null) 'authorUrl': authorUrl,
      'license': license,
      'tags': tags,
      'downloads': downloads,
      'downloadUrl': downloadUrl,
      'previews': previews,
      'screens': screens.map((e) => e.toJson()).toList(),
      'flutter': flutter,
      'dependencies': dependencies,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() => 'RegistryPack(id: $id, name: $name, version: $version)';
}

/// Registry index model (index.json).
class RegistryIndex {
  /// Index schema version.
  final String version;

  /// Last update timestamp.
  final DateTime updated;

  /// Registry repository URL.
  final String registry;

  /// List of available packs.
  final List<RegistryPack> packs;

  const RegistryIndex({
    required this.version,
    required this.updated,
    required this.registry,
    required this.packs,
  });

  factory RegistryIndex.fromJson(Map<String, dynamic> json) {
    return RegistryIndex(
      version: json['version'] as String,
      updated: DateTime.parse(json['updated'] as String),
      registry: json['registry'] as String,
      packs: (json['packs'] as List<dynamic>)
          .map((e) => RegistryPack.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'updated': updated.toIso8601String(),
      'registry': registry,
      'packs': packs.map((e) => e.toJson()).toList(),
    };
  }
}
