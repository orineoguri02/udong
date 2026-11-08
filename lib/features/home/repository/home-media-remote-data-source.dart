import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../core/api/api-client.dart';
import '../../../core/api/api-endpoints.dart';
import 'home-auth-token-provider.dart';
import 'home-api-helpers.dart';

class HomeMediaRemoteDataSource {
  HomeMediaRemoteDataSource({
    required ApiClient apiClient,
    required HomeAuthTokenProvider tokenProvider,
    required void Function(String) log,
  }) : _apiClient = apiClient,
       _tokenProvider = tokenProvider,
       _log = log;

  final ApiClient _apiClient;
  final HomeAuthTokenProvider _tokenProvider;
  final void Function(String) _log;
  final Uri? _apiBaseUri = _resolveApiBaseUri();
  static const Duration _cacheTtl = Duration(minutes: 10);
  List<String>? _cachedAdBannerUrls;
  DateTime? _adBannerFetchedAt;
  List<String>? _cachedMagazineUrls;
  DateTime? _magazineFetchedAt;

  Future<List<String>> fetchAdBannerUrls() async {
    if (_isCacheValid(_adBannerFetchedAt) && _cachedAdBannerUrls != null) {
      return List<String>.from(_cachedAdBannerUrls!);
    }
    final response = await _getWithOptionalAuth(ApiEndpoints.adsTotal);
    final imageUrls = _extractBannerImageUrls(response);
    _log('[HomeRepo] ads imageUrls=${imageUrls.length}');
    _cachedAdBannerUrls = List<String>.from(imageUrls);
    _adBannerFetchedAt = DateTime.now();
    return imageUrls;
  }

  Future<List<String>> fetchMagazineUrls() async {
    if (_isCacheValid(_magazineFetchedAt) && _cachedMagazineUrls != null) {
      return List<String>.from(_cachedMagazineUrls!);
    }
    final response = await _getWithOptionalAuth(ApiEndpoints.magazineRandom);
    final imageUrls = _extractMagazineImageUrls(response);
    _log('[HomeRepo] magazine imageUrls=${imageUrls.length}');
    _cachedMagazineUrls = List<String>.from(imageUrls);
    _magazineFetchedAt = DateTime.now();
    return imageUrls;
  }

  Future<dynamic> _getWithOptionalAuth(String path) async {
    final accessToken = await _tokenProvider.ensureServerAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      return _apiClient.get(path);
    }

    try {
      return await _apiClient.get(
        path,
        headers: homePetAuthHeaders(accessToken),
      );
    } on DioException catch (e) {
      if (homeIsAuthFailureStatus(e.response?.statusCode)) {
        final refreshed = await _tokenProvider.ensureServerAccessToken(
          forceRefresh: true,
        );
        if (refreshed != null && refreshed.isNotEmpty) {
          return _apiClient.get(path, headers: homePetAuthHeaders(refreshed));
        }
      }
      rethrow;
    }
  }

  bool _isCacheValid(DateTime? fetchedAt) {
    if (fetchedAt == null) return false;
    return DateTime.now().difference(fetchedAt) < _cacheTtl;
  }

  List<String> _extractBannerImageUrls(dynamic response) {
    dynamic listNode = response;
    if (response is Map) {
      final map = Map<String, dynamic>.from(
        response.map((key, value) => MapEntry(key.toString(), value)),
      );
      listNode = map['body'] ?? map['data'] ?? map['result'];
    }
    if (listNode is! List) return const <String>[];

    final collected = <String>[];
    for (final item in listNode) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(
        item.map((key, value) => MapEntry(key.toString(), value)),
      );
      final rawUrl = (map['advertisementUrl'] ?? map['advertisement_url'])
          ?.toString()
          .trim();
      if (rawUrl == null || rawUrl.isEmpty) continue;
      final normalized = _normalizeImageUrl(rawUrl);
      if (normalized.isNotEmpty) {
        collected.add(normalized);
      }
    }
    return _dedupe(collected);
  }

  List<String> _extractMagazineImageUrls(dynamic response) {
    final collected = <String>[];

    void collect(dynamic node) {
      if (node == null) return;
      if (node is String) {
        final normalized = _normalizeImageUrl(node);
        if (normalized.isNotEmpty) {
          collected.add(normalized);
        }
        return;
      }
      if (node is List) {
        for (final item in node) {
          collect(item);
        }
        return;
      }
      if (node is! Map) return;

      final map = Map<String, dynamic>.from(
        node.map((key, value) => MapEntry(key.toString(), value)),
      );

      collect(map['imageUrls']);
      collect(map['image_urls']);
      collect(map['images']);

      const directImageKeys = <String>[
        'imageUrl',
        'image_url',
        'thumbnailUrl',
        'thumbnail_url',
        'thumbnail',
        'coverImage',
        'cover_image',
        'image',
        'imgUrl',
        'img_url',
        'img',
        'photoUrl',
        'photo_url',
        'photo',
      ];
      for (final key in directImageKeys) {
        collect(map[key]);
      }

      const nestedKeys = <String>[
        'data',
        'result',
        'item',
        'magazine',
        'payload',
      ];
      for (final key in nestedKeys) {
        collect(map[key]);
      }
    }

    collect(response);
    return _dedupe(collected);
  }

  List<String> _dedupe(List<String> values) {
    final deduped = <String>[];
    final seen = <String>{};
    for (final value in values) {
      if (seen.add(value)) {
        deduped.add(value);
      }
    }
    return deduped;
  }

  String _normalizeImageUrl(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '';

    if (value.startsWith('//')) {
      return _encodeOnce('https:$value');
    }

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return _encodeOnce(value);
    }

    if (value.startsWith('/')) {
      final base = _apiBaseUri;
      if (base == null) return '';
      return _encodeOnce(base.resolve(value).toString());
    }

    return '';
  }

  /// 백엔드가 이미 인코딩한 URL(`today's%20knowledge`)을 다시 인코딩하면
  /// `%2520`이 되어 400이 나므로, 한 번 디코딩한 뒤 인코딩한다.
  String _encodeOnce(String url) {
    try {
      return Uri.encodeFull(Uri.decodeFull(url));
    } on ArgumentError {
      // '%'가 인코딩 용도가 아닌 문자로 들어 있으면 디코딩이 실패한다.
      return Uri.encodeFull(url);
    }
  }

  static Uri? _resolveApiBaseUri() {
    var raw = (dotenv.env['API_BASE_URL'] ?? '').trim();
    if (raw.isEmpty) return null;

    if ((raw.startsWith('"') && raw.endsWith('"')) ||
        (raw.startsWith("'") && raw.endsWith("'"))) {
      raw = raw.substring(1, raw.length - 1).trim();
    }
    if (raw.isEmpty) return null;

    if (!raw.contains('://')) {
      raw = 'https://$raw';
    } else if (raw.toLowerCase().startsWith('http://')) {
      raw = 'https://${raw.substring(7)}';
    }

    final parsed = Uri.tryParse(raw);
    if (parsed == null || parsed.host.isEmpty) return null;

    final normalized = parsed.scheme.toLowerCase() == 'https'
        ? parsed
        : parsed.replace(scheme: 'https');
    final withPort = (normalized.hasPort && normalized.port == 80)
        ? normalized.replace(port: null)
        : normalized;

    if (withPort.path.isEmpty || withPort.path == '/') {
      return withPort.replace(path: '/');
    }
    if (withPort.path.endsWith('/')) return withPort;
    return withPort.replace(path: '${withPort.path}/');
  }
}
