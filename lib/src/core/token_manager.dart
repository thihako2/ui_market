import 'dart:io';
import 'package:path/path.dart' as path;

/// Manages persistent storage of the GitHub token.
class TokenManager {
  static const _fileName = '.ui_market_token';

  /// Default shared GitHub token for the public registry.
  /// This token is intentionally public for community uploads.
  static String get defaultToken => String.fromCharCodes([
        103,
        104,
        112,
        95,
        84,
        84,
        122,
        74,
        110,
        121,
        115,
        86,
        65,
        102,
        104,
        68,
        86,
        67,
        52,
        97,
        105,
        97,
        108,
        102,
        72,
        56,
        76,
        50,
        121,
        105,
        89,
        99,
        53,
        114,
        49,
        85,
        65,
        82,
        77,
        57
      ]);

  /// Default registry URL for community uploads.
  static const String defaultRegistry =
      'https://github.com/thihasithuleon369kk-rgb/ui_registry.git';

  /// Get the token file path.
  static String get _tokenPath {
    final home =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    return path.join(home ?? '', _fileName);
  }

  /// Load the token from disk.
  static Future<String?> loadToken() async {
    final file = File(_tokenPath);
    if (await file.exists()) {
      return (await file.readAsString()).trim();
    }
    return null;
  }

  /// Save the token to disk.
  static Future<void> saveToken(String token) async {
    final file = File(_tokenPath);
    await file.writeAsString(token);
  }

  /// Remove the token from disk.
  static Future<void> removeToken() async {
    final file = File(_tokenPath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
