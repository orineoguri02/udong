import '../../../features/auth/models/user.dart';
import '../models/pet-profile.dart';

/// Home 화면 단일 Store (데이터만, 화면 정보 없음)
class HomeState {
  final User user;
  final List<PetProfile> profiles;
  final List<String> adBannerUrls;
  final List<String> magazineUrls;
  final int selectedProfileIndex;
  final bool isLoading;
  final bool isAdBannerLoading;
  final bool isMagazineLoading;

  const HomeState({
    required this.user,
    this.profiles = const <PetProfile>[],
    this.adBannerUrls = const <String>[],
    this.magazineUrls = const <String>[],
    this.selectedProfileIndex = 0,
    this.isLoading = false,
    this.isAdBannerLoading = false,
    this.isMagazineLoading = false,
  });

  PetProfile? get selectedPet {
    if (profiles.isEmpty) return null;
    final i = selectedProfileIndex;
    if (i < 0 || i >= profiles.length) {
      return profiles.isNotEmpty ? profiles.first : null;
    }
    return profiles[i];
  }

  HomeState copyWith({
    User? user,
    List<PetProfile>? profiles,
    List<String>? adBannerUrls,
    List<String>? magazineUrls,
    int? selectedProfileIndex,
    bool? isLoading,
    bool? isAdBannerLoading,
    bool? isMagazineLoading,
  }) {
    return HomeState(
      user: user ?? this.user,
      profiles: profiles ?? this.profiles,
      adBannerUrls: adBannerUrls ?? this.adBannerUrls,
      magazineUrls: magazineUrls ?? this.magazineUrls,
      selectedProfileIndex: selectedProfileIndex ?? this.selectedProfileIndex,
      isLoading: isLoading ?? this.isLoading,
      isAdBannerLoading: isAdBannerLoading ?? this.isAdBannerLoading,
      isMagazineLoading: isMagazineLoading ?? this.isMagazineLoading,
    );
  }

  static bool areSameProfiles(List<PetProfile> a, List<PetProfile> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_isSameProfile(a[i], b[i])) {
        return false;
      }
    }
    return true;
  }

  static bool _isSameProfile(PetProfile x, PetProfile y) {
    return x.petId == y.petId &&
        x.name == y.name &&
        x.isMale == y.isMale &&
        x.animalType == y.animalType &&
        x.breed == y.breed &&
        x.birthDate == y.birthDate &&
        x.adoptDate == y.adoptDate &&
        x.imageUrl == y.imageUrl;
  }

  static bool _areSameStringList(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! HomeState) return false;
    return user.id == other.user.id &&
        user.serverId == other.user.serverId &&
        user.displayName == other.user.displayName &&
        user.email == other.user.email &&
        selectedProfileIndex == other.selectedProfileIndex &&
        isLoading == other.isLoading &&
        isAdBannerLoading == other.isAdBannerLoading &&
        isMagazineLoading == other.isMagazineLoading &&
        areSameProfiles(profiles, other.profiles) &&
        _areSameStringList(adBannerUrls, other.adBannerUrls) &&
        _areSameStringList(magazineUrls, other.magazineUrls);
  }

  @override
  int get hashCode {
    return Object.hash(
      user.id,
      user.serverId,
      user.displayName,
      user.email,
      selectedProfileIndex,
      isLoading,
      isAdBannerLoading,
      isMagazineLoading,
      Object.hashAll(
        profiles.map(
          (p) => Object.hash(
            p.petId,
            p.name,
            p.isMale,
            p.animalType,
            p.breed,
            p.birthDate,
            p.adoptDate,
            p.imageUrl,
          ),
        ),
      ),
      Object.hashAll(adBannerUrls),
      Object.hashAll(magazineUrls),
    );
  }
}
