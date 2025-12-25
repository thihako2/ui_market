import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:path/path.dart' as path;

import '../models/visual_widget.dart';

/// Compiles Dart code into VisualWidget IR.
class WidgetCompiler {
  static Future<List<VisualWidget>> compile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return [];

    try {
      final content = await file.readAsString();
      final result = parseString(content: content, path: filePath);

      final visitor = _WidgetVisitor();
      result.unit.visitChildren(visitor);

      // Post-process to ensure layout
      return _generateLayout(visitor.widgets);
    } catch (e) {
      print('Widget compilation failed for $filePath: $e');
      return [];
    }
  }

  static List<VisualWidget> _generateLayout(List<VisualWidget> widgets) {
    // Simple vertical stack heuristic
    double currentY = 20; // Start below status bar

    for (var widget in widgets) {
      widget.y = currentY;

      // Auto-center horizontally
      widget.x = (375 - widget.width) / 2;

      // Advance Y
      currentY += widget.height + 16;
    }

    return widgets;
  }
}

class _WidgetVisitor extends RecursiveAstVisitor<void> {
  final List<VisualWidget> widgets = [];
  int _counter = 0;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final typeName = node.constructorName.type.name2.lexeme;

    if (_isInterestWidget(typeName)) {
      final widget = _extractWidget(node, typeName);
      if (widget != null) {
        widgets.add(widget);
      }
    }

    super.visitInstanceCreationExpression(node);
  }

  bool _isInterestWidget(String typeName) {
    const interest = {
      'Text',
      'ElevatedButton',
      'FilledButton',
      'OutlinedButton',
      'TextButton',
      'Image',
      'Icon',
      'Card',
      'Container',
      'ListTile',
      'FloatingActionButton',
      'AppBar'
    };
    return interest.contains(typeName);
  }

  VisualWidget? _extractWidget(
      InstanceCreationExpression node, String typeName) {
    final type = _mapType(typeName);
    if (type == null) return null;

    final id = 'w_${_counter++}';
    final props = <String, dynamic>{};

    // Extract common properties based on arguments
    for (final arg in node.argumentList.arguments) {
      if (arg is NamedExpression) {
        final name = arg.name.label.name;
        final value = _extractValue(arg.expression);
        if (value != null) {
          props[name] = value;
        }
      } else if (arg is SimpleStringLiteral) {
        // Positional string (often text)
        if (typeName == 'Text') {
          props['text'] = arg.value;
        }
      }
    }

    // Special handling for Text widget positional argument
    if (typeName == 'Text' &&
        !props.containsKey('text') &&
        node.argumentList.arguments.isNotEmpty) {
      final first = node.argumentList.arguments.first;
      final val = _extractValue(first);
      if (val != null) props['text'] = val;
    }

    // Defaults
    double width = 300;
    double height = 50;

    if (typeName == 'Text') {
      width = 320;
      height = 40; // rough estimate
    } else if (typeName == 'Icon') {
      width = 40;
      height = 40;
    }

    return VisualWidget(
      id: id,
      name: typeName,
      type: type,
      width: width,
      height: height,
      properties: props,
    );
  }

  VisualWidgetType? _mapType(String typeName) {
    switch (typeName) {
      case 'Text':
        return VisualWidgetType.text;
      case 'ElevatedButton':
      case 'FilledButton':
      case 'OutlinedButton':
      case 'TextButton':
        return VisualWidgetType.button;
      case 'Image':
        return VisualWidgetType.image;
      case 'Icon':
        return VisualWidgetType.icon;
      case 'Card':
        return VisualWidgetType.card;
      case 'Container':
        return VisualWidgetType.container;
      case 'ListTile':
        return VisualWidgetType.listTile;
      case 'FloatingActionButton':
        return VisualWidgetType.floatingActionButton;
      case 'AppBar':
        return VisualWidgetType.appBar;
      default:
        return null;
    }
  }

  dynamic _extractValue(Expression expr) {
    if (expr is SimpleStringLiteral) return expr.value;
    if (expr is IntegerLiteral) return expr.value;
    if (expr is DoubleLiteral) return expr.value;
    if (expr is BooleanLiteral) return expr.value;

    // Simple constant access like Colors.red or Icons.add
    if (expr is PrefixedIdentifier) {
      if (expr.prefix.name == 'Icons') {
        return expr.identifier.name; // "add"
      }
      // Colors are hard to resolve without context, maybe return null or string
    }

    return null;
  }
}
