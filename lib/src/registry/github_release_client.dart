import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

import '../core/exceptions.dart';
import '../core/logger.dart';
import '../models/registry_pack.dart';

/// Client for downloading packs from GitHub Releases.
class GitHubReleaseClient {
  final http.Client _httpClient;

  GitHubReleaseClient({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  /// Download a pack bundle from the given URL.
  Future<List<int>> downloadBundle(String downloadUrl) async {
    Logger.debug('Downloading bundle from: $downloadUrl');

    try {
      final response = await _httpClient.get(
        Uri.parse(downloadUrl),
        headers: {'Accept': 'application/octet-stream'},
      );

      if (response.statusCode == 200) {
        Logger.debug('Downloaded ${response.bodyBytes.length} bytes');
        return response.bodyBytes;
      } else if (response.statusCode == 404) {
        throw const FileOperationException(
          'Bundle not found',
          'The pack bundle may have been removed or the URL is incorrect.',
        );
      } else {
        throw NetworkException(
          'Failed to download bundle',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is UIMarketException) rethrow;
      throw NetworkException(
        'Failed to download bundle',
        details: e.toString(),
      );
    }
  }

  /// Download a pack and save to temp directory.
  Future<String> downloadToTemp(RegistryPack pack) async {
    final bytes = await downloadBundle(pack.downloadUrl);

    final tempDir = Directory.systemTemp;
    final tempFile = File(
      path.join(tempDir.path, 'ui_market_${pack.id}_${pack.version}.zip'),
    );

    await tempFile.writeAsBytes(bytes);
    Logger.debug('Saved bundle to: ${tempFile.path}');

    return tempFile.path;
  }

  /// Download preview image.
  Future<List<int>> downloadPreview(String previewUrl) async {
    Logger.debug('Downloading preview from: $previewUrl');

    try {
      final response = await _httpClient.get(Uri.parse(previewUrl));

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw NetworkException(
          'Failed to download preview',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is UIMarketException) rethrow;
      throw NetworkException(
        'Failed to download preview',
        details: e.toString(),
      );
    }
  }

  /// Parse GitHub repo info from registry URL.
  static GitHubRepoInfo? parseRepoUrl(String registryUrl) {
    final uri = Uri.parse(registryUrl);
    if (uri.host != 'github.com') return null;

    final pathParts = uri.pathSegments;
    if (pathParts.length < 2) return null;

    // Strip .git suffix if present
    var repoName = pathParts[1];
    if (repoName.endsWith('.git')) {
      repoName = repoName.substring(0, repoName.length - 4);
    }

    return GitHubRepoInfo(owner: pathParts[0], repo: repoName);
  }

  /// Get release information from GitHub API.
  Future<List<GitHubRelease>> getReleases(
    String owner,
    String repo, {
    String? token,
  }) async {
    final url = 'https://api.github.com/repos/$owner/$repo/releases';
    Logger.debug('Fetching releases from: $url');

    final headers = <String, String>{
      'Accept': 'application/vnd.github.v3+json',
    };
    if (token != null) {
      headers['Authorization'] = 'token $token';
    }

    try {
      final response = await _httpClient.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> json = jsonDecode(response.body);
        return json
            .map((e) => GitHubRelease.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw NetworkException(
          'Failed to fetch releases',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is UIMarketException) rethrow;
      throw NetworkException('Failed to fetch releases', details: e.toString());
    }
  }

  void dispose() {
    _httpClient.close();
  }
}

/// GitHub repository info.
class GitHubRepoInfo {
  final String owner;
  final String repo;

  const GitHubRepoInfo({required this.owner, required this.repo});

  String get apiUrl => 'https://api.github.com/repos/$owner/$repo';
  String get rawUrl => 'https://raw.githubusercontent.com/$owner/$repo/main';
}

/// GitHub release info.
class GitHubRelease {
  final int id;
  final String tagName;
  final String name;
  final String? body;
  final bool draft;
  final bool prerelease;
  final DateTime createdAt;
  final DateTime publishedAt;
  final List<GitHubAsset> assets;

  const GitHubRelease({
    required this.id,
    required this.tagName,
    required this.name,
    this.body,
    required this.draft,
    required this.prerelease,
    required this.createdAt,
    required this.publishedAt,
    required this.assets,
  });

  factory GitHubRelease.fromJson(Map<String, dynamic> json) {
    return GitHubRelease(
      id: json['id'] as int,
      tagName: json['tag_name'] as String,
      name: json['name'] as String,
      body: json['body'] as String?,
      draft: json['draft'] as bool,
      prerelease: json['prerelease'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      publishedAt: DateTime.parse(json['published_at'] as String),
      assets: (json['assets'] as List<dynamic>)
          .map((e) => GitHubAsset.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// GitHub release asset.
class GitHubAsset {
  final int id;
  final String name;
  final String contentType;
  final int size;
  final String browserDownloadUrl;

  const GitHubAsset({
    required this.id,
    required this.name,
    required this.contentType,
    required this.size,
    required this.browserDownloadUrl,
  });

  factory GitHubAsset.fromJson(Map<String, dynamic> json) {
    return GitHubAsset(
      id: json['id'] as int,
      name: json['name'] as String,
      contentType: json['content_type'] as String,
      size: json['size'] as int,
      browserDownloadUrl: json['browser_download_url'] as String,
    );
  }
}
