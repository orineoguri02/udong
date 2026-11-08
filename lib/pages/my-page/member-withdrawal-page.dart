import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app-theme.dart';
import '../../core/utils/app-size.dart';
import '../../core/widgets/confirm-dialog.dart';
import '../../core/widgets/page-title-app-bar.dart';
import '../../features/auth/bloc/auth-bloc.dart';
import '../../features/auth/bloc/auth-event.dart';
import '../../features/auth/bloc/auth-state.dart';

class MemberWithdrawalPage extends StatelessWidget {
  const MemberWithdrawalPage({super.key});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (_, current) => current is AuthFailure,
      listener: (context, state) {
        if (state is AuthFailure) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('탈퇴 실패: ${state.message}')));
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFFFF),
        appBar: PageTitleAppBar(title: '회원탈퇴'),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(15.s, 25.s, 15.s, 0.s),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeaderText(),
                    SizedBox(height: 18.s),
                    _InfoCard(
                      highlightText: '반려동물 정보',
                      titlePrefix: '관리 중인 ',
                      titleSuffix: '는 사라져요',
                      description:
                          '탈퇴 시 등록한 특수동물 정보, 건강 기록과 진료 이력이 모두 삭제돼요.\n다시 확인하거나 복구할 수 없어요.',
                    ),
                    SizedBox(height: 14.s),
                    _InfoCard(
                      highlightText: '기록',
                      titlePrefix: '',
                      titleSuffix: '은 다시 돌아오지 않아요',
                      description:
                          '체중 변화, 증상 메모, 병원 상담 내역 등 \n지금까지 쌓아온 관리 기록이 모두 사라져요.',
                    ),
                    SizedBox(height: 14.s),
                    _InfoCard(
                      highlightText: '처음부터',
                      titlePrefix: '다시 가입하려면 ',
                      titleSuffix: '예요',
                      description: '탈퇴 후에는 반려동물 등록과 건강 정보 입력을\n처음부터 다시 해야 해요.',
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(46.s, 0, 46.s, 10.s),
                child: _BottomButtons(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(30.s, 0, 30.s, 0),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontFamily: AppFonts.family,
            fontSize: 12.s,
            fontWeight: FontWeight.w700,
            color: AppColors.font,
          ),
          children: const [
            TextSpan(text: '잠시만요! '),
            TextSpan(
              text: '우동',
              style: TextStyle(color: AppColors.main),
            ),
            TextSpan(text: '을 탈퇴하기 전에 아래 정보를 확인해주세요.'),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String highlightText;
  final String titlePrefix;
  final String titleSuffix;
  final String description;

  const _InfoCard({
    required this.highlightText,
    required this.titlePrefix,
    required this.titleSuffix,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.s, vertical: 20.s),
      decoration: BoxDecoration(
        color: Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12.644.s),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 3.s,
            spreadRadius: 0.198.s,
            offset: Offset.zero,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 16.s),
            child: Image.asset(
              'assets/icons/sub-icon.webp',
              width: 27.s,
              height: 22.s,
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(width: 12.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontFamily: AppFonts.family,
                      fontSize: 11.7.s,
                      fontWeight: FontWeight.w700,
                      color: AppColors.font,
                    ),
                    children: [
                      if (titlePrefix.isNotEmpty) TextSpan(text: titlePrefix),
                      TextSpan(
                        text: highlightText,
                        style: const TextStyle(color: AppColors.main),
                      ),
                      TextSpan(text: titleSuffix),
                    ],
                  ),
                ),
                SizedBox(height: 6.s),
                Text(
                  description,
                  style: TextStyle(
                    fontFamily: AppFonts.family,
                    fontSize: 9.8.s,
                    fontWeight: FontWeight.w400,
                    color: AppColors.fontLight,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF737373),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.s),
                ),
              ),
              child: Text(
                '취소',
                style: TextStyle(
                  fontFamily: AppFonts.family,
                  fontSize: 15.s,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 18.s),
        Expanded(
          child: SizedBox(
            child: ElevatedButton(
              onPressed: () {
                showConfirmDialog(
                  context: context,
                  highlightText: '회원탈퇴',
                  message: '를 진행하시겠습니까?',
                  confirmLabel: '회원탈퇴',
                  onConfirm: () {
                    context.read<AuthBloc>().add(const WithdrawalRequested());
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.main,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.s),
                ),
              ),
              child: Text(
                '회원탈퇴',
                style: TextStyle(
                  fontFamily: AppFonts.family,
                  fontSize: 15.s,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
