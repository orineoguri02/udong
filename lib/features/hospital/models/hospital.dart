/// 병원 모델
///
/// - 역할: 병원 정보 데이터 구조
/// - API JSON: place_name, phone, address, latitude, longitude 지원

class Hospital {
  static const List<String> _koreanWeekdays = <String>[
    '월요일',
    '화요일',
    '수요일',
    '목요일',
    '금요일',
    '토요일',
    '일요일',
  ];
  static const Map<String, String> _weekdayEngToKor = <String, String>{
    'MONDAY': '월요일',
    'TUESDAY': '화요일',
    'WEDNESDAY': '수요일',
    'THURSDAY': '목요일',
    'FRIDAY': '금요일',
    'SATURDAY': '토요일',
    'SUNDAY': '일요일',
  };

  final int? clinicId;
  final String name;
  final String address;
  final String phone;
  final String operatingHours;
  final List<String> features;
  final bool isOpen;

  /// 요일별 진료 시간 (null = 휴진)
  /// key: '월요일', '화요일', ... '일요일'
  final Map<String, String?> weekdaySchedule;

  /// 진료 가능 동물 목록
  final List<String> animals;

  /// 추가 정보 (label + badge)
  final List<HospitalExtraInfo> extraInfo;

  /// 위도/경도 (카카오 지도 표시용, null이면 주소 기준 서울 기본값 사용)
  /// 백엔드에서 전달받을 위도/경도 (딥링크용)
  final double? latitude;
  final double? longitude;

  const Hospital({
    this.clinicId,
    required this.name,
    required this.address,
    required this.phone,
    required this.operatingHours,
    required this.features,
    this.isOpen = true,
    this.weekdaySchedule = const {},
    this.animals = const [],
    this.extraInfo = const [],
    this.latitude,
    this.longitude,
  });

  /// API JSON 응답 파싱 (place_name, phone, address, latitude, longitude)
  factory Hospital.fromJson(Map<String, dynamic> json) {
    final name = _readString(json, const ['place_name', 'name']);
    final address = _readString(json, const ['address']);
    final phone = _formatPhoneNumber(
      _readNullableString(json, const ['phone']) ?? '',
    );
    final lat = _readDouble(json, const [
      'latitude',
      'lat',
      'y',
      'clinicLatitude',
      'clinic_latitude',
    ]);
    final lng = _readDouble(json, const [
      'longitude',
      'lng',
      'x',
      'clinicLongitude',
      'clinic_longitude',
    ]);
    final clinicHours = _readClinicHours(json);
    final todayClinicHour = _findTodayClinicHour(clinicHours);

    final isClosedDayRaw = _readBool(json, const ['isClosedDay', 'is_closed_day']);
    final backendIsOpen = _readBool(json, const ['is_open']);

    final todayOpenTimeRaw = _readNullableString(json, const [
      'todayOpenTime',
      'today_open_time',
    ]);
    final todayCloseTimeRaw = _readNullableString(json, const [
      'todayCloseTime',
      'today_close_time',
    ]);
    final todayOpenTime = todayOpenTimeRaw ?? todayClinicHour?.openTime;
    final todayCloseTime = todayCloseTimeRaw ?? todayClinicHour?.closeTime;
    final isClosedDay = isClosedDayRaw ?? _isClosedByClinicHour(todayClinicHour);

    final operatingHours = _buildOperatingHours(
      json: json,
      isClosedDay: isClosedDay,
      openTime: todayOpenTime,
      closeTime: todayCloseTime,
    );
    final isOpen = _computeIsOpenNow(
      isClosedDay: isClosedDay,
      openTime: todayOpenTime,
      closeTime: todayCloseTime,
      fallbackIsOpen: backendIsOpen,
    );

    final animals = _readAnimals(json);
    return Hospital(
      clinicId: _readInt(json, const ['clinicId', 'clinic_id', 'id']),
      name: name,
      address: address,
      phone: phone,
      operatingHours: operatingHours,
      features: _readStringList(json, const ['features']),
      isOpen: isOpen,
      weekdaySchedule: _buildWeekdaySchedule(
        json: json,
        isClosedDay: isClosedDay,
        openTime: todayOpenTime,
        closeTime: todayCloseTime,
        clinicHours: clinicHours,
      ),
      animals: animals,
      extraInfo: _buildExtraInfo(json),
      latitude: lat,
      longitude: lng,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clinicId': clinicId,
      'place_name': name,
      'name': name,
      'address': address,
      'phone': phone,
      'latitude': latitude,
      'longitude': longitude,
      'operating_hours': operatingHours,
      'features': features,
      'is_open': isOpen,
      'weekday_schedule': weekdaySchedule,
      'animals': animals,
    };
  }

  static String _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return '';
  }

  static String? _readNullableString(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  static int? _readInt(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value.trim());
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  static double? _readDouble(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value.trim());
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  static bool? _readBool(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (normalized == 'true' || normalized == '1') return true;
        if (normalized == 'false' || normalized == '0') return false;
      }
    }
    return null;
  }

  static List<String> _readStringList(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value is List) {
        return value
            .map((item) => item.toString().trim())
            .where((item) => item.isNotEmpty)
            .toList();
      }
    }
    return const [];
  }

  static List<String> _readAnimals(Map<String, dynamic> json) {
    final fromList = _readStringList(json, const [
      'animals',
      'speciesList',
      'species',
    ]);
    if (fromList.isNotEmpty) return fromList;

    final speciesRaw = _readNullableString(json, const ['species']);
    if (speciesRaw == null || speciesRaw.isEmpty) return const [];

    return speciesRaw
        .split(RegExp(r'[,/]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static List<_ClinicHour> _readClinicHours(Map<String, dynamic> json) {
    final raw = json['clinicHours'] ?? json['clinic_hours'];
    if (raw is! List) return const <_ClinicHour>[];

    final result = <_ClinicHour>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final dayRaw = _readNullableString(map, const ['dayOfWeek', 'day_of_week']);
      if (dayRaw == null) continue;

      final normalized = dayRaw.trim().toUpperCase();
      final dayKor = _weekdayEngToKor[normalized] ?? dayRaw.trim();
      if (!_koreanWeekdays.contains(dayKor)) continue;

      result.add(
        _ClinicHour(
          dayOfWeek: dayKor,
          openTime: _readNullableString(map, const ['openTime', 'open_time']),
          closeTime: _readNullableString(map, const ['closeTime', 'close_time']),
          isClosedDay:
              _readBool(map, const ['isClosedDay', 'is_closed_day']) ?? false,
        ),
      );
    }
    return result;
  }

  static _ClinicHour? _findTodayClinicHour(List<_ClinicHour> clinicHours) {
    if (clinicHours.isEmpty) return null;
    final today = _koreanWeekdays[DateTime.now().weekday - 1];
    for (final hour in clinicHours) {
      if (hour.dayOfWeek == today) return hour;
    }
    return null;
  }

  static bool _isClosedByClinicHour(_ClinicHour? hour) {
    if (hour == null) return false;
    if (hour.isClosedDay) return true;
    final open = _toDisplayTime(hour.openTime);
    final close = _toDisplayTime(hour.closeTime);
    return open == null || close == null;
  }

  static Map<String, String?> _buildWeekdayScheduleFromClinicHours(
    List<_ClinicHour> clinicHours,
  ) {
    if (clinicHours.isEmpty) return const {};
    final schedule = <String, String?>{
      for (final day in _koreanWeekdays) day: null,
    };
    for (final hour in clinicHours) {
      final open = _toDisplayTime(hour.openTime);
      final close = _toDisplayTime(hour.closeTime);
      if (hour.isClosedDay || open == null || close == null) {
        schedule[hour.dayOfWeek] = null;
        continue;
      }
      schedule[hour.dayOfWeek] = '$open ~ $close';
    }
    return schedule;
  }

  static String _buildOperatingHours({
    required Map<String, dynamic> json,
    required bool isClosedDay,
    required String? openTime,
    required String? closeTime,
  }) {
    if (isClosedDay) return '휴진';
    final openDisplay = _toDisplayTime(openTime);
    final closeDisplay = _toDisplayTime(closeTime);
    if (openDisplay != null && closeDisplay != null) {
      return '$openDisplay ~ $closeDisplay';
    }

    final operating = _readNullableString(json, const [
      'operating_hours',
      'operatingHours',
    ]);
    if (operating != null && operating.isNotEmpty) return operating;

    return '-';
  }

  static Map<String, String?> _buildWeekdaySchedule({
    required Map<String, dynamic> json,
    required bool isClosedDay,
    required String? openTime,
    required String? closeTime,
    required List<_ClinicHour> clinicHours,
  }) {
    final rawSchedule = json['weekday_schedule'];
    if (rawSchedule is Map) {
      final mapped = <String, String?>{};
      rawSchedule.forEach((key, value) {
        mapped[key.toString()] = value?.toString();
      });
      return mapped;
    }

    final fromClinicHours = _buildWeekdayScheduleFromClinicHours(clinicHours);
    if (fromClinicHours.isNotEmpty) {
      return fromClinicHours;
    }

    final dayOfWeek = _readNullableString(json, const [
      'dayOfWeek',
      'day_of_week',
    ]);
    if (dayOfWeek == null || dayOfWeek.isEmpty) {
      return const {};
    }

    final normalizedDay = dayOfWeek.trim().toUpperCase();
    final targetDay = _weekdayEngToKor[normalizedDay];
    if (targetDay == null) return const {};

    final schedule = <String, String?>{
      for (final day in _koreanWeekdays) day: null,
    };
    if (!isClosedDay) {
      final openDisplay = _toDisplayTime(openTime);
      final closeDisplay = _toDisplayTime(closeTime);
      if (openDisplay != null && closeDisplay != null) {
        schedule[targetDay] = '$openDisplay ~ $closeDisplay';
      }
    }
    return schedule;
  }

  static List<HospitalExtraInfo> _buildExtraInfo(Map<String, dynamic> json) {
    final extra = <HospitalExtraInfo>[];
    final seenLabels = <String>{};

    String normalizeInfoValue(String value) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return '';
      final normalized = trimmed.toLowerCase();
      if (normalized == 'null' || normalized == 'string') return '';
      return trimmed;
    }

    void addInfo(String label, String badge) {
      final trimmedLabel = normalizeInfoValue(label);
      final trimmedBadge = normalizeInfoValue(badge);
      if (trimmedLabel.isEmpty || trimmedBadge.isEmpty) return;
      if (seenLabels.add(trimmedLabel)) {
        extra.add(HospitalExtraInfo(label: trimmedLabel, badge: trimmedBadge));
      }
    }

    final rawExtraInfo = json['extra_info'];
    if (rawExtraInfo is List) {
      for (final item in rawExtraInfo) {
        if (item is Map<String, dynamic>) {
          final parsed = HospitalExtraInfo.fromJson(item);
          addInfo(parsed.label, parsed.badge);
        }
      }
    }

    final specialty = _readBool(json, const ['specialty']);
    if (specialty != null) {
      addInfo('특화 진료', specialty ? '가능' : '미지원');
    }

    final emergency = _readBool(json, const ['emergency']);
    if (emergency != null) {
      addInfo('응급 진료', emergency ? '가능' : '미지원');
    }

    final homepage = _readNullableString(json, const ['homepage']);
    if (homepage != null && homepage.isNotEmpty) {
      addInfo('홈페이지', homepage);
    }

    final instagram = _readNullableString(json, const ['instagram']);
    if (instagram != null && instagram.isNotEmpty) {
      addInfo('인스타그램', instagram);
    }

    final email = _readNullableString(json, const ['email']);
    if (email != null && email.isNotEmpty) {
      addInfo('이메일', email);
    }

    final sourceUrl = _readNullableString(json, const [
      'sourceUrl',
      'source_url',
    ]);
    if (sourceUrl != null && sourceUrl.isNotEmpty) {
      addInfo('출처', sourceUrl);
    }

    final description = _readNullableString(json, const [
      'text',
      'description',
    ]);
    if (description != null && description.isNotEmpty) {
      addInfo('설명', description);
    }

    return extra;
  }

  static bool _computeIsOpenNow({
    required bool isClosedDay,
    required String? openTime,
    required String? closeTime,
    required bool? fallbackIsOpen,
  }) {
    if (isClosedDay) return false;

    final openMinutes = _parseTimeToMinutes(openTime);
    final closeMinutes = _parseTimeToMinutes(closeTime);

    if (openMinutes != null && closeMinutes != null) {
      final now = DateTime.now();
      final nowMinutes = now.hour * 60 + now.minute;

      if (openMinutes == closeMinutes) {
        return true;
      }
      if (openMinutes < closeMinutes) {
        return nowMinutes >= openMinutes && nowMinutes < closeMinutes;
      }
      return nowMinutes >= openMinutes || nowMinutes < closeMinutes;
    }

    if (fallbackIsOpen != null) return fallbackIsOpen;
    return true;
  }

  static int? _parseTimeToMinutes(String? raw) {
    final hhmm = _toDisplayTime(raw);
    if (hhmm == null) return null;
    final parts = hhmm.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return hour * 60 + minute;
  }

  static String? _toDisplayTime(String? raw) {
    if (raw == null) return null;
    final value = raw.trim();
    if (value.isEmpty) return null;

    final timeMatch = RegExp(r'(\d{1,2}):(\d{1,2})').firstMatch(value);
    if (timeMatch != null) {
      final hour = int.tryParse(timeMatch.group(1)!);
      final minute = int.tryParse(timeMatch.group(2)!);
      if (hour == null || minute == null) return null;
      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
      final hh = hour.toString().padLeft(2, '0');
      final mm = minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    }

    final compactMatch = RegExp(
      r'^(\d{2})(\d{2})$',
    ).firstMatch(value.replaceAll(RegExp(r'[^0-9]'), ''));
    if (compactMatch != null) {
      final hour = int.tryParse(compactMatch.group(1)!);
      final minute = int.tryParse(compactMatch.group(2)!);
      if (hour == null || minute == null) return null;
      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
      final hh = hour.toString().padLeft(2, '0');
      final mm = minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    }

    final parsedDate = DateTime.tryParse(value);
    if (parsedDate != null) {
      final hh = parsedDate.hour.toString().padLeft(2, '0');
      final mm = parsedDate.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    }

    return null;
  }

  static String _formatPhoneNumber(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '';

    var digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return value;

    // +82 또는 82로 온 번호를 국내 표기(0 시작)로 보정
    if (digits.startsWith('82')) {
      digits = '0${digits.substring(2)}';
    }

    if (digits.startsWith('02')) {
      if (digits.length == 9) {
        return '02-${digits.substring(2, 5)}-${digits.substring(5)}';
      }
      if (digits.length == 10) {
        return '02-${digits.substring(2, 6)}-${digits.substring(6)}';
      }
    }

    if (digits.length == 8) {
      return '${digits.substring(0, 4)}-${digits.substring(4)}';
    }
    if (digits.length == 10) {
      return '${digits.substring(0, 3)}-${digits.substring(3, 6)}-${digits.substring(6)}';
    }
    if (digits.length == 11) {
      return '${digits.substring(0, 3)}-${digits.substring(3, 7)}-${digits.substring(7)}';
    }

    return value;
  }

  bool get hasCoordinates => latitude != null && longitude != null;
}

class HospitalExtraInfo {
  final String label;
  final String badge;

  const HospitalExtraInfo({required this.label, required this.badge});

  factory HospitalExtraInfo.fromJson(Map<String, dynamic> json) {
    return HospitalExtraInfo(
      label: json['label'] as String? ?? '',
      badge: json['badge'] as String? ?? '',
    );
  }
}

class _ClinicHour {
  final String dayOfWeek;
  final String? openTime;
  final String? closeTime;
  final bool isClosedDay;

  const _ClinicHour({
    required this.dayOfWeek,
    required this.openTime,
    required this.closeTime,
    required this.isClosedDay,
  });
}
