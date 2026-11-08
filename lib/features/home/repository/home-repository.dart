import '../../../core/api/api-client.dart';
import '../../../core/utils/app-logger.dart';
import '../../auth/repository/auth-repository.dart';
import '../models/pet-profile.dart';
import 'home-auth-token-provider.dart';
import 'home-media-remote-data-source.dart';
import 'home-pet-profile-remote-data-source.dart';
import 'home-pet-state-remote-data-source.dart';

/// Home 화면 데이터 소스 (펫 프로필 등)
abstract class HomeRepository {
  Future<List<PetProfile>> fetchPetProfiles();
  Future<List<String>> fetchAdBannerUrls();
  Future<List<String>> fetchMagazineUrls();
  Future<List<PetProfile>> fetchMyPetProfiles();
  Future<void> selectMainPet({required int petId});
  Future<void> createPetStateRecord({
    required int petId,
    required Map<String, dynamic> body,
    String? imagePath,
  });
  Future<void> updatePetStateRecord({
    required int petId,
    required String date,
    required Map<String, dynamic> body,
    String? imagePath,
  });
  Future<Map<String, Map<String, dynamic>>> fetchPetStateRecordsByMonth({
    required int petId,
    required int year,
    required int month,
  });
  Future<Map<String, dynamic>?> fetchPetStateRecordDetail({
    required int petId,
    required String date,
    required String view,
  });
  Future<PetProfile> createPetProfile({
    required PetProfile profile,
    String? imagePath,
  });
  Future<PetProfile> updatePetProfile({
    required int petId,
    required PetProfile profile,
    String? imagePath,
  });
  Future<void> deletePetProfile({required int petId});
}

class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl({
    required AuthRepository authRepository,
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient() {
    _tokenProvider = HomeAuthTokenProvider(
      ensureToken: authRepository.ensureServerAccessToken,
      log: _homeLog,
    );
    _petProfileDataSource = HomePetProfileRemoteDataSource(
      apiClient: _apiClient,
      tokenProvider: _tokenProvider,
      log: _homeLog,
    );
    _petStateDataSource = HomePetStateRemoteDataSource(
      apiClient: _apiClient,
      tokenProvider: _tokenProvider,
      log: _homeLog,
    );
    _mediaDataSource = HomeMediaRemoteDataSource(
      apiClient: _apiClient,
      tokenProvider: _tokenProvider,
      log: _homeLog,
    );
  }

  final ApiClient _apiClient;
  late final HomeAuthTokenProvider _tokenProvider;
  late final HomePetProfileRemoteDataSource _petProfileDataSource;
  late final HomePetStateRemoteDataSource _petStateDataSource;
  late final HomeMediaRemoteDataSource _mediaDataSource;

  @override
  Future<List<PetProfile>> fetchPetProfiles() {
    return _petProfileDataSource.fetchPetProfiles();
  }

  @override
  Future<List<String>> fetchAdBannerUrls() {
    return _mediaDataSource.fetchAdBannerUrls();
  }

  @override
  Future<List<String>> fetchMagazineUrls() {
    return _mediaDataSource.fetchMagazineUrls();
  }

  @override
  Future<List<PetProfile>> fetchMyPetProfiles() {
    return _petProfileDataSource.fetchMyPetProfiles();
  }

  @override
  Future<void> selectMainPet({required int petId}) {
    return _petProfileDataSource.selectMainPet(petId: petId);
  }

  @override
  Future<void> createPetStateRecord({
    required int petId,
    required Map<String, dynamic> body,
    String? imagePath,
  }) {
    return _petStateDataSource.createPetStateRecord(
      petId: petId,
      body: body,
      imagePath: imagePath,
    );
  }

  @override
  Future<void> updatePetStateRecord({
    required int petId,
    required String date,
    required Map<String, dynamic> body,
    String? imagePath,
  }) {
    return _petStateDataSource.updatePetStateRecord(
      petId: petId,
      date: date,
      body: body,
      imagePath: imagePath,
    );
  }

  @override
  Future<Map<String, Map<String, dynamic>>> fetchPetStateRecordsByMonth({
    required int petId,
    required int year,
    required int month,
  }) {
    return _petStateDataSource.fetchPetStateRecordsByMonth(
      petId: petId,
      year: year,
      month: month,
    );
  }

  @override
  Future<Map<String, dynamic>?> fetchPetStateRecordDetail({
    required int petId,
    required String date,
    required String view,
  }) {
    return _petStateDataSource.fetchPetStateRecordDetail(
      petId: petId,
      date: date,
      view: view,
    );
  }

  @override
  Future<PetProfile> createPetProfile({
    required PetProfile profile,
    String? imagePath,
  }) {
    return _petProfileDataSource.createPetProfile(
      profile: profile,
      imagePath: imagePath,
    );
  }

  @override
  Future<PetProfile> updatePetProfile({
    required int petId,
    required PetProfile profile,
    String? imagePath,
  }) {
    return _petProfileDataSource.updatePetProfile(
      petId: petId,
      profile: profile,
      imagePath: imagePath,
    );
  }

  @override
  Future<void> deletePetProfile({required int petId}) {
    return _petProfileDataSource.deletePetProfile(petId: petId);
  }

  void _homeLog(String message) {
    AppLogger.info(message);
  }
}
