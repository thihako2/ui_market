import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/exceptions.dart';
import '../core/logger.dart';
import '../models/registry_pack.dart';

/// Client for fetching data from the UI Market registry.
class RegistryClient {
  final String registryUrl;
  final http.Client _httpClient;

  /// Default registry URL.
  static const defaultRegistry =
      'https://github.com/your-org/flutter-ui-registry';

  RegistryClient({String? registryUrl, http.Client? httpClient})
    : registryUrl = registryUrl ?? defaultRegistry,
      _httpClient = httpClient ?? http.Client();

  /// Get the raw GitHub URL for registry files.
  String get _rawBaseUrl {
    // Convert github.com URL to raw.githubusercontent.com
    final uri = Uri.parse(registryUrl);
    if (uri.host == 'github.com') {
      final pathParts = uri.pathSegments;
      if (pathParts.length >= 2) {
        return 'https://raw.githubusercontent.com/${pathParts[0]}/${pathParts[1]}/main';
      }
    }
    return '$registryUrl/raw/main';
  }

  /// Fetch the registry index.
  Future<RegistryIndex> fetchIndex() async {
    final url = '$_rawBaseUrl/registry/index.json';
    Logger.debug('Fetching index from: $url');

    try {
      final response = await _httpClient.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return RegistryIndex.fromJson(json);
      } else if (response.statusCode == 404) {
        throw const RegistryException(
          'Registry index not found',
          'The registry may not be set up yet or the URL is incorrect.',
        );
      } else {
        throw NetworkException(
          'Failed to fetch registry index',
          statusCode: response.statusCode,
          details: response.body,
        );
      }
    } on FormatException catch (e) {
      throw RegistryException('Invalid registry index format', e.message);
    } catch (e) {
      if (e is UIMarketException) rethrow;
      throw NetworkException(
        'Failed to connect to registry',
        details: e.toString(),
      );
    }
  }

  /// Search packs by keyword.
  Future<List<RegistryPack>> search(String keyword) async {
    final index = await fetchIndex();
    final lowerKeyword = keyword.toLowerCase();

    return index.packs.where((pack) {
      return pack.name.toLowerCase().contains(lowerKeyword) ||
          pack.description.toLowerCase().contains(lowerKeyword) ||
          pack.id.toLowerCase().contains(lowerKeyword) ||
          pack.tags.any((tag) => tag.toLowerCase().contains(lowerKeyword));
    }).toList();
  }

  /// Get a specific pack by ID.
  Future<RegistryPack?> getPack(String packId) async {
    final index = await fetchIndex();
    try {
      return index.packs.firstWhere((pack) => pack.id == packId);
    } catch (_) {
      return null;
    }
  }

  /// Get pack by ID or throw.
  Future<RegistryPack> getPackOrThrow(String packId) async {
    final pack = await getPack(packId);
    if (pack == null) {
      throw PackNotFoundException(packId);
    }
    return pack;
  }

  /// List all packs.
  Future<List<RegistryPack>> listPacks() async {
    final index = await fetchIndex();
    return index.packs;
  }

  /// List packs by tag.
  Future<List<RegistryPack>> listByTag(String tag) async {
    final index = await fetchIndex();
    return index.packs
        .where((pack) => pack.tags.contains(tag.toLowerCase()))
        .toList();
  }

  /// Get available tags with counts.
  Future<Map<String, int>> getTags() async {
    final index = await fetchIndex();
    final tags = <String, int>{};

    for (final pack in index.packs) {
      for (final tag in pack.tags) {
        tags[tag] = (tags[tag] ?? 0) + 1;
      }
    }

    return tags;
  }

  /// Check if a pack version exists.
  Future<bool> versionExists(String packId, String version) async {
    final pack = await getPack(packId);
    if (pack == null) return false;
    // For now, just check if it's the current version
    // Future versions could check release history
    return pack.version == version;
  }

  void dispose() {
    _httpClient.close();
  }
}
