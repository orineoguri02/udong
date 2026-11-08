/// 홈 화면의 매거진 캐러셀 섹션 위젯입니다.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app-theme.dart';
import '../../../core/utils/app-logger.dart';
import '../../../core/utils/app-size.dart';

class MagazineSection extends StatefulWidget {
  final List<String> imageUrls;

  const MagazineSection({super.key, required this.imageUrls});

  @override
  State<MagazineSection> createState() => _MagazineSectionState();
}

class _MagazineSectionState extends State<MagazineSection> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void didUpdateWidget(covariant MagazineSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final pageCount = widget.imageUrls.isNotEmpty ? widget.imageUrls.length : 1;
    if (_currentIndex >= pageCount) {
      setState(() {
        _currentIndex = 0;
      });
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    }
  }

  Widget _buildMagazineImage(BuildContext context, String imageUrl) {
    if (imageUrl.trim().isEmpty) {
      return _buildImageFallback();
    }

    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheWidth = ((MediaQuery.sizeOf(context).width - (30.s)) * dpr)
        .round();
    final cacheHeight = ((353.s - 23.s) * dpr).round();

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      memCacheWidth: cacheWidth,
      memCacheHeight: cacheHeight,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholder: (_, _) => _buildImageFallback(),
      errorWidget: (_, url, error) {
        AppLogger.warn('[MagazineSection] 이미지 로드 실패 url=$url error=$error');
        return _buildImageFallback();
      },
    );
  }

  Widget _buildImageFallback() {
    return Container(
      color: const Color(0xFFF3F3F3),
      alignment: Alignment.center,
      child: Icon(
        Icons.pets_outlined,
        size: 42.s,
        color: const Color(0xFFBEBEBE),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final pageCount = widget.imageUrls.isNotEmpty ? widget.imageUrls.length : 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(left: 15.s),
          width: 102.s,
          height: 26.s,
          decoration: BoxDecoration(
            color: const Color(0xFFFF9645),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(13.52.s),
              topRight: Radius.circular(14.158.s),
            ),
          ),
          alignment: Alignment.center,
          child: const Text(
            '오늘의 동물 상식',
            style: TextStyle(
              color: Colors.white,
              fontFamily: AppFonts.family,
              fontSize: 11,
              fontStyle: FontStyle.normal,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.22,
            ),
          ),
        ),
        Container(
          height: 353.s,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.s),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index % pageCount;
                    });
                  },
                  itemCount: pageCount,
                  itemBuilder: (context, index) {
                    final imageUrl = widget.imageUrls.isNotEmpty
                        ? widget.imageUrls[index]
                        : '';
                    return Padding(
                      padding: EdgeInsets.fromLTRB(15.s, 15.s, 15.s, 8.s),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.s),
                        child: _buildMagazineImage(context, imageUrl),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 16.s),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    pageCount,
                    (index) => Container(
                      margin: EdgeInsets.symmetric(horizontal: 4.s),
                      width: 10.s,
                      height: 10.s,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index == _currentIndex
                            ? AppColors.main
                            : const Color(0xFFE0E0E0),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
