import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/theme/app-theme.dart';
import 'core/widgets/mobile-frame.dart';
import 'features/auth/bloc/auth-bloc.dart';
import 'features/auth/bloc/auth-event.dart';
import 'features/auth/bloc/auth-state.dart';
import 'features/auth/repository/auth-repository.dart';
import 'features/home/repository/home-repository.dart';
import 'features/hospital/repository/hospital-repository.dart';
import 'pages/auth/guest-page.dart';
import 'pages/auth/login-page.dart';
import 'pages/auth/signup/nickname-input-page.dart';
import 'pages/auth/signup/pet-profile-input-page.dart';
import 'pages/auth/signup/terms-agreement-page.dart';
import 'pages/home/home-shell.dart';
import 'pages/splash/splash-page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<AuthRepository>(
      create: (_) => AuthRepositoryImpl(),
      child: RepositoryProvider<HomeRepository>(
        create: (context) =>
            HomeRepositoryImpl(authRepository: context.read<AuthRepository>()),
        child: RepositoryProvider<HospitalRepository>(
          create: (context) => HospitalRepositoryImpl(
            authRepository: context.read<AuthRepository>(),
          ),
          child: BlocProvider<AuthBloc>(
            create: (context) =>
                AuthBloc(context.read<AuthRepository>())
                  ..add(const AppStarted()),
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'udon',
              theme: AppTheme.light(),
              // 웹: 모바일 폭으로 고정하고, 마우스 드래그로도 스크롤되게 한다.
              builder: kIsWeb
                  ? (context, child) => MobileFrame(child: child!)
                  : null,
              scrollBehavior: kIsWeb
                  ? const MaterialScrollBehavior().copyWith(
                      dragDevices: PointerDeviceKind.values.toSet(),
                    )
                  : null,
              home: SplashPage(
                child: BlocBuilder<AuthBloc, AuthState>(
                  buildWhen: (previous, current) {
                    if (previous.runtimeType != current.runtimeType) {
                      return true;
                    }

                    if (previous is AuthAuthenticated &&
                        current is AuthAuthenticated) {
                      return previous.user.id != current.user.id ||
                          previous.user.serverId != current.user.serverId ||
                          previous.user.displayName !=
                              current.user.displayName ||
                          previous.user.email != current.user.email;
                    }

                    if (previous is AuthFailure && current is AuthFailure) {
                      return previous.message != current.message;
                    }

                    if (previous is SignupNickname &&
                        current is SignupNickname) {
                      return previous.marketingAgreed !=
                          current.marketingAgreed;
                    }

                    if (previous is SignupPetProfile &&
                        current is SignupPetProfile) {
                      return previous.nickname != current.nickname ||
                          previous.marketingAgreed != current.marketingAgreed;
                    }

                    return false;
                  },
                  builder: (context, state) => _AuthGate(state: state),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 유일한 화면 결정 지점 — AuthState에 따라 보여줄 위젯을 반환한다.
/// Navigator.push는 여기에도 존재하지 않는다.
class _AuthGate extends StatelessWidget {
  final AuthState state;

  const _AuthGate({required this.state});

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      AuthInitial() || AuthLoading() => const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      ),
      AuthAuthenticated(:final user) => HomeShell(user: user),
      AuthGuest() => const GuestPage(),
      SignupTerms() => const TermsAgreementPage(),
      SignupNickname(:final marketingAgreed) => NicknameInputPage(
        marketingAgreed: marketingAgreed,
      ),
      SignupPetProfile(:final nickname, :final marketingAgreed) =>
        PetProfileInputPage(
          nickname: nickname,
          marketingAgreed: marketingAgreed,
        ),
      AuthUnauthenticated() || AuthFailure() => LoginPage(),
    };
  }
}
