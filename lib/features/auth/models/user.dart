/// 인증 도메인의 사용자(User) 모델 파일입니다.
///
/// - 역할: 로그인/세션 등 인증 상태에서 참조할 사용자 정보를 표현
/// - 비고: 실제 프로젝트에서는 서버 스펙에 맞춰 필드를 확장하세요.

class User {
  final String id;
  final String displayName;
  final String? email;

  /// 소셜 로그인 최초 가입 여부 (백엔드 연동 전 임시 플래그)
  final bool isNewUser;

  /// 서버(백엔드)에서 부여한 long 타입 id. 회원탈퇴 등 API path에 사용
  final int? serverId;

  const User({
    required this.id,
    required this.displayName,
    this.email,
    this.isNewUser = false,
    this.serverId,
  });

  /// 목데이터(users.json) 등 JSON 파싱용
  factory User.fromJson(Map<String, dynamic> json) {
    final displayName =
        json['display_name'] as String? ?? json['displayName'] as String? ?? '';
    final idRaw = json['id'];
    final id = idRaw is int ? idRaw.toString() : (idRaw as String? ?? '');
    return User(
      id: id,
      displayName: displayName,
      email: json['email'] as String?,
      serverId: idRaw is int ? idRaw : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'display_name': displayName, 'email': email};
  }
}
