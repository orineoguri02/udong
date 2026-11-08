class UserProfile {
  const UserProfile({
    required this.id,
    required this.nickname,
    this.name,
    this.email,
  });

  final int id;
  final String nickname;
  final String? name;
  final String? email;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final id = rawId is int
        ? rawId
        : (rawId is num
              ? rawId.toInt()
              : int.tryParse(rawId?.toString() ?? '') ?? 0);
    final nickname = (json['nickname']?.toString().trim().isNotEmpty ?? false)
        ? json['nickname'].toString()
        : (json['name']?.toString() ?? '');

    return UserProfile(
      id: id,
      nickname: nickname,
      name: json['name']?.toString(),
      email: json['email']?.toString(),
    );
  }
}
