import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/api/api-client.dart';
import '../../../core/api/api-endpoints.dart';
import '../../../core/utils/app-logger.dart';
import '../../auth/repository/auth-repository.dart';
import '../models/hospital.dart';

abstract class HospitalRepository {
  Future<List<Hospital>> getHospitals({
    bool? isOpen,
    double? latitude,
    double? longitude,
  });

  Future<Hospital> getHospitalDetail({required int clinicId});
}

class HospitalRepositoryImpl implements HospitalRepository {
  static const double _defaultLatitude = 37.5665;
  static const double _defaultLongitude = 126.9780;

  HospitalRepositoryImpl({
    required AuthRepository authRepository,
    ApiClient? apiClient,
  }) : _authRepository = authRepository,
       _apiClient = apiClient ?? ApiClient();

  final AuthRepository _authRepository;
  final ApiClient _apiClient;

  @override
  Future<List<Hospital>> getHospitals({
    bool? isOpen,
    double? latitude,
    double? longitude,
  }) async {
    final location = await _resolveUserLocation(
      latitude: latitude,
      longitude: longitude,
    );

    _hospitalLog(
      '[HospitalRepo] getHospitals lat=${location.latitude} lng=${location.longitude}',
    );

    final response = await _getWithTokenRetry(
      path: ApiEndpoints.clinicMain,
      queryParameters: <String, dynamic>{
        'userLongitude': location.longitude,
        'userLatitude': location.latitude,
      },
    );

    final clinicMaps = _extractClinicMaps(response);
    final hospitals = clinicMaps.map(Hospital.fromJson).toList();
    if (isOpen == null) return hospitals;
    return hospitals.where((hospital) => hospital.isOpen == isOpen).toList();
  }

  @override
  Future<Hospital> getHospitalDetail({required int clinicId}) async {
    final path = ApiEndpoints.clinicDetail.replaceFirst(
      '{clinic_id}',
      '$clinicId',
    );
    _hospitalLog('[HospitalRepo] getHospitalDetail clinicId=$clinicId');

    final response = await _getWithTokenRetry(path: path);
    final detail = _extractClinicMap(response);
    if (detail == null) {
      throw Exception('병원 상세 응답 파싱에 실패했습니다. clinicId=$clinicId');
    }
    return Hospital.fromJson(detail);
  }

  Future<dynamic> _getWithTokenRetry({
    required String path,
    Map<String, dynamic>? queryParameters,
  }) async {
    final accessToken = await _authRepository.ensureServerAccessToken();

    try {
      return await _apiClient.get(
        path,
        queryParameters: queryParameters,
        headers: _authHeaders(accessToken),
      );
    } on DioException catch (e) {
      if (!_isAuthFailureStatus(e.response?.statusCode)) {
        rethrow;
      }

      final refreshedToken = await _authRepository.ensureServerAccessToken(
        forceRefresh: true,
      );
      if (refreshedToken == null || refreshedToken.isEmpty) {
        rethrow;
      }

      return _apiClient.get(
        path,
        queryParameters: queryParameters,
        headers: _authHeaders(refreshedToken),
      );
    }
  }

  Map<String, dynamic>? _authHeaders(String? accessToken) {
    if (accessToken == null || accessToken.trim().isEmpty) {
      return null;
    }

    return <String, dynamic>{
      'Authorization': 'Bearer $accessToken',
    };
  }

  bool _isAuthFailureStatus(int? statusCode) {
    return statusCode == 401 || statusCode == 403;
  }

  Future<_UserLocation> _resolveUserLocation({
    double? latitude,
    double? longitude,
  }) async {
    if (latitude != null && longitude != null) {
      return _UserLocation(latitude: latitude, longitude: longitude);
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const _UserLocation(
          latitude: _defaultLatitude,
          longitude: _defaultLongitude,
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return const _UserLocation(
          latitude: _defaultLatitude,
          longitude: _defaultLongitude,
        );
      }

      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        return _UserLocation(
          latitude: lastKnown.latitude,
          longitude: lastKnown.longitude,
        );
      }

      // 위치를 못 잡으면(시뮬레이터 위치 미설정, 실내 등) 무한 대기하므로 시간 제한을 둔다.
      // 시간 초과 시 아래 catch에서 기본 좌표로 대체된다.
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 5),
        ),
      );
      return _UserLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      return const _UserLocation(
        latitude: _defaultLatitude,
        longitude: _defaultLongitude,
      );
    }
  }

  List<Map<String, dynamic>> _extractClinicMaps(dynamic response) {
    if (response is List) {
      return response.whereType<Map<String, dynamic>>().toList();
    }
    if (response is Map<String, dynamic>) {
      if (_looksLikeClinicPayload(response)) {
        return [response];
      }

      const listKeys = <String>[
        'data',
        'items',
        'results',
        'result',
        'clinics',
        'clinicList',
        'content',
      ];
      for (final key in listKeys) {
        final value = response[key];
        if (value is List) {
          final list = value.whereType<Map<String, dynamic>>().toList();
          if (list.isNotEmpty) return list;
        }
      }

      const nestedKeys = <String>['data', 'result', 'clinic'];
      for (final key in nestedKeys) {
        final value = response[key];
        if (value is Map<String, dynamic>) {
          if (_looksLikeClinicPayload(value)) {
            return [value];
          }
        }
      }
    }
    return const <Map<String, dynamic>>[];
  }

  Map<String, dynamic>? _extractClinicMap(dynamic response) {
    if (response is Map<String, dynamic>) {
      if (_looksLikeClinicPayload(response)) {
        return response;
      }

      const nestedKeys = <String>['data', 'result', 'clinic'];
      for (final key in nestedKeys) {
        final value = response[key];
        if (value is Map<String, dynamic> && _looksLikeClinicPayload(value)) {
          return value;
        }
      }

      for (final value in response.values) {
        if (value is Map<String, dynamic> && _looksLikeClinicPayload(value)) {
          return value;
        }
      }
    }
    return null;
  }

  bool _looksLikeClinicPayload(Map<String, dynamic> value) {
    return value.containsKey('clinicId') ||
        value.containsKey('clinic_id') ||
        value.containsKey('name') ||
        value.containsKey('place_name');
  }

  void _hospitalLog(String message) {
    AppLogger.info(message);
  }
}

class _UserLocation {
  final double latitude;
  final double longitude;

  const _UserLocation({required this.latitude, required this.longitude});
}
