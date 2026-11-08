import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/pet-profile.dart';
import '../repository/home-repository.dart';
import 'home-event.dart';
import 'home-state.dart';

/// Home 데이터만 관리. 화면 전환/네비게이션은 모른다.
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final HomeRepository _repo;

  HomeBloc(this._repo, {required HomeState initialState})
    : super(initialState) {
    // 처리 중인 fetch가 있으면 새로 들어온 동일 이벤트를 drop.
    // 수동 _isFetchingProfiles 플래그 불필요.
    on<HomeStarted>(_onHomeStarted, transformer: droppable());
    on<RefreshHome>(_onRefreshHome, transformer: droppable());
    on<ProfileSelected>(_onProfileSelected);
    on<MainPetSelected>(_onMainPetSelected);
    on<ProfilesUpdated>(_onProfilesUpdated);
    on<FetchMyPetProfilesRequested>(
      _onFetchMyPetProfilesRequested,
      transformer: sequential(),
    );
    on<FetchPetProfilesRequested>(
      _onFetchPetProfilesRequested,
      transformer: sequential(),
    );
    on<CreatePetProfileRequested>(_onCreatePetProfileRequested);
    on<UpdatePetProfileRequested>(_onUpdatePetProfileRequested);
    on<DeletePetProfileRequested>(_onDeletePetProfileRequested);
    on<FetchPetStateRecordsByMonthRequested>(
      _onFetchPetStateRecordsByMonthRequested,
    );
    on<FetchPetStateRecordDetailRequested>(
      _onFetchPetStateRecordDetailRequested,
    );
    on<SavePetStateRecordRequested>(_onSavePetStateRecordRequested);
  }

  Future<void> _onHomeStarted(HomeStarted event, Emitter<HomeState> emit) =>
      _doFetchHome(emit);

  Future<void> _onRefreshHome(RefreshHome event, Emitter<HomeState> emit) =>
      _doFetchHome(emit);

  /// 홈 데이터 fetch 공통 로직.
  /// [HomeStarted], [RefreshHome] 모두 이 메서드를 직접 호출한다.
  /// droppable() 트랜스포머가 동시성을 보장하므로 수동 플래그 불필요.
  Future<void> _doFetchHome(Emitter<HomeState> emit) async {
    final shouldShowProfileLoading =
        state.user.id != 'guest' && state.profiles.isEmpty && !state.isLoading;
    final shouldShowAdBannerLoading =
        state.adBannerUrls.isEmpty && !state.isAdBannerLoading;
    final shouldShowMagazineLoading =
        state.magazineUrls.isEmpty && !state.isMagazineLoading;
    if (shouldShowProfileLoading) {
      emit(
        state.copyWith(
          isLoading: true,
          isAdBannerLoading: shouldShowAdBannerLoading
              ? true
              : state.isAdBannerLoading,
          isMagazineLoading: shouldShowMagazineLoading
              ? true
              : state.isMagazineLoading,
        ),
      );
    } else if (shouldShowAdBannerLoading) {
      emit(state.copyWith(isAdBannerLoading: true));
    } else if (shouldShowMagazineLoading) {
      emit(state.copyWith(isMagazineLoading: true));
    }

    final adBannerFuture = () async {
      try {
        return await _repo.fetchAdBannerUrls();
      } catch (_) {
        return null;
      }
    }();
    final magazineFuture = () async {
      try {
        return await _repo.fetchMagazineUrls();
      } catch (_) {
        return null;
      }
    }();

    List<PetProfile>? fetchedProfiles;
    if (state.user.id == 'guest') {
      fetchedProfiles = const <PetProfile>[];
    } else {
      try {
        fetchedProfiles = await _repo.fetchPetProfiles();
      } catch (_) {
        // 기존 데이터 유지
      }
    }

    final profiles =
        fetchedProfiles ??
        (state.user.id == 'guest' ? const <PetProfile>[] : state.profiles);

    final selectedPetId = state.selectedPet?.petId;
    var index = 0;
    if (profiles.isNotEmpty && selectedPetId != null) {
      final matched = profiles.indexWhere((p) => p.petId == selectedPetId);
      if (matched >= 0) index = matched;
    }

    final profileLoadedState = state.copyWith(
      profiles: profiles,
      selectedProfileIndex: profiles.isEmpty ? 0 : index,
      isLoading: false,
    );
    if (profileLoadedState != state) {
      emit(profileLoadedState);
    } else if (state.isLoading) {
      emit(state.copyWith(isLoading: false));
    }

    final fetchedAdBannerUrls = await adBannerFuture;
    final fetchedMagazineUrls = await magazineFuture;
    final mediaLoadedState = state.copyWith(
      adBannerUrls: fetchedAdBannerUrls ?? state.adBannerUrls,
      magazineUrls: fetchedMagazineUrls ?? state.magazineUrls,
      isAdBannerLoading: false,
      isMagazineLoading: false,
    );
    if (mediaLoadedState != state) {
      emit(mediaLoadedState);
    } else if (state.isAdBannerLoading || state.isMagazineLoading) {
      emit(state.copyWith(isAdBannerLoading: false, isMagazineLoading: false));
    }
  }

  Future<void> _onProfileSelected(
    ProfileSelected event,
    Emitter<HomeState> emit,
  ) async {
    var index = event.index;
    if (index < 0 || index >= state.profiles.length) index = 0;
    if (index == state.selectedProfileIndex) return;
    final selectedPet = state.profiles.isNotEmpty
        ? state.profiles[index]
        : null;
    final nextState = state.copyWith(selectedProfileIndex: index);
    if (nextState != state) {
      emit(nextState);
    }
    if (selectedPet != null && selectedPet.petId != null) {
      await _selectMainPetAndMaybeRefresh(
        selectedPet: selectedPet,
        refreshOnIncomplete: true,
      );
    }
  }

  Future<void> _onProfilesUpdated(
    ProfilesUpdated event,
    Emitter<HomeState> emit,
  ) async {
    final previousSelectedPetId = state.selectedPet?.petId;
    final profiles = List<PetProfile>.from(event.profiles);
    var index = event.selectedIndex;
    if (profiles.isEmpty) {
      index = 0;
    } else if (index < 0 || index >= profiles.length) {
      index = 0;
    }
    final selectedPet = profiles.isNotEmpty ? profiles[index] : null;
    final isSameState =
        HomeState.areSameProfiles(state.profiles, profiles) &&
        state.selectedProfileIndex == index;
    if (!isSameState) {
      emit(state.copyWith(profiles: profiles, selectedProfileIndex: index));
    }

    final petId = selectedPet?.petId;
    if (petId != null && petId != previousSelectedPetId) {
      await _selectMainPetAndMaybeRefresh(
        selectedPet: selectedPet!,
        refreshOnIncomplete: true,
      );
    }
  }

  Future<void> _onMainPetSelected(
    MainPetSelected event,
    Emitter<HomeState> emit,
  ) async {
    final optimisticProfiles = List<PetProfile>.from(state.profiles);
    var optimisticIndex = optimisticProfiles.indexWhere(
      (p) => p.petId == event.petId,
    );
    if (optimisticIndex >= 0) {
      final current = optimisticProfiles[optimisticIndex];
      optimisticProfiles[optimisticIndex] = _mergeMainProfile(
        mainProfile: event.profile,
        fallback: current,
        petId: event.petId,
      );
    } else {
      optimisticProfiles.add(event.profile);
      optimisticIndex = optimisticProfiles.length - 1;
    }

    final optimisticState = state.copyWith(
      profiles: optimisticProfiles,
      selectedProfileIndex: optimisticIndex,
    );
    if (optimisticState != state) {
      emit(optimisticState);
    }

    await _selectMainPetAndMaybeRefresh(
      selectedPet: event.profile,
      petIdOverride: event.petId,
      refreshOnIncomplete: true,
    );
  }

  bool _isProfileIncomplete(PetProfile profile) {
    return profile.animalType.trim().isEmpty ||
        profile.birthDate.trim().isEmpty;
  }

  PetProfile _mergeMainProfile({
    required PetProfile mainProfile,
    required PetProfile fallback,
    required int petId,
  }) {
    return PetProfile.merge(
      primary: mainProfile.petId == null
          ? mainProfile.copyWith(petId: petId)
          : mainProfile,
      fallback: fallback,
    );
  }

  Future<void> _selectMainPetAndMaybeRefresh({
    required PetProfile selectedPet,
    int? petIdOverride,
    bool refreshOnIncomplete = false,
    bool forceRefresh = false,
  }) async {
    final petId = petIdOverride ?? selectedPet.petId;
    if (petId == null) return;
    try {
      await _repo.selectMainPet(petId: petId);
      final needsRefresh =
          forceRefresh ||
          (refreshOnIncomplete && _isProfileIncomplete(selectedPet));
      if (needsRefresh) {
        add(const RefreshHome());
      }
    } catch (_) {
      // 화면 상태는 유지하고 서버 동기화 실패는 다음 조회에서 복구한다.
    }
  }

  Future<void> _onFetchMyPetProfilesRequested(
    FetchMyPetProfilesRequested event,
    Emitter<HomeState> emit,
  ) async {
    try {
      final profiles = await _repo.fetchMyPetProfiles();
      if (!event.completer.isCompleted) {
        event.completer.complete(profiles);
      }
    } catch (e, st) {
      if (!event.completer.isCompleted) {
        event.completer.completeError(e, st);
      }
    }
  }

  Future<void> _onFetchPetProfilesRequested(
    FetchPetProfilesRequested event,
    Emitter<HomeState> emit,
  ) async {
    try {
      final profiles = await _repo.fetchPetProfiles();
      if (!event.completer.isCompleted) {
        event.completer.complete(profiles);
      }
    } catch (e, st) {
      if (!event.completer.isCompleted) {
        event.completer.completeError(e, st);
      }
    }
  }

  Future<void> _onCreatePetProfileRequested(
    CreatePetProfileRequested event,
    Emitter<HomeState> emit,
  ) async {
    try {
      final created = await _repo.createPetProfile(
        profile: event.profile,
        imagePath: event.imagePath,
      );
      if (!event.completer.isCompleted) {
        event.completer.complete(created);
      }
    } catch (e, st) {
      if (!event.completer.isCompleted) {
        event.completer.completeError(e, st);
      }
    }
  }

  Future<void> _onUpdatePetProfileRequested(
    UpdatePetProfileRequested event,
    Emitter<HomeState> emit,
  ) async {
    try {
      final saved = await _repo.updatePetProfile(
        petId: event.petId,
        profile: event.profile,
        imagePath: event.imagePath,
      );
      if (!event.completer.isCompleted) {
        event.completer.complete(saved);
      }
    } catch (e, st) {
      if (!event.completer.isCompleted) {
        event.completer.completeError(e, st);
      }
    }
  }

  Future<void> _onDeletePetProfileRequested(
    DeletePetProfileRequested event,
    Emitter<HomeState> emit,
  ) async {
    try {
      await _repo.deletePetProfile(petId: event.petId);
      final nextProfiles = state.profiles
          .where((profile) => profile.petId != event.petId)
          .toList();
      var nextSelectedIndex = state.selectedProfileIndex;
      if (nextProfiles.isEmpty) {
        nextSelectedIndex = 0;
      } else if (nextSelectedIndex >= nextProfiles.length) {
        nextSelectedIndex = nextProfiles.length - 1;
      } else if (nextSelectedIndex < 0) {
        nextSelectedIndex = 0;
      }

      final nextState = state.copyWith(
        profiles: nextProfiles,
        selectedProfileIndex: nextSelectedIndex,
      );
      if (nextState != state) {
        emit(nextState);
      }

      // 삭제 직후 화면은 즉시 로컬 상태로 반영하고,
      // 서버 기준 메인 프로필은 후속 refresh로 동기화한다.
      add(const RefreshHome());
      if (!event.completer.isCompleted) {
        event.completer.complete();
      }
    } catch (e, st) {
      if (!event.completer.isCompleted) {
        event.completer.completeError(e, st);
      }
    }
  }

  Future<void> _onFetchPetStateRecordsByMonthRequested(
    FetchPetStateRecordsByMonthRequested event,
    Emitter<HomeState> emit,
  ) async {
    try {
      final records = await _repo.fetchPetStateRecordsByMonth(
        petId: event.petId,
        year: event.year,
        month: event.month,
      );
      if (!event.completer.isCompleted) {
        event.completer.complete(records);
      }
    } catch (e, st) {
      if (!event.completer.isCompleted) {
        event.completer.completeError(e, st);
      }
    }
  }

  Future<void> _onFetchPetStateRecordDetailRequested(
    FetchPetStateRecordDetailRequested event,
    Emitter<HomeState> emit,
  ) async {
    try {
      final detail = await _repo.fetchPetStateRecordDetail(
        petId: event.petId,
        date: event.date,
        view: event.view,
      );
      if (!event.completer.isCompleted) {
        event.completer.complete(detail);
      }
    } catch (e, st) {
      if (!event.completer.isCompleted) {
        event.completer.completeError(e, st);
      }
    }
  }

  Future<void> _onSavePetStateRecordRequested(
    SavePetStateRecordRequested event,
    Emitter<HomeState> emit,
  ) async {
    try {
      if (event.isEditMode) {
        final date = event.date?.trim() ?? '';
        if (date.isEmpty) {
          throw ArgumentError('date is required when isEditMode=true');
        }
        await _repo.updatePetStateRecord(
          petId: event.petId,
          date: date,
          body: event.body,
          imagePath: event.imagePath,
        );
      } else {
        await _repo.createPetStateRecord(
          petId: event.petId,
          body: event.body,
          imagePath: event.imagePath,
        );
      }
      if (!event.completer.isCompleted) {
        event.completer.complete();
      }
    } catch (e, st) {
      if (!event.completer.isCompleted) {
        event.completer.completeError(e, st);
      }
    }
  }
}
