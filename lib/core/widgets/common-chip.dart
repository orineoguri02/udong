/// 공통 Chip 컴포넌트
///
/// - 역할: 예방접종, 전문의, 특수동물 등 병원 특징 표시용 칩
/// - 디자인: 오렌지 배경(rgba 255,150,69,0.85), 흰색 텍스트
/// - variant: 회색 버전 지원 (진료 종료 상태)

import 'package:flutter/material.dart';

import '../theme/app-theme.dart';

class CommonChip extends StatelessWidget {
  final String label;
  final bool isActive; // true: 오렌지, false: 회색

  const CommonChip({
    super.key,
    required this.label,
    this.isActive = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 37,
      height: 16,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isActive 
            ? AppColors.main.withValues(alpha: 0.85)
            : const Color(0xFF757575),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: AppFonts.family,
          fontWeight: FontWeight.w800,
          fontSize: 6.6,
          height: 1.0,
          color: Colors.white,
        ),
      ),
    );
  }
}