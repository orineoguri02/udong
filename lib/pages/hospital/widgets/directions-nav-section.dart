/// 찾아가기 탭 - 지도 앱 길찾기 섹션
///
/// - 역할: 위도·경도·주소·상호를 넘겨 네이버맵/카카오맵/티맵 길찾기(경로)로 열기
/// - 앱 전환 시 iOS/Android 기본 확인 창 사용(자체 팝업 없음)

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:udon/core/theme/app-theme.dart';
import 'package:udon/core/utils/app-size.dart';
import 'package:udon/features/hospital/models/hospital.dart';

class DirectionsNavSection extends StatelessWidget {
  final Hospital hospital;

  const DirectionsNavSection({super.key, required this.hospital});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return Column(
      children: [
        _MapLinkRow(
          iconPath: 'assets/images/hospital/naver-map-icon.webp',
          label: '네이버맵 바로가기',
          onTap: () => _launchMap(
            _naverMapAppUrl(hospital),
            _naverMapWebUrl(hospital),
          ),
        ),
        SizedBox(height: 28.s),
        _MapLinkRow(
          iconPath: 'assets/images/hospital/kakao-map-icon.webp',
          label: '카카오맵 바로가기',
          onTap: () => _launchMap(
            _kakaoMapAppUrl(hospital),
            _kakaoMapWebUrl(hospital),
          ),
        ),
        SizedBox(height: 28.s),
        _MapLinkRow(
          iconPath: 'assets/images/hospital/tmap-icon.webp',
          label: '티맵 바로가기',
          onTap: () => _launchMap(
            _tmapAppUrl(hospital),
            _tmapWebUrl(hospital),
          ),
        ),
      ],
    );
  }

  // ── 딥링크 URL: 위도·경도·주소·상호 기반 길찾기(출발=현재위치, 도착=병원) ──

  /// 도착지 표시명: 상호 + 주소
  String _destinationName(Hospital h) => '${h.name} ${h.address}'.trim();

  /// 네이버 앱: 내비게이션(도착지 = 좌표 + 상호·주소)
  String _naverMapAppUrl(Hospital h) {
    if (h.hasCoordinates) {
      return 'nmap://navigation?dlat=${h.latitude}&dlng=${h.longitude}'
          '&dname=${Uri.encodeComponent(_destinationName(h))}&appname=com.udon';
    }
    return 'nmap://search?query=${Uri.encodeComponent(h.address)}&appname=com.udon';
  }

  String _naverMapWebUrl(Hospital h) {
    if (h.hasCoordinates) {
      return 'https://map.naver.com/v5/?c=${h.longitude},${h.latitude},15,0,0,0,dh';
    }
    return 'https://map.naver.com/v5/search/${Uri.encodeComponent(h.address)}';
  }

  /// 카카오맵 앱: 경로(ep=도착지 좌표, en=도착지명 상호·주소)
  String _kakaoMapAppUrl(Hospital h) {
    if (h.hasCoordinates) {
      return 'kakaomap://route?ep=${h.latitude},${h.longitude}'
          '&en=${Uri.encodeComponent(_destinationName(h))}&by=CAR';
    }
    return 'kakaomap://search?q=${Uri.encodeComponent(h.address)}';
  }

  /// 카카오맵 웹: 길찾기(도착지)
  String _kakaoMapWebUrl(Hospital h) {
    if (h.hasCoordinates) {
      return 'https://map.kakao.com/link/to/${Uri.encodeComponent(_destinationName(h))},${h.latitude},${h.longitude}';
    }
    return 'https://map.kakao.com/?q=${Uri.encodeComponent(h.address)}';
  }

  /// 티맵 앱: 경로(목적지 = 좌표 + 상호·주소)
  String _tmapAppUrl(Hospital h) {
    if (h.hasCoordinates) {
      return 'tmap://route?goalname=${Uri.encodeComponent(_destinationName(h))}'
          '&goalx=${h.longitude}&goaly=${h.latitude}';
    }
    return 'tmap://search?name=${Uri.encodeComponent(h.address)}';
  }

  String _tmapWebUrl(Hospital h) {
    return 'https://www.tmap.co.kr/';
  }

  /// launchUrl 호출 시 OS가 자동으로 "'앱이름'에서 '카카오맵'을(를) 열려고 합니다" 등 확인 창 표시
  Future<void> _launchMap(String appUrl, String webUrl) async {
    final appUri = Uri.parse(appUrl);
    if (await canLaunchUrl(appUri)) {
      await launchUrl(appUri, mode: LaunchMode.externalApplication);
    } else {
      final webUri = Uri.parse(webUrl);
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }
}

// ── 지도 앱 바로가기 행 위젯 ──
class _MapLinkRow extends StatelessWidget {
  final String iconPath;
  final String label;
  final VoidCallback onTap;

  const _MapLinkRow({
    required this.iconPath,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return GestureDetector(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 46.5.s,
            height: 46.5.s,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12.41.s),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 2.s,
                  offset: Offset(0, 0.6.s),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.41.s),
              child: Image.asset(
                iconPath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.map_outlined,
                  color: AppColors.main,
                  size: 24.s,
                ),
              ),
            ),
          ),
          SizedBox(width: 25.66.s),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                height: 43.2014.s,
                constraints: BoxConstraints(maxWidth: 250.7787.s),
                decoration: BoxDecoration(
                  color: AppColors.font.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(21.6007.s),
                ),
                padding: EdgeInsets.symmetric(horizontal: 21.51.s),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: AppFonts.family,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.6443.s,
                        height: 14 / 12.6443,
                        color: AppColors.font,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 11.s,
                      color: AppColors.font,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
