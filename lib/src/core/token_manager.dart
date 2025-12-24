import 'dart:io';
import 'package:path/path.dart' as path;

/// Manages persistent storage of the GitHub token.
class TokenManager {
  static const _fileName = '.ui_market_token';

  /// Default shared GitHub token for the public registry.
  /// This token is intentionally public for community uploads.
  static const String defaultToken = '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';

  /// Default registry URL for community uploads.
  static const String defaultRegistry =
      'https://github.com/thihasithuleon369kk-rgb/ui_registry.git';

  /// Get the token file path.
  static String get _tokenPath {
    final home =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home == null) {
      throw Exception('Could not determine home directory');
    }
    return path.join(home, _fileName);
  }

  /// Load the stored token.
  static Future<String?> loadToken() async {
    try {
      final file = File(_tokenPath);
      if (await file.exists()) {
        final token = await file.readAsString();
        return token.trim();
      }
    } catch (e) {
      // Ignore errors reading token file
    }
    return null;
  }

  /// Save the token.
  static Future<void> saveToken(String token) async {
    final file = File(_tokenPath);
    await file.writeAsString(token.trim());
  }

  /// Remove the stored token.
  static Future<void> removeToken() async {
    final file = File(_tokenPath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
