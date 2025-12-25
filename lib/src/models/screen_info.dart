import 'visual_widget.dart';

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

  /// Visual widgets for preview.
  final List<VisualWidget> widgets;

  const ScreenInfo({
    required this.name,
    required this.route,
    required this.file,
    this.description,
    this.widgets = const [],
  });

  factory ScreenInfo.fromJson(Map<String, dynamic> json) {
    return ScreenInfo(
      name: json['name'] as String,
      route: json['route'] as String,
      file: json['file'] as String,
      description: json['description'] as String?,
      widgets: (json['widgets'] as List<dynamic>?)
              ?.map((e) => VisualWidget.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'route': route,
      'file': file,
      if (description != null) 'description': description,
      'widgets': widgets.map((e) => e.toJson()).toList(),
    };
  }

  ScreenInfo copyWith({
    String? name,
    String? route,
    String? file,
    String? description,
    List<VisualWidget>? widgets,
  }) {
    return ScreenInfo(
      name: name ?? this.name,
      route: route ?? this.route,
      file: file ?? this.file,
      description: description ?? this.description,
      widgets: widgets ?? this.widgets,
    );
  }

  @override
  String toString() => 'ScreenInfo(name: $name, route: $route, file: $file)';
}
