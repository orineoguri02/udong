import 'package:dio/dio.dart';

import 'home-api-helpers.dart';
import 'home-auth-token-provider.dart';

Future<T> homeWithServerAccessTokenRetry<T>({
  required HomeAuthTokenProvider tokenProvider,
  required String missingTokenMessage,
  required Future<T> Function(String accessToken) request,
}) async {
  final ensuredToken = await tokenProvider.ensureServerAccessToken();
  if (ensuredToken == null || ensuredToken.isEmpty) {
    throw Exception(missingTokenMessage);
  }

  try {
    return await request(ensuredToken);
  } on DioException catch (e) {
    if (!homeIsAuthFailureStatus(e.response?.statusCode)) {
      rethrow;
    }
    final refreshed = await tokenProvider.ensureServerAccessToken(
      forceRefresh: true,
    );
    if (refreshed == null || refreshed.isEmpty) {
      rethrow;
    }
    return request(refreshed);
  }
}
