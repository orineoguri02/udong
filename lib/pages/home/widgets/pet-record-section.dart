/// 홈 화면의 우리들의 반려동물 섹션 위젯입니다.

import 'package:flutter/material.dart';

import '../../../core/theme/app-theme.dart';
import '../../../core/utils/app-size.dart';
import '../../../core/widgets/centered-message-dialog.dart';
import '../../../features/home/models/animal-category.dart';

class PetRecordSection extends StatelessWidget {
  final bool isPetConfigured;
  final VoidCallback? onAddPet;

  const PetRecordSection({
    super.key,
    this.isPetConfigured = true,
    this.onAddPet,
  });

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    if (!isPetConfigured) {
      return GestureDetector(
        onTap: onAddPet,
        child: Container(
          height: 228.s,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.868.s),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44.s,
                height: 44.s,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.main, width: 1.5.s),
                ),
                child: Icon(Icons.add, color: AppColors.main, size: 24.s),
              ),
              SizedBox(height: 12.s),
              Text(
                '반려동물을 추가해주세요',
                style: TextStyle(
                  color: AppColors.fontLight,
                  fontFamily: AppFonts.family,
                  fontSize: 13.s,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => showCenteredMessageDialog(
        context,
        message: '아직 준비중인 서비스에요',
      ),
      child: Container(
      height: 228.s,
      padding: EdgeInsets.only(
        left: 31.s,
        right: 31.s,
        top: 14.s,
        bottom: 14.91.s,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.868.s),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            '반려 가족 돌봄 게시판',
            style: TextStyle(
              color: Color(0xFF000000),
              fontFamily: AppFonts.family,
              fontSize: 15,
              fontStyle: FontStyle.normal,
              fontWeight: FontWeight.w800,
              height: 1.0,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: 13.s),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 140.s) / 3;
              return Wrap(
                spacing: 70.s,
                runSpacing: 11.s,
                children: animalCategories
                    .map(
                      (category) => SizedBox(
                        width: itemWidth,
                        child: _buildAnimalCategoryItem(
                          category.name,
                          category.iconPath,
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildAnimalCategoryItem(String name, String iconPath) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 56.s,
          height: 56.s,
          child: Image.asset(
            iconPath,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 56.s,
                height: 56.s,
                decoration: const BoxDecoration(
                  color: AppColors.main,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.pets,
                  color: Colors.white,
                  size: 35,
                ),
              );
            },
          ),
        ),
        SizedBox(height: 6.s),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF383838),
            fontFamily: AppFonts.family,
            fontSize: 11.564,
            fontStyle: FontStyle.normal,
            fontWeight: FontWeight.w800,
            height: 1.0,
            letterSpacing: -0.231,
          ),
        ),
      ],
    );
  }
}

