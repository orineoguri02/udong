import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/api-endpoints.dart';
import 'auth-repository.dart';

mixin AuthRepositoryAccount on AuthRepositoryBase {
  @override
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final serverAccessToken = prefs.getString(authKeyAccessToken);
    final refreshToken = prefs.getString(authKeyRefreshToken);
    String? supabaseAccessToken;
    try {
      supabaseAccessToken = await getSupabaseAccessToken();
    } catch (_) {}

    if (refreshToken == null || refreshToken.isEmpty) {
      throw Exception('저장된 refreshToken이 없어 백엔드 로그아웃을 완료할 수 없습니다.');
    }
    final normalizedRefreshToken =
        refreshToken.toLowerCase().startsWith('bearer ')
        ? refreshToken.substring(7).trim()
        : refreshToken;

    final headersCandidates = <Map<String, dynamic>>[
      if (serverAccessToken != null && serverAccessToken.isNotEmpty)
        <String, dynamic>{'Authorization': 'Bearer $serverAccessToken'},
      if (supabaseAccessToken != null)
        <String, dynamic>{'Authorization': 'Bearer $supabaseAccessToken'},
    ];

    for (var i = 0; i < headersCandidates.length; i++) {
      final headers = headersCandidates[i];
      try {
        await apiClient.post(
          ApiEndpoints.logout,
          data: <String, dynamic>{'refreshToken': normalizedRefreshToken},
          headers: headers,
        );
        break;
      } on DioException catch (e) {
        final statusCode = e.response?.statusCode;
        final hasNextAttempt = i < headersCandidates.length - 1;
        if (hasNextAttempt &&
            (statusCode == 400 ||
                statusCode == 401 ||
                statusCode == 403 ||
                statusCode == 415 ||
                statusCode == 422)) {
          continue;
        }
        if (statusCode != 400 &&
            statusCode != 401 &&
            statusCode != 403 &&
            statusCode != 415 &&
            statusCode != 422) {
          // 네트워크 오류 등 예상 밖 에러도 로컬은 항상 초기화
          break;
        }
      } catch (_) {
        break;
      }
    }

    // 백엔드 응답과 무관하게 로컬 상태는 항상 초기화
    await resetLocalAuth();
  }

  @override
  Future<void> deleteAccount({int? serverId}) async {
    if (supabaseAuth.currentUser == null) {
      throw Exception('로그인된 사용자가 없습니다.');
    }

    final prefs = await SharedPreferences.getInstance();
    final idForPath = serverId ?? prefs.getInt(authKeyServerId);
    final accessToken = prefs.getString(authKeyAccessToken);
    if (idForPath == null) {
      throw Exception('백엔드 사용자 ID(serverId)가 없어 회원탈퇴 요청을 보낼 수 없습니다.');
    }
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('백엔드 accessToken이 없어 회원탈퇴 요청을 보낼 수 없습니다.');
    }

    final path = ApiEndpoints.withdrawal.replaceFirst(
      '{user_id}',
      idForPath.toString(),
    );

    await apiClient.delete(
      path,
      headers: <String, dynamic>{'Authorization': 'Bearer $accessToken'},
    );

    // Supabase auth 사용자 삭제는 service_role 권한이 필요하므로 백엔드(회원탈퇴 API)에서 처리한다.
    try {
      await prefs.remove(authKeyServerId);
      await prefs.remove(authKeyAccessToken);
      await prefs.remove(authKeyRefreshToken);
    } catch (_) {}

    await signOutGoogleSafely();
    await signOutSupabaseSafely();
  }
}
