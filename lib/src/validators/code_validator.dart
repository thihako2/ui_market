import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../core/exceptions.dart';
import '../core/logger.dart';

/// AST-based code validator for UI packs.
///
/// Enforces strict rules:
/// - StatelessWidget only (no StatefulWidget)
/// - No setState calls
/// - No state management libraries
/// - No networking libraries
/// - No dart:io or dangerous imports
/// - Only relative or package:flutter imports
class CodeValidator {
  /// Prohibited widget base classes.
  static const prohibitedClasses = ['StatefulWidget', 'State'];

  /// Prohibited method calls.
  static const prohibitedMethods = ['setState'];

  /// Prohibited imports (patterns).
  static const prohibitedImportPatterns = [
    // State management
    'package:provider/',
    'package:bloc/',
    'package:flutter_bloc/',
    'package:riverpod/',
    'package:flutter_riverpod/',
    'package:get/',
    'package:getx/',
    'package:mobx/',
    'package:flutter_mobx/',
    'package:redux/',
    'package:flutter_redux/',
    'package:signals/',

    // Networking
    'package:http/',
    'package:dio/',
    'package:socket_io/',
    'package:web_socket/',
    'package:graphql/',
    'package:chopper/',
    'package:retrofit/',

    // Storage / Database
    'package:sqflite/',
    'package:hive/',
    'package:isar/',
    'package:drift/',
    'package:moor/',
    'package:shared_preferences/',
    'package:path_provider/',

    // Platform channels
    'package:flutter/services.dart',

    // Dangerous dart imports
    'dart:io',
    'dart:ffi',
    'dart:isolate',
    'dart:mirrors',
    'dart:developer',
  ];

  /// Allowed import prefixes.
  static const allowedImportPrefixes = [
    'package:flutter/',
    'package:flutter_svg/',
    'package:google_fonts/',
    'package:cached_network_image/',
    'package:lottie/',
    'package:shimmer/',
    'dart:math',
    'dart:async',
    'dart:collection',
    'dart:convert',
    'dart:core',
    'dart:typed_data',
    'dart:ui',
  ];

  /// Validate a single Dart file.
  static Future<List<CodeViolation>> validateFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return [
        CodeViolation(
          file: filePath,
          message: 'File not found',
          severity: ViolationSeverity.error,
        ),
      ];
    }

    final content = await file.readAsString();
    return validateCode(content, filePath);
  }

  /// Validate Dart code content.
  static List<CodeViolation> validateCode(String code, String fileName) {
    final violations = <CodeViolation>[];

    try {
      final result = parseString(content: code, throwIfDiagnostics: false);
      final unit = result.unit;

      // Check for parse errors
      for (final error in result.errors) {
        violations.add(
          CodeViolation(
            file: fileName,
            line: error.offset,
            message: 'Parse error: ${error.message}',
            severity: ViolationSeverity.error,
          ),
        );
      }

      // Run AST visitor
      final visitor = _CodeValidatorVisitor(fileName);
      unit.visitChildren(visitor);
      violations.addAll(visitor.violations);
    } catch (e) {
      violations.add(
        CodeViolation(
          file: fileName,
          message: 'Failed to parse: $e',
          severity: ViolationSeverity.error,
        ),
      );
    }

    return violations;
  }

  /// Validate all Dart files in a pack.
  static Future<List<CodeViolation>> validatePack(String packPath) async {
    final violations = <CodeViolation>[];
    final dir = Directory(packPath);

    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        Logger.debug('Validating: ${entity.path}');
        final fileViolations = await validateFile(entity.path);
        violations.addAll(fileViolations);
      }
    }

    return violations;
  }

  /// Check if code is valid (no violations).
  static Future<bool> isValid(String packPath) async {
    final violations = await validatePack(packPath);
    return violations
        .where((v) => v.severity == ViolationSeverity.error)
        .isEmpty;
  }

  /// Throw exception if validation fails.
  static Future<void> validateOrThrow(String packPath) async {
    final violations = await validatePack(packPath);
    final errors =
        violations.where((v) => v.severity == ViolationSeverity.error).toList();

    if (errors.isNotEmpty) {
      throw ValidationException(
        'Code validation failed with ${errors.length} error(s)',
        errors: errors.map((v) => v.toString()).toList(),
      );
    }

    // Log warnings
    final warnings = violations.where(
      (v) => v.severity == ViolationSeverity.warning,
    );
    for (final warning in warnings) {
      Logger.warning(warning.toString());
    }
  }
}

/// Code violation record.
class CodeViolation {
  final String file;
  final int? line;
  final String message;
  final ViolationSeverity severity;

  const CodeViolation({
    required this.file,
    this.line,
    required this.message,
    required this.severity,
  });

  @override
  String toString() {
    final location = line != null ? ':$line' : '';
    final prefix = severity == ViolationSeverity.error ? '✗' : '⚠';
    return '$prefix $file$location: $message';
  }
}

enum ViolationSeverity { error, warning }

/// AST visitor for code validation.
class _CodeValidatorVisitor extends RecursiveAstVisitor<void> {
  final String fileName;
  final List<CodeViolation> violations = [];

  _CodeValidatorVisitor(this.fileName);

  @override
  void visitImportDirective(ImportDirective node) {
    final uri = node.uri.stringValue ?? '';

    // Check prohibited imports
    for (final pattern in CodeValidator.prohibitedImportPatterns) {
      if (uri.startsWith(pattern) || uri == pattern) {
        violations.add(
          CodeViolation(
            file: fileName,
            line: node.offset,
            message:
                "Prohibited import: '$uri'. UI packs must not use $pattern",
            severity: ViolationSeverity.error,
          ),
        );
        return;
      }
    }

    // Check if import is allowed (relative or approved packages)
    if (!uri.startsWith('.') && !uri.startsWith('package:flutter/')) {
      bool isAllowed = false;
      for (final prefix in CodeValidator.allowedImportPrefixes) {
        if (uri.startsWith(prefix) || uri == prefix) {
          isAllowed = true;
          break;
        }
      }

      if (!isAllowed && !uri.startsWith('.')) {
        violations.add(
          CodeViolation(
            file: fileName,
            line: node.offset,
            message: "External package import: '$uri'. "
                "Consider if this dependency is necessary.",
            severity: ViolationSeverity.warning,
          ),
        );
      }
    }

    super.visitImportDirective(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final extendsClause = node.extendsClause;
    if (extendsClause != null) {
      final superclass = extendsClause.superclass.name2.lexeme;

      // Check for StatefulWidget
      if (superclass == 'StatefulWidget') {
        violations.add(
          CodeViolation(
            file: fileName,
            line: node.offset,
            message: "Class '${node.name.lexeme}' extends StatefulWidget. "
                "UI packs must use StatelessWidget only.",
            severity: ViolationSeverity.error,
          ),
        );
      }

      // Check for State<T>
      if (superclass == 'State') {
        violations.add(
          CodeViolation(
            file: fileName,
            line: node.offset,
            message: "Class '${node.name.lexeme}' extends State. "
                "UI packs must not contain stateful logic.",
            severity: ViolationSeverity.error,
          ),
        );
      }
    }

    super.visitClassDeclaration(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final methodName = node.methodName.name;

    // Check for setState
    if (methodName == 'setState') {
      violations.add(
        CodeViolation(
          file: fileName,
          line: node.offset,
          message: "setState() is not allowed in UI packs. "
              "Use StatelessWidget and pass callbacks for state changes.",
          severity: ViolationSeverity.error,
        ),
      );
    }

    super.visitMethodInvocation(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final typeName = node.constructorName.type.name2.lexeme;

    // Check for prohibited widget instantiation
    if (CodeValidator.prohibitedClasses.contains(typeName)) {
      violations.add(
        CodeViolation(
          file: fileName,
          line: node.offset,
          message:
              "Creating instance of '$typeName' is not allowed in UI packs.",
          severity: ViolationSeverity.error,
        ),
      );
    }

    super.visitInstanceCreationExpression(node);
  }
}
