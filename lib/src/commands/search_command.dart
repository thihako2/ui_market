import 'package:args/command_runner.dart';

import '../core/logger.dart';
import '../models/config.dart';
import '../registry/registry_client.dart';

/// Search for UI packs in the marketplace.
class SearchCommand extends Command<int> {
  @override
  String get name => 'search';

  @override
  String get description => 'Search for UI packs in the marketplace';

  @override
  String get invocation => '${runner!.executableName} $name <keyword>';

  SearchCommand() {
    argParser.addOption('tag', abbr: 't', help: 'Filter by tag');
    argParser.addFlag(
      'all',
      abbr: 'a',
      help: 'List all packs',
      negatable: false,
    );
  }

  @override
  Future<int> run() async {
    final keyword = argResults!.rest.isNotEmpty
        ? argResults!.rest.join(' ')
        : null;
    final tag = argResults!['tag'] as String?;
    final showAll = argResults!['all'] as bool;

    if (keyword == null && tag == null && !showAll) {
      Logger.error('Please provide a search keyword, tag, or use --all');
      Logger.info(usage);
      return 1;
    }

    // Load config or use default
    final config = await UIMarketConfig.load() ?? UIMarketConfig.defaultConfig;
    final client = RegistryClient(registryUrl: config.registry);

    try {
      Logger.info('Searching marketplace...');

      final packs = showAll
          ? await client.listPacks()
          : tag != null
          ? await client.listByTag(tag)
          : await client.search(keyword!);

      if (packs.isEmpty) {
        Logger.warning('No packs found.');
        if (keyword != null) {
          Logger.info(
            "Try different keywords or run 'dart run ui_market search --all'",
          );
        }
        return 0;
      }

      Logger.newLine();
      Logger.info('Found ${packs.length} pack(s):');
      Logger.divider();

      // Print header
      Logger.table(['Name', 'Version', 'Description'], widths: [25, 10, 45]);
      Logger.divider();

      for (final pack in packs) {
        final description = pack.description.length > 42
            ? '${pack.description.substring(0, 42)}...'
            : pack.description;

        Logger.table(
          [pack.id, pack.version, description],
          widths: [25, 10, 45],
        );
      }

      Logger.divider();
      Logger.newLine();
      Logger.info("To install a pack, run: dart run ui_market add <pack_id>");
      Logger.newLine();

      return 0;
    } catch (e) {
      Logger.error('Search failed: $e');
      return 1;
    } finally {
      client.dispose();
    }
  }
}
