import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../../../core/api/api-client.dart';
import '../../../core/api/api-endpoints.dart';
import '../../../core/constants/app-constants.dart';
import '../../../core/utils/app-logger.dart';
import '../../../core/utils/jwt-utils.dart';
import '../models/signup-pet-data.dart';
import '../models/user.dart';
import '../models/user-profile.dart';
import 'auth-repository-account.dart';
import 'auth-repository-session-profile.dart';
import 'auth-repository-social-signup.dart';

/// 하위 호환을 위한 별칭. 새 코드는 [AuthPrefsKeys]를 직접 사용한다.
const String authKeyServerId = AuthPrefsKeys.serverId;
const String authKeyAccessToken = AuthPrefsKeys.accessToken;
const String authKeyRefreshToken = AuthPrefsKeys.refreshToken;
const String authKeyPendingSignupUid = AuthPrefsKeys.pendingSignupUid;

/// Bloc 등에서 의존하는 인증 레포지토리 인터페이스
abstract class AuthRepository {
  Future<User?> getCurrentUser();

  Future<UserProfile> fetchProfile({required String userId});

  Future<UserProfile> updateProfileName({
    required int userId,
    required String name,
  });

  Future<void> resetLocalAuth();

  Future<User> login({required String email, required String password});

  Future<User> loginAnonymously();

  Future<User> loginWithGoogle();

  Future<User> completeSignup({
    String? nickname,
    SignupPetData? pet,
    String? petImagePath,
    bool marketingAgreed = false,
  });

  Future<void> cancelSignup();

  Future<void> logout();

  Future<void> deleteAccount({int? serverId});

  Future<String?> ensureServerAccessToken({bool forceRefresh = false});
}

abstract class AuthRepositoryBase implements AuthRepository {
  ApiClient get apiClient;
  GoogleSignIn get googleSignIn;
  supa.GoTrueClient get supabaseAuth;

  String? get pendingDisplayName;
  set pendingDisplayName(String? value);

  String? get pendingEmail;
  set pendingEmail(String? value);

  /// 회원가입(약관→닉네임→펫) 진행 중인 Supabase 사용자 id
  String? get pendingSignupUid;
  set pendingSignupUid(String? value);

  Future<void> setPendingSignupUidSafely(String? value) async {
    final normalized = value?.trim();
    pendingSignupUid = (normalized == null || normalized.isEmpty)
        ? null
        : normalized;

    try {
      final prefs = await SharedPreferences.getInstance();
      if (pendingSignupUid == null) {
        await prefs.remove(authKeyPendingSignupUid);
      } else {
        await prefs.setString(authKeyPendingSignupUid, pendingSignupUid!);
      }
    } catch (_) {}
  }

  /// 웹은 google_sign_in 대신 Supabase OAuth 리다이렉트로 로그인하므로 건너뛴다.
  Future<void> signOutGoogleSafely() async {
    if (kIsWeb) return;
    try {
      await googleSignIn.signOut();
    } catch (_) {}
  }

  Future<void> signOutSupabaseSafely() async {
    try {
      await supabaseAuth.signOut(scope: supa.SignOutScope.local);
    } catch (_) {}
  }

  /// 백엔드 Authorization 헤더에 넣을 Supabase access token(JWT).
  Future<String> getSupabaseAccessToken({bool forceRefresh = false}) async {
    var session = supabaseAuth.currentSession;
    if (session == null) {
      throw Exception('Supabase 로그인 세션이 없습니다.');
    }
    if (forceRefresh || session.isExpired) {
      final refreshed = await supabaseAuth.refreshSession();
      session = refreshed.session ?? session;
    }
    final token = session.accessToken;
    if (token.isEmpty) {
      throw Exception('Supabase access token을 가져오지 못했습니다.');
    }
    return token;
  }

  /// Supabase 로그인 직후 공통 후처리 ([AuthRepositorySocialSignup]에서 구현).
  Future<User> completeSocialLogin({
    required supa.User supabaseUser,
    String? displayName,
    String? email,
  });

  @override
  Future<String?> ensureServerAccessToken({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final currentAccessToken = prefs.getString(authKeyAccessToken);
    final hasToken =
        currentAccessToken != null && currentAccessToken.trim().isNotEmpty;
    final isExpired = isJwtExpired(currentAccessToken);

    if (!forceRefresh && hasToken && !isExpired) {
      authLog(
        '[AuthRepo] 기존 accessToken 사용 '
        'token=${previewToken(currentAccessToken)}',
      );
      return currentAccessToken;
    }

    authLog(
      '[AuthRepo] 서버 accessToken 재동기화 시도 '
      'forceRefresh=$forceRefresh '
      'hasToken=$hasToken '
      'isExpired=$isExpired',
    );
    final refreshed = await refreshServerSessionFromSupabase();
    if (refreshed != null && refreshed.isNotEmpty) {
      return refreshed;
    }

    if (hasToken) {
      authLog(
        '[AuthRepo] 재동기화 실패로 기존 accessToken 유지 '
        'token=${previewToken(currentAccessToken)}',
      );
      return currentAccessToken;
    }
    return null;
  }

  Future<String?> refreshServerSessionFromSupabase() async {
    final supabaseUser = supabaseAuth.currentUser;
    if (supabaseUser == null) {
      authLog('[AuthRepo] Supabase 세션이 없어 서버 토큰 재동기화를 건너뜁니다.');
      return null;
    }

    try {
      if (supabaseUser.isAnonymous) {
        final supabaseAccessToken = await getSupabaseAccessToken(
          forceRefresh: true,
        );
        await loginAnonymousServerSession(
          supabaseAccessToken: supabaseAccessToken,
        );
      } else {
        await syncServerSessionForCurrentUser(
          fallbackDisplayName: pendingDisplayName ?? '사용자',
          fallbackEmail: pendingEmail,
        );
      }
    } catch (e) {
      authLog('[AuthRepo] 서버 세션 재동기화 실패: $e');
      return null;
    }

    final prefs = await SharedPreferences.getInstance();
    final refreshedAccessToken = prefs.getString(authKeyAccessToken);
    authLog(
      '[AuthRepo] 서버 accessToken 재동기화 결과 '
      'token=${previewToken(refreshedAccessToken)}',
    );
    return refreshedAccessToken;
  }

  Future<int> syncServerSessionForCurrentUser({
    required String fallbackDisplayName,
    String? fallbackEmail,
    bool marketingAgreed = false,
  }) async {
    final supabaseUser = supabaseAuth.currentUser;
    if (supabaseUser == null) {
      throw Exception('Supabase 로그인 세션이 없어 서버 세션을 동기화할 수 없습니다.');
    }

    final supabaseAccessToken = await getSupabaseAccessToken();
    final rawName = (supabaseDisplayName(supabaseUser) ?? fallbackDisplayName)
        .trim();
    final effectiveDisplayName = rawName.isNotEmpty ? rawName : '사용자';
    final effectiveEmail = (supabaseUser.email ?? fallbackEmail ?? '').trim();

    final userBody = <String, dynamic>{
      'name': effectiveDisplayName,
      'nickname': effectiveDisplayName,
      'photo': null,
      'email': effectiveEmail,
      // 백엔드 DB의 date 컬럼은 빈 문자열("")을 거부하므로 값이 없으면 null로 보낸다.
      'gender': null,
      'birthday': null,
      'marketing': marketingAgreed,
    };

    dynamic response;
    try {
      response = await apiClient.post(
        ApiEndpoints.signupUser,
        data: userBody,
        headers: <String, dynamic>{
          'Authorization': 'Bearer $supabaseAccessToken',
        },
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      authLog(
        '[AuthRepo] ${ApiEndpoints.signupUser} 실패 '
        'status=$status data=$data body=$userBody',
      );
      final serverMessage = data is Map ? data['message'] : data;
      throw Exception('서버 세션 동기화 실패($status): $serverMessage');
    }

    final serverId = parseServerId(response);
    final accessToken = parseStringField(response, 'accessToken');
    final refreshToken = parseStringField(response, 'refreshToken');
    if (serverId == null ||
        accessToken == null ||
        accessToken.isEmpty ||
        refreshToken == null ||
        refreshToken.isEmpty) {
      throw Exception('서버 세션 동기화 실패: 응답에 인증 토큰이 없습니다.');
    }

    await saveServerSession(
      serverId: serverId,
      accessToken: accessToken,
      refreshToken: refreshToken,
      context: 'syncServerSessionForCurrentUser',
    );
    return serverId;
  }

  Future<int?> loginAnonymousServerSession({
    required String supabaseAccessToken,
  }) async {
    authLog(
      '[AuthRepo][Anonymous] 백엔드 익명 로그인 시도 '
      'path=${ApiEndpoints.anonymousLogin} '
      'supabaseAccessToken=${previewToken(supabaseAccessToken)}',
    );

    dynamic response;
    try {
      response = await apiClient.post(
        ApiEndpoints.anonymousLogin,
        headers: <String, dynamic>{
          'Authorization': 'Bearer $supabaseAccessToken',
        },
      );
    } on DioException catch (e) {
      authLog(
        '[AuthRepo][Anonymous] 백엔드 익명 로그인 실패 '
        'status=${e.response?.statusCode} '
        'data=${e.response?.data}',
      );
      rethrow;
    }

    final serverId = parseServerId(response);
    final accessToken = parseStringField(response, 'accessToken');
    final refreshToken = parseStringField(response, 'refreshToken');
    authLog(
      '[AuthRepo][Anonymous] 백엔드 익명 로그인 응답 '
      'serverId=$serverId '
      'accessToken=${previewToken(accessToken)} '
      'refreshToken=${previewToken(refreshToken)} '
      'keys=${responseKeys(response)}',
    );

    if (serverId == null ||
        accessToken == null ||
        accessToken.isEmpty ||
        refreshToken == null ||
        refreshToken.isEmpty) {
      throw Exception('익명 로그인 응답에 인증 정보가 누락되었습니다.');
    }

    await saveServerSession(
      serverId: serverId,
      accessToken: accessToken,
      refreshToken: refreshToken,
      context: 'loginAnonymousServerSession',
    );
    authLog('[AuthRepo][Anonymous] 익명 로그인 세션 저장 완료 serverId=$serverId');
    return serverId;
  }

  Future<void> saveServerSession({
    required int serverId,
    required String accessToken,
    required String refreshToken,
    required String context,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(authKeyServerId, serverId);
    await prefs.setString(authKeyAccessToken, accessToken);
    await prefs.setString(authKeyRefreshToken, refreshToken);
    authLogJwtToken(context: context, accessToken: accessToken);
  }

  void clearPending() {
    pendingDisplayName = null;
    pendingEmail = null;
  }
}

class AuthRepositoryImpl extends AuthRepositoryBase
    with
        AuthRepositorySessionProfile,
        AuthRepositorySocialSignup,
        AuthRepositoryAccount {
  AuthRepositoryImpl({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;
  // 웹에서는 생성자가 곧바로 초기화를 시도하며 에러를 던지므로, 실제 사용 시점까지 미룬다.
  // serverClientId(웹 클라이언트 ID)를 넘겨야 Android에서 idToken이 발급되고,
  // idToken의 aud가 Supabase Google provider에 등록한 클라이언트 ID와 일치한다.
  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email', 'profile'],
    serverClientId: _nonEmpty(dotenv.env['GOOGLE_WEB_CLIENT_ID']),
  );

  String? _pendingDisplayName;
  String? _pendingEmail;
  String? _pendingSignupUid;

  @override
  ApiClient get apiClient => _apiClient;

  @override
  GoogleSignIn get googleSignIn => _googleSignIn;

  @override
  supa.GoTrueClient get supabaseAuth => supa.Supabase.instance.client.auth;

  @override
  String? get pendingDisplayName => _pendingDisplayName;

  @override
  set pendingDisplayName(String? value) {
    _pendingDisplayName = value;
  }

  @override
  String? get pendingEmail => _pendingEmail;

  @override
  set pendingEmail(String? value) {
    _pendingEmail = value;
  }

  @override
  String? get pendingSignupUid => _pendingSignupUid;

  @override
  set pendingSignupUid(String? value) {
    _pendingSignupUid = value;
  }
}

String? _nonEmpty(String? value) {
  final trimmed = value?.trim();
  return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
}

/// Google 로그인 시 Supabase가 user_metadata에 저장하는 이름.
String? supabaseDisplayName(supa.User user) {
  final metadata = user.userMetadata;
  if (metadata == null) return null;
  for (final key in const ['nickname', 'full_name', 'name']) {
    final value = metadata[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
  }
  return null;
}

/// 가입 직후 첫 로그인인지 판정한다. (created_at ≈ last_sign_in_at)
bool isFirstSupabaseSignIn(supa.User user) {
  final createdAt = DateTime.tryParse(user.createdAt);
  final lastSignInAt = DateTime.tryParse(user.lastSignInAt ?? '');
  if (createdAt == null || lastSignInAt == null) return false;
  return lastSignInAt.difference(createdAt).inSeconds.abs() <= 5;
}

int? parseServerId(dynamic response) {
  if (response is! Map<String, dynamic>) return null;
  final id =
      response['id'] ?? response['data']?['id'] ?? response['user']?['id'];
  if (id is int) return id;
  if (id is num) return id.toInt();
  return null;
}

String? parseStringField(dynamic response, String key) {
  if (response is! Map<String, dynamic>) return null;
  final value = response[key];
  if (value is String && value.isNotEmpty) return value;

  final dataValue = response['data']?[key];
  if (dataValue is String && dataValue.isNotEmpty) return dataValue;

  final userValue = response['user']?[key];
  if (userValue is String && userValue.isNotEmpty) return userValue;

  final tokenValue = response['tokens']?[key];
  if (tokenValue is String && tokenValue.isNotEmpty) return tokenValue;

  return null;
}

void authLog(String message) {
  AppLogger.info(message);
}

void authLogJwtToken({required String context, required String? accessToken}) {
  if (accessToken == null || accessToken.isEmpty) return;
  authLog(
    '[AuthRepo] JWT token context=$context token=${previewToken(accessToken)}',
  );
}

String previewToken(String? token) {
  if (token == null || token.isEmpty) return '(empty)';
  final trimmed = token.trim();
  final preview = trimmed.length > 8 ? '${trimmed.substring(0, 8)}***' : '***';
  return '$preview(len=${trimmed.length})';
}

String responseKeys(dynamic response) {
  if (response is Map) {
    return response.keys.map((e) => e.toString()).toList().join(', ');
  }
  return response.runtimeType.toString();
}
