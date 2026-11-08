import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'home-page.dart';

/// Home 전용 Navigator. AuthGate 안에서만 사용.
/// 안드로이드 시스템 뒤로 가기를 가로채서 내부 스택을 먼저 pop한다.
/// 홈 루트에서는 2초 이내 두 번 누르면 앱 종료 (안드로이드 표준 패턴).
class HomeNavigator extends StatefulWidget {
  const HomeNavigator({super.key});

  @override
  State<HomeNavigator> createState() => _HomeNavigatorState();
}

class _HomeNavigatorState extends State<HomeNavigator> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  DateTime? _lastBackPressed;

  void _onPopInvoked() {
    final inner = _navigatorKey.currentState;

    // 내부 스택에 뒤로 갈 페이지가 있으면 먼저 그쪽을 pop
    if (inner != null && inner.canPop()) {
      inner.pop();
      return;
    }

    // 홈 루트 — 안드로이드에서만 "한 번 더 누르면 종료" 패턴 적용
    if (kIsWeb || !Platform.isAndroid) return;

    final now = DateTime.now();
    if (_lastBackPressed != null &&
        now.difference(_lastBackPressed!) < const Duration(seconds: 2)) {
      // 2초 이내 두 번째 탭 → 앱 종료
      exit(0);
    } else {
      _lastBackPressed = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('뒤로 가기 버튼을 한 번 더 누르면 종료됩니다'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) => _onPopInvoked(),
      child: Navigator(
        key: _navigatorKey,
        onGenerateRoute: (settings) {
          return MaterialPageRoute<void>(
            builder: (_) => const HomePage(),
          );
        },
      ),
    );
  }
}
