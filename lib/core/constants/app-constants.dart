/// 앱 전역 상수 모음 파일입니다.
///
/// - 역할: 문자열/숫자/플래그 등 하드코딩을 줄이고 한 곳에서 관리
/// - 주의: 환경별 값은 추후 `--dart-define` 또는 별도 config로 분리 권장

abstract final class AppConstants {
  static const appName = 'udon';

  /// 문의하기(구글폼) 링크
  /// - 민감정보가 아니면 상수로 관리합니다.
  /// - 운영/스테이징 분리가 필요해지면 `.env` 또는 `--dart-define`로 이동 권장
  static const inquiryFormUrl = 'https://forms.gle/hYVtP9aS4RFq698u5';
}

/// SharedPreferences에서 인증 토큰/세션 데이터를 저장할 때 쓰는 키 상수.
///
/// 여러 레이어(auth, hospital, home 위젯 등)가 동일 키를 직접 하드코딩하면
/// 한쪽 수정 시 키 불일치 버그가 발생할 수 있으므로 여기서 단일 관리한다.
abstract final class AuthPrefsKeys {
  static const serverId = 'auth_server_id';
  static const accessToken = 'auth_access_token';
  static const refreshToken = 'auth_refresh_token';
  static const pendingSignupUid = 'auth_pending_signup_uid';

  /// 웹 OAuth 리다이렉트 직전에 저장 → 복귀 후 로그인 후처리(신규 가입 판정) 실행
  static const pendingOAuthLogin = 'auth_pending_oauth_login';
}
