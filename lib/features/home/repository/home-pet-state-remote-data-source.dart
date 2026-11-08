import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../../../core/api/api-client.dart';
import '../../../core/api/api-endpoints.dart';
import '../../../core/utils/image-compress.dart';
import 'home-api-helpers.dart';
import 'home-auth-token-provider.dart';
import 'home-token-retry.dart';

class HomePetStateRemoteDataSource {
  HomePetStateRemoteDataSource({
    required ApiClient apiClient,
    required HomeAuthTokenProvider tokenProvider,
    required void Function(String) log,
  }) : _apiClient = apiClient,
       _tokenProvider = tokenProvider,
       _log = log;

  final ApiClient _apiClient;
  final HomeAuthTokenProvider _tokenProvider;
  final void Function(String) _log;

  Future<void> createPetStateRecord({
    required int petId,
    required Map<String, dynamic> body,
    String? imagePath,
  }) async {
    _log(
      '[HomeRepo] createPetStateRecord '
      'petId=$petId '
      'hasPhoto=${(imagePath ?? '').trim().isNotEmpty}',
    );

    final path = ApiEndpoints.petState.replaceFirst('{pet_id}', '$petId');
    await _withServerAccessTokenRetry<void>(
      missingTokenMessage: '상태 기록 등록에 필요한 accessToken이 없습니다.',
      request: (accessToken) async {
        final formData = await _buildPetStateFormData(
          request: body,
          imagePath: imagePath,
          requestPartName: 'stateRequest',
        );
        await _apiClient.postMultipart(
          path,
          data: formData,
          headers: homePetAuthHeaders(accessToken),
        );
      },
    );
    _log(
      '[HomeRepo] createPetStateRecord multipart 요청 성공 '
      'requestPart=stateRequest requestPartContentType=application/json '
      'hasPhoto=${(imagePath ?? '').trim().isNotEmpty}',
    );
  }

  Future<void> updatePetStateRecord({
    required int petId,
    required String date,
    required Map<String, dynamic> body,
    String? imagePath,
  }) async {
    _log(
      '[HomeRepo] updatePetStateRecord '
      'petId=$petId '
      'date=$date '
      'hasPhoto=${(imagePath ?? '').trim().isNotEmpty}',
    );

    final path = ApiEndpoints.petState.replaceFirst('{pet_id}', '$petId');
    final query = <String, dynamic>{'date': date};
    await _withServerAccessTokenRetry<void>(
      missingTokenMessage: '상태 기록 수정에 필요한 accessToken이 없습니다.',
      request: (accessToken) async {
        final formData = await _buildPetStateFormData(
          request: body,
          imagePath: imagePath,
          requestPartName: 'stateEditRequest',
        );
        await _apiClient.patchMultipart(
          path,
          queryParameters: query,
          data: formData,
          headers: homePetAuthHeaders(accessToken),
        );
      },
    );
    _log(
      '[HomeRepo] updatePetStateRecord multipart 요청 성공 '
      'queryDate=$date '
      'requestPart=stateEditRequest requestPartContentType=application/json '
      'hasPhoto=${(imagePath ?? '').trim().isNotEmpty}',
    );
  }

  Future<Map<String, Map<String, dynamic>>> fetchPetStateRecordsByMonth({
    required int petId,
    required int year,
    required int month,
  }) async {
    _log(
      '[HomeRepo] fetchPetStateRecordsByMonth '
      'petId=$petId year=$year month=$month',
    );
    final path = ApiEndpoints.petStateCalendar.replaceFirst(
      '{pet_id}',
      '$petId',
    );
    final query = _petCalendarQueryParams(year: year, month: month);
    dynamic response;
    try {
      response = await _withServerAccessTokenRetry<dynamic>(
        missingTokenMessage: '상태 기록 조회에 필요한 accessToken이 없습니다.',
        request: (accessToken) {
          return _apiClient.get(
            path,
            queryParameters: query,
            headers: homePetAuthHeaders(accessToken),
          );
        },
      );
    } on DioException catch (e) {
      _log(
        '[HomeRepo] fetchPetStateRecordsByMonth 요청 실패 '
        'status=${e.response?.statusCode} '
        'path=$path '
        'query=$query '
        'data=${e.response?.data}',
      );
      rethrow;
    }

    final records = _extractStateRecordsByDate(
      response,
      year: year,
      month: month,
    );
    _log('[HomeRepo] fetchPetStateRecordsByMonth records=${records.length}');
    if (records.isEmpty) {
      _log(
        '[HomeRepo] fetchPetStateRecordsByMonth empty-response '
        'type=${response.runtimeType} data=$response',
      );
    }
    return records;
  }

  Future<Map<String, dynamic>?> fetchPetStateRecordDetail({
    required int petId,
    required String date,
    required String view,
  }) async {
    if (view != 'brief' && view != 'full') {
      throw ArgumentError.value(view, 'view', 'must be "brief" or "full"');
    }

    _log(
      '[HomeRepo] fetchPetStateRecordDetail '
      'petId=$petId date=$date view=$view',
    );
    final path = ApiEndpoints.petStateDetail.replaceFirst('{pet_id}', '$petId');
    final query = <String, dynamic>{'date': date, 'view': view};

    dynamic response;
    try {
      response = await _withServerAccessTokenRetry<dynamic>(
        missingTokenMessage: '상태 기록 상세 조회에 필요한 accessToken이 없습니다.',
        request: (accessToken) {
          return _apiClient.get(
            path,
            queryParameters: query,
            headers: homePetAuthHeaders(accessToken),
          );
        },
      );
    } on DioException catch (e) {
      if (_isNoRecordDetailStatus(e.response?.statusCode)) {
        _log(
          '[HomeRepo] fetchPetStateRecordDetail no-record '
          'status=${e.response?.statusCode} petId=$petId date=$date view=$view',
        );
        return null;
      } else {
        _log(
          '[HomeRepo] fetchPetStateRecordDetail 요청 실패 '
          'status=${e.response?.statusCode} path=$path query=$query data=${e.response?.data}',
        );
        rethrow;
      }
    }

    final rawDetail = response is Map<String, dynamic>
        ? (_extractDetailPayloadByView(response, view: view) ??
              _extractStateRecordDetailMap(response))
        : _extractStateRecordDetailMap(response);
    if (rawDetail == null) {
      _log(
        '[HomeRepo] fetchPetStateRecordDetail empty-response '
        'type=${response.runtimeType} data=$response',
      );
      return null;
    }

    final normalized = _normalizeStateDetailMap(rawDetail, date: date);
    if (normalized == null) {
      _log(
        '[HomeRepo] fetchPetStateRecordDetail parse-failed '
        'date=$date responseType=${response.runtimeType}',
      );
      return null;
    }
    return normalized;
  }

  Map<String, dynamic>? _extractDetailPayloadByView(
    Map<String, dynamic> response, {
    required String view,
  }) {
    final direct = response[view];
    if (direct is Map<String, dynamic>) {
      return direct;
    }

    const wrapperKeys = ['data', 'result', 'record', 'state'];
    for (final key in wrapperKeys) {
      final nested = response[key];
      if (nested is! Map<String, dynamic>) continue;
      final viewMap = nested[view];
      if (viewMap is Map<String, dynamic>) {
        return viewMap;
      }
    }
    return null;
  }

  Map<String, dynamic> _petCalendarQueryParams({
    required int year,
    required int month,
  }) {
    return <String, dynamic>{'year': year, 'month': month};
  }

  bool _isNoRecordDetailStatus(int? statusCode) {
    return statusCode == 404;
  }

  Future<T> _withServerAccessTokenRetry<T>({
    required String missingTokenMessage,
    required Future<T> Function(String accessToken) request,
  }) async {
    return homeWithServerAccessTokenRetry(
      tokenProvider: _tokenProvider,
      missingTokenMessage: missingTokenMessage,
      request: request,
    );
  }

  Map<String, Map<String, dynamic>> _extractStateRecordsByDate(
    dynamic response, {
    required int year,
    required int month,
  }) {
    final byDate = <String, Map<String, dynamic>>{};

    String normalizeDateForMonth(String date) {
      if (_isEpochPlaceholderDateKey(date)) {
        return _fallbackDateKeyForMonth(year: year, month: month);
      }
      return date;
    }

    void addDateOnly(String date) {
      final normalizedDate = normalizeDateForMonth(date);
      byDate.putIfAbsent(
        normalizedDate,
        () => <String, dynamic>{'date': normalizedDate},
      );
    }

    void addRawRecord(Map<String, dynamic> raw) {
      final normalized = _normalizeStateRecordMap(raw);
      if (normalized == null) return;
      final date = normalized['date']?.toString().trim();
      if (date == null || date.isEmpty) return;
      final normalizedDate = normalizeDateForMonth(date);
      byDate[normalizedDate] = <String, dynamic>{
        ...normalized,
        'date': normalizedDate,
      };
    }

    void visit(dynamic node) {
      if (node is List) {
        for (final item in node) {
          final date = _normalizeDateKey(item);
          if (date != null) {
            addDateOnly(date);
            continue;
          }
          visit(item);
        }
        return;
      }
      if (node is! Map<String, dynamic>) return;

      if (_looksLikeStateRecordPayload(node)) {
        addRawRecord(node);
      }

      var foundDateKeyedEntries = false;
      for (final entry in node.entries) {
        final keyAsDate = _normalizeDateKey(entry.key);
        final value = entry.value;
        if (keyAsDate != null) {
          if (value is Map<String, dynamic>) {
            final merged = <String, dynamic>{...value, 'date': keyAsDate};
            addRawRecord(merged);
          } else if (value is String || value is int) {
            addDateOnly(keyAsDate);
          }
          foundDateKeyedEntries = true;
        }
      }
      const directDateFields = [
        'localDate',
        'date',
        'recordDate',
        'stateDate',
        'createdAt',
        'updatedAt',
      ];
      for (final field in directDateFields) {
        final value = node[field];
        if (value == null) continue;
        final date = _normalizeDateKey(value);
        if (date != null) addDateOnly(date);
      }
      if (!foundDateKeyedEntries) {
        for (final value in node.values) {
          if (value is Map<String, dynamic> || value is List) {
            visit(value);
          }
        }
      }
    }

    // 캘린더 API: {recordedDaysOfMonth: [3, 8]} 처럼 '일(day)' 숫자만 주는 경우
    final recordedDays = response is Map
        ? response['recordedDaysOfMonth']
        : null;
    if (recordedDays is List) {
      for (final day in recordedDays) {
        final dayNumber = day is int ? day : int.tryParse('$day');
        if (dayNumber == null || dayNumber < 1 || dayNumber > 31) continue;
        addDateOnly(
          '${year.toString().padLeft(4, '0')}-'
          '${month.toString().padLeft(2, '0')}-'
          '${dayNumber.toString().padLeft(2, '0')}',
        );
      }
    }

    visit(response);

    if (byDate.isNotEmpty) {
      return byDate;
    }

    final list = _extractStateRecordMaps(response);
    for (final raw in list) {
      addRawRecord(raw);
    }

    return byDate;
  }

  List<Map<String, dynamic>> _extractStateRecordMaps(dynamic response) {
    if (response is List) {
      return response.whereType<Map<String, dynamic>>().toList();
    }
    if (response is! Map<String, dynamic>) return const [];

    if (_looksLikeStateRecordPayload(response)) {
      return [response];
    }

    const listKeys = [
      'data',
      'items',
      'results',
      'result',
      'records',
      'stateRecords',
      'recordList',
      'list',
      'content',
    ];
    for (final key in listKeys) {
      final value = response[key];
      if (value is List) {
        final list = value.whereType<Map<String, dynamic>>().toList();
        if (list.isNotEmpty) return list;
      }
    }

    const nestedKeys = [
      'data',
      'result',
      'record',
      'state',
      'stateRequest',
      'stateEditRequest',
    ];
    for (final key in nestedKeys) {
      final value = _asStringKeyMap(response[key]);
      if (value != null) {
        final nested = _extractStateRecordMaps(value);
        if (nested.isNotEmpty) return nested;
      }
    }

    return const [];
  }

  bool _looksLikeStateRecordPayload(Map<String, dynamic> value) {
    return value.containsKey('date') ||
        value.containsKey('feed') ||
        value.containsKey('defecation') ||
        value.containsKey('weight') ||
        value.containsKey('appearance') ||
        value.containsKey('temperatureNHumidity') ||
        value.containsKey('stateRequest') ||
        value.containsKey('stateEditRequest');
  }

  Map<String, dynamic>? _normalizeStateRecordMap(Map<String, dynamic> raw) {
    return _normalizeStateMap(raw, requireContent: false);
  }

  Map<String, dynamic>? _normalizeStateDetailMap(
    Map<String, dynamic> raw, {
    required String date,
  }) {
    final normalized = _normalizeStateMap(raw, requireContent: false);
    if (normalized != null) return normalized;

    return _normalizeStateMap(raw, fallbackDate: date, requireContent: true);
  }

  Map<String, dynamic>? _normalizeStateMap(
    Map<String, dynamic> raw, {
    String? fallbackDate,
    required bool requireContent,
  }) {
    final stateRequest =
        _asStringKeyMap(raw['stateRequest']) ??
        _asStringKeyMap(raw['stateEditRequest']);
    final source = stateRequest != null
        ? <String, dynamic>{...stateRequest}
        : <String, dynamic>{...raw};
    if (stateRequest != null) {
      source['photo'] ??= raw['photo'];
      source['createdAt'] ??= raw['createdAt'];
      source['updatedAt'] ??= raw['updatedAt'];
    }

    final trimmedFallbackDate = fallbackDate?.trim();
    final date = (trimmedFallbackDate != null && trimmedFallbackDate.isNotEmpty)
        ? trimmedFallbackDate
        : _extractStateDateKey(source);
    if (date == null || date.isEmpty) return null;

    final feed = _asStringKeyMap(source['feed']);
    final weight = _asStringKeyMap(source['weight']);
    final appearance = _asStringKeyMap(source['appearance']);
    final currentWeight = _extractCurrentWeightMap(
      weight: weight,
      source: source,
    );
    final weightDifference = _extractWeightDifferenceMap(
      weight: weight,
      source: source,
    );

    final weightValue = _firstNonNullValue([
      currentWeight?['weight'],
      currentWeight?['value'],
      weight?['weightStatus'],
      source['weightStatus'],
      source['currentWeight'],
      source['current_weight'],
      source['todayWeight'],
      source['weight'] is Map<String, dynamic> ? null : source['weight'],
    ]);
    final weightUnit = _normalizeWeightUnit(
      _firstString([
        currentWeight?['unit'],
        weight?['status'],
        source['weightUnit'],
        source['currentWeightUnit'],
        source['current_weight_unit'],
        source['status'],
      ]),
    );
    final sanitizedWeight = _sanitizeWeightValue(weightValue, unit: weightUnit);
    final weightChange = _extractWeightChangeText(
      source: source,
      weightDifference: weightDifference,
      fallbackUnit: weightUnit,
    );
    final mealTime = _firstString([
      feed?['feedTime'],
      source['feedTime'],
      source['lastMeal'],
    ]);
    final mealStatus = _toMealStatusText(
      _firstString([
        feed?['feedStatus'],
        source['feedStatus'],
        source['mealStatus'],
      ]),
    );
    final poopStatus = _toDefecationText(
      _firstString([source['defecation'], source['poopStatus']]),
    );
    final photoPath = _firstString([
      appearance?['imageUrl'],
      source['imageUrl'],
      source['photoPath'],
      source['photo'],
    ]);
    final appearanceMemo = _firstString([
      appearance?['appearanceMemo'],
      appearance?['appearance_memo'],
      source['appearanceMemo'],
      source['appearance_memo'],
    ]);

    final normalized = <String, dynamic>{'date': date, 'raw': source};
    var hasContent = false;

    if (sanitizedWeight != null) {
      normalized['weight'] = sanitizedWeight;
      hasContent = true;
    }
    if (weightUnit != null && weightUnit.isNotEmpty) {
      normalized['weightUnit'] = weightUnit;
      hasContent = true;
    }
    if (weightChange != null && weightChange.isNotEmpty) {
      normalized['weightChange'] = weightChange;
      hasContent = true;
    }
    if (mealTime != null && mealTime.isNotEmpty) {
      normalized['lastMeal'] = mealTime;
      hasContent = true;
    }
    if (mealStatus != null && mealStatus.isNotEmpty) {
      normalized['mealStatus'] = mealStatus;
      hasContent = true;
    }
    if (poopStatus != null && poopStatus.isNotEmpty) {
      normalized['poopStatus'] = poopStatus;
      hasContent = true;
    }
    if (photoPath != null && photoPath.isNotEmpty) {
      normalized['photoPath'] = photoPath;
      hasContent = true;
    }
    if (appearanceMemo != null && appearanceMemo.isNotEmpty) {
      normalized['appearanceMemo'] = appearanceMemo;
      hasContent = true;
    }

    if (requireContent && !hasContent) return null;
    return normalized;
  }

  Map<String, dynamic>? _extractStateRecordDetailMap(dynamic response) {
    if (response is Map<String, dynamic>) {
      if (_asStringKeyMap(response['stateRequest']) != null ||
          _asStringKeyMap(response['stateEditRequest']) != null) {
        return response;
      }
      if (_looksLikeStateRecordPayload(response)) {
        return response;
      }

      const nestedKeys = [
        'data',
        'result',
        'record',
        'state',
        'stateRequest',
        'stateEditRequest',
      ];
      for (final key in nestedKeys) {
        final nested = _asStringKeyMap(response[key]);
        if (nested != null) {
          if (_asStringKeyMap(nested['stateRequest']) != null ||
              _asStringKeyMap(nested['stateEditRequest']) != null) {
            return nested;
          }
          if (_looksLikeStateRecordPayload(nested)) {
            return nested;
          }
          final deep = _extractStateRecordDetailMap(nested);
          if (deep != null) return deep;
        }
      }
    }

    final list = _extractStateRecordMaps(response);
    if (list.isNotEmpty) return list.first;
    return null;
  }

  String? _extractStateDateKey(Map<String, dynamic> source) {
    final candidates = <dynamic>[
      source['localDate'],
      source['createdAt'],
      source['updatedAt'],
      source['date'],
      source['recordDate'],
      source['stateDate'],
    ];
    for (final candidate in candidates) {
      final normalized = _normalizeDateKey(candidate);
      if (normalized != null) return normalized;
    }
    return null;
  }

  bool _isEpochPlaceholderDateKey(String dateKey) {
    return dateKey == '1970-01-01';
  }

  String _fallbackDateKeyForMonth({required int year, required int month}) {
    final now = DateTime.now();
    final isCurrentMonth = now.year == year && now.month == month;
    final maxDay = DateTime(year, month + 1, 0).day;
    final day = isCurrentMonth ? now.day.clamp(1, maxDay) : 1;
    return '${year.toString().padLeft(4, '0')}-'
        '${month.toString().padLeft(2, '0')}-'
        '${day.toString().padLeft(2, '0')}';
  }

  String? _normalizeDateKey(dynamic raw) {
    if (raw == null) return null;
    if (raw is String) {
      final value = raw.trim();
      if (value.isEmpty) return null;
      final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(value);
      if (match != null) {
        return '${match.group(1)}-${match.group(2)}-${match.group(3)}';
      }
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return '${parsed.year.toString().padLeft(4, '0')}-'
            '${parsed.month.toString().padLeft(2, '0')}-'
            '${parsed.day.toString().padLeft(2, '0')}';
      }
      final parts = value.split(RegExp(r'[./]'));
      if (parts.length == 3) {
        final y = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final d = int.tryParse(parts[2]);
        if (y != null && m != null && d != null) {
          return '${y.toString().padLeft(4, '0')}-'
              '${m.toString().padLeft(2, '0')}-'
              '${d.toString().padLeft(2, '0')}';
        }
      }
      return null;
    }
    if (raw is int) {
      final abs = raw.abs();
      if (abs < 1000000000) return null;
      final millis = abs < 1000000000000 ? raw * 1000 : raw;
      final parsed = DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
      return '${parsed.year.toString().padLeft(4, '0')}-'
          '${parsed.month.toString().padLeft(2, '0')}-'
          '${parsed.day.toString().padLeft(2, '0')}';
    }
    return null;
  }

  dynamic _firstNonNullValue(List<dynamic> values) {
    for (final value in values) {
      if (value != null) return value;
    }
    return null;
  }

  Map<String, dynamic>? _asStringKeyMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, mapValue) => MapEntry(key.toString(), mapValue));
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      if (!(trimmed.startsWith('{') && trimmed.endsWith('}'))) {
        return null;
      }
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) {
          return decoded.map(
            (key, mapValue) => MapEntry(key.toString(), mapValue),
          );
        }
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Map<String, dynamic>? _extractCurrentWeightMap({
    required Map<String, dynamic>? weight,
    required Map<String, dynamic> source,
  }) {
    return _asStringKeyMap(weight?['currentWeight']) ??
        _asStringKeyMap(source['currentWeight']) ??
        _asStringKeyMap(source['current_weight']);
  }

  Map<String, dynamic>? _extractWeightDifferenceMap({
    required Map<String, dynamic>? weight,
    required Map<String, dynamic> source,
  }) {
    return _asStringKeyMap(weight?['weightDifference']) ??
        _asStringKeyMap(source['weightDifference']) ??
        _asStringKeyMap(source['weight_difference']);
  }

  String? _firstString(List<dynamic> values) {
    for (final value in values) {
      if (value == null) continue;
      if (value is Map || value is List || value is Set) {
        continue;
      }
      final text = value.toString().trim();
      if (text == '{}' || text == '[]') continue;
      if (text.toLowerCase() == 'null') continue;
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  String? _extractWeightChangeText({
    required Map<String, dynamic> source,
    required Map<String, dynamic>? weightDifference,
    required String? fallbackUnit,
  }) {
    final text = _firstString([
      source['weightChange'],
      source['weight_change'],
      source['weightDelta'],
      source['weight_diff'],
      source['changeFromPrevDay'],
      source['previousDayWeightChange'],
    ]);
    if (text != null) return text;

    final unit = _normalizeWeightUnit(
      _firstString([
        weightDifference?['unit'],
        source['weightDifferenceUnit'],
        source['weight_difference_unit'],
        source['weightDiffUnit'],
        source['weight_diff_unit'],
        fallbackUnit,
      ]),
    );
    final diffValue = _firstNonNullValue([
      weightDifference?['weight'],
      weightDifference?['value'],
      weightDifference?['difference'],
      source['weightDifferenceValue'],
      source['weight_difference_value'],
      source['weightDiffValue'],
      source['weight_diff_value'],
    ]);
    return _formatWeightDifferenceText(diffValue, unit: unit ?? fallbackUnit);
  }

  String? _normalizeWeightUnit(String? raw) {
    if (raw == null) return null;
    final upper = raw.trim().toUpperCase();
    if (upper == 'KG') return 'kg';
    if (upper == 'G') return 'g';
    return null;
  }

  num? _sanitizeWeightValue(dynamic raw, {String? unit}) {
    final parsed = _toNum(raw);
    if (parsed == null) return null;
    if (parsed <= 0) return null;
    if (parsed > 300000) return null;

    final normalizedUnit = unit?.trim().toLowerCase();
    if (normalizedUnit == 'kg') {
      if (parsed < 0.01 || parsed > 300) return null;
    } else if (normalizedUnit == 'g') {
      if (parsed < 1 || parsed > 300000) return null;
    }
    return parsed;
  }

  String? _formatWeightDifferenceText(dynamic raw, {String? unit}) {
    final normalizedUnit = _normalizeWeightUnit(unit);
    if (normalizedUnit == null) return null;

    final parsed = _toNum(raw);
    if (parsed == null) return null;

    final absValue = parsed.abs();
    if (absValue > 300000) return null;
    if (normalizedUnit == 'kg' && absValue > 300) return null;

    final displayValue = _formatNumber(absValue);
    if (parsed > 0) return '+ $displayValue $normalizedUnit';
    if (parsed < 0) return '- $displayValue $normalizedUnit';
    return '$displayValue $normalizedUnit';
  }

  String _formatNumber(num value) {
    final rounded = (value * 1000).round() / 1000;
    final asInt = rounded.toInt();
    if (rounded == asInt) return asInt.toString();
    return rounded.toString();
  }

  num? _toNum(dynamic value) {
    if (value is num) return value;
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      final direct = num.tryParse(trimmed.replaceAll(',', ''));
      if (direct != null) return direct;
      final match = RegExp(r'[-+]?\d*\.?\d+').firstMatch(trimmed);
      if (match != null) {
        return num.tryParse((match.group(0) ?? '').replaceAll(',', ''));
      }
    }
    return null;
  }

  String? _toMealStatusText(String? raw) {
    if (raw == null) return null;
    switch (raw.trim().toUpperCase()) {
      case 'COMPLETED':
        return '잘 먹음';
      case 'INCOMPLETE':
        return '조금 먹음';
      case 'SKIPPED':
        return '안 먹음';
      default:
        return raw;
    }
  }

  String? _toDefecationText(String? raw) {
    if (raw == null) return null;
    switch (raw.trim().toUpperCase()) {
      case 'NORMAL':
        return '정상';
      case 'DIARRHEA':
        return '설사';
      case 'CONSTIPATED':
        return '변비';
      case 'NONE':
        return '오늘 안함';
      default:
        return raw;
    }
  }

  Future<FormData> _buildPetStateFormData({
    required Map<String, dynamic> request,
    required String? imagePath,
    required String requestPartName,
  }) async {
    final photoPart = await _toPhotoPart(imagePath);
    return FormData.fromMap({
      requestPartName: MultipartFile.fromString(
        jsonEncode(request),
        contentType: MediaType('application', 'json', {'charset': 'utf-8'}),
      ),
      'photo': ?photoPart,
    });
  }

  Future<MultipartFile?> _toPhotoPart(String? imagePath) async {
    if (imagePath == null) return null;
    final trimmed = imagePath.trim();
    if (trimmed.isEmpty) return null;
    if (homeIsRemoteImageUrl(trimmed)) {
      return null;
    }

    try {
      if (!await localImageExists(trimmed)) {
        _log('[HomeRepo] photo 파일 없음: $trimmed');
        return null;
      }

      return await homeCompressedImagePart(trimmed);
    } catch (e) {
      _log('[HomeRepo] photo 파일 파트 생성 실패: $e');
      return null;
    }
  }
}
