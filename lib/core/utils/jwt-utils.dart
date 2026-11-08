import 'dart:convert';

/// JWT 토큰의 만료 여부를 순수하게 판단하는 유틸리티.
///
/// 인증 레이어와 홈 레이어 모두에서 동일 로직을 재사용할 수 있도록
/// 클래스 의존 없이 최상위 함수로 제공한다.
bool isJwtExpired(
  String? token, {
  Duration leeway = const Duration(seconds: 30),
}) {
  if (token == null) return true;
  final trimmed = token.trim();
  if (trimmed.isEmpty) return true;

  final parts = trimmed.split('.');
  if (parts.length != 3) return false;

  try {
    final payloadBytes = base64Url.decode(base64Url.normalize(parts[1]));
    final payload = jsonDecode(utf8.decode(payloadBytes));
    if (payload is! Map<String, dynamic>) return false;

    final rawExp = payload['exp'];
    int? expSeconds;
    if (rawExp is int) {
      expSeconds = rawExp;
    } else if (rawExp is num) {
      expSeconds = rawExp.toInt();
    } else if (rawExp is String) {
      expSeconds = int.tryParse(rawExp.trim());
    }
    if (expSeconds == null) return false;

    final expiresAt = DateTime.fromMillisecondsSinceEpoch(
      expSeconds * 1000,
      isUtc: true,
    );
    final now = DateTime.now().toUtc();
    return !expiresAt.isAfter(now.add(leeway));
  } catch (_) {
    return false;
  }
}
