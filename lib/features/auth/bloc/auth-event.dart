import 'dart:async';

import '../models/signup-pet-data.dart';
import '../models/user-profile.dart';

sealed class AuthEvent {
  const AuthEvent();
}

/// 앱 시작 시 자동 로그인 여부 확인
final class AppStarted extends AuthEvent {
  const AppStarted();
}

final class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  const LoginRequested({required this.email, required this.password});
}

final class GoogleLoginRequested extends AuthEvent {
  const GoogleLoginRequested();
}

/// 로그인 화면에서 "게스트 로그인" 탭 → GuestPage로 이동
final class GuestRequested extends AuthEvent {
  const GuestRequested();
}

/// GuestPage에서 "게스트로 계속하기" 탭 → 홈으로 이동
final class GuestContinued extends AuthEvent {
  const GuestContinued();
}

/// 약관 동의 완료 → NicknameInputPage로 이동
final class TermsAgreed extends AuthEvent {
  final bool marketingAgreed;
  const TermsAgreed(this.marketingAgreed);
}

/// 닉네임 입력 완료 → PetProfileInputPage로 이동
final class NicknameSubmitted extends AuthEvent {
  final String nickname;
  const NicknameSubmitted(this.nickname);
}

/// NicknameInputPage 뒤로가기 → TermsAgreementPage로 복귀
final class SignupBackFromNickname extends AuthEvent {
  const SignupBackFromNickname();
}

/// PetProfileInputPage 뒤로가기 → NicknameInputPage로 복귀
final class SignupBackFromPetProfile extends AuthEvent {
  const SignupBackFromPetProfile();
}

/// 펫 프로필 입력 완료 → 회원가입 백엔드 처리 후 홈으로
final class SignupCompleted extends AuthEvent {
  final String? nickname;
  final SignupPetData? pet;
  final String? petImagePath;
  final bool marketingAgreed;
  const SignupCompleted({
    this.nickname,
    this.pet,
    this.petImagePath,
    this.marketingAgreed = false,
  });
}

/// 회원가입 도중 취소 → 로그인 화면으로 복귀
final class SignupCancelled extends AuthEvent {
  const SignupCancelled();
}

final class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

final class WithdrawalRequested extends AuthEvent {
  const WithdrawalRequested();
}

/// 마이페이지 진입/복귀 시 프로필 조회
final class ProfileFetchRequested extends AuthEvent {
  final bool forceRefresh;
  const ProfileFetchRequested({this.forceRefresh = false});
}

/// 페이지가 직접 repo를 호출한 뒤 성공 결과를 AuthBloc에 동기화
final class ProfileUpdated extends AuthEvent {
  final UserProfile profile;
  const ProfileUpdated(this.profile);
}

/// 프로필 이름 수정 요청 (페이지는 Repository를 직접 호출하지 않는다)
final class ProfileNameUpdateRequested extends AuthEvent {
  final int userId;
  final String name;
  final Completer<UserProfile> completer;

  const ProfileNameUpdateRequested({
    required this.userId,
    required this.name,
    required this.completer,
  });
}
