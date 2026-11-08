/// 앱 실행 진입점(Entry point) 파일입니다.
///
/// - 역할: `runApp()` 호출로 루트 위젯(App)을 실행
/// - 비고: 실제 앱 구성(테마/라우팅/DI)은 `lib/app.dart`에서 관리

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 고해상도 프로필/기록 이미지를 자주 사용하므로 이미지 캐시 용량을 상향.
  PaintingBinding.instance.imageCache.maximumSize = 1000;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 250 << 20;

  if (kIsWeb) {
    // 웹은 .env를 asset으로 번들하지 않는다(공개 URL로 노출되므로).
    // 빌드 시 --dart-define(또는 --dart-define-from-file=.env)으로 주입한다.
    dotenv.loadFromString(
      isOptional: true,
      mergeWith: const {
        'KAKAO_JS_KEY': String.fromEnvironment('KAKAO_JS_KEY'),
        'API_BASE_URL': String.fromEnvironment('API_BASE_URL'),
        'SUPABASE_URL': String.fromEnvironment('SUPABASE_URL'),
        'SUPABASE_ANON_KEY': String.fromEnvironment('SUPABASE_ANON_KEY'),
      },
    );
  } else if (await File('.env.local').exists()) {
    // .env.local 있으면 우선 로드, 없으면 .env 로드 (백엔드 주소 등 로컬 전용은 .env.local에)
    await dotenv.load(fileName: '.env.local');
  } else {
    await dotenv.load(fileName: '.env');
  }

  // Supabase 초기화 (인증 세션 자동 저장/갱신, 웹 OAuth 리다이렉트 처리 포함)
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    publishableKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  // 카카오 지도 JavaScript API 키 초기화
  AuthRepository.initialize(appKey: dotenv.env['KAKAO_JS_KEY'] ?? '');

  runApp(const App());
}
