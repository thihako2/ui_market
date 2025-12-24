import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/registry_pack.dart';

class RegistryService {
  static const String _defaultRegistry =
      'https://raw.githubusercontent.com/your-org/flutter-ui-registry/main';

  final String _baseUrl;

  RegistryService({String? registryUrl})
      : _baseUrl = registryUrl ?? _defaultRegistry;

  Future<List<RegistryPack>> fetchPacks() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/registry/index.json'),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final packs = json['packs'] as List<dynamic>;
      return packs
          .map((e) => RegistryPack.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to fetch packs');
    }
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
