import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../../../core/api/api-client.dart';
import '../../../core/api/api-endpoints.dart';
import '../../../core/utils/image-compress.dart';
import '../models/pet-profile.dart';
import 'home-api-helpers.dart';
import 'home-auth-token-provider.dart';
import 'home-token-retry.dart';

class HomePetProfileRemoteDataSource {
  HomePetProfileRemoteDataSource({
    required ApiClient apiClient,
    required HomeAuthTokenProvider tokenProvider,
    required void Function(String) log,
  }) : _apiClient = apiClient,
       _tokenProvider = tokenProvider,
       _log = log;

  final ApiClient _apiClient;
  final HomeAuthTokenProvider _tokenProvider;
  final void Function(String) _log;

  Future<List<PetProfile>> fetchPetProfiles() async {
    final response = await _withTokenRetry(
      missingTokenMessage: '반려가족 조회에 필요한 accessToken이 없습니다.',
      request: (accessToken) {
        _log('[HomeRepo] fetchPetProfiles');
        return _fetchPetListWithToken(
          path: ApiEndpoints.petMain,
          accessToken: accessToken,
        );
      },
    );

    return _parseProfilesOrThrow(
      response: response,
      emptyMessage: '반려가족 메인 정보 응답이 비어있습니다.',
      emptyLogPrefix: '[HomeRepo] pet/main 파싱 결과 없음',
    );
  }

  Future<List<PetProfile>> fetchMyPetProfiles() async {
    final response = await _withTokenRetry(
      missingTokenMessage: '반려가족 조회에 필요한 accessToken이 없습니다.',
      request: (accessToken) {
        _log('[HomeRepo] fetchMyPetProfiles');
        return _fetchPetListWithToken(
          path: ApiEndpoints.petMe,
          accessToken: accessToken,
        );
      },
    );

    return _parseProfilesOrThrow(
      response: response,
      emptyMessage: '반려가족 목록 응답이 비어있습니다.',
      emptyLogPrefix: '[HomeRepo] pet/me 파싱 결과 없음',
    );
  }

  Future<void> selectMainPet({required int petId}) async {
    final path = ApiEndpoints.petMainSelect.replaceFirst('{pet_id}', '$petId');

    await _withTokenRetry(
      missingTokenMessage: '메인 반려가족 선택에 필요한 accessToken이 없습니다.',
      request: (accessToken) async {
        _log('[HomeRepo] selectMainPet petId=$petId');
        await _apiClient.patch(
          path,
          data: const <String, dynamic>{},
          headers: homePetAuthHeaders(accessToken),
        );
      },
    );
  }

  Future<void> deletePetProfile({required int petId}) async {
    final path = ApiEndpoints.petDelete.replaceFirst('{pet_id}', '$petId');

    await _withTokenRetry(
      missingTokenMessage: '반려가족 삭제에 필요한 accessToken이 없습니다.',
      request: (accessToken) async {
        _log(
          '[HomeRepo] deletePetProfile petId=$petId',
        );
        await _apiClient.delete(path, headers: homePetAuthHeaders(accessToken));
      },
    );
  }

  Future<PetProfile> updatePetProfile({
    required int petId,
    required PetProfile profile,
    String? imagePath,
  }) async {
    final path = ApiEndpoints.petUpdate.replaceFirst('{pet_id}', '$petId');
    final request = profile.toPatchBody();
    final normalizedImagePath = imagePath?.trim();

    _log(
      '[HomeRepo] updatePetProfile multipart payload '
      'petId=$petId '
      'name=${request['name']} '
      'gender=${request['gender']} '
      'species=${request['species']} '
      'breed=${request['breed']} '
      'birthday=${request['birthday']} '
      'adoptedAt=${request['adoptedAt']} '
      'hasPhoto=${(normalizedImagePath ?? '').isNotEmpty}',
    );

    final response = await _withTokenRetry(
      missingTokenMessage: '반려가족 수정에 필요한 accessToken이 없습니다.',
      request: (accessToken) async {
        _log(
          '[HomeRepo] updatePetProfile petId=$petId',
        );
        final formData = await _buildPetEditFormData(
          request: request,
          imagePath: normalizedImagePath,
        );
        return _apiClient.patchMultipart(
          path,
          data: formData,
          headers: homePetAuthHeaders(accessToken),
        );
      },
    );

    _log(
      '[HomeRepo] updatePetProfile multipart 요청 성공 '
      'requestPart=petEditRequest requestPartContentType=application/json '
      'fileParts=photo,file',
    );

    final parsed = _parseSingleProfile(response);
    if (parsed == null) {
      return profile.copyWith(petId: petId);
    }

    return parsed.copyWith(petId: parsed.petId ?? petId);
  }

  Future<PetProfile> createPetProfile({
    required PetProfile profile,
    String? imagePath,
  }) async {
    _log(
      '[HomeRepo] createPetProfile imagePath=$imagePath '
      'accessToken=<with-token-retry>',
    );

    if ((imagePath ?? '').trim().isEmpty) {
      throw Exception('photo 이미지가 없어 /pet/new 요청을 보낼 수 없습니다.');
    }

    final profileImage = imagePath == null
        ? ''
        : homeToImageFilename(imagePath);
    final request = profile.toPetNewRequestBody(profileImage: profileImage);

    _log(
      '[HomeRepo] createPetProfile multipart payload '
      'name=${request['name']} '
      'gender=${request['gender']} '
      'species=${request['species']} '
      'breed=${request['breed']} '
      'birthday=${request['birthday']} '
      'adoptedAt=${request['adoptedAt']} '
      'profileImageLen=${(request['profileImage'] as String?)?.length ?? 0} '
      'hasPhoto=${(imagePath ?? '').trim().isNotEmpty}',
    );

    final response = await _withTokenRetry(
      missingTokenMessage: '반려가족 추가에 필요한 accessToken이 없습니다.',
      request: (accessToken) async {
        _log('[HomeRepo] createPetProfile');
        final formData = await _buildPetNewFormData(
          request: request,
          imagePath: imagePath,
        );
        return _apiClient.postMultipart(
          ApiEndpoints.petNew,
          data: formData,
          headers: homePetAuthHeaders(accessToken),
        );
      },
    );

    _log(
      '[HomeRepo] createPetProfile multipart 요청 성공 '
      'requestPart=petNewRequest requestPartContentType=application/json '
      'fileParts=photo,file',
    );

    final parsed = _parseSingleProfile(response);
    if (parsed == null || parsed.petId == null) {
      _log('[HomeRepo] createPetProfile pet_id 파싱 실패 response=$response');
      throw Exception('반려가족 생성 응답에서 pet_id를 확인하지 못했습니다.');
    }

    return _mergeCreatedWithFallback(parsed: parsed, fallback: profile);
  }

  Future<T> _withTokenRetry<T>({
    required String missingTokenMessage,
    required Future<T> Function(String accessToken) request,
  }) async {
    return homeWithServerAccessTokenRetry(
      tokenProvider: _tokenProvider,
      missingTokenMessage: missingTokenMessage,
      request: request,
    );
  }

  Future<dynamic> _fetchPetListWithToken({
    required String path,
    required String accessToken,
  }) async {
    return _apiClient.get(path, headers: homePetAuthHeaders(accessToken));
  }

  List<PetProfile> _parseProfilesOrThrow({
    required dynamic response,
    required String emptyMessage,
    required String emptyLogPrefix,
  }) {
    final petMaps = _extractPetMaps(response);
    if (petMaps.isEmpty) {
      _log('$emptyLogPrefix responseType=${response.runtimeType}');
      throw Exception(emptyMessage);
    }
    return petMaps.map(PetProfile.fromJson).toList();
  }

  PetProfile? _parseSingleProfile(dynamic response) {
    if (response is Map<String, dynamic>) {
      final parsed = PetProfile.fromJson(response);
      if (_hasMeaningfulProfile(parsed)) {
        return parsed;
      }
    }

    final petMaps = _extractPetMaps(response);
    if (petMaps.isEmpty) {
      return null;
    }
    return PetProfile.fromJson(petMaps.first);
  }

  List<Map<String, dynamic>> _extractPetMaps(dynamic response) {
    if (response is List) {
      return _toMapList(response);
    }

    final root = _toStringKeyedMap(response);
    if (root == null) return const [];

    final directList = _extractPetListFromMap(root);
    if (directList.isNotEmpty) return directList;

    final singleFromRoot = _extractSinglePetMap(root);
    if (singleFromRoot != null) return [singleFromRoot];

    for (final key in _wrapperMapKeys) {
      final wrapper = _toStringKeyedMap(root[key]);
      if (wrapper == null) continue;

      final wrapperList = _extractPetListFromMap(wrapper);
      if (wrapperList.isNotEmpty) return wrapperList;

      final singleFromWrapper = _extractSinglePetMap(wrapper);
      if (singleFromWrapper != null) return [singleFromWrapper];
    }

    return const [];
  }

  Map<String, dynamic>? _toStringKeyedMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      final mapped = <String, dynamic>{};
      for (final entry in value.entries) {
        final key = entry.key?.toString();
        if (key == null || key.isEmpty) continue;
        mapped[key] = entry.value;
      }
      return mapped;
    }
    return null;
  }

  static const List<String> _petListKeys = [
    'pets',
    'petList',
    'petProfiles',
    'items',
    'list',
    'content',
  ];

  static const List<String> _wrapperMapKeys = ['data', 'result'];

  static const List<String> _singlePetKeys = [
    'pet',
    'petMain',
    'petInfo',
    'petDetail',
    'petProfile',
    'profile',
    'item',
  ];

  List<Map<String, dynamic>> _extractPetListFromMap(Map<String, dynamic> map) {
    for (final key in _petListKeys) {
      final list = _toMapList(map[key]);
      if (list.isNotEmpty) {
        return list;
      }
    }
    return const [];
  }

  Map<String, dynamic>? _extractSinglePetMap(Map<String, dynamic> map) {
    if (_isPetPayload(map)) {
      return map;
    }

    for (final key in _singlePetKeys) {
      final nested = _toStringKeyedMap(map[key]);
      if (nested == null) continue;
      if (_isPetPayload(nested)) {
        return _mergeImageFields(nested, map);
      }
    }
    return null;
  }

  List<Map<String, dynamic>> _toMapList(dynamic rawList) {
    if (rawList is! List) {
      return const [];
    }

    final list = <Map<String, dynamic>>[];
    for (final item in rawList) {
      final map = _toStringKeyedMap(item);
      if (map != null) {
        list.add(map);
      }
    }
    return list;
  }

  bool _isPetPayload(Map<String, dynamic> map) {
    const petIdKeys = ['pet_id', 'petId'];
    const nameKeys = ['name', 'petName', 'pet_name'];

    final hasPetId = _hasAnyKey(map, petIdKeys);
    final hasName = _hasAnyKey(map, nameKeys);
    return hasPetId || hasName;
  }

  bool _hasAnyKey(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      if (map.containsKey(key)) return true;
    }
    return false;
  }

  Map<String, dynamic> _mergeImageFields(
    Map<String, dynamic> petMap,
    Map<String, dynamic>? source,
  ) {
    if (source == null) return petMap;

    final merged = <String, dynamic>{...petMap};
    if (!merged.containsKey('photo') && source['photo'] != null) {
      merged['photo'] = source['photo'];
    }
    if (!merged.containsKey('file') && source['file'] != null) {
      merged['file'] = source['file'];
    }
    if (!merged.containsKey('imageUrl') && source['imageUrl'] != null) {
      merged['imageUrl'] = source['imageUrl'];
    }
    if (!merged.containsKey('image_url') && source['image_url'] != null) {
      merged['image_url'] = source['image_url'];
    }
    return merged;
  }

  PetProfile _mergeCreatedWithFallback({
    required PetProfile parsed,
    required PetProfile fallback,
  }) {
    return PetProfile.merge(primary: parsed, fallback: fallback);
  }

  bool _hasMeaningfulProfile(PetProfile profile) {
    return profile.petId != null ||
        profile.name.trim().isNotEmpty ||
        profile.animalType.trim().isNotEmpty ||
        profile.breed.trim().isNotEmpty;
  }

  /// 파일을 디스크에서 **1회**만 읽어 `photo`와 `file` 파트에 쓸
  /// 독립적인 [MultipartFile] 두 개를 반환한다.
  ///
  /// 같은 [MultipartFile] 객체를 두 파트에 공유하면 Dio가 스트림을
  /// 두 번 소비하려 해서 두 번째 파트에서 빈 바이트를 전송할 수 있다.
  /// [fromBytes]로 각각 독립 객체를 만들어 이 문제를 방지한다.
  Future<(MultipartFile?, MultipartFile?)> _toPhotoAndFileParts(
    String? imagePath,
  ) async {
    if (imagePath == null) return (null, null);
    final trimmed = imagePath.trim();
    if (trimmed.isEmpty || homeIsRemoteImageUrl(trimmed)) return (null, null);

    try {
      if (!await localImageExists(trimmed)) {
        _log('[HomeRepo] photo 파일 없음: $trimmed');
        return (null, null);
      }

      // 두 파트에 같은 스트림을 공유하면 두 번째 파트가 빈 바이트를 전송하므로
      // 각각 독립적인 MultipartFile 객체를 생성한다.
      // 압축은 1회만 수행하고 결과 바이트를 복제해 사용한다.
      final (compressedBytes, filename) =
          await homeCompressedImageBytesAndFilename(trimmed);
      final part1 = MultipartFile.fromBytes(
        List<int>.from(compressedBytes),
        filename: filename,
        contentType: MediaType('image', 'webp'),
      );
      final part2 = MultipartFile.fromBytes(
        List<int>.from(compressedBytes),
        filename: filename,
        contentType: MediaType('image', 'webp'),
      );

      return (part1, part2);
    } catch (e) {
      _log('[HomeRepo] photo 파일 파트 생성 실패: $e');
      return (null, null);
    }
  }

  Future<FormData> _buildPetEditFormData({
    required Map<String, dynamic> request,
    required String? imagePath,
  }) async {
    final (photoPart, filePart) = await _toPhotoAndFileParts(imagePath);

    if (imagePath != null && imagePath.trim().isNotEmpty && photoPart == null) {
      _log(
        '[HomeRepo] updatePetProfile photo 파트 생성 실패 '
        'imagePath=$imagePath',
      );
    }

    final body = <String, dynamic>{
      'petEditRequest': MultipartFile.fromString(
        jsonEncode(request),
        contentType: MediaType('application', 'json', {'charset': 'utf-8'}),
      ),
    };
    if (photoPart != null) {
      body['photo'] = photoPart;
    }
    if (filePart != null) {
      body['file'] = filePart;
    }

    return FormData.fromMap(body);
  }

  Future<FormData> _buildPetNewFormData({
    required Map<String, dynamic> request,
    required String? imagePath,
  }) async {
    final (photoPart, filePart) = await _toPhotoAndFileParts(imagePath);
    if (photoPart == null) {
      throw Exception('photo 이미지 파트 생성에 실패했습니다.');
    }

    final body = <String, dynamic>{
      'petNewRequest': MultipartFile.fromString(
        jsonEncode(request),
        contentType: MediaType('application', 'json', {'charset': 'utf-8'}),
      ),
      'photo': photoPart,
    };
    if (filePart != null) {
      body['file'] = filePart;
    }

    return FormData.fromMap(body);
  }
}
