/// 소셜 로그인 화면(UI) 파일입니다.
///
/// - 역할: 카카오, 구글, 애플 소셜 로그인 제공
/// - 상태관리: 전역(AuthBloc) — Action dispatch만 수행, Navigator 없음

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app-theme.dart';
import '../../core/utils/app-size.dart';
import '../../features/auth/bloc/auth-bloc.dart';
import '../../features/auth/bloc/auth-event.dart';
import '../../features/auth/bloc/auth-state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  void initState() {
    super.initState();
    // 로그인 실패 시 _AuthGate가 LoginPage를 새로 만들기 때문에
    // BlocConsumer listener가 첫 AuthFailure를 받지 못한다 → 여기서 직접 표시.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = context.read<AuthBloc>().state;
      if (state is AuthFailure) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.message)));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.s),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  Image.asset(
                    'assets/images/login/login_logo.webp',
                    width: 100.s,
                    height: 120.s,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: 70.s),
                  SizedBox(height: 48.s),
                  _buildSocialButton(
                    onPressed: isLoading
                        ? null
                        : () => context.read<AuthBloc>().add(
                            const GoogleLoginRequested(),
                          ),
                    backgroundColor: Colors.white,
                    textColor: const Color(0xFF191919),
                    iconPath: 'assets/images/login/google.webp',
                    text: '구글로 시작하기',
                    borderColor: const Color(0xFFE0E0E0),
                    isLoading: isLoading,
                    iconWidth: 27.s,
                    iconHeight: 28.s,
                  ),
                  SizedBox(height: 12.s),
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () => context.read<AuthBloc>().add(
                            const GuestRequested(),
                          ),
                    child: Text(
                      '게스트 로그인',
                      style: TextStyle(
                        fontFamily: AppFonts.family,
                        fontSize: 15.s,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFFFC08F),
                      ),
                    ),
                  ),
                  SizedBox(height: 30.s),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSocialButton({
    required VoidCallback? onPressed,
    required Color backgroundColor,
    required Color textColor,
    required String iconPath,
    required String text,
    Color? borderColor,
    required bool isLoading,
    double iconWidth = 24,
    double iconHeight = 24,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56.s,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22.s),
            side: borderColor != null
                ? BorderSide(color: borderColor, width: 1)
                : BorderSide.none,
          ),
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: 16.s),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(iconPath, width: iconWidth, height: iconHeight),
            SizedBox(width: 12.s),
            Text(
              text,
              style: TextStyle(
                fontFamily: AppFonts.family,
                fontSize: 16.s,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
