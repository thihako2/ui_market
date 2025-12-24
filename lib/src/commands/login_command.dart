import 'dart:io';

import 'package:args/command_runner.dart';
import '../core/logger.dart';
import '../core/token_manager.dart';

/// Log in to the marketplace.
class LoginCommand extends Command<int> {
  @override
  String get name => 'login';

  @override
  String get description => 'Log in with a custom GitHub token (optional)';

  @override
  String get invocation => '${runner!.executableName} login [token]';

  LoginCommand() {
    argParser.addOption(
      'token',
      abbr: 't',
      help: 'GitHub personal access token',
    );
  }

  @override
  Future<int> run() async {
    var token = argResults!['token'] as String?;

    if (token == null && argResults!.rest.isNotEmpty) {
      token = argResults!.rest.first;
    }

    if (token == null) {
      Logger.info('📢 Note: Login is OPTIONAL for ui_market.');
      Logger.info(
          '   A shared community token is used by default for uploads.');
      Logger.newLine();
      Logger.info(
          'If you want to use your own GitHub token, provide it below.');
      Logger.info('You can generate one at https://github.com/settings/tokens');
      Logger.info('Required scopes: repo');
      Logger.newLine();

      stdout.write('Token (press Enter to skip): ');
      token = stdin.readLineSync();
    }

    if (token == null || token.isEmpty) {
      Logger.info('No token provided. Using default shared token.');
      Logger.success('You can upload without logging in!');
      return 0;
    }

    try {
      await TokenManager.saveToken(token);
      Logger.success('Successfully logged in with custom token!');
      return 0;
    } catch (e) {
      Logger.error('Failed to save token: $e');
      return 1;
    }
  }
}
