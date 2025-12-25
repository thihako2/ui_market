enum VisualWidgetType {
  // Basic
  container,
  text,
  icon,
  image,
  button,

  // Layout
  column,
  row,
  stack,
  padding,
  center,

  // Material
  card,
  listTile,
  appBar,
  floatingActionButton,
  bottomNavigationBar,
  divider,
  chip,
  slider,
  checkbox,
  materialSwitch,

  // Cupertino
  cupertinoButton,
  cupertinoNavigationBar,
  cupertinoSlider,
  cupertinoSwitch,
}

class VisualWidget {
  final String id;
  String name;
  final VisualWidgetType type;

  // Layout
  double x;
  double y;
  double width;
  double height;

  // Properties (color, text, fontSize, borderRadius, padding, etc.)
  Map<String, dynamic> properties;

  VisualWidget({
    required this.id,
    required this.name,
    required this.type,
    this.x = 0,
    this.y = 0,
    this.width = 100,
    this.height = 100,
    Map<String, dynamic>? properties,
  }) : properties = properties ?? {};

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.index,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'properties': properties,
    };
  }

  factory VisualWidget.fromJson(Map<String, dynamic> json) {
    return VisualWidget(
      id: json['id'],
      name: json['name'],
      type: VisualWidgetType.values[json['type']],
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      properties: json['properties'] as Map<String, dynamic>,
    );
  }
}
