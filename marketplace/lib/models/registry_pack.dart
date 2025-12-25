import 'studio/visual_widget.dart';

class RegistryPack {
  final String id;
  final String name;
  final String description;
  final String version;
  final String author;
  final String? authorUrl;
  final String license;
  final String? homepage;
  final List<String> tags;
  final int downloads;
  final String downloadUrl;
  final List<String> previews;
  final List<ScreenInfo> screens;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RegistryPack({
    required this.id,
    required this.name,
    required this.description,
    required this.version,
    required this.author,
    this.authorUrl,
    required this.license,
    this.homepage,
    required this.tags,
    required this.downloads,
    required this.downloadUrl,
    required this.previews,
    required this.screens,
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
      homepage: json['homepage'] as String?,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              [],
      downloads: json['downloads'] as int? ?? 0,
      downloadUrl: json['downloadUrl'] as String,
      previews: (json['previews'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      screens: (json['screens'] as List<dynamic>?)
              ?.map((e) => ScreenInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

class ScreenInfo {
  final String name;
  final String route;
  final String file;
  final List<VisualWidget> widgets;

  const ScreenInfo({
    required this.name,
    required this.route,
    required this.file,
    required this.widgets,
  });

  factory ScreenInfo.fromJson(Map<String, dynamic> json) {
    return ScreenInfo(
      name: json['name'] as String,
      route: json['route'] as String,
      file: json['file'] as String,
      widgets: (json['widgets'] as List<dynamic>?)
              ?.map((e) => VisualWidget.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
