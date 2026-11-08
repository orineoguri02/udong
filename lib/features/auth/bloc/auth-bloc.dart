import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/app-logger.dart';
import '../repository/auth-repository.dart';
import 'auth-event.dart';
import 'auth-state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository;
  static const String _oneTimeResetKey = 'auth_one_time_local_reset_done_v1';

  void _authLog(String message) {
    AppLogger.info(message);
  }

  AuthBloc(this._repository) : super(const AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginRequested>(_onLoginRequested);
    on<GoogleLoginRequested>(_onGoogleLoginRequested);
    on<GuestRequested>(_onGuestRequested);
    on<GuestContinued>(_onGuestContinued);
    on<TermsAgreed>(_onTermsAgreed);
    on<NicknameSubmitted>(_onNicknameSubmitted);
    on<SignupBackFromNickname>(_onSignupBackFromNickname);
    on<SignupBackFromPetProfile>(_onSignupBackFromPetProfile);
    on<SignupCompleted>(_onSignupCompleted);
    on<SignupCancelled>(_onSignupCancelled);
    on<LogoutRequested>(_onLogoutRequested);
    on<WithdrawalRequested>(_onWithdrawalRequested);
    on<ProfileFetchRequested>(_onProfileFetchRequested);
    on<ProfileUpdated>(_onProfileUpdated);
    on<ProfileNameUpdateRequested>(_onProfileNameUpdateRequested);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final prefs = await SharedPreferences.getInstance();
      final didOneTimeReset = prefs.getBool(_oneTimeResetKey) ?? false;
      if (!didOneTimeReset) {
        await _repository.resetLocalAuth();
        await prefs.setBool(_oneTimeResetKey, true);
      }

      final user = await _repository.getCurrentUser();
      if (user != null && user.isNewUser) {
        // 웹 OAuth 리다이렉트로 돌아온 신규 사용자 → 회원가입 플로우
        emit(const SignupTerms());
      } else if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _repository.login(
        email: event.email,
        password: event.password,
      );
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onGoogleLoginRequested(
    GoogleLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _repository.loginWithGoogle();
      if (user.isNewUser) {
        emit(const SignupTerms());
      } else {
        emit(AuthAuthenticated(user));
      }
    } catch (e, st) {
      _authLog('[AuthBloc][Google] 구글 로그인 실패: $e');
      _authLog('[AuthBloc][Google] stack: $st');
      emit(AuthFailure(e.toString()));
    }
  }

  void _onGuestRequested(GuestRequested event, Emitter<AuthState> emit) {
    _authLog('[AuthBloc][Anonymous] GuestRequested -> AuthGuest');
    emit(const AuthGuest());
  }

  Future<void> _onGuestContinued(
    GuestContinued event,
    Emitter<AuthState> emit,
  ) async {
    _authLog('[AuthBloc][Anonymous] GuestContinued 수신 -> 익명 로그인 시작');
    emit(const AuthLoading());
    try {
      final guestUser = await _repository.loginAnonymously();
      _authLog(
        '[AuthBloc][Anonymous] 익명 로그인 성공 '
        'userId=${guestUser.id} serverId=${guestUser.serverId}',
      );
      emit(AuthAuthenticated(guestUser));
    } catch (e, st) {
      _authLog('[AuthBloc][Anonymous] 익명 로그인 실패: $e');
      _authLog('[AuthBloc][Anonymous] stack: $st');
      emit(const AuthGuest());
    }
  }

  void _onTermsAgreed(TermsAgreed event, Emitter<AuthState> emit) {
    emit(SignupNickname(event.marketingAgreed));
  }

  void _onNicknameSubmitted(NicknameSubmitted event, Emitter<AuthState> emit) {
    final currentState = state;
    if (currentState is! SignupNickname) return;
    emit(
      SignupPetProfile(
        nickname: event.nickname,
        marketingAgreed: currentState.marketingAgreed,
      ),
    );
  }

  void _onSignupBackFromNickname(
    SignupBackFromNickname event,
    Emitter<AuthState> emit,
  ) {
    emit(const SignupTerms());
  }

  void _onSignupBackFromPetProfile(
    SignupBackFromPetProfile event,
    Emitter<AuthState> emit,
  ) {
    final currentState = state;
    if (currentState is! SignupPetProfile) return;
    emit(SignupNickname(currentState.marketingAgreed));
  }

  Future<void> _onSignupCompleted(
    SignupCompleted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _repository.completeSignup(
        nickname: event.nickname,
        pet: event.pet,
        petImagePath: event.petImagePath,
        marketingAgreed: event.marketingAgreed,
      );
      _authLog(
        '[AuthBloc][Signup] 완료 userId=${user.id} serverId=${user.serverId}',
      );
      emit(AuthAuthenticated(user));
    } catch (e, st) {
      _authLog('[AuthBloc][Signup] 실패: $e');
      _authLog('[AuthBloc][Signup] stack: $st');
      await _repository.resetLocalAuth();
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onSignupCancelled(
    SignupCancelled event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;

    if (currentState is SignupState) {
      try {
        await _repository.cancelSignup();
      } catch (e, st) {
        _authLog('[AuthBloc][Signup] 취소 처리 실패: $e');
        _authLog('[AuthBloc][Signup] 취소 처리 stack: $st');
      }
      emit(const AuthUnauthenticated());
      return;
    }

    final isAuthenticatedGuest =
        currentState is AuthAuthenticated && currentState.user.id == 'guest';
    if (isAuthenticatedGuest) {
      try {
        await _repository.deleteAccount(serverId: currentState.user.serverId);
      } catch (_) {
        await _repository.resetLocalAuth();
      }
    }

    emit(const AuthUnauthenticated());
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    final previousState = state;
    emit(const AuthLoading());
    try {
      await _repository.logout();
      emit(const AuthUnauthenticated());
    } catch (e) {
      if (previousState is AuthAuthenticated) {
        emit(
          AuthAuthenticated(
            previousState.user,
            profile: previousState.profile,
            logoutError: '로그아웃 실패: $e',
          ),
        );
      } else {
        emit(AuthFailure(e.toString()));
      }
    }
  }

  Future<void> _onWithdrawalRequested(
    WithdrawalRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    final serverId = currentState is AuthAuthenticated
        ? currentState.user.serverId
        : null;
    emit(const AuthLoading());
    try {
      await _repository.deleteAccount(serverId: serverId);
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onProfileFetchRequested(
    ProfileFetchRequested event,
    Emitter<AuthState> emit,
  ) async {
    final current = state;
    if (current is! AuthAuthenticated) return;
    if (!event.forceRefresh && current.profile != null) return;

    try {
      final userIdForProfile =
          current.user.serverId?.toString() ?? current.user.id;
      final profile = await _repository.fetchProfile(userId: userIdForProfile);
      emit(current.copyWith(profile: profile));
    } catch (e) {
      _authLog('[AuthBloc] 프로필 조회 실패: $e');
    }
  }

  void _onProfileUpdated(ProfileUpdated event, Emitter<AuthState> emit) {
    final current = state;
    if (current is! AuthAuthenticated) return;
    emit(current.copyWith(profile: event.profile));
  }

  Future<void> _onProfileNameUpdateRequested(
    ProfileNameUpdateRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final updatedProfile = await _repository.updateProfileName(
        userId: event.userId,
        name: event.name,
      );
      final current = state;
      if (current is AuthAuthenticated) {
        emit(current.copyWith(profile: updatedProfile));
      }
      if (!event.completer.isCompleted) {
        event.completer.complete(updatedProfile);
      }
    } catch (e, st) {
      if (!event.completer.isCompleted) {
        event.completer.completeError(e, st);
      }
    }
  }
}
