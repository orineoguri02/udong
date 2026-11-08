/// 앱 전역 테마(색상/타이포그래피 등) 정의 파일입니다.
///
/// - 역할: `ThemeData`를 한 곳에서 관리하여 UI 일관성 유지
/// - 사용 위치: `App`(루트 위젯)에서 `theme:`로 주입

import 'package:flutter/material.dart';

/// 앱 전역 색상 상수
abstract final class AppColors {
  /// 메인 브랜드 컬러
  static const Color main = Color(0xFFFF9644);

  /// 기본 텍스트(폰트) 컬러
  static const Color font = Color(0xFF383838);

  /// 폰트 컬러 - 밝은 변형 (서브 텍스트용)
  static const Color fontLight = Color(0xFF757575);

  /// 폰트 컬러 - 매우 밝은 변형 (비활성/플레이스홀더)
  static const Color fontMuted = Color(0xFF9E9E9E);

  /// 로고 프레임 (갈색)
  static const Color logoFrame = Color(0xFF8B4513);
}

/// 앱 폰트 패밀리 상수 (Nanum Square Round 통일)
abstract final class AppFonts {
  /// 앱 기본 폰트 (Nanum Square Round)
  static const String family = 'NanumSquareRound';
}

abstract final class AppTheme {
  static ThemeData light() {
    const mainColor = AppColors.main;
    const fontColor = AppColors.font;

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: mainColor,
        primary: mainColor,
        onPrimary: Colors.white,
        surface: Colors.white,
        onSurface: fontColor,
        onSurfaceVariant: AppColors.fontLight,
      ),
      textTheme: _buildTextTheme(),
      fontFamily: AppFonts.family,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: fontColor,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: mainColor,
          foregroundColor: Colors.white,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: mainColor,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: const TextStyle(color: AppColors.fontLight),
        hintStyle: const TextStyle(color: AppColors.fontMuted),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: mainColor),
        ),
      ),
    );
  }

  /// 스플래시 하단 슬로건 텍스트 스타일 (Nanum Square Round 16, w700, #383838)
  static TextStyle get splashSloganStyle => TextStyle(
        color: AppColors.font,
        fontFamily: AppFonts.family,
        fontSize: 16,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.w700,
        height: 1.0,
      );

  static TextTheme _buildTextTheme() {
    const color = AppColors.font;
    // 제목용: Nanum Square Round (display, headline, title)
    final titleBase = TextStyle(
      fontFamily: AppFonts.family,
      color: color,
    );
    // 본문·라벨용: Nanum Square Round
    final bodyBase = TextStyle(
      fontFamily: AppFonts.family,
      color: color,
    );
    return TextTheme(
      displayLarge: titleBase.copyWith(fontSize: 32, fontWeight: FontWeight.w700),
      displayMedium: titleBase.copyWith(fontSize: 28, fontWeight: FontWeight.w700),
      displaySmall: titleBase.copyWith(fontSize: 24, fontWeight: FontWeight.w700),
      headlineLarge: titleBase.copyWith(fontSize: 22, fontWeight: FontWeight.w700),
      headlineMedium: titleBase.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
      headlineSmall: titleBase.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
      titleLarge: titleBase.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
      titleMedium: titleBase.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
      titleSmall: titleBase.copyWith(fontSize: 12, fontWeight: FontWeight.w700),
      bodyLarge: bodyBase.copyWith(fontSize: 16, fontWeight: FontWeight.w300),
      bodyMedium: bodyBase.copyWith(fontSize: 14, fontWeight: FontWeight.w300),
      bodySmall: bodyBase.copyWith(fontSize: 12, fontWeight: FontWeight.w300),
      labelLarge: bodyBase.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
      labelMedium: bodyBase.copyWith(fontSize: 12, fontWeight: FontWeight.w700),
      labelSmall: bodyBase.copyWith(fontSize: 10, fontWeight: FontWeight.w700),
    );
  }
}
