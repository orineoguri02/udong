import '../models/user.dart';
import '../models/user-profile.dart';

sealed class AuthState {
  const AuthState();
}

final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthLoading extends AuthState {
  const AuthLoading();
}

final class AuthAuthenticated extends AuthState {
  final User user;
  final UserProfile? profile;

  /// 로그아웃 실패 시 표시할 일회성 오류 메시지.
  /// 프로필 로딩/수정과 무관한 인증 도메인 전용 필드.
  final String? logoutError;

  const AuthAuthenticated(this.user, {this.profile, this.logoutError});

  static const Object _noChange = Object();

  AuthAuthenticated copyWith({
    User? user,
    Object? profile = _noChange,
    Object? logoutError = _noChange,
  }) {
    return AuthAuthenticated(
      user ?? this.user,
      profile: profile == _noChange ? this.profile : profile as UserProfile?,
      logoutError: logoutError == _noChange
          ? this.logoutError
          : logoutError as String?,
    );
  }
}

/// 인증되지 않은 상태 → 로그인 화면
final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// 게스트 모드 진입 안내 화면
final class AuthGuest extends AuthState {
  const AuthGuest();
}

final class AuthFailure extends AuthState {
  final String message;
  const AuthFailure(this.message);
}

/* ===== Signup Flow ===== */

sealed class SignupState extends AuthState {
  const SignupState();
}

/// 회원가입 1단계: 약관 동의
final class SignupTerms extends SignupState {
  const SignupTerms();
}

/// 회원가입 2단계: 닉네임 입력
final class SignupNickname extends SignupState {
  final bool marketingAgreed;
  const SignupNickname(this.marketingAgreed);
}

/// 회원가입 3단계: 반려동물 프로필 입력
final class SignupPetProfile extends SignupState {
  final String nickname;
  final bool marketingAgreed;
  const SignupPetProfile({
    required this.nickname,
    required this.marketingAgreed,
  });
}
