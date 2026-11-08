/// 홈 화면의 병원 찾기 및 상태 기록 카드 위젯입니다.

import 'package:flutter/material.dart';

import '../../../core/theme/app-theme.dart';
import '../../../core/utils/app-size.dart';
import '../../../core/widgets/signup-required-dialog.dart';
import '../../../features/auth/models/user.dart';
import '../../hospital/hospital-find-page.dart';
import '../../status-record/status-record-page.dart';

class FeatureCards extends StatelessWidget {
  final User user;

  const FeatureCards({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final isGuest = user.id == 'guest';
    final hospitalSubtitle = isGuest ? '회원가입이 필요한 서비스입니다.' : '지금 병원을 찾아보세요';
    final statusSubtitle = isGuest ? '회원가입이 필요한 서비스입니다.' : '반려가족의 상태를 확인해보세요';

    return Row(
      children: [
        Expanded(
          child: _buildFeatureCard(
            context: context,
            title: '병원 찾기',
            subtitle: hospitalSubtitle,
            iconPath: 'assets/images/home/hospital.webp',
            onTap: () {
              if (isGuest) {
                showSignupRequiredDialog(context);
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const HospitalFindPage(),
                  ),
                );
              }
            },
          ),
        ),
        SizedBox(width: 12.s),
        Expanded(
          child: _buildFeatureCard(
            context: context,
            title: '상태 기록',
            subtitle: statusSubtitle,
            iconPath: 'assets/images/home/status_record.webp',
            onTap: () {
              if (isGuest) {
                showSignupRequiredDialog(context);
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => StatusRecordPage(user: user),
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String iconPath,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.only(
          left: 19.s,
          right: 20.1.s,
          top: 27.s,
          bottom: 13.43.s,
        ),
        height: 143.s,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.643.s),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF000000),
                fontFamily: AppFonts.family,
                fontSize: 19,
                fontStyle: FontStyle.normal,
                fontWeight: FontWeight.w800,
                height: 1.0,
                letterSpacing: -0.38,
              ),
            ),
            SizedBox(height: 8.s),
            Text(
              subtitle,
              style: const TextStyle(
                color: Color(0xFF383838),
                fontFamily: AppFonts.family,
                fontSize: 9.5,
                fontStyle: FontStyle.normal,
                fontWeight: FontWeight.w400,
                height: 1.0,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Align(
              alignment: Alignment.centerRight,
              child: Image.asset(iconPath, width: 50.s, height: 50.s),
            ),
          ],
        ),
      ),
    );
  }
}
