/// 사용자 닉네임 입력 화면입니다.
///
/// - 역할: 회원가입 시 닉네임을 입력받는 화면
/// - Navigator 없음 — Action dispatch만 수행

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app-theme.dart';
import '../../../core/utils/app-size.dart';
import '../../../features/auth/bloc/auth-bloc.dart';
import '../../../features/auth/bloc/auth-event.dart';

class NicknameInputPage extends StatefulWidget {
  final bool marketingAgreed;

  const NicknameInputPage({super.key, this.marketingAgreed = false});

  @override
  State<NicknameInputPage> createState() => _NicknameInputPageState();
}

class _NicknameInputPageState extends State<NicknameInputPage> {
  final TextEditingController _controller = TextEditingController();
  bool get _canProceed => _controller.text.trim().isNotEmpty;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          padding: EdgeInsets.only(left: 12.s),
          icon: Image.asset(
            'assets/icons/icon-arrow-right-small-mono.webp',
            width: 24.s,
            height: 24.s,
          ),
          onPressed: () => context
              .read<AuthBloc>()
              .add(const SignupBackFromNickname()),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bottomInset = MediaQuery.of(context).viewInsets.bottom;
          return SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 24.s,
              right: 24.s,
              top: 24.s,
              bottom: 24.s + bottomInset,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 24.s),
                Image.asset(
                  'assets/icons/logo-icon.webp',
                  width: 56.s,
                  height: 56.s,
                ),
                SizedBox(height: 16.s),
                Text(
                  '사용자 닉네임 입력',
                  style: TextStyle(
                    fontFamily: AppFonts.family,
                    fontSize: 25.s,
                    fontWeight: FontWeight.w800,
                    color: AppColors.font,
                    letterSpacing: -0.48.s,
                  ),
                ),
                SizedBox(height: 12.s),
                Text(
                  '정확한 데이터 기반의 의료·헬스케어 서비스를 제공하기 위해\n보호자 및 반려동물 정보를 입력해주세요.\n모든 정보는 우동에서 안전하게 관리됩니다.',
                  style: TextStyle(
                    fontFamily: AppFonts.family,
                    fontSize: 13.s,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF383838),
                    height: 1.69,
                    letterSpacing: -0.32.s,
                  ),
                ),
                SizedBox(height: 24.s),
                Text(
                  '닉네임',
                  style: TextStyle(
                    fontFamily: AppFonts.family,
                    fontSize: 16.s,
                    fontWeight: FontWeight.w800,
                    color: AppColors.font,
                  ),
                ),
                SizedBox(height: 10.s),
                TextField(
                  controller: _controller,
                  onChanged: (_) => setState(() {}),
                  cursorColor: AppColors.main,
                  style: TextStyle(
                    fontFamily: AppFonts.family,
                    fontSize: 14.s,
                    fontWeight: FontWeight.w400,
                    color: AppColors.font,
                  ),
                  decoration: InputDecoration(
                    hintText: '닉네임을 입력해주세요.',
                    hintStyle: TextStyle(
                      fontFamily: AppFonts.family,
                      fontSize: 14.s,
                      fontWeight: FontWeight.w400,
                      color: AppColors.fontMuted,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(27.s),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(27.s),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(27.s),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 24.s,
                      vertical: 14.s,
                    ),
                  ),
                ),
                SizedBox(height: 12.s),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 15.s),
                  child: Text(
                    '우동은 만 14세 미만 아동의 회원가입을 제한하고 있습니다.',
                    style: TextStyle(
                      fontFamily: AppFonts.family,
                      fontSize: 12.s,
                      fontWeight: FontWeight.w400,
                      color: AppColors.fontMuted,
                    ),
                  ),
                ),
                SizedBox(height: 270.s),
                Center(
                  child: SizedBox(
                    width: 145.s,
                    height: 37.s,
                    child: OutlinedButton(
                      onPressed: _canProceed
                          ? () => context.read<AuthBloc>().add(
                                NicknameSubmitted(_controller.text.trim()),
                              )
                          : null,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: _canProceed
                              ? AppColors.main
                              : const Color(0xFFD0D0D0),
                          width: 1.24.s,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18.5.s),
                        ),
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.main,
                        disabledForegroundColor: const Color(0xFFBDBDBD),
                      ),
                      child: Text(
                        '다음',
                        style: TextStyle(
                          fontFamily: AppFonts.family,
                          fontSize: 16.s,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 40.s),
              ],
            ),
          );
        },
      ),
    );
  }
}
