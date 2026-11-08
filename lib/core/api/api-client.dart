/// API 통신을 담당하는 클라이언트(HTTP 래퍼) 파일입니다.
/// - 역할: 공통 헤더, 타임아웃, GET 등 네트워크 정책 관리
/// - Dio 기반

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiClient {
  ApiClient({String? baseUrl})
    : _dio = _createDio(
        _normalizeBaseUrl(baseUrl ?? dotenv.env['API_BASE_URL'] ?? ''),
      );

  final Dio _dio;

  /// TLS 오류를 줄이기 위해 baseUrl의 스킴/포트를 정규화한다.
  static String _normalizeBaseUrl(String url) {
    var u = url.trim();
    if (u.isEmpty) return u;

    // .env에서 따옴표로 감싼 경우 정리
    if ((u.startsWith('"') && u.endsWith('"')) ||
        (u.startsWith("'") && u.endsWith("'"))) {
      u = u.substring(1, u.length - 1).trim();
    }
    if (u.isEmpty) return u;

    if (!u.contains('://')) {
      u = 'https://$u';
    } else if (u.toLowerCase().startsWith('http://')) {
      u = 'https://${u.substring(7)}';
    }

    final parsed = Uri.tryParse(u);
    if (parsed == null) return u;

    // https에 80 포트가 지정되면 일부 서버가 400(TLS 필요)로 응답할 수 있어 제거
    final normalizedPort =
        (parsed.scheme.toLowerCase() == 'https' &&
            parsed.hasPort &&
            parsed.port == 80)
        ? null
        : (parsed.hasPort ? parsed.port : null);

    return parsed.replace(port: normalizedPort).toString();
  }

  static String _normalizePath(String path) {
    final p = path.trim();
    if (p.toLowerCase().startsWith('http://')) {
      return 'https://${p.substring(7)}';
    }
    return p;
  }

  static Map<String, dynamic> _withoutContentType(
    Map<String, dynamic> headers,
  ) {
    final sanitized = <String, dynamic>{...headers};
    final keys = sanitized.keys
        .where((key) => key.toLowerCase() == 'content-type')
        .toList();
    for (final key in keys) {
      sanitized.remove(key);
    }
    return sanitized;
  }

  static Dio _createDio(String baseUrl) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    return dio;
  }

  /// GET 요청 후 JSON 파싱
  /// [path] 예: '/hospitals.json' 또는 'hospitals.json'
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    final normalizedPath = _normalizePath(path);
    final mergedHeaders = headers != null
        ? <String, dynamic>{..._dio.options.headers, ...headers}
        : null;
    final options = mergedHeaders != null
        ? Options(headers: mergedHeaders)
        : null;
    try {
      final response = await _dio.get<dynamic>(
        normalizedPath,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException {
      rethrow;
    }
  }

  /// POST 요청 (JSON body)
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? headers,
  }) async {
    final normalizedPath = _normalizePath(path);
    final mergedHeaders = <String, dynamic>{
      ..._dio.options.headers,
      if (headers != null) ...headers,
    };

    try {
      final response = await _dio.post<dynamic>(
        normalizedPath,
        data: data,
        options: Options(headers: mergedHeaders),
      );
      return response.data;
    } on DioException {
      rethrow;
    }
  }

  /// DELETE 요청
  Future<dynamic> delete(String path, {Map<String, dynamic>? headers}) async {
    final normalizedPath = _normalizePath(path);
    final mergedHeaders = <String, dynamic>{
      ..._dio.options.headers,
      if (headers != null) ...headers,
    };

    try {
      final response = await _dio.delete<dynamic>(
        normalizedPath,
        options: Options(headers: mergedHeaders),
      );
      return response.data;
    } on DioException {
      rethrow;
    }
  }

  /// PATCH 요청 (JSON body)
  Future<dynamic> patch(
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? headers,
  }) async {
    final normalizedPath = _normalizePath(path);
    final mergedHeaders = <String, dynamic>{
      ..._dio.options.headers,
      if (headers != null) ...headers,
    };

    try {
      final response = await _dio.patch<dynamic>(
        normalizedPath,
        data: data,
        options: Options(headers: mergedHeaders),
      );
      return response.data;
    } on DioException {
      rethrow;
    }
  }

  /// POST 요청 (multipart/form-data)
  /// - joinedData 같은 JSON 문자열 + 파일 업로드 등에 사용
  Future<dynamic> postMultipart(
    String path, {
    required FormData data,
    Map<String, dynamic>? headers,
  }) async {
    final normalizedPath = _normalizePath(path);
    // multipart에서는 Content-Type을 수동 지정하지 않고 Dio가 boundary를 포함해 자동 생성하게 둔다.
    final baseHeaders = _withoutContentType(
      Map<String, dynamic>.from(_dio.options.headers),
    );
    final requestHeaders = headers != null
        ? _withoutContentType(<String, dynamic>{...headers})
        : const <String, dynamic>{};

    final mergedHeaders = <String, dynamic>{...baseHeaders, ...requestHeaders};

    try {
      final response = await _dio.post<dynamic>(
        normalizedPath,
        data: data,
        options: Options(
          headers: mergedHeaders,
          contentType: Headers.multipartFormDataContentType,
        ),
      );
      return response.data;
    } on DioException {
      rethrow;
    }
  }

  /// PATCH 요청 (multipart/form-data)
  Future<dynamic> patchMultipart(
    String path, {
    required FormData data,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? queryParameters,
  }) async {
    final normalizedPath = _normalizePath(path);
    final baseHeaders = _withoutContentType(
      Map<String, dynamic>.from(_dio.options.headers),
    );
    final requestHeaders = headers != null
        ? _withoutContentType(<String, dynamic>{...headers})
        : const <String, dynamic>{};

    final mergedHeaders = <String, dynamic>{...baseHeaders, ...requestHeaders};

    try {
      final response = await _dio.patch<dynamic>(
        normalizedPath,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          headers: mergedHeaders,
          contentType: Headers.multipartFormDataContentType,
        ),
      );
      return response.data;
    } on DioException {
      rethrow;
    }
  }
}
