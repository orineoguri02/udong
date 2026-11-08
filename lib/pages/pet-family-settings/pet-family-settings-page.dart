import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app-theme.dart';
import '../../core/utils/app-size.dart';
import '../../core/widgets/page-title-app-bar.dart';
import '../../core/widgets/profile-select-dialog.dart';
import '../../features/home/bloc/home-bloc.dart';
import '../../features/home/bloc/home-event.dart';
import '../../features/home/bloc/home-state.dart';
import '../../features/home/models/pet-profile.dart';
import 'animal-type-select-page.dart';
import 'widgets/animal-type-section.dart';
import 'widgets/birth-adopt-date-section.dart';
import 'widgets/profile-settings-section.dart';

class PetFamilySettingsResult {
  final int selectedIndex;
  final List<PetProfile> profiles;

  const PetFamilySettingsResult({
    required this.selectedIndex,
    required this.profiles,
  });
}

class PetFamilySettingsPage extends StatefulWidget {
  final int initialSelectedIndex;
  final List<PetProfile> initialProfiles;
  final bool startWithAddProfile;

  const PetFamilySettingsPage({
    super.key,
    this.initialSelectedIndex = 0,
    this.initialProfiles = const [],
    this.startWithAddProfile = false,
  });

  @override
  State<PetFamilySettingsPage> createState() => _PetFamilySettingsPageState();
}

class _PetFamilySettingsPageState extends State<PetFamilySettingsPage> {
  late List<PetProfile> _profiles;
  late int _selectedIndex;
  bool _isNewProfile = false;
  bool _isSaving = false;
  late final TextEditingController _nameController;
  late final TextEditingController _animalTypeController;
  late final TextEditingController _breedController;
  bool _isMale = true;
  DateTime? _birthDate;
  DateTime? _adoptDate;
  String? _pickedImagePath;

  @override
  void initState() {
    super.initState();
    final homeState = context.read<HomeBloc>().state;
    final useInitialProfilesFirst =
        widget.startWithAddProfile && widget.initialProfiles.isNotEmpty;

    if (useInitialProfilesFirst) {
      _profiles = List<PetProfile>.from(widget.initialProfiles);
      _selectedIndex = widget.initialSelectedIndex;
      if (_selectedIndex < 0 || _selectedIndex >= _profiles.length) {
        _selectedIndex = 0;
      }
    } else if (homeState.profiles.isNotEmpty) {
      _profiles = List<PetProfile>.from(homeState.profiles);
      _selectedIndex = homeState.selectedProfileIndex;
      if (_selectedIndex < 0 || _selectedIndex >= _profiles.length) {
        _selectedIndex = 0;
      }
    } else {
      _selectedIndex = widget.initialSelectedIndex;
      _profiles = widget.initialProfiles.isNotEmpty
          ? List<PetProfile>.from(widget.initialProfiles)
          : List<PetProfile>.from(defaultPetProfiles);
    }
    _nameController = TextEditingController();
    _animalTypeController = TextEditingController();
    _breedController = TextEditingController();
    _isNewProfile = widget.startWithAddProfile;
    if (_isNewProfile) {
      _resetNewProfileForm();
    } else {
      _applyProfileToForm(_currentBaseProfile);
    }
    if (homeState.user.id != 'guest') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _loadDetailedProfilesIfNeeded();
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _animalTypeController.dispose();
    _breedController.dispose();
    super.dispose();
  }

  int get _safeIndex {
    if (_profiles.isEmpty) return 0;
    final index = _selectedIndex;
    if (index < 0) return 0;
    if (index >= _profiles.length) return _profiles.length - 1;
    return index;
  }

  PetProfile get _currentBaseProfile {
    if (_profiles.isEmpty) {
      return const PetProfile(
        name: '',
        isMale: true,
        animalType: '',
        breed: '',
        birthDate: '',
        adoptDate: '',
      );
    }
    return _profiles[_safeIndex];
  }

  void _applyProfileToForm(PetProfile profile) {
    _nameController.text = profile.name;
    _animalTypeController.text = profile.animalType;
    _breedController.text = profile.breed;
    _isMale = profile.isMale;
    _birthDate = _parseDate(profile.birthDate);
    _adoptDate = _parseDate(profile.adoptDate);
    _pickedImagePath = null;
  }

  void _resetNewProfileForm() {
    _nameController.clear();
    _animalTypeController.clear();
    _breedController.clear();
    _isMale = true;
    _birthDate = null;
    _adoptDate = null;
    _pickedImagePath = null;
  }

  bool _shouldFetchProfiles(List<PetProfile> profiles) {
    if (profiles.isEmpty || profiles.length <= 1) return true;
    return profiles.every((profile) => profile.petId == null);
  }

  bool _needsDetailedProfile(PetProfile profile) {
    return profile.animalType.trim().isEmpty ||
        profile.breed.trim().isEmpty ||
        profile.birthDate.trim().isEmpty;
  }

  Future<void> _loadDetailedProfilesIfNeeded() async {
    if (_isSaving) return;
    final shouldFetch =
        _shouldFetchProfiles(_profiles) || _profiles.any(_needsDetailedProfile);
    if (!shouldFetch) return;

    try {
      final loaded = await _requestMainPetProfiles();
      if (!mounted || loaded.isEmpty) return;
      final mergedLoaded = _mergeProfilesWithFallback(
        incoming: List<PetProfile>.from(loaded),
        fallback: _profiles,
      );

      final selectedPetId = _currentBaseProfile.petId;
      var nextIndex = _selectedIndex;
      if (selectedPetId != null) {
        final matched = mergedLoaded.indexWhere(
          (p) => p.petId == selectedPetId,
        );
        if (matched >= 0) {
          nextIndex = matched;
        }
      }
      if (nextIndex < 0 || nextIndex >= mergedLoaded.length) {
        nextIndex = 0;
      }

      setState(() {
        _profiles = mergedLoaded;
        _selectedIndex = nextIndex;
        if (!_isNewProfile) {
          _applyProfileToForm(_currentBaseProfile);
        }
      });
    } catch (_) {}
  }

  List<PetProfile> _mergeProfilesWithFallback({
    required List<PetProfile> incoming,
    required List<PetProfile> fallback,
  }) {
    if (fallback.isEmpty) return incoming;
    final fallbackByPetId = <int, PetProfile>{
      for (final profile in fallback)
        if (profile.petId != null) profile.petId!: profile,
    };

    return incoming.map((profile) {
      final petId = profile.petId;
      if (petId == null) return profile;
      final previous = fallbackByPetId[petId];
      if (previous == null) return profile;
      final mergedIsMale = (!previous.isMale && profile.isMale)
          ? previous.isMale
          : profile.isMale;
      return profile.copyWith(
        isMale: mergedIsMale,
        animalType: profile.animalType.trim().isNotEmpty
            ? profile.animalType
            : previous.animalType,
        breed: profile.breed.trim().isNotEmpty ? profile.breed : previous.breed,
        birthDate: profile.birthDate.trim().isNotEmpty
            ? profile.birthDate
            : previous.birthDate,
        adoptDate: profile.adoptDate.trim().isNotEmpty
            ? profile.adoptDate
            : previous.adoptDate,
      );
    }).toList();
  }

  void _syncFromHomeState(HomeState state) {
    if (!mounted) return;
    var nextIndex = state.selectedProfileIndex;
    if (state.profiles.isEmpty) {
      nextIndex = 0;
    } else if (nextIndex < 0 || nextIndex >= state.profiles.length) {
      nextIndex = 0;
    }
    final nextProfiles = _mergeProfilesWithFallback(
      incoming: List<PetProfile>.from(state.profiles),
      fallback: _profiles,
    );
    final changed =
        _selectedIndex != nextIndex ||
        !HomeState.areSameProfiles(_profiles, nextProfiles);
    if (!changed) return;

    setState(() {
      _profiles = nextProfiles;
      _selectedIndex = nextIndex;
      if (!_isNewProfile) {
        _applyProfileToForm(_currentBaseProfile);
      }
    });
  }

  DateTime? _parseDate(String raw) {
    if (raw.trim().isEmpty) return null;
    final parts = raw.split(RegExp(r'[.\-/]'));
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    return DateTime(year, month, day);
  }

  /// 반려가족 설정 본문 데이터는 `/pet/main` 기준으로 불러온다.
  Future<List<PetProfile>> _requestMainPetProfiles() {
    final completer = Completer<List<PetProfile>>();
    context.read<HomeBloc>().add(
      FetchPetProfilesRequested(completer: completer),
    );
    return completer.future;
  }

  /// 프로필 선택 다이얼로그(편집)는 `/pet/me` 기준으로 불러온다.
  Future<List<PetProfile>> _requestMyPetProfiles() {
    final completer = Completer<List<PetProfile>>();
    context.read<HomeBloc>().add(
      FetchMyPetProfilesRequested(completer: completer),
    );
    return completer.future;
  }

  Future<PetProfile> _requestCreatePetProfile({
    required PetProfile profile,
    String? imagePath,
  }) {
    final completer = Completer<PetProfile>();
    context.read<HomeBloc>().add(
      CreatePetProfileRequested(
        profile: profile,
        imagePath: imagePath,
        completer: completer,
      ),
    );
    return completer.future;
  }

  Future<PetProfile> _requestUpdatePetProfile({
    required int petId,
    required PetProfile profile,
    String? imagePath,
  }) {
    final completer = Completer<PetProfile>();
    context.read<HomeBloc>().add(
      UpdatePetProfileRequested(
        petId: petId,
        profile: profile,
        imagePath: imagePath,
        completer: completer,
      ),
    );
    return completer.future;
  }

  Future<void> _requestDeletePetProfile({required int petId}) {
    final completer = Completer<void>();
    context.read<HomeBloc>().add(
      DeletePetProfileRequested(petId: petId, completer: completer),
    );
    return completer.future;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '${date.year}.$mm.$dd';
  }

  Future<void> _onSave() async {
    if (_isSaving) return;

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('반려가족 이름을 입력해주세요.')));
      return;
    }

    final animalType = _animalTypeController.text.trim();
    final breedText = _breedController.text.trim();

    final candidate = PetProfile(
      name: name,
      isMale: _isMale,
      animalType: animalType,
      breed: breedText,
      birthDate: _formatDate(_birthDate),
      adoptDate: _formatDate(_adoptDate),
    );

    final shouldCreateAsNew =
        _isNewProfile || _currentBaseProfile.petId == null;
    if (shouldCreateAsNew) {
      final replacingNullPetSlot =
          !_isNewProfile &&
          _profiles.isNotEmpty &&
          _currentBaseProfile.petId == null;

      setState(() => _isSaving = true);
      try {
        final created = await _requestCreatePetProfile(
          profile: candidate,
          imagePath: _pickedImagePath,
        );

        if (!mounted) return;
        setState(() {
          final createdWithLocalImage =
              (_pickedImagePath != null && _pickedImagePath!.trim().isNotEmpty)
              ? created.copyWith(imageUrl: _pickedImagePath!.trim())
              : created;

          final next = List<PetProfile>.from(_profiles);
          if (replacingNullPetSlot) {
            final replaceIndex = _safeIndex;
            next[replaceIndex] = createdWithLocalImage;
            _selectedIndex = replaceIndex;
          } else {
            next.add(createdWithLocalImage);
            _selectedIndex = next.length - 1;
          }

          _profiles = next;
          _isNewProfile = false;
          _isSaving = false;
          _applyProfileToForm(_profiles[_selectedIndex]);
        });
        context.read<HomeBloc>().add(
          ProfilesUpdated(
            profiles: List<PetProfile>.from(_profiles),
            selectedIndex: _selectedIndex,
          ),
        );
        Navigator.of(context).pop(
          PetFamilySettingsResult(
            selectedIndex: _selectedIndex,
            profiles: List<PetProfile>.from(_profiles),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('반려가족 추가 실패: $e')));
      }
      return;
    }

    if (_profiles.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('수정할 반려가족 정보가 없습니다.')));
      return;
    }

    final baseProfile = _currentBaseProfile;
    final petId = baseProfile.petId;
    if (petId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('pet_id가 없어 저장할 수 없습니다.')));
      return;
    }

    final updateCandidate = baseProfile.copyWith(
      name: name,
      isMale: _isMale,
      animalType: animalType,
      breed: breedText,
      birthDate: _formatDate(_birthDate),
      adoptDate: _formatDate(_adoptDate),
    );

    setState(() => _isSaving = true);
    try {
      final pickedImagePath = _pickedImagePath?.trim();
      final effectiveImagePath =
          (pickedImagePath != null && pickedImagePath.isNotEmpty)
          ? pickedImagePath
          : null;

      final saved = await _requestUpdatePetProfile(
        petId: petId,
        profile: updateCandidate,
        imagePath: effectiveImagePath,
      );
      if (!mounted) return;
      setState(() {
        final next = List<PetProfile>.from(_profiles);
        final localImage =
            (pickedImagePath != null && pickedImagePath.isNotEmpty)
            ? pickedImagePath
            : null;
        next[_safeIndex] = saved.copyWith(
          petId: saved.petId ?? petId,
          imageUrl: localImage ?? saved.imageUrl ?? baseProfile.imageUrl,
        );
        _profiles = next;
        _isSaving = false;
      });
      context.read<HomeBloc>().add(
        ProfilesUpdated(
          profiles: List<PetProfile>.from(_profiles),
          selectedIndex: _selectedIndex,
        ),
      );
      Navigator.of(context).pop(
        PetFamilySettingsResult(
          selectedIndex: _selectedIndex,
          profiles: List<PetProfile>.from(_profiles),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('반려가족 저장 실패: $e')));
    }
  }

  Future<void> _selectAnimalType() async {
    final selected = await Navigator.of(context).push<Map<String, String>>(
      MaterialPageRoute<Map<String, String>>(
        builder: (_) => const AnimalTypeSelectPage(),
      ),
    );
    if (selected == null || !mounted) return;

    final category = (selected['category'] ?? '').trim();
    final species = (selected['species'] ?? '').trim();

    if (category.isNotEmpty) {
      _animalTypeController.text = category;
    }
    if (species.isNotEmpty && species != '직접입력') {
      _breedController.text = species;
    } else {
      _breedController.clear();
    }
    setState(() {});
  }

  Future<void> _showProfileDialog() async {
    var dialogProfiles = List<PetProfile>.from(_profiles);
    var fetchFailed = false;
    final isGuest = context.read<HomeBloc>().state.user.id == 'guest';
    if (!isGuest) {
      try {
        final loaded = await _requestMyPetProfiles();
        if (loaded.isNotEmpty) {
          dialogProfiles = _mergeProfilesWithFallback(
            incoming: List<PetProfile>.from(loaded),
            fallback: dialogProfiles,
          );
        }
      } catch (_) {
        fetchFailed = true;
      }
    }
    // petId 없는 기본 플레이스홀더 제거 — 진짜 등록된 프로필만 다이얼로그에 표시
    dialogProfiles = dialogProfiles.where((p) => p.petId != null).toList();

    if (!mounted) return;
    if (fetchFailed) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('반려가족 목록을 불러오지 못했습니다.')));
    }

    // 실제 프로필이 없으면 추가 버튼만 있는 다이얼로그 표시
    final currentSelectedPetId = _currentBaseProfile.petId;
    var initialSelectedIndex = 0;
    if (currentSelectedPetId != null && dialogProfiles.isNotEmpty) {
      final matched = dialogProfiles.indexWhere(
        (p) => p.petId == currentSelectedPetId,
      );
      if (matched >= 0) initialSelectedIndex = matched;
    }
    if (dialogProfiles.isNotEmpty &&
        (initialSelectedIndex < 0 ||
            initialSelectedIndex >= dialogProfiles.length)) {
      initialSelectedIndex = 0;
    }

    final labels = dialogProfiles
        .map((e) => e.name.isNotEmpty ? e.name : '프로필')
        .toList();
    // petId == null 프로필은 이미 필터링됐으므로 nonDeletableIndices는 비어있음
    const nonDeletableIndices = <int>{};

    final selected = await showProfileSelectDialog(
      context: context,
      labels: labels,
      imageUrls: dialogProfiles.map((e) => e.imageUrl).toList(),
      initialSelectedIndex: initialSelectedIndex,
      enableEdit: true,
      nonDeletableIndices: nonDeletableIndices,
      onDeleteIndex: (index) async {
        if (index < 0 || index >= dialogProfiles.length) return false;
        final target = dialogProfiles[index];
        final targetPetId = target.petId;
        if (targetPetId == null) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('삭제할 수 없는 프로필입니다.')));
          }
          return false;
        }

        try {
          await _requestDeletePetProfile(petId: targetPetId);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('반려가족 삭제 실패: $e')));
          }
          return false;
        }

        dialogProfiles.removeAt(index);
        if (!mounted) return true;

        if (dialogProfiles.isEmpty) {
          setState(() {
            _profiles = const <PetProfile>[];
            _selectedIndex = 0;
            _isNewProfile = true;
            _resetNewProfileForm();
          });
          context.read<HomeBloc>().add(
            const ProfilesUpdated(profiles: <PetProfile>[], selectedIndex: 0),
          );
          return true;
        }

        var nextIndex = 0;
        if (currentSelectedPetId != null) {
          final matched = dialogProfiles.indexWhere(
            (profile) => profile.petId == currentSelectedPetId,
          );
          if (matched >= 0) {
            nextIndex = matched;
          }
        }
        if (nextIndex < 0 || nextIndex >= dialogProfiles.length) {
          nextIndex = 0;
        }

        setState(() {
          _profiles = List<PetProfile>.from(dialogProfiles);
          _selectedIndex = nextIndex;
          _isNewProfile = false;
          _applyProfileToForm(_profiles[_selectedIndex]);
        });
        return true;
      },
    );
    if (!mounted || selected == null || dialogProfiles.isEmpty) return;

    // -1: 새 반려가족 추가 선택
    if (selected == -1) {
      setState(() {
        _isNewProfile = true;
        _resetNewProfileForm();
      });
      return;
    }

    final selectedProfile = dialogProfiles[selected];
    setState(() {
      _isNewProfile = false;
      _profiles = List<PetProfile>.from(dialogProfiles);
      _selectedIndex = selected;
      _applyProfileToForm(selectedProfile);
    });
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final baseProfile = _currentBaseProfile;
    final profile = _isNewProfile
        ? const PetProfile(
            name: '',
            isMale: true,
            animalType: '',
            breed: '',
            birthDate: '',
            adoptDate: '',
          )
        : baseProfile;

    return BlocListener<HomeBloc, HomeState>(
      listenWhen: (previous, current) {
        return previous.selectedProfileIndex != current.selectedProfileIndex ||
            !HomeState.areSameProfiles(previous.profiles, current.profiles);
      },
      listener: (context, state) {
        _syncFromHomeState(state);
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Scaffold(
          backgroundColor: const Color(0xFFFFFFFF),
          appBar: PageTitleAppBar(title: '반려가족 설정'),
          body: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(15.s, 21.s, 15.s, 43.s),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProfileSettingsSection(
                  key: ValueKey(
                    'profile-$_selectedIndex-${profile.name}-${profile.isMale}',
                  ),
                  onShowDialog: _showProfileDialog,
                  profile: profile.copyWith(
                    name: _nameController.text,
                    isMale: _isMale,
                  ),
                  nameController: _nameController,
                  onGenderChanged: (isMale) => _isMale = isMale,
                  onImagePicked: (path) => _pickedImagePath = path,
                ),
                SizedBox(height: 22.s),
                AnimalTypeSection(
                  key: ValueKey(
                    'animal-$_selectedIndex-${profile.animalType}-${profile.breed}-${_isNewProfile ? 'new' : 'old'}',
                  ),
                  animalTypeController: _animalTypeController,
                  breedController: _breedController,
                  onSelectAnimalType: _selectAnimalType,
                ),
                SizedBox(height: 22.s),
                BirthAdoptDateSection(
                  key: ValueKey(
                    'birth-$_selectedIndex-${_formatDate(_birthDate)}-${_formatDate(_adoptDate)}-${_isNewProfile ? 'new' : 'old'}',
                  ),
                  initialBirthDate: _formatDate(_birthDate),
                  initialAdoptDate: _formatDate(_adoptDate),
                  onBirthChanged: (value) => _birthDate = value,
                  onAdoptChanged: (value) => _adoptDate = value,
                ),
                SizedBox(height: 150.s),
                _SaveButton(onPressed: _onSave, isSaving: _isSaving),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final Future<void> Function() onPressed;
  final bool isSaving;

  const _SaveButton({required this.onPressed, required this.isSaving});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    return Center(
      child: SizedBox(
        width: 93.279.s,
        child: OutlinedButton(
          onPressed: isSaving ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.main,
            side: BorderSide(color: AppColors.main, width: 1.24.s),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18.2.s),
            ),
            minimumSize: const Size(0, 0),
            padding: EdgeInsets.symmetric(vertical: 7.s),
          ),
          child: Text(
            isSaving ? '저장중' : '저장하기',
            style: TextStyle(
              fontFamily: AppFonts.family,
              fontSize: 13.65.s,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
