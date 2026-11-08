export 'home-image-helpers.dart';

bool homeIsAuthFailureStatus(int? statusCode) {
  return statusCode == 401 || statusCode == 403;
}

Map<String, dynamic> homePetAuthHeaders(String accessToken) {
  return <String, dynamic>{'Authorization': 'Bearer $accessToken'};
}
