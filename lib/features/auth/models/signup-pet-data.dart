/// [회원가입 백엔드] POST /user/signup/with-pet 의 petRequest 바디 모델.
/// name, species, breed, birthday(yyyy-MM-dd), adoptedAt(yyyy-MM-dd), gender(male/female).

class SignupPetData {
  final String name;
  final String species;
  final String breed;
  final String birthday;
  final String adoptedAt;
  final String gender;

  const SignupPetData({
    required this.name,
    required this.species,
    required this.breed,
    required this.birthday,
    required this.adoptedAt,
    required this.gender,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'species': species,
    'breed': breed,
    'birthday': birthday,
    'adoptedAt': adoptedAt,
    'gender': gender,
  };
}
