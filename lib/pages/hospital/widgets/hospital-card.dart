/// 병원 정보 카드 위젯
///
/// - 역할: 병원 목록의 개별 카드 UI (이름, 주소, 전화, 영업시간, 진료가능동물 chip, 위치 버튼)
/// - isOpen: 진료 중 여부에 따라 회색/오렌지 표시
/// - chip 디자인: "진료가능동물" 라벨(오렌지 #FF9645 85%, radius 3) + 동물명(#F5F5F5, pill)

import 'package:flutter/material.dart';

import 'package:udon/core/theme/app-theme.dart';
import 'package:udon/core/utils/app-size.dart';
import 'package:udon/features/hospital/models/hospital.dart';

class HospitalCard extends StatelessWidget {
  final Hospital hospital;
  final VoidCallback? onLocationTap;

  const HospitalCard({super.key, required this.hospital, this.onLocationTap});

  @override
  Widget build(BuildContext context) {
    final bool isOpen = hospital.isOpen;
    final List<String> animalLabels = hospital.animals.isNotEmpty
        ? hospital.animals.take(3).toList()
        : const ['정보없음'];
    final bool hasMoreAnimals = hospital.animals.length > 3;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.8676.s),
      ),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(
              left: 33.02.s,
              top: 30.s,
              bottom: 26.s,
              right: 95.s,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hospital.name,
                  style: TextStyle(
                    fontFamily: AppFonts.family,
                    fontWeight: FontWeight.w700,
                    fontSize: 17.7.s,
                    height: 19 / 17,
                    letterSpacing: -0.34.s,
                    color: AppColors.font,
                  ),
                ),
                SizedBox(height: 5.s),
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  text: hospital.address,
                ),
                _InfoRow(icon: Icons.call_outlined, text: hospital.phone),
                _InfoRow(icon: Icons.schedule, text: hospital.operatingHours),
                SizedBox(height: 5.s),
                Padding(
                  padding: EdgeInsets.only(left: 2.s),
                  child: Wrap(
                    spacing: 4.s,
                    runSpacing: 4.s,
                    children: [
                      _AnimalLabelChip(isActive: isOpen),
                      ...animalLabels.map(
                        (a) => _AnimalNameChip(label: a, isActive: isOpen),
                      ),
                      if (hasMoreAnimals) const _MoreAnimalsChip(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 오른쪽 아이콘
          Positioned(
            top: 37.84.s,
            right: 31.s,
            child: GestureDetector(
              onTap: onLocationTap,
              child: Image.asset(
                isOpen
                    ? 'assets/images/hospital/hospital-location-icon.webp'
                    : 'assets/images/hospital/hospital-location-close.webp',
                height: isOpen ? 89.81.s : 100.21.s,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "진료가능동물" 라벨 chip: 오렌지 배경, radius 3
class _AnimalLabelChip extends StatelessWidget {
  final bool isActive;
  const _AnimalLabelChip({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      // Figma: 좌우 4pt, 위 5pt, 아래 4pt
      padding: EdgeInsets.fromLTRB(4.s, 5.s, 4.s, 4.s),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.main.withValues(alpha: 0.85)
            : const Color(0xFF757575),
        borderRadius: BorderRadius.circular(3.s),
      ),
      child: Text(
        '진료가능동물',
        style: TextStyle(
          fontFamily: AppFonts.family,
          fontWeight: FontWeight.w800,
          // Figma: 6.853pt, line-height 100%
          fontSize: 6.853.s,
          height: 1.0,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// 동물명 chip: #F5F5F5 배경, pill shape (radius 11.4)
class _AnimalNameChip extends StatelessWidget {
  final String label;
  final bool isActive;
  const _AnimalNameChip({required this.label, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      // Figma: 좌우 9pt, 위 5pt, 아래 4pt (pill)
      padding: EdgeInsets.fromLTRB(9.s, 5.s, 9.s, 4.s),
      decoration: BoxDecoration(
        // 영업 중/종료 모두 동일한 둥근 chip 회색 배경 사용
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(11.4.s),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppFonts.family,
          fontWeight: FontWeight.w800,
          // Figma: 6.853pt, line-height 100%
          fontSize: 6.853.s,
          height: 1.0,
          color: isActive ? AppColors.main : const Color(0xFF757575),
        ),
      ),
    );
  }
}

/// 더보기 chip: 회색 원형에 '+' 표시 (동물 4개 이상일 때)
class _MoreAnimalsChip extends StatelessWidget {
  const _MoreAnimalsChip();

  @override
  Widget build(BuildContext context) {
    // chip 높이(17pt)에 맞춰 정렬되도록 + 아이콘 전용 이미지 사용
    return SizedBox(
      width: 17.s,
      height: 17.s,
      child: Center(
        child: Image.asset(
          'assets/images/hospital/+icon.webp',
          width: 16.s,
          height: 16.s,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11.806.s, color: AppColors.font),
        SizedBox(width: 5.s),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: AppFonts.family,
              fontWeight: FontWeight.w400,
              fontSize: 9.8383.s,
              height: 19.6766 / 9.8383,
              letterSpacing: 0,
              color: AppColors.font,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
