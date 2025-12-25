import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/registry_pack.dart';

class RegistryService {
  /// Shared community registry URL
  static const String _defaultRegistry =
      'https://raw.githubusercontent.com/thihako2/ui_market/main';

  final String _baseUrl;

  RegistryService({String? registryUrl})
      : _baseUrl = registryUrl ?? _defaultRegistry;

  /// Temporary storage for packs published during this session
  static final List<RegistryPack> _localPacks = [];
  static List<RegistryPack> _lastRemotePacks = [];

  static final packsNotifier = ValueNotifier<List<RegistryPack>>([]);

  static void addLocalPack(RegistryPack pack) {
    // Remove if exists (replace)
    _localPacks.removeWhere((p) => p.id == pack.id);
    _localPacks.insert(0, pack);
    print(
        "Marketplace: Registered local pack '${pack.name}' with ID '${pack.id}'");

    // Update notifier with merged list
    _updateNotifier();
  }

  static void _updateNotifier() {
    // Merge local changes with last known remote state
    packsNotifier.value = [..._localPacks, ..._lastRemotePacks];
  }

  Future<List<RegistryPack>> fetchPacks() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/registry/index.json'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final packs = json['packs'] as List<dynamic>;
        _lastRemotePacks = packs
            .map((e) => RegistryPack.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}

    final all = [..._localPacks, ..._lastRemotePacks];
    packsNotifier.value = all;
    return all;
  }

  Future<List<RegistryPack>> searchPacks(String query) async {
    final packs = await fetchPacks();
    final lowerQuery = query.toLowerCase();

    return packs.where((pack) {
      return pack.name.toLowerCase().contains(lowerQuery) ||
          pack.description.toLowerCase().contains(lowerQuery) ||
          pack.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  Future<List<String>> getTags() async {
    final packs = await fetchPacks();
    final tags = <String>{};

    for (final pack in packs) {
      tags.addAll(pack.tags);
    }

    return tags.toList()..sort();
  }
}
