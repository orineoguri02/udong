import 'package:flutter/material.dart';

import '../../core/theme/app-theme.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 3),
  });
  // TODO 현빈 이거 로고 디자인만 다시 바꿔줘 밑에 글자랑
  final Widget child;

  final Duration duration;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.duration, () {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) return const SplashView();
    return widget.child;
  }
}

class SplashView extends StatelessWidget {
  const SplashView({super.key});

  static const _splashImagePath = 'assets/images/splash/splash_logo.webp';
  static const _imageWidth = 76.0;
  static const _imageHeight = 73.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: _imageWidth,
              height: _imageHeight,
              child: Image.asset(_splashImagePath, fit: BoxFit.contain),
            ),
            const SizedBox(height: 28),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '우리들의 반려동물, ',
                    style: AppTheme.splashSloganStyle.copyWith(
                      color: AppColors.font, // 기본 글자색(검정/짙은 회색)
                      fontSize: 16.17, // 사진 크기 느낌
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextSpan(
                    text: '우동',
                    style: AppTheme.splashSloganStyle.copyWith(
                      color: AppColors.main, // 주황색(사진의 포인트 컬러)
                      fontSize: 16.17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextSpan(
                    text: '에서',
                    style: AppTheme.splashSloganStyle.copyWith(
                      color: AppColors.font,
                      fontSize: 16.17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
