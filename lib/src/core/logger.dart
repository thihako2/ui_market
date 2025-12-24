import 'dart:io';

/// Logger utility for CLI output.
class Logger {
  static bool verbose = false;

  /// Print info message.
  static void info(String message) {
    stdout.writeln(message);
  }

  /// Print success message in green.
  static void success(String message) {
    stdout.writeln('\x1B[32m✓ $message\x1B[0m');
  }

  /// Print warning message in yellow.
  static void warning(String message) {
    stdout.writeln('\x1B[33m⚠ $message\x1B[0m');
  }

  /// Print error message in red.
  static void error(String message) {
    stderr.writeln('\x1B[31m✗ $message\x1B[0m');
  }

  /// Print debug message (only if verbose).
  static void debug(String message) {
    if (verbose) {
      stdout.writeln('\x1B[90m  $message\x1B[0m');
    }
  }

  /// Print a step with number.
  static void step(int number, String message) {
    stdout.writeln('\x1B[36m[$number]\x1B[0m $message');
  }

  /// Print progress indicator.
  static void progress(String message) {
    stdout.write('\x1B[34m→ $message\x1B[0m');
  }

  /// Clear current line.
  static void clearLine() {
    stdout.write('\r\x1B[K');
  }

  /// Print a newline.
  static void newLine() {
    stdout.writeln();
  }

  /// Print a horizontal divider.
  static void divider() {
    stdout.writeln('\x1B[90m${'─' * 50}\x1B[0m');
  }

  /// Print a header.
  static void header(String title) {
    newLine();
    stdout.writeln('\x1B[1m$title\x1B[0m');
    divider();
  }

  /// Print a table row.
  static void table(List<String> columns, {List<int>? widths}) {
    final buffer = StringBuffer();
    for (var i = 0; i < columns.length; i++) {
      final col = columns[i];
      final width = widths != null && i < widths.length ? widths[i] : 20;
      buffer.write(col.padRight(width));
    }
    stdout.writeln(buffer.toString());
  }

  /// Print a key-value pair.
  static void keyValue(String key, String value) {
    stdout.writeln('\x1B[90m$key:\x1B[0m $value');
  }

  /// Ask for confirmation.
  static Future<bool> confirm(
    String message, {
    bool defaultValue = false,
  }) async {
    final defaultText = defaultValue ? 'Y/n' : 'y/N';
    stdout.write('$message [$defaultText]: ');
    final input = stdin.readLineSync()?.toLowerCase().trim();
    if (input == null || input.isEmpty) return defaultValue;
    return input == 'y' || input == 'yes';
  }
}
