/// 앱 공용 로거(로그 출력) 유틸 파일입니다.
///
/// - 역할: 디버그/릴리즈 환경별 로깅 정책을 한 곳에서 관리
/// - 비고: 지금은 최소 구현. 필요 시 `logger` 패키지 등으로 확장 가능

// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';

abstract final class AppLogger {
  static const bool _enableDebugLogs = kDebugMode;

  static void info(String message) {
    if (!_enableDebugLogs) return;
    print('[INFO] $message');
  }

  static void warn(String message) {
    if (!_enableDebugLogs) return;
    print('[WARN] $message');
  }

  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    print('[ERROR] $message');
    if (error != null) print('[ERROR] error: $error');
    if (stackTrace != null) print('[ERROR] stack: $stackTrace');
  }
}
