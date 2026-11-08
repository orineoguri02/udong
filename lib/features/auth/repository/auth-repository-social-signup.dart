import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../../../core/api/api-endpoints.dart';
import '../../../core/constants/app-constants.dart';
import '../../../core/utils/image-compress.dart';
import '../models/signup-pet-data.dart';
import '../models/user.dart';
import 'auth-repository.dart';

mixin AuthRepositorySocialSignup on AuthRepositoryBase {
  @override
  Future<User> login({required String email, required String password}) {
    throw UnimplementedError();
  }

  @override
  Future<User> loginAnonymously() async {
    await setPendingSignupUidSafely(null);
    authLog(
      '[AuthRepo][Anonymous] Supabase 익명 로그인 시작 '
      'currentUid=${supabaseAuth.currentUser?.id} '
      'currentIsAnonymous=${supabaseAuth.currentUser?.isAnonymous}',
    );
    try {
      final authResponse = await supabaseAuth.signInAnonymously();
      final supabaseUser = authResponse.user;
      final supabaseAccessToken = authResponse.session?.accessToken;
      if (supabaseUser == null ||
          supabaseAccessToken == null ||
          supabaseAccessToken.isEmpty) {
        throw Exception('익명 로그인에 실패했습니다.');
      }

      authLog(
        '[AuthRepo][Anonymous] Supabase 익명 로그인 성공 '
        'uid=${supabaseUser.id} '
        'token=${previewToken(supabaseAccessToken)}',
      );

      final serverId = await loginAnonymousServerSession(
        supabaseAccessToken: supabaseAccessToken,
      );
      clearPending();

      authLog(
        '[AuthRepo][Anonymous] 익명 로그인 최종 성공 '
        'guestId=guest serverId=$serverId',
      );
      return User(
        id: 'guest',
        displayName: '게스트',
        email: null,
        serverId: serverId,
      );
    } catch (e, st) {
      authLog('[AuthRepo][Anonymous] 익명 로그인 실패: $e');
      authLog('[AuthRepo][Anonymous] stack: $st');
      rethrow;
    }
  }

  @override
  Future<User> loginWithGoogle() async {
    await setPendingSignupUidSafely(null);
    if (kIsWeb) return _loginWithGoogleOnWeb();

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('구글 로그인이 취소되었습니다.');
    }

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw Exception('구글 ID Token을 가져오지 못했습니다. (GOOGLE_WEB_CLIENT_ID 확인)');
    }

    final authResponse = await supabaseAuth.signInWithIdToken(
      provider: supa.OAuthProvider.google,
      idToken: idToken,
      accessToken: googleAuth.accessToken,
    );
    final supabaseUser = authResponse.user;
    if (supabaseUser == null) {
      throw Exception('구글 로그인에 실패했습니다.');
    }

    return completeSocialLogin(
      supabaseUser: supabaseUser,
      displayName: googleUser.displayName,
      email: googleUser.email,
    );
  }

  /// 웹: Supabase OAuth로 같은 탭에서 구글 로그인 페이지로 이동한다.
  /// 돌아오면 앱이 새로 시작되고 `getCurrentUser()`가 [completeSocialLogin]을 이어서 처리한다.
  Future<User> _loginWithGoogleOnWeb() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AuthPrefsKeys.pendingOAuthLogin, true);

    final launched = await supabaseAuth.signInWithOAuth(
      supa.OAuthProvider.google,
      redirectTo: '${Uri.base.origin}${Uri.base.path}',
    );
    if (!launched) {
      await prefs.remove(AuthPrefsKeys.pendingOAuthLogin);
      throw Exception('구글 로그인 페이지를 열지 못했습니다.');
    }

    // 정상이라면 페이지가 이동하므로 아래는 완료되지 않는다.
    // (뒤로가기로 돌아온 경우 등) 일정 시간 안에 로그인되지 않으면 취소로 처리한다.
    try {
      final authState = await supabaseAuth.onAuthStateChange
          .firstWhere((state) => state.event == supa.AuthChangeEvent.signedIn)
          .timeout(const Duration(minutes: 2));
      await prefs.remove(AuthPrefsKeys.pendingOAuthLogin);
      final supabaseUser = authState.session?.user;
      if (supabaseUser == null) {
        throw Exception('구글 로그인에 실패했습니다.');
      }
      return await completeSocialLogin(supabaseUser: supabaseUser);
    } on TimeoutException {
      await prefs.remove(AuthPrefsKeys.pendingOAuthLogin);
      throw Exception('구글 로그인이 취소되었습니다.');
    }
  }

  Future<(int?, String?)> _readLocalServerSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return (
        prefs.getInt(authKeyServerId),
        prefs.getString(authKeyAccessToken),
      );
    } catch (_) {
      return (null, null);
    }
  }

  /// Supabase 로그인 직후 공통 후처리.
  /// - 첫 로그인 → 회원가입 플로우(isNewUser=true)
  /// - 기존 회원 → 백엔드 세션 동기화
  @override
  Future<User> completeSocialLogin({
    required supa.User supabaseUser,
    String? displayName,
    String? email,
  }) async {
    final resolvedDisplayName =
        displayName ?? supabaseDisplayName(supabaseUser) ?? '구글 사용자';
    final resolvedEmail = email ?? supabaseUser.email;
    pendingDisplayName = resolvedDisplayName;
    pendingEmail = resolvedEmail;

    final isNewUser = isFirstSupabaseSignIn(supabaseUser);
    authLog(
      '[AuthRepo][Social] Supabase 로그인 완료 '
      'uid=${supabaseUser.id} '
      'createdAt=${supabaseUser.createdAt} '
      'lastSignInAt=${supabaseUser.lastSignInAt} '
      'isNewUser=$isNewUser',
    );

    if (isNewUser) {
      await setPendingSignupUidSafely(supabaseUser.id);
      return User(
        id: supabaseUser.id,
        displayName: resolvedDisplayName,
        email: resolvedEmail,
        isNewUser: true,
      );
    }

    await setPendingSignupUidSafely(null);
    final resolvedServerId = await _resolveServerSessionForLogin(
      fallbackDisplayName: resolvedDisplayName,
      fallbackEmail: resolvedEmail,
    );
    clearPending();

    return User(
      id: supabaseUser.id,
      displayName: resolvedDisplayName,
      email: resolvedEmail,
      isNewUser: false,
      serverId: resolvedServerId,
    );
  }

  @override
  Future<User> completeSignup({
    String? nickname,
    SignupPetData? pet,
    String? petImagePath,
    bool marketingAgreed = false,
  }) async {
    final displayName = (nickname != null && nickname.trim().isNotEmpty)
        ? nickname.trim()
        : (pendingDisplayName ?? '사용자');
    final supabaseUser = supabaseAuth.currentUser;
    if (supabaseUser == null) {
      throw Exception('회원가입 인증 정보가 없습니다. 다시 로그인한 뒤 시도해 주세요.');
    }

    authLog(
      '[AuthRepo][Signup] 회원가입 요청 시작 '
      'uid=${supabaseUser.id} '
      'petProvided=${pet != null}',
    );

    final supabaseAccessToken = await getSupabaseAccessToken();
    final authHeaders = <String, dynamic>{
      'Authorization': 'Bearer $supabaseAccessToken',
    };
    final email = pendingEmail ?? supabaseUser.email ?? '';

    try {
      dynamic signupResponse;
      if (pet != null) {
        final joinedData = <String, dynamic>{
          'userRequest': <String, dynamic>{
            'name': displayName,
            'nickname': displayName,
            'email': email,
            'marketing': marketingAgreed,
          },
          'petRequest': pet.toJson(),
        };

        final formData = FormData.fromMap({
          'joinedData': MultipartFile.fromString(
            jsonEncode(joinedData),
            contentType: MediaType('application', 'json'),
          ),
          if (petImagePath != null)
            'photo': await _compressedMultipartFile(petImagePath),
        });

        try {
          signupResponse = await apiClient.postMultipart(
            ApiEndpoints.signupUserAndPet,
            data: formData,
            headers: authHeaders,
          );
        } on DioException catch (e) {
          if (e.response?.statusCode != 500) rethrow;
          signupResponse = await apiClient.post(
            ApiEndpoints.signupUser,
            data: <String, dynamic>{
              'name': displayName,
              'nickname': displayName,
              'photo': null,
              'email': email,
              'gender': null,
              'birthday': _todayDateString(),
              'marketing': marketingAgreed,
            },
            headers: authHeaders,
          );
        }
      } else {
        authLog(
          '[AuthRepo][Signup] pet 미입력 경로 → ${ApiEndpoints.signupUser} POST',
        );
        signupResponse = await apiClient.post(
          ApiEndpoints.signupUser,
          data: <String, dynamic>{'name': displayName},
          headers: authHeaders,
        );
      }

      final serverId = parseServerId(signupResponse);
      final accessToken = parseStringField(signupResponse, 'accessToken');
      final refreshToken = parseStringField(signupResponse, 'refreshToken');
      if (serverId == null ||
          accessToken == null ||
          accessToken.isEmpty ||
          refreshToken == null ||
          refreshToken.isEmpty) {
        throw Exception('회원가입 응답에 인증 정보가 누락되었습니다.');
      }

      try {
        await supabaseAuth.updateUser(
          supa.UserAttributes(data: <String, dynamic>{'nickname': displayName}),
        );
      } catch (_) {}

      try {
        await saveServerSession(
          serverId: serverId,
          accessToken: accessToken,
          refreshToken: refreshToken,
          context: 'completeSignup',
        );
      } catch (_) {}

      await setPendingSignupUidSafely(null);
      clearPending();

      return User(
        id: supabaseUser.id,
        displayName: displayName,
        email: supabaseUser.email,
        isNewUser: false,
        serverId: serverId,
      );
    } catch (e) {
      await setPendingSignupUidSafely(null);
      clearPending();
      rethrow;
    }
  }

  Future<MultipartFile> _compressedMultipartFile(String imagePath) async {
    final compressed = await compressImageToWebp(imagePath);

    if (compressed != null) {
      return MultipartFile.fromBytes(
        compressed,
        filename: '${_basenameWithoutExtension(imagePath)}.webp',
        contentType: MediaType('image', 'webp'),
      );
    }

    throw Exception('이미지를 WebP로 변환하지 못했습니다.');
  }

  String _basenameWithoutExtension(String rawPath) {
    final normalized = rawPath.replaceAll('\\', '/');
    final withoutQuery = normalized.split('?').first;
    final filename = withoutQuery.split('/').last.trim();
    if (filename.isEmpty) return 'photo';
    final dotIndex = filename.lastIndexOf('.');
    if (dotIndex <= 0) return filename;
    return filename.substring(0, dotIndex);
  }

  Future<int?> _resolveServerSessionForLogin({
    required String fallbackDisplayName,
    required String? fallbackEmail,
  }) async {
    final (serverId, accessToken) = await _readLocalServerSession();
    final hasLocalSession =
        serverId != null && accessToken != null && accessToken.isNotEmpty;
    if (hasLocalSession) {
      return serverId;
    }

    await syncServerSessionForCurrentUser(
      fallbackDisplayName: fallbackDisplayName,
      fallbackEmail: fallbackEmail,
    );
    final (storedServerId, storedAccessToken) = await _readLocalServerSession();
    final hasStoredSession =
        storedServerId != null &&
        storedAccessToken != null &&
        storedAccessToken.isNotEmpty;
    if (!hasStoredSession) {
      throw Exception('로그인 후 서버 accessToken 저장에 실패했습니다.');
    }
    return storedServerId;
  }

  String _todayDateString() {
    final now = DateTime.now();
    final year = now.year.toString().padLeft(4, '0');
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
