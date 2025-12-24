/// Screen information model for UI packs.
class ScreenInfo {
  /// Screen display name.
  final String name;

  /// Route path for the screen.
  final String route;

  /// Relative file path within the pack.
  final String file;

  /// Optional description.
  final String? description;

  const ScreenInfo({
    required this.name,
    required this.route,
    required this.file,
    this.description,
  });

  factory ScreenInfo.fromJson(Map<String, dynamic> json) {
    return ScreenInfo(
      name: json['name'] as String,
      route: json['route'] as String,
      file: json['file'] as String,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'route': route,
      'file': file,
      if (description != null) 'description': description,
    };
  }

  @override
  String toString() => 'ScreenInfo(name: $name, route: $route, file: $file)';
}
