/// 홈 화면의 광고 배너 위젯입니다.

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../core/theme/app-theme.dart';
import '../../../core/utils/app-logger.dart';
import '../../../core/utils/app-size.dart';

class AdBanner extends StatefulWidget {
  final List<String> imageUrls;
  final bool isLoading;

  const AdBanner({super.key, required this.imageUrls, this.isLoading = false});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> with WidgetsBindingObserver {
  static const Duration _autoSlideInterval = Duration(seconds: 5);
  static const Duration _autoSlideDuration = Duration(milliseconds: 400);

  final PageController _pageController = PageController();

  Timer? _autoSlideTimer;
  int _currentDotIndex = 0;
  int _currentVirtualPage = 0;
  bool _isAnimating = false;
  bool _isUserDragging = false;
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lifecycleState =
        WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;
    _configureInfiniteLoop();
  }

  @override
  void didUpdateWidget(covariant AdBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.imageUrls, widget.imageUrls)) {
      setState(() {
        _currentDotIndex = 0;
      });
      _configureInfiniteLoop();
    }
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
    if (state == AppLifecycleState.resumed) {
      _startAutoSlide();
    } else {
      _autoSlideTimer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    return Container(
      height: 112.s,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.868.s),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.868.s),
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (widget.isLoading) {
      return _buildFallback(isLoading: true);
    }

    final imageUrls = widget.imageUrls;
    if (imageUrls.isEmpty) {
      return _buildFallback();
    }

    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheWidth = ((MediaQuery.sizeOf(context).width - (30.s)) * dpr)
        .round();
    final cacheHeight = (112.s * dpr).round();
    final canLoop = imageUrls.length > 1;

    return Stack(
      fit: StackFit.expand,
      children: [
        NotificationListener<UserScrollNotification>(
          onNotification: (notification) {
            final isDragging = notification.direction != ScrollDirection.idle;
            if (isDragging == _isUserDragging) return false;
            _isUserDragging = isDragging;
            if (isDragging) {
              _autoSlideTimer?.cancel();
            } else {
              _startAutoSlide();
            }
            return false;
          },
          child: PageView.builder(
            controller: _pageController,
            physics: canLoop
                ? const BouncingScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            itemCount: canLoop ? null : 1,
            onPageChanged: (index) {
              if (imageUrls.isEmpty) return;
              _currentVirtualPage = index;
              setState(() {
                _currentDotIndex = index % imageUrls.length;
              });
            },
            itemBuilder: (context, index) {
              final imageUrl = imageUrls[index % imageUrls.length];
              return CachedNetworkImage(
                imageUrl: imageUrl,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                memCacheWidth: cacheWidth,
                memCacheHeight: cacheHeight,
                fadeInDuration: Duration.zero,
                fadeOutDuration: Duration.zero,
                placeholder: (context, url) => _buildFallback(isLoading: true),
                errorWidget: (context, url, error) {
                  AppLogger.warn('[AdBanner] 이미지 로드 실패 url=$url error=$error');
                  return _buildFallback();
                },
              );
            },
          ),
        ),
        if (canLoop)
          Positioned(
            left: 0,
            right: 0,
            bottom: 8.s,
            child: IgnorePointer(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  imageUrls.length,
                  (index) => Container(
                    margin: EdgeInsets.symmetric(horizontal: 3.s),
                    width: 6.s,
                    height: 6.s,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _currentDotIndex
                          ? AppColors.main
                          : const Color(0xFFE0E0E0),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _configureInfiniteLoop() {
    _autoSlideTimer?.cancel();
    if (widget.imageUrls.length <= 1) {
      _currentVirtualPage = 0;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
      return;
    }

    final initialPage = _initialVirtualPage(widget.imageUrls.length);
    _currentVirtualPage = initialPage;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageController.hasClients) return;
      _pageController.jumpToPage(initialPage);
      _startAutoSlide();
    });
  }

  int _initialVirtualPage(int length) {
    const seed = 10000;
    return seed - (seed % length);
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    if (widget.imageUrls.length <= 1 ||
        _lifecycleState != AppLifecycleState.resumed) {
      return;
    }
    _autoSlideTimer = Timer.periodic(_autoSlideInterval, (_) {
      _animateToNextPage();
    });
  }

  Future<void> _animateToNextPage() async {
    if (!mounted ||
        !_pageController.hasClients ||
        widget.imageUrls.length <= 1 ||
        _isAnimating ||
        _isUserDragging ||
        _lifecycleState != AppLifecycleState.resumed ||
        !_isRouteVisible()) {
      return;
    }

    _isAnimating = true;
    _currentVirtualPage += 1;
    try {
      await _pageController.animateToPage(
        _currentVirtualPage,
        duration: _autoSlideDuration,
        curve: Curves.easeOut,
      );
    } catch (_) {
      // 라우트 전환 직후 컨트롤러 상태 경합 시 예외를 무시하고 다음 tick에서 재시도.
    } finally {
      _isAnimating = false;
    }
  }

  bool _isRouteVisible() {
    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic>) {
      return route.isCurrent;
    }
    return true;
  }

  Widget _buildFallback({bool isLoading = false}) {
    return Container(
      color: Colors.white,
      alignment: Alignment.center,
      child: isLoading
          ? SizedBox(
              width: 18.s,
              height: 18.s,
              child: CircularProgressIndicator(
                strokeWidth: 2.s,
                color: AppColors.fontLight,
              ),
            )
          : Text(
              '광고',
              style: TextStyle(
                fontSize: 16.s,
                color: AppColors.fontLight,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }
}
