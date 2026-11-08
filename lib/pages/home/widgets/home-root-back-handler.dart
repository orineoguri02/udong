import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// [HomeNavigator] 최하단(홈만 열린 상태)에서 Android 시스템 뒤로가기가
/// 내부 스택에 팝할 항목이 없을 때 루트까지 전달되어 앱이 바로 종료되는 것을 막고,
/// 짧은 시간 내 두 번 누르면 [SystemNavigator.pop]으로 종료합니다.
///
/// 그 위로 병원 찾기 등이 push된 경우에는 이 위젯이 아닌 상위 라우트가 먼저 pop됩니다.
class HomeRootBackHandler extends StatefulWidget {
  const HomeRootBackHandler({super.key, required this.child});

  final Widget child;

  @override
  State<HomeRootBackHandler> createState() => _HomeRootBackHandlerState();
}

class _HomeRootBackHandlerState extends State<HomeRootBackHandler> {
  DateTime? _lastBackPressed;

  @override
  Widget build(BuildContext context) {
    // 웹(안드로이드 브라우저 포함)은 앱 종료 개념이 없으므로 제외한다.
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return widget.child;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final messenger = ScaffoldMessenger.maybeOf(context);
        final now = DateTime.now();
        if (_lastBackPressed == null ||
            now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
          _lastBackPressed = now;
          messenger?.showSnackBar(
            const SnackBar(
              content: Text('한 번 더 누르면 종료됩니다.'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
        SystemNavigator.pop();
      },
      child: widget.child,
    );
  }
}
