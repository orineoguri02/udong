import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app-constants.dart';
import '../../core/theme/app-theme.dart';
import '../../core/utils/app-size.dart';
import '../../core/widgets/page-title-app-bar.dart';

class InquiryPage extends StatelessWidget {
  const InquiryPage({super.key});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: PageTitleAppBar(title: '문의하기'),
      body: Padding(
        padding: EdgeInsets.fromLTRB(15.s, 28.s, 15.s, 0.s),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: EdgeInsets.all(18.s),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14.s),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8.s,
                    spreadRadius: 0.2.s,
                    offset: Offset(0, 2.s),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '의견 남겨주셔서 감사합니다.',
                    style: TextStyle(
                      fontFamily: AppFonts.family,
                      fontSize: 16.s,
                      fontWeight: FontWeight.w800,
                      color: AppColors.font,
                    ),
                  ),
                  SizedBox(height: 8.s),

                  SizedBox(height: 16.s),
                  SizedBox(
                    width: double.infinity,
                    height: 52.s,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (AppConstants.inquiryFormUrl.isEmpty) {
                          return;
                        }
                        final uri = Uri.parse(AppConstants.inquiryFormUrl);
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.main,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        alignment: Alignment.center,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.s),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 18.s),
                      ),
                      child: Text(
                        '문의하기',
                        style: TextStyle(
                          fontFamily: AppFonts.family,
                          fontSize: 15.s,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
