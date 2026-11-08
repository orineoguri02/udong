import 'package:flutter/material.dart';

/// 웹에서 넓은 화면(데스크톱 브라우저 등)일 때 앱을 모바일 폭으로 고정해 가운데에 표시한다.
///
/// - 화면이 [maxWidth]보다 좁으면(실제 모바일 브라우저) 그대로 전체 폭을 사용한다.
/// - 넓으면 [maxWidth] 폭으로 고정하고, 하위 위젯이 보는 [MediaQuery] 크기도
///   같은 폭으로 바꿔 `SizeConfig`(`.s`) 스케일이 모바일 기준으로 계산되게 한다.
class MobileFrame extends StatelessWidget {
  /// iPhone Pro Max 가로폭
  static const double maxWidth = 430;

  final Widget child;

  const MobileFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    if (screenSize.width <= maxWidth) return child;

    return ColoredBox(
      color: const Color(0xFFF2F2F2),
      child: Center(
        child: SizedBox(
          width: maxWidth,
          height: screenSize.height,
          child: ClipRect(
            child: MediaQuery(
              data: mediaQuery.copyWith(
                size: Size(maxWidth, screenSize.height),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
