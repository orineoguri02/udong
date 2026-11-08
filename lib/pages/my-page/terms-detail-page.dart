/// 이용약관 상세 페이지
///
/// - 역할: 각 이용약관 항목의 상세 내용 표시

import 'package:flutter/material.dart';

import 'package:udon/core/theme/app-theme.dart';
import 'package:udon/core/utils/app-size.dart';

class TermsDetailPage extends StatelessWidget {
  final String title;
  final String content;

  const TermsDetailPage({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Image.asset(
            'assets/icons/back-icon.webp',
            width: 25.s,
            height: 35.s,
            fit: BoxFit.contain,
          ),
          onPressed: () => Navigator.of(context).pop(),
          padding: EdgeInsets.zero,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: const Color(0xFF383838),
            fontFamily: AppFonts.family,
            fontSize: 18.9.s,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: const Color(0xFFE0E0E0)),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.s, vertical: 24.s),
        child: _buildStyledContent(),
      ),
    );
  }

  Widget _buildStyledContent() {
    final lines = content.split('\n');
    final List<Widget> widgets = [];
    // 번호 패턴: "제1조", "1.", "(1)" 등
    final RegExp numberPattern = RegExp(r'^(제\d+조|\d+\.|\(\d+\))');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmedLine = line.trim();

      if (trimmedLine.isEmpty) {
        widgets.add(SizedBox(height: 8.s));
        continue;
      }

      // 번호로 시작하는 줄인지 확인
      if (numberPattern.hasMatch(trimmedLine)) {
        // 번호가 있는 문장 전에 항상 한 줄씩 더 띄우기
        if (i > 0) {
          widgets.add(SizedBox(height: 24.s));
        }
        widgets.add(
          Padding(
            padding: EdgeInsets.only(bottom: 8.s),
            child: Text(
              trimmedLine,
              style: TextStyle(
                color: Colors.black,
                fontFamily: AppFonts.family,
                fontSize: 16.s,
                fontWeight: FontWeight.w700,
                height: 1.7,
              ),
            ),
          ),
        );
      } else {
        widgets.add(
          Padding(
            padding: EdgeInsets.only(bottom: 4.s),
            child: Text(
              trimmedLine,
              style: TextStyle(
                color: AppColors.font,
                fontFamily: AppFonts.family,
                fontSize: 14.s,
                fontWeight: FontWeight.w400,
                height: 1.7,
              ),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}
