import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:udon/app.dart';

void main() {
  testWidgets('앱 시작 시 로그인 화면이 노출된다', (WidgetTester tester) async {
    await tester.pumpWidget(const App());

    // AppBar 타이틀과 버튼 텍스트가 모두 '로그인'일 수 있으므로, 최소 1개 이상만 확인.
    expect(find.text('로그인'), findsWidgets);
    expect(find.text('비밀번호'), findsOneWidget);
  });

  testWidgets('로그인 버튼 탭 시 홈으로 전환된다', (WidgetTester tester) async {
    await tester.pumpWidget(const App());

    await tester.tap(find.widgetWithText(FilledButton, '로그인'));
    await tester.pump(); // 로딩 시작 프레임
    await tester.pump(const Duration(milliseconds: 700)); // FakeAuthRepository 지연(500ms) 대기

    expect(find.text('홈'), findsOneWidget);
    expect(find.textContaining('환영합니다'), findsOneWidget);
  });
}
