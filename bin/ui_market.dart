import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:ui_market/src/commands/init_command.dart';
import 'package:ui_market/src/commands/search_command.dart';
import 'package:ui_market/src/commands/add_command.dart';
import 'package:ui_market/src/commands/remove_command.dart';
import 'package:ui_market/src/commands/build_command.dart';
import 'package:ui_market/src/commands/upload_command.dart';
import 'package:ui_market/src/commands/login_command.dart';
import 'package:ui_market/src/core/logger.dart';

void main(List<String> arguments) async {
  final runner = CommandRunner<int>(
    'ui_market',
    'Flutter UI Marketplace CLI - Browse, install, and upload UI packs.',
  )
    ..addCommand(InitCommand())
    ..addCommand(SearchCommand())
    ..addCommand(AddCommand())
    ..addCommand(RemoveCommand())
    ..addCommand(BuildCommand())
    ..addCommand(UploadCommand())
    ..addCommand(LoginCommand());

  try {
    final result = await runner.run(arguments);
    exit(result ?? 0);
  } on UsageException catch (e) {
    Logger.error(e.message);
    Logger.info(e.usage);
    exit(64);
  } catch (e, stackTrace) {
    Logger.error('An unexpected error occurred: $e');
    Logger.debug(stackTrace.toString());
    exit(1);
  }
}
