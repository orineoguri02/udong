class PetProfile {
  final int? petId;
  final String name;
  final bool isMale;
  final String animalType;
  final String breed;
  final String birthDate;
  final String adoptDate;
  final String? imageUrl;

  const PetProfile({
    this.petId,
    required this.name,
    required this.isMale,
    required this.animalType,
    required this.breed,
    required this.birthDate,
    required this.adoptDate,
    this.imageUrl,
  });

  factory PetProfile.fromJson(Map<String, dynamic> json) {
    final root = _toStringMap(json) ?? <String, dynamic>{};
    final scopes = _buildScopes(root);

    return PetProfile(
      petId: _extractPetId(scopes),
      name: _readText(scopes, _nameKeys),
      isMale: _parseIsMale(_readValue(scopes, _genderKeys)),
      animalType: _readText(scopes, _speciesKeys),
      breed: _readText(scopes, _breedKeys),
      birthDate: _normalizeDate(_readText(scopes, _birthDateKeys)),
      adoptDate: _normalizeDate(_readText(scopes, _adoptDateKeys)),
      imageUrl: _extractImageUrl(scopes),
    );
  }

  PetProfile copyWith({
    int? petId,
    String? name,
    bool? isMale,
    String? animalType,
    String? breed,
    String? birthDate,
    String? adoptDate,
    String? imageUrl,
  }) {
    return PetProfile(
      petId: petId ?? this.petId,
      name: name ?? this.name,
      isMale: isMale ?? this.isMale,
      animalType: animalType ?? this.animalType,
      breed: breed ?? this.breed,
      birthDate: birthDate ?? this.birthDate,
      adoptDate: adoptDate ?? this.adoptDate,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  /// [primary]의 각 필드가 비어 있으면 [fallback]의 값으로 채운다.
  ///
  /// `petId`는 nullable이므로 null일 때만 fallback을 사용한다.
  /// `isMale`은 bool이라 항상 [primary]를 우선한다.
  static PetProfile merge({
    required PetProfile primary,
    required PetProfile fallback,
  }) {
    return primary.copyWith(
      petId: primary.petId ?? fallback.petId,
      name: primary.name.trim().isNotEmpty ? primary.name : fallback.name,
      animalType: primary.animalType.trim().isNotEmpty
          ? primary.animalType
          : fallback.animalType,
      breed: primary.breed.trim().isNotEmpty ? primary.breed : fallback.breed,
      birthDate: primary.birthDate.trim().isNotEmpty
          ? primary.birthDate
          : fallback.birthDate,
      adoptDate: primary.adoptDate.trim().isNotEmpty
          ? primary.adoptDate
          : fallback.adoptDate,
      imageUrl: (primary.imageUrl ?? '').trim().isNotEmpty
          ? primary.imageUrl
          : fallback.imageUrl,
    );
  }

  Map<String, dynamic> toPatchBody() {
    return <String, dynamic>{
      'name': name.trim(),
      'species': animalType.trim(),
      'breed': breed.trim(),
      'birthday': _toApiDate(birthDate),
      'adoptedAt': _toApiDate(adoptDate),
      'gender': isMale ? 'male' : 'female',
    };
  }

  Map<String, dynamic> toPetNewRequestBody({String profileImage = ''}) {
    return <String, dynamic>{
      'profileImage': profileImage,
      'name': name.trim(),
      'gender': isMale ? 'male' : 'female',
      'species': animalType.trim(),
      'breed': breed.trim(),
      'birthday': _toApiDate(birthDate),
      'adoptedAt': _toApiDate(adoptDate),
    };
  }

  static const List<String> _petIdKeys = ['pet_id', 'petId'];

  static const List<String> _nameKeys = [
    'name',
    'petName',
    'pet_name',
    'nickname',
  ];

  static const List<String> _genderKeys = [
    'gender',
    'sex',
    'genderType',
    'gender_type',
    'genderCode',
    'gender_code',
    'sexType',
    'sex_type',
    'sexCode',
    'sex_code',
    'isMale',
    'is_male',
    'petGender',
    'pet_gender',
    'petSex',
    'pet_sex',
    'petGenderType',
    'pet_gender_type',
    'petSexType',
    'pet_sex_type',
  ];

  static const List<String> _speciesKeys = [
    'species',
    'animalType',
    'animal_type',
    'animal',
    'petSpecies',
    'pet_species',
  ];

  static const List<String> _breedKeys = [
    'breed',
    'petBreed',
    'pet_breed',
    'breedName',
    'breed_name',
  ];

  static const List<String> _birthDateKeys = [
    'birthday',
    'birthDate',
    'birth_date',
    'birth',
    'birthDay',
    'birth_day',
    'dateOfBirth',
    'date_of_birth',
    'dob',
  ];

  static const List<String> _adoptDateKeys = [
    'adoptedAt',
    'adopted_at',
    'adoptDate',
    'adopt_date',
    'adoptDay',
    'adopt_day',
    'adoptionDate',
    'adoption_date',
  ];

  static const List<String> _imageKeys = [
    'photo',
    'file',
    'profileImage',
    'profile_image',
    'profileImageUrl',
    'profile_image_url',
    'imageUrl',
    'image_url',
    'image',
  ];

  static const List<String> _wrapperKeys = [
    'data',
    'result',
    'response',
    'petResponse',
    'petMainResponse',
    'petMeResponse',
  ];

  static const List<String> _singlePetKeys = [
    'pet',
    'petMain',
    'petInfo',
    'petDetail',
    'petProfile',
    'profile',
    'item',
  ];

  static const List<String> _petListKeys = [
    'pets',
    'petList',
    'petProfiles',
    'items',
    'list',
    'content',
    'data',
    'result',
  ];

  static Map<String, dynamic> _resolvePetPayload(Map<String, dynamic> root) {
    final candidates = <Map<String, dynamic>>[root];
    final singleFromRoot = _extractSinglePetMap(root);
    if (singleFromRoot != null) candidates.add(singleFromRoot);
    final listFromRoot = _extractFirstPetFromLists(root);
    if (listFromRoot != null) candidates.add(listFromRoot);

    for (final key in _wrapperKeys) {
      final wrapper = _toStringMap(root[key]);
      if (wrapper == null) continue;
      candidates.add(wrapper);

      final singleFromWrapper = _extractSinglePetMap(wrapper);
      if (singleFromWrapper != null) {
        candidates.add(singleFromWrapper);
      }

      final listFromWrapper = _extractFirstPetFromLists(wrapper);
      if (listFromWrapper != null) {
        candidates.add(listFromWrapper);
      }
    }

    Map<String, dynamic> best = root;
    var bestScore = _payloadScore(root);
    for (final candidate in candidates) {
      final score = _payloadScore(candidate);
      if (score > bestScore) {
        best = candidate;
        bestScore = score;
      }
    }
    return best;
  }

  static List<Map<String, dynamic>> _buildScopes(Map<String, dynamic> root) {
    final ordered = <Map<String, dynamic>>[];

    void addScope(Map<String, dynamic>? scope) {
      if (scope == null) return;
      if (ordered.any((s) => identical(s, scope))) return;
      ordered.add(scope);
    }

    final payload = _resolvePetPayload(root);
    addScope(payload);
    addScope(root);

    for (final key in _singlePetKeys) {
      addScope(_toStringMap(root[key]));
    }

    addScope(_extractFirstPetFromLists(root));

    for (final key in _wrapperKeys) {
      final wrapper = _toStringMap(root[key]);
      addScope(wrapper);
      if (wrapper == null) continue;

      for (final nestedKey in _singlePetKeys) {
        addScope(_toStringMap(wrapper[nestedKey]));
      }
      addScope(_extractFirstPetFromLists(wrapper));
    }

    final indexed = ordered.asMap().entries.toList();
    indexed.sort((a, b) {
      final scoreDiff = _payloadScore(b.value) - _payloadScore(a.value);
      if (scoreDiff != 0) return scoreDiff;
      return a.key.compareTo(b.key);
    });

    return indexed.map((entry) => entry.value).toList();
  }

  static Map<String, dynamic>? _extractSinglePetMap(Map<String, dynamic> map) {
    for (final key in _singlePetKeys) {
      final candidate = _toStringMap(map[key]);
      if (candidate == null) continue;
      if (_looksLikePetMap(candidate)) {
        return candidate;
      }
    }
    return null;
  }

  static Map<String, dynamic>? _extractFirstPetFromLists(
    Map<String, dynamic> map,
  ) {
    for (final key in _petListKeys) {
      final list = map[key];
      if (list is! List) continue;
      for (final item in list) {
        final itemMap = _toStringMap(item);
        if (itemMap == null) continue;

        if (_looksLikePetMap(itemMap)) {
          return itemMap;
        }

        final nested = _extractSinglePetMap(itemMap);
        if (nested != null) {
          return nested;
        }
      }
    }
    return null;
  }

  static bool _looksLikePetMap(Map<String, dynamic> map) {
    final hasPetId = _hasAnyKey(map, _petIdKeys);
    final hasName = _hasAnyKey(map, _nameKeys);
    final hasSpecies = _hasAnyKey(map, _speciesKeys);
    final hasBirthDate = _hasAnyKey(map, _birthDateKeys);
    final hasGender = _hasAnyKey(map, _genderKeys);

    if (hasPetId && (hasName || hasSpecies || hasBirthDate || hasGender)) {
      return true;
    }

    return (hasName || hasGender) && (hasSpecies || hasBirthDate);
  }

  static int _payloadScore(Map<String, dynamic> map) {
    var score = 0;
    if (_hasAnyKey(map, _petIdKeys)) score += 5;
    if (_hasAnyKey(map, _nameKeys)) score += 3;
    if (_hasAnyKey(map, _speciesKeys)) score += 4;
    if (_hasAnyKey(map, _birthDateKeys)) score += 4;
    if (_hasAnyKey(map, _breedKeys)) score += 2;
    if (_hasAnyKey(map, _adoptDateKeys)) score += 1;
    if (_hasAnyKey(map, _imageKeys)) score += 1;
    if (_hasAnyKey(map, _genderKeys)) score += 1;
    return score;
  }

  static bool _hasAnyKey(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      if (map.containsKey(key)) {
        return true;
      }
    }
    return false;
  }

  static int? _extractPetId(List<Map<String, dynamic>> scopes) {
    final petId = _parseInt(_readValue(scopes, _petIdKeys));
    if (petId != null) {
      return petId;
    }

    for (final scope in scopes) {
      if (!_looksLikePetMap(scope)) continue;
      final fallback = _parseInt(scope['id']);
      if (fallback != null) {
        return fallback;
      }
    }

    return null;
  }

  static dynamic _readValue(
    List<Map<String, dynamic>> scopes,
    List<String> keys,
  ) {
    for (final scope in scopes) {
      for (final key in keys) {
        if (!scope.containsKey(key)) continue;
        final value = scope[key];
        if (value != null) {
          return value;
        }
      }
    }
    return null;
  }

  static String _readText(
    List<Map<String, dynamic>> scopes,
    List<String> keys,
  ) {
    for (final scope in scopes) {
      for (final key in keys) {
        if (!scope.containsKey(key)) continue;
        final text = _toText(scope[key]);
        if (text.isNotEmpty) {
          return text;
        }
      }
    }
    return '';
  }

  static String? _extractImageUrl(List<Map<String, dynamic>> scopes) {
    for (final scope in scopes) {
      for (final key in _imageKeys) {
        if (!scope.containsKey(key)) continue;
        final normalized = _normalizeImageValue(scope[key]);
        if (normalized != null && normalized.isNotEmpty) {
          return normalized;
        }
      }
    }
    return null;
  }

  static String? _normalizeImageValue(dynamic value) {
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    final map = _toStringMap(value);
    if (map == null) {
      return null;
    }

    const nestedImageKeys = ['url', 'path', 'imageUrl', 'fileUrl', 'photoUrl'];
    for (final key in nestedImageKeys) {
      final nested = _toText(map[key]);
      if (nested.isNotEmpty) {
        return nested;
      }
    }

    return null;
  }

  static String _toText(dynamic value) {
    if (value == null) return '';

    if (value is String) {
      return value.trim();
    }

    if (value is num || value is bool) {
      return value.toString().trim();
    }

    if (value is List) {
      for (final item in value) {
        final text = _toText(item);
        if (text.isNotEmpty) {
          return text;
        }
      }
      return '';
    }

    final map = _toStringMap(value);
    if (map == null) {
      return '';
    }

    final year = _parseInt(map['year']);
    final month = _parseInt(map['month']);
    final day = _parseInt(map['day']);
    if (year != null && month != null && day != null) {
      return '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
    }

    const nestedTextKeys = [
      'value',
      'text',
      'name',
      'label',
      'title',
      'displayName',
      'display_name',
      'species',
      'breed',
      'date',
    ];

    for (final key in nestedTextKeys) {
      if (!map.containsKey(key)) continue;
      final text = _toText(map[key]);
      if (text.isNotEmpty) {
        return text;
      }
    }

    if (map.length == 1) {
      return _toText(map.values.first);
    }

    return '';
  }

  static Map<String, dynamic>? _toStringMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      final mapped = <String, dynamic>{};
      for (final entry in value.entries) {
        final key = entry.key?.toString();
        if (key == null || key.isEmpty) continue;
        mapped[key] = entry.value;
      }
      return mapped;
    }
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static bool _parseIsMale(dynamic rawGender) {
    if (rawGender == null) {
      return true;
    }
    if (rawGender is bool) {
      return rawGender;
    }
    if (rawGender is num) {
      return rawGender != 0;
    }
    if (rawGender is String) {
      final value = rawGender.trim().toLowerCase();
      if (value == 'male' ||
          value == 'm' ||
          value == 'man' ||
          value == 'boy' ||
          value == 'masculine' ||
          value == '남성' ||
          value == '수' ||
          value == '수놈' ||
          value == '남' ||
          value == '남아' ||
          value == '수컷' ||
          value == 'true' ||
          value == '1') {
        return true;
      }
      if (value == 'female' ||
          value == 'f' ||
          value == 'woman' ||
          value == 'girl' ||
          value == 'feminine' ||
          value == '여성' ||
          value == '암' ||
          value == '암놈' ||
          value == '여' ||
          value == '여아' ||
          value == '암컷' ||
          value == 'false' ||
          value == '0') {
        return false;
      }
      if (value.contains('female') ||
          value.contains('woman') ||
          value.contains('여') ||
          value.contains('암')) {
        return false;
      }
      if (value.contains('male') ||
          value.contains('man') ||
          value.contains('남') ||
          value.contains('수')) {
        return true;
      }
    }
    // 인식 불가한 값은 male로 강제하지 않는다.
    return false;
  }

  static bool _isDigitsOnly(String value) {
    return RegExp(r'^\d+$').hasMatch(value);
  }

  static DateTime? _parseEpochDate(String rawDigits) {
    if (!_isDigitsOnly(rawDigits)) return null;
    final raw = int.tryParse(rawDigits);
    if (raw == null) return null;
    if (rawDigits.length == 13) {
      return DateTime.fromMillisecondsSinceEpoch(raw).toLocal();
    }
    if (rawDigits.length == 10) {
      return DateTime.fromMillisecondsSinceEpoch(raw * 1000).toLocal();
    }
    return null;
  }

  static DateTime? _parseCompactDate(String rawDigits) {
    if (rawDigits.length != 8 || !_isDigitsOnly(rawDigits)) return null;
    final year = int.tryParse(rawDigits.substring(0, 4));
    final month = int.tryParse(rawDigits.substring(4, 6));
    final day = int.tryParse(rawDigits.substring(6, 8));
    if (year == null || month == null || day == null) return null;
    final candidate = DateTime(year, month, day);
    if (candidate.year != year ||
        candidate.month != month ||
        candidate.day != day) {
      return null;
    }
    return candidate;
  }

  static String _normalizeDate(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';

    final compact = _parseCompactDate(trimmed);
    if (compact != null) {
      return _formatDate(compact.year, compact.month, compact.day);
    }

    final epoch = _parseEpochDate(trimmed);
    if (epoch != null) {
      return _formatDate(epoch.year, epoch.month, epoch.day);
    }

    final isoCandidate = trimmed.contains('T') && trimmed.length >= 10
        ? trimmed.substring(0, 10)
        : trimmed;
    final isoParsed = DateTime.tryParse(isoCandidate);
    if (isoParsed != null) {
      return _formatDate(isoParsed.year, isoParsed.month, isoParsed.day);
    }

    final parts = isoCandidate.split(RegExp(r'[./-]'));
    if (parts.length >= 3) {
      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final day = int.tryParse(parts[2]);
      if (year != null && month != null && day != null) {
        return _formatDate(year, month, day);
      }
    }

    return isoCandidate.replaceAll('-', '.').replaceAll('/', '.');
  }

  static String _toApiDate(String raw) {
    final normalized = _normalizeDate(raw);
    if (normalized.isEmpty) return '';
    return normalized.replaceAll('.', '-');
  }

  static String _formatDate(int year, int month, int day) {
    final mm = month.toString().padLeft(2, '0');
    final dd = day.toString().padLeft(2, '0');
    return '$year.$mm.$dd';
  }
}

/// JSON 로드 전·실패 시 사용하는 기본 반려가족 1마리
List<PetProfile> get defaultPetProfiles => [
  const PetProfile(
    petId: null,
    name: '',
    isMale: true,
    animalType: '눌러서 선택',
    breed: '',
    birthDate: '',
    adoptDate: '',
    imageUrl: null,
  ),
];
