/// 알림 및 수신 동의 설정 화면(UI) 파일입니다.
///
/// - 역할: 마이페이지에서 진입, 마케팅 정보 알림 토글만 노출

import 'package:flutter/material.dart';

import '../../core/theme/app-theme.dart';
import '../../core/utils/app-size.dart';
import '../../core/widgets/page-title-app-bar.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  bool _marketingEnabled = true;

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: const PageTitleAppBar(title: '알림 및 수신 동의'),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 22.s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20.s),
              Container(
                width: 363.s,
                padding: EdgeInsets.symmetric(horizontal: 21.s, vertical: 30.s),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.644.s),
                  border: Border(
                    top: BorderSide(
                      width: 1.054.s,
                      color: const Color(0xFF383838).withValues(alpha: 0.10),
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.20),
                      offset: Offset(0, 1.s),
                      blurRadius: 3.s,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRow('마케팅 정보 알림', _marketingEnabled, (v) {
                      setState(() => _marketingEnabled = v);
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(
    String label,
    bool value,
    ValueChanged<bool> onChanged, {
    bool isSectionTitle = false,
  }) {
    return SizedBox(
      height: 21.s,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.font,
                fontSize: isSectionTitle ? 17.8.s : 14.s,
                fontWeight: isSectionTitle ? FontWeight.w800 : FontWeight.w400,
              ),
            ),
          ),
          Transform.scale(
            scale: 0.75,
            child: Switch(
              value: value,
              onChanged: onChanged,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              activeTrackColor: AppColors.main,
              activeThumbColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
