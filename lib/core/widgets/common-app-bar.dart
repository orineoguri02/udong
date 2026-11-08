import 'package:flutter/material.dart';

/// 공통 AppBar 컴포넌트
///
/// - 역할: 앱 전체에서 사용되는 헤더바
/// - 구성: 로고(또는 뒤로가기), 홈 아이콘(선택), 알림 아이콘, 마이페이지 아이콘
class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onNotificationPressed;
  final VoidCallback? onMyPagePressed;

  /// true면 뒤로가기 + 홈아이콘 모드 (서브 페이지용)
  final bool showBackButton;

  /// 앱바 배경색 (null이면 기본 연회색)
  final Color? backgroundColor;

  const CommonAppBar({
    super.key,
    this.onNotificationPressed,
    this.onMyPagePressed,
    this.showBackButton = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 21, right: 21, top: 10, bottom: 10),
      child: AppBar(
        backgroundColor: backgroundColor ?? const Color(0xFFF5F5F5),
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        leadingWidth: showBackButton ? 35 : 35,
        leading: showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF383838), size: 20),
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
              )
            : Image.asset(
                'assets/images/home/home-logo.webp',
                fit: BoxFit.contain,
              ),
        actions: [
          // 홈 아이콘 (서브 페이지에서만 표시)
          if (showBackButton) ...[
            GestureDetector(
              onTap: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: Image.asset(
                'assets/icons/home-icon.webp',
                width: 24,
                height: 24,
              ),
            ),
            const SizedBox(width: 11),
          ],
          // 알림 아이콘 (비활성화)
          //
          // NOTE: "notification에 관한 모든거 주석처리" 요청에 따라
          // 공통 앱바에서 알림 진입점 자체를 숨깁니다.
          // GestureDetector(
          //   onTap: onNotificationPressed ?? () {},
          //   child: Image.asset(
          //     'assets/icons/notificationIcon.webp',
          //     width: 24,
          //     height: 24,
          //   ),
          // ),
          // const SizedBox(width: 11),
          // 마이페이지 아이콘
          GestureDetector(
            onTap: onMyPagePressed ?? () {},
            child: Image.asset(
              'assets/icons/mypageIcon.webp',
              width: 22,
              height: 22,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(64);
}
