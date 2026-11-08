/// 동물 세부 종 모델 파일

class AnimalSpeciesGroup {
  final String name;
  final List<String> subSpecies;

  const AnimalSpeciesGroup({required this.name, required this.subSpecies});
}

/// 카테고리 인덱스별 세부 종 그룹 목록
/// 인덱스: 0=파충류, 1=양서류, 2=포유류, 3=조류, 4=어류, 5=설치류
const Map<int, List<AnimalSpeciesGroup>> animalSpeciesMap = {
  0: [
    AnimalSpeciesGroup(
      name: '도마뱀',
      subSpecies: ['레오파드 게코', '크레스티드 게코', '비어디드 드래곤', '직접입력'],
    ),
    AnimalSpeciesGroup(
      name: '거북이',
      subSpecies: ['레드이어드 슬라이더', '복거북', '인도별거북', '직접입력'],
    ),
    AnimalSpeciesGroup(
      name: '뱀',
      subSpecies: ['콘스네이크', '볼파이썬', '킹스네이크', '직접입력'],
    ),
  ],
  1: [
    AnimalSpeciesGroup(
      name: '개구리',
      subSpecies: ['화이트트리프로그', '팩맨', '다트프로그', '직접입력'],
    ),
    AnimalSpeciesGroup(
      name: '도롱뇽',
      subSpecies: ['티거 샐러맨더', '악어 도롱뇽', '불도롱뇽', '직접입력'],
    ),
  ],
  2: [
    AnimalSpeciesGroup(
      name: '고슴도치',
      subSpecies: ['아프리카 피그미', '유럽 고슴도치', '직접입력'],
    ),
    AnimalSpeciesGroup(name: '페럿', subSpecies: ['얼룩 페럿', '알비노', '직접입력']),
  ],
  3: [
    AnimalSpeciesGroup(
      name: '앵무새',
      subSpecies: ['버드파케트', '코뉴어', '아마존', '직접입력'],
    ),
    AnimalSpeciesGroup(name: '카나리아', subSpecies: ['옐로우', '레드 팩터', '직접입력']),
  ],
  4: [
    AnimalSpeciesGroup(name: '금붕어', subSpecies: ['라이언헤드', '란추', '오란다', '직접입력']),
    AnimalSpeciesGroup(name: '열대어', subSpecies: ['네온 테트라', '구피', '베타', '직접입력']),
  ],
  5: [
    AnimalSpeciesGroup(
      name: '햄스터',
      subSpecies: ['골든햄스터', '드워프', '로보로브스키', '직접입력'],
    ),
    AnimalSpeciesGroup(
      name: '기니피그',
      subSpecies: ['아메리칸', '퍼비안', '압신스', '직접입력'],
    ),
    AnimalSpeciesGroup(
      name: '토끼',
      subSpecies: ['네덜란드 드워프', '라이온헤드', '미니렉스', '직접입력'],
    ),
  ],
};
