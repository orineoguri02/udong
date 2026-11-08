import 'dart:async';

import '../models/pet-profile.dart';

/// Pet 프로필 조회 API 매핑 계약
///
/// - profile-select-dialog(홈/설정, 편집 포함): `/pet/me` -> [FetchMyPetProfilesRequested]
/// - status-record-page: `/pet/me` -> [FetchMyPetProfilesRequested]
/// - home/widgets/profile-card(카드 본문 표시 데이터): `/pet/main` -> [FetchPetProfilesRequested]
/// - pet-family-settings-page(본문): `/pet/main` -> [FetchPetProfilesRequested]
///
/// 주의:
/// - 페이지에서 Repository를 직접 호출하지 않는다.
/// - 반드시 화면 목적에 맞는 이벤트 타입을 선택한다.

/// Home 화면 BLoC 이벤트 (데이터 로딩/갱신만, 화면 전환 없음)
sealed class HomeEvent {
  const HomeEvent();
}

/// 진입 시 초기 데이터 로드
final class HomeStarted extends HomeEvent {
  const HomeStarted();
}

/// 당겨서 새로고침 등
final class RefreshHome extends HomeEvent {
  const RefreshHome();
}

/// 프로필 카드에서 반려동물 선택 변경 (또는 MyPage 복귀 시)
final class ProfileSelected extends HomeEvent {
  final int index;
  const ProfileSelected(this.index);
}

/// pet_id 기반 메인 반려가족 선택 (설정/다이얼로그에서 사용)
final class MainPetSelected extends HomeEvent {
  final int petId;
  final PetProfile profile;

  const MainPetSelected({required this.petId, required this.profile});
}

/// 마이페이지/반려가족 설정에서 프로필 데이터가 수정된 경우
final class ProfilesUpdated extends HomeEvent {
  final List<PetProfile> profiles;
  final int selectedIndex;

  const ProfilesUpdated({required this.profiles, required this.selectedIndex});
}

/// /pet/me 조회 요청 (페이지에서 Repository 직접 호출 금지)
final class FetchMyPetProfilesRequested extends HomeEvent {
  final Completer<List<PetProfile>> completer;

  const FetchMyPetProfilesRequested({required this.completer});
}

/// /pet/main 조회 요청 (페이지에서 Repository 직접 호출 금지)
final class FetchPetProfilesRequested extends HomeEvent {
  final Completer<List<PetProfile>> completer;

  const FetchPetProfilesRequested({required this.completer});
}

/// 반려가족 생성 요청
final class CreatePetProfileRequested extends HomeEvent {
  final PetProfile profile;
  final String? imagePath;
  final Completer<PetProfile> completer;

  const CreatePetProfileRequested({
    required this.profile,
    this.imagePath,
    required this.completer,
  });
}

/// 반려가족 수정 요청
final class UpdatePetProfileRequested extends HomeEvent {
  final int petId;
  final PetProfile profile;
  final String? imagePath;
  final Completer<PetProfile> completer;

  const UpdatePetProfileRequested({
    required this.petId,
    required this.profile,
    this.imagePath,
    required this.completer,
  });
}

/// 반려가족 삭제 요청
final class DeletePetProfileRequested extends HomeEvent {
  final int petId;
  final Completer<void> completer;

  const DeletePetProfileRequested({
    required this.petId,
    required this.completer,
  });
}

/// 월별 상태 기록 조회 요청
final class FetchPetStateRecordsByMonthRequested extends HomeEvent {
  final int petId;
  final int year;
  final int month;
  final Completer<Map<String, Map<String, dynamic>>> completer;

  const FetchPetStateRecordsByMonthRequested({
    required this.petId,
    required this.year,
    required this.month,
    required this.completer,
  });
}

/// 상태 기록 상세 조회 요청
final class FetchPetStateRecordDetailRequested extends HomeEvent {
  final int petId;
  final String date;
  final String view;
  final Completer<Map<String, dynamic>?> completer;

  const FetchPetStateRecordDetailRequested({
    required this.petId,
    required this.date,
    required this.view,
    required this.completer,
  });
}

/// 상태 기록 저장 요청 (post/patch 공통)
final class SavePetStateRecordRequested extends HomeEvent {
  final int petId;
  final bool isEditMode;
  final String? date;
  final Map<String, dynamic> body;
  final String? imagePath;
  final Completer<void> completer;

  const SavePetStateRecordRequested({
    required this.petId,
    required this.isEditMode,
    this.date,
    required this.body,
    this.imagePath,
    required this.completer,
  });
}
