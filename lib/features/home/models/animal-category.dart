/// 동물 카테고리 모델 파일입니다.
///
/// - 역할: 홈 화면에서 사용되는 동물 카테고리 데이터 정의

class AnimalCategory {
  final String name;
  final String iconPath;

  const AnimalCategory({required this.name, required this.iconPath});
}

/// 동물 카테고리 목록
const List<AnimalCategory> animalCategories = [
  AnimalCategory(
    name: '파충류',
    iconPath: 'assets/icons/animal-icon/be-lizard-icon.webp',
  ),
  AnimalCategory(
    name: '양서류',
    iconPath: 'assets/icons/animal-icon/be-frog-icon.webp',
  ),
  AnimalCategory(
    name: '포유류',
    iconPath: 'assets/icons/animal-icon/be-hedgehog-icon.webp',
  ),
  AnimalCategory(
    name: '조류',
    iconPath: 'assets/icons/animal-icon/be-parrot-icon.webp',
  ),
  AnimalCategory(
    name: '어류',
    iconPath: 'assets/icons/animal-icon/be-fish-icon.webp',
  ),
  AnimalCategory(
    name: '설치류',
    iconPath: 'assets/icons/animal-icon/be-rabbit-icon.webp',
  ),
];
