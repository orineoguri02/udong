/// API 엔드포인트 경로 상수입니다.
///
/// - 역할: 백엔드 path를 한 곳에서 관리 (오타 방지, 버전 변경 시 수정 용이)
/// - 사용: Repository에서 `apiClient.get(ApiEndpoints.hospitals)` 형태로 참조
/// - baseUrl은 ApiClient에서 처리하므로 여기서는 path만 정의 (앞에 / 포함 권장)

abstract final class ApiEndpoints {
  ApiEndpoints._();
  // --- 인증/사용자 ---
  //유저 프로필 조회
  static const String profile = '/user/{user_id}/profile';

  /// 유저 프로필 수정
  static const String profileEdit = '/user/{user_id}';

  /// 회원가입 (유저 + 펫)
  static const String signupUserAndPet = '/user/signup/with-pet';

  /// 회원가입 유저만
  static const String signupUser = '/user/signup';

  /// 익명 로그인
  static const String anonymousLogin = '/user/anonymous/login';

  /// 로그아웃
  static const String logout = '/user/logout';

  /// 회원탈퇴
  static const String withdrawal = '/user/{user_id}';

  /// 반려동물 메인 정보 조회
  static const String petMain = '/pet/main';

  /// 내 반려동물 전체 조회
  static const String petMe = '/pet/me';

  /// 메인 반려동물 선택
  static const String petMainSelect = '/pet/main/{pet_id}';

  /// 반려동물 신규 등록
  static const String petNew = '/pet/new';

  /// 반려동물 정보 수정
  static const String petUpdate = '/pet/{pet_id}';

  /// 반려동물 삭제
  static const String petDelete = '/pet/{pet_id}';

  /// 오늘의 상태 기록 등록
  static const String petState = '/pet/{pet_id}/state';

  /// 월별 상태 기록 조회 (캘린더)
  static const String petStateCalendar = '/pet/{pet_id}/state/calendar';

  /// 날짜별 상태 기록 상세 조회
  static const String petStateDetail = '/pet/{pet_id}/state/detail';

  /// 메인 병원 목록 조회 (현재 위치 기준)
  static const String clinicMain = '/clinic/main';

  /// 병원 상세 조회
  static const String clinicDetail = '/clinic/{clinic_id}/detail';

  /// 홈 광고 배너 조회
  static const String adsTotal = '/ads/total';

  /// 홈 랜덤 매거진 조회
  static const String magazineRandom = '/magazine/random';
}
