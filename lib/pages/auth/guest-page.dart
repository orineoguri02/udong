/// 게스트 로그인 화면(UI) 파일입니다.
///
/// - 역할: 게스트로 시작하기 / 회원가입하기 선택 UI
/// - Navigator 없음 — Action dispatch만 수행

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app-theme.dart';
import '../../core/utils/app-size.dart';
import '../../features/auth/bloc/auth-bloc.dart';
import '../../features/auth/bloc/auth-event.dart';

class GuestPage extends StatelessWidget {
  const GuestPage({super.key});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.s),
          child: Column(
            children: [
              SizedBox(height: 130.s),
              Image.asset(
                'assets/icons/guest-login-icon.webp',
                width: 64.s,
                height: 64.s,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 24.s),
              Text(
                '게스트로 시작하기',
                style: TextStyle(
                  fontFamily: AppFonts.family,
                  fontSize: 25.s,
                  fontWeight: FontWeight.w800,
                  color: AppColors.font,
                ),
              ),
              SizedBox(height: 8.s),
              Text(
                '간편하게 서비스를 먼저 체험해보세요',
                style: TextStyle(
                  fontFamily: AppFonts.family,
                  fontSize: 13.s,
                  fontWeight: FontWeight.w400,
                  color: AppColors.fontLight,
                ),
              ),
              SizedBox(height: 40.s),
              _FeatureItem(
                iconPath: 'assets/images/signup/guest/guest-icon1.webp',
                title: '게스트로 활동',
                description: '우동 서비스를 가볍게 체험해 볼 수 있어요',
              ),
              SizedBox(height: 16.s),
              _FeatureItem(
                iconPath: 'assets/images/signup/guest/guest-icon2.webp',
                title: '일부 기능의 제한',
                description: '게스트 이용 시 기록 저장, 상세 정보 확인이 어려워요',
              ),
              SizedBox(height: 16.s),
              _FeatureItem(
                iconPath: 'assets/images/signup/guest/guest-icon3.webp',
                title: '정식 회원 전환',
                description: '반려동물의 기록과 정보 관리가 모두 가능해요',
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 54.s,
                child: ElevatedButton(
                  onPressed: () =>
                      context.read<AuthBloc>().add(const GuestContinued()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.main,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.s),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    '게스트로 계속하기',
                    style: TextStyle(
                      fontFamily: AppFonts.family,
                      fontSize: 16.s,
                      fontWeight: FontWeight.w700,
                      height: 1.5,
                      letterSpacing: -0.312,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12.s),
              SizedBox(
                width: double.infinity,
                height: 54.s,
                child: OutlinedButton(
                  onPressed: () =>
                      context.read<AuthBloc>().add(const SignupCancelled()),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.font,
                    side: BorderSide(color: const Color(0xFF9B9B9B), width: 1.s),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.s),
                    ),
                  ),
                  child: Text(
                    '회원가입하기',
                    style: TextStyle(
                      fontFamily: AppFonts.family,
                      fontSize: 16.s,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF9B9B9B),
                      height: 1.5,
                      letterSpacing: -0.312,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20.s),
              Text(
                '우동은 만 14세 미만 아동의\n회원가입을 제한하고 있습니다.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFonts.family,
                  fontSize: 13.s,
                  fontWeight: FontWeight.w400,
                  color: AppColors.fontMuted,
                  height: 1.30769,
                ),
              ),
              SizedBox(height: 24.s),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({
    required this.iconPath,
    required this.title,
    required this.description,
  });

  final String iconPath;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52.s,
          height: 52.s,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(14.s),
          ),
          child: Center(
            child: Image.asset(
              iconPath,
              width: 28.s,
              height: 28.s,
              fit: BoxFit.contain,
            ),
          ),
        ),
        SizedBox(width: 16.s),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: AppFonts.family,
                  fontSize: 15.s,
                  fontWeight: FontWeight.w700,
                  color: AppColors.font,
                  height: 1.8,
                  letterSpacing: -0.439,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontFamily: AppFonts.family,
                  fontSize: 12.s,
                  fontWeight: FontWeight.w400,
                  color: AppColors.fontLight,
                  height: 1.667,
                  letterSpacing: -0.15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
