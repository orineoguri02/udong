import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/api-endpoints.dart';
import '../../../core/constants/app-constants.dart';
import '../../../core/utils/jwt-utils.dart';
import '../models/user.dart';
import '../models/user-profile.dart';
import 'auth-repository.dart';

mixin AuthRepositorySessionProfile on AuthRepositoryBase {
  @override
  Future<User?> getCurrentUser() async {
    final user = supabaseAuth.currentUser;

    SharedPreferences? prefs;
    var hasPendingOAuthLogin = false;
    try {
      prefs = await SharedPreferences.getInstance();
      hasPendingOAuthLogin =
          prefs.getBool(AuthPrefsKeys.pendingOAuthLogin) ?? false;
      if (hasPendingOAuthLogin) {
        await prefs.remove(AuthPrefsKeys.pendingOAuthLogin);
      }
    } catch (_) {}

    if (user == null) {
      await setPendingSignupUidSafely(null);
      return null;
    }

    // 웹 OAuth 리다이렉트에서 막 돌아온 경우: 로그인 후처리(신규 가입 판정 등)를 이어서 진행
    if (hasPendingOAuthLogin && !user.isAnonymous) {
      authLog('[AuthRepo][Social] OAuth 리다이렉트 복귀 감지 uid=${user.id}');
      try {
        return await completeSocialLogin(supabaseUser: user);
      } catch (e) {
        authLog('[AuthRepo][Social] OAuth 복귀 후처리 실패: $e');
        await resetLocalAuth();
        return null;
      }
    }

    int? serverId;
    String? accessToken;
    try {
      serverId = prefs?.getInt(authKeyServerId);
      final persistedPendingUid =
          prefs?.getString(authKeyPendingSignupUid)?.trim() ?? '';
      if (persistedPendingUid.isNotEmpty) {
        pendingSignupUid = persistedPendingUid;
      }
    } catch (_) {}

    final pendingUid = pendingSignupUid?.trim();
    final hasPendingUid = pendingUid != null && pendingUid.isNotEmpty;
    final localAccessTokenForPendingCheck = prefs?.getString(
      authKeyAccessToken,
    );
    final hasLocalServerSession =
        serverId != null &&
        localAccessTokenForPendingCheck != null &&
        localAccessTokenForPendingCheck.trim().isNotEmpty;
    if (hasPendingUid && pendingUid == user.id) {
      if (!hasLocalServerSession) {
        authLog(
          '[AuthRepo][Signup] 미완료 회원가입 세션 감지 '
          'uid=${user.id} -> 로컬 인증 상태 정리',
        );
        await _resetLocalAuthInternal();
        return null;
      }
      await setPendingSignupUidSafely(null);
    }
    if (hasPendingUid && pendingUid != user.id) {
      await setPendingSignupUidSafely(null);
    }

    if (user.isAnonymous) {
      final localAccessToken = prefs?.getString(authKeyAccessToken);
      final hasLocalAccess =
          localAccessToken != null && localAccessToken.trim().isNotEmpty;
      final isLocalExpired = isJwtExpired(localAccessToken);
      authLog(
        '[AuthRepo][Anonymous] getCurrentUser 익명 세션 감지 '
        'uid=${user.id} '
        'localServerId=$serverId '
        'hasLocalAccess=$hasLocalAccess '
        'isLocalExpired=$isLocalExpired',
      );
      if (serverId == null || !hasLocalAccess || isLocalExpired) {
        authLog(
          '[AuthRepo][Anonymous] 로컬 서버 세션 없음 -> 자동 익명 로그인 재시도하지 않고 세션 정리',
        );
        await resetLocalAuth();
        return null;
      }

      authLog(
        '[AuthRepo][Anonymous] getCurrentUser 반환 guest serverId=$serverId',
      );
      return User(
        id: 'guest',
        displayName: '게스트',
        email: null,
        serverId: serverId,
      );
    }

    final displayName = supabaseDisplayName(user) ?? '사용자';

    try {
      accessToken = await ensureServerAccessToken();
    } catch (_) {}

    if (serverId == null || accessToken == null || accessToken.isEmpty) {
      try {
        serverId = await syncServerSessionForCurrentUser(
          fallbackDisplayName: displayName,
          fallbackEmail: user.email,
        );
        accessToken = await ensureServerAccessToken();
      } catch (_) {
        await resetLocalAuth();
        return null;
      }
    }

    return User(
      id: user.id,
      displayName: displayName,
      email: user.email,
      serverId: serverId,
    );
  }

  @override
  Future<void> resetLocalAuth() async {
    await _resetLocalAuthInternal();
  }

  @override
  Future<void> cancelSignup() async {
    await _resetLocalAuthInternal();
  }

  Future<void> _resetLocalAuthInternal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(authKeyServerId);
      await prefs.remove(authKeyAccessToken);
      await prefs.remove(authKeyRefreshToken);
      await prefs.remove(authKeyPendingSignupUid);
      await prefs.remove(AuthPrefsKeys.pendingOAuthLogin);
    } catch (_) {}
    pendingSignupUid = null;

    await signOutGoogleSafely();
    await signOutSupabaseSafely();

    clearPending();
  }

  @override
  Future<UserProfile> fetchProfile({required String userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final serverId = prefs.getInt(authKeyServerId);
    final numericUserId = int.tryParse(userId);
    final idForPath = serverId ?? numericUserId;
    final serverAccessToken = await ensureServerAccessToken();

    if (idForPath == null) {
      throw Exception('프로필 조회에 필요한 serverId가 없습니다.');
    }
    if (serverAccessToken == null || serverAccessToken.isEmpty) {
      throw Exception('프로필 조회에 필요한 백엔드 accessToken이 없습니다.');
    }

    final path = ApiEndpoints.profile.replaceFirst(
      '{user_id}',
      idForPath.toString(),
    );
    dynamic response;
    var tokenForRequest = serverAccessToken;
    try {
      response = await apiClient.get(
        path,
        headers: _profileHeaders(serverAccessToken: tokenForRequest),
      );
    } on DioException catch (e) {
      if (!_isAuthFailureStatus(e.response?.statusCode)) rethrow;
      final refreshedToken = await ensureServerAccessToken(forceRefresh: true);
      if (refreshedToken == null || refreshedToken.isEmpty) rethrow;
      tokenForRequest = refreshedToken;
      response = await apiClient.get(
        path,
        headers: _profileHeaders(serverAccessToken: tokenForRequest),
      );
    }

    if (response is! Map<String, dynamic>) {
      throw Exception('프로필 조회 응답 형식이 올바르지 않습니다.');
    }
    return UserProfile.fromJson(response);
  }

  @override
  Future<UserProfile> updateProfileName({
    required int userId,
    required String name,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final serverId = prefs.getInt(authKeyServerId);
    final idForPath = serverId ?? userId;
    final serverAccessToken = await ensureServerAccessToken();
    if (serverAccessToken == null || serverAccessToken.isEmpty) {
      throw Exception('프로필 수정에 필요한 백엔드 accessToken이 없습니다.');
    }

    final path = ApiEndpoints.profileEdit.replaceFirst(
      '{user_id}',
      idForPath.toString(),
    );
    final payload = <String, dynamic>{'id': idForPath, 'name': name};
    dynamic response;
    var tokenForRequest = serverAccessToken;
    try {
      response = await apiClient.patch(
        path,
        data: payload,
        headers: _profileHeaders(serverAccessToken: tokenForRequest),
      );
    } on DioException catch (e) {
      if (!_isAuthFailureStatus(e.response?.statusCode)) rethrow;
      final refreshedToken = await ensureServerAccessToken(forceRefresh: true);
      if (refreshedToken == null || refreshedToken.isEmpty) rethrow;
      tokenForRequest = refreshedToken;
      response = await apiClient.patch(
        path,
        data: payload,
        headers: _profileHeaders(serverAccessToken: tokenForRequest),
      );
    }

    if (response is! Map<String, dynamic>) {
      throw Exception('프로필 수정 응답 형식이 올바르지 않습니다.');
    }
    return UserProfile.fromJson(response);
  }

  Map<String, dynamic> _profileHeaders({required String serverAccessToken}) {
    return <String, dynamic>{'Authorization': 'Bearer $serverAccessToken'};
  }

  bool _isAuthFailureStatus(int? statusCode) {
    return statusCode == 401 || statusCode == 403;
  }
}
