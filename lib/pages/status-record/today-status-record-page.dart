/// 오늘의 상태 기록하기 → "빠른 기록" 2페이지 플로우
///
/// - Page 1: 식사(O/X + 시간 + 잘/조금/안먹음), 배변, 체중, 외관(사진 + 추가 메모)
/// - Page 2: 청소, 목욕, 온도 및 습도, 메모
/// - "다음 페이지" / "이전 페이지" 버튼으로 전환, "기록 완료"로 저장

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';

import '../../core/theme/app-theme.dart';
import '../../core/utils/app-logger.dart';
import '../../core/utils/app-size.dart';
import '../../core/widgets/common-app-bar.dart';
import '../../core/widgets/open-my-page-from-app-bar.dart';
import '../../features/auth/models/user.dart';
import '../../features/home/bloc/home-bloc.dart';
import '../../features/home/bloc/home-event.dart';
import 'widgets/today-status-cards.dart';

class TodayStatusRecordPage extends StatefulWidget {
  final User user;
  final int? selectedPetId;
  final DateTime? selectedDate;
  final Map<String, dynamic>? initialRecord;
  final bool hasExistingRecord;

  const TodayStatusRecordPage({
    super.key,
    required this.user,
    this.selectedPetId,
    this.selectedDate,
    this.initialRecord,
    this.hasExistingRecord = false,
  });

  @override
  State<TodayStatusRecordPage> createState() => _TodayStatusRecordPageState();
}

class _TodayStatusRecordPageState extends State<TodayStatusRecordPage> {
  int _currentPage = 0;

  // ── Page 1 state ──
  /// O 선택 시에만 시계·잘/조금/안 먹음 노출. 디폴트는 O/X만 전체 너비.
  bool _mealDetailVisible = false;
  bool _mealDone = false;
  int _mealTypeIndex = 0;
  int _bowelIndex = 0;
  int _appearanceIndex = -1;
  final _weightController = TextEditingController(text: '12');
  bool _weightUnitIsKg = true;
  TimeOfDay _feedTime = TimeOfDay.now();
  final _page1MemoController = TextEditingController();

  // ── Page 2 state ──
  bool _cleaningO = true;
  bool _bathO = true;
  final _page2MemoController = TextEditingController();
  final _temperatureController = TextEditingController(text: '31');
  final _humidityController = TextEditingController(text: '42');
  final ScrollController _scrollController = ScrollController();
  String? _photoPath;
  bool _isSubmitting = false;
  Map<String, dynamic>? _initialStateRecordBody;

  @override
  void initState() {
    super.initState();
    _feedTime = TimeOfDay.now();
    if (widget.initialRecord != null) {
      _applyInitialRecord(widget.initialRecord!);
      _initialStateRecordBody = _buildStateRecordBody();
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _page1MemoController.dispose();
    _page2MemoController.dispose();
    _temperatureController.dispose();
    _humidityController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: CommonAppBar(
        showBackButton: true,
        onNotificationPressed: null,
        onMyPagePressed: () => openMyPageFromAppBar(context),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          Expanded(child: _currentPage == 0 ? _buildPage1() : _buildPage2()),
          _buildBottomButtons(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // Header
  // ═══════════════════════════════════════════════════════
  static String _truncatePetName(String name) {
    final trimmed = name.trim();
    if (trimmed.length <= 8) return trimmed;
    return '${trimmed.substring(0, 8)}...';
  }

  Widget _buildHeader() {
    final pet = context.read<HomeBloc>().state.selectedPet;
    final displayName = pet != null ? _truncatePetName(pet.name) : null;

    return Padding(
      padding: EdgeInsets.fromLTRB(28.s, 0, 15.s, 12.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '빠른 기록',
            style: TextStyle(
              fontFamily: AppFonts.family,
              fontSize: 20.s,
              fontWeight: FontWeight.w800,
              height: 1.0,
              color: const Color(0xFF383838),
            ),
          ),
          if (displayName != null && displayName.isNotEmpty) ...[
            SizedBox(height: 6.s),
            Text(
              displayName,
              style: TextStyle(
                fontFamily: AppFonts.family,
                fontSize: 14.s,
                fontWeight: FontWeight.w600,
                height: 17 / 14,
                color: const Color(0x80383838),
              ),
            ),
          ],
          SizedBox(height: 8.s),
          Text(
            '탭 한 번으로 몇 초 만에 기록',
            style: TextStyle(
              fontFamily: AppFonts.family,
              fontSize: 14.s,
              fontWeight: FontWeight.w400,
              height: 17 / 14,
              color: const Color(0x80383838),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // Bottom buttons (page-specific)
  // ═══════════════════════════════════════════════════════
  Widget _buildBottomButtons() {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(15.s, 10.s, 15.s, 8.s),
        child: _currentPage == 0
            ? _outlinedBtn('다음 페이지', () async {
                await _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                );
                if (!mounted) return;
                setState(() => _currentPage = 1);
              })
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _outlinedBtn('이전 페이지', () async {
                    await _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                    );
                    if (!mounted) return;
                    setState(() => _currentPage = 0);
                  }),
                  SizedBox(height: 8.s),
                  _filledBtn('기록 완료', _submitRecord),
                ],
              ),
      ),
    );
  }

  Future<void> _submitRecord() async {
    if (_isSubmitting) return;

    final petId =
        widget.selectedPetId ??
        context.read<HomeBloc>().state.selectedPet?.petId;
    final targetDate = _buildStateDate();
    final isEditMode = widget.hasExistingRecord;
    if (petId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('반려가족 정보를 찾을 수 없습니다.')));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final primaryPostBody = _buildStateRecordBody();
      final body = isEditMode
          ? _buildPatchStateRecordBody(primaryPostBody)
          : primaryPostBody;
      AppLogger.info(
        '[TodayStatusRecordPage] state ${isEditMode ? 'patch' : 'post'} '
        'body(primary)=${jsonEncode(body)}',
      );
      await _savePetStateRecord(
        petId: petId,
        date: targetDate,
        body: body,
        imagePath: _photoPath,
        isEditMode: isEditMode,
      );
      if (!mounted) return;
      Navigator.of(context).pop(targetDate);
    } catch (e) {
      if (e is DioException) {
        final statusCode = e.response?.statusCode;
        AppLogger.info(
          '[TodayStatusRecordPage] state ${isEditMode ? 'patch' : 'post'} failed '
          'status=$statusCode data=${e.response?.data}',
        );
        if (statusCode == 400 || statusCode == 500) {
          try {
            final fallbackPostBody = _buildStateRecordBody(
              useCanonicalEnums: true,
              canonicalFeedTime: true,
              includeAppearanceImageUrl: false,
            );
            final fallbackBody = isEditMode
                ? _buildPatchStateRecordBody(fallbackPostBody)
                : fallbackPostBody;
            AppLogger.info(
              '[TodayStatusRecordPage] state '
              '${isEditMode ? 'patch' : 'post'} body(fallback)='
              '${jsonEncode(fallbackBody)}',
            );
            await _savePetStateRecord(
              petId: petId,
              date: targetDate,
              body: fallbackBody,
              imagePath: _photoPath,
              isEditMode: isEditMode,
            );
            if (!mounted) return;
            Navigator.of(context).pop(targetDate);
            return;
          } catch (retryError) {
            if (retryError is DioException) {
              AppLogger.info(
                '[TodayStatusRecordPage] state '
                '${isEditMode ? 'patch' : 'post'} fallback failed '
                'status=${retryError.response?.statusCode} '
                'data=${retryError.response?.data}',
              );
            } else {
              AppLogger.info(
                '[TodayStatusRecordPage] state '
                '${isEditMode ? 'patch' : 'post'} fallback failed: $retryError',
              );
            }
          }
        }
      } else {
        AppLogger.info(
          '[TodayStatusRecordPage] state '
          '${isEditMode ? 'patch' : 'post'} failed: $e',
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('상태 기록 저장에 실패했습니다.')));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _savePetStateRecord({
    required int petId,
    required String date,
    required Map<String, dynamic> body,
    required String? imagePath,
    required bool isEditMode,
  }) async {
    final completer = Completer<void>();
    context.read<HomeBloc>().add(
      SavePetStateRecordRequested(
        petId: petId,
        isEditMode: isEditMode,
        date: date,
        body: body,
        imagePath: imagePath,
        completer: completer,
      ),
    );
    return completer.future;
  }

  Map<String, dynamic> _buildStateRecordBody({
    bool useCanonicalEnums = true,
    bool canonicalFeedTime = true,
    bool includeAppearanceImageUrl = true,
  }) {
    final weight = double.tryParse(_weightController.text.trim()) ?? 0;
    final temperature = _parseTemperature(_temperatureController.text.trim());
    final humidity = _parseHumidity(_humidityController.text.trim());
    final appearanceImageUrl = includeAppearanceImageUrl
        ? _toAppearanceImageUrl()
        : '';
    final feed = <String, dynamic>{
      'feed': _mealDone,
      'feedStatus': _buildFeedStatus(canonical: useCanonicalEnums),
    };
    if (_mealDone) {
      feed['feedTime'] = _buildFeedTime(canonical: canonicalFeedTime);
    } else {
      feed['feedTime'] = '';
    }

    return <String, dynamic>{
      'feed': feed,
      'defecation': _buildDefecationStatus(canonical: useCanonicalEnums),
      'weight': <String, dynamic>{
        'weight': weight,
        'unit': useCanonicalEnums
            ? (_weightUnitIsKg ? 'KG' : 'G')
            : (_weightUnitIsKg ? 'Kg' : 'g'),
      },
      'appearance': <String, dynamic>{
        'normalStatus': _buildAppearanceStatus(canonical: useCanonicalEnums),
        'imageUrl': appearanceImageUrl,
        'appearanceMemo': _page1MemoController.text.trim(),
      },
      'clean': _cleaningO,
      'wash': _bathO,
      'temperatureNHumidity': <String, dynamic>{
        'temperature': temperature,
        'humidity': humidity,
      },
      'date': _buildStateDate(),
      'memo': _page2MemoController.text.trim(),
    };
  }

  Map<String, dynamic> _buildPatchStateRecordBody(
    Map<String, dynamic> currentBody,
  ) {
    final initialBody = _initialStateRecordBody;
    if (initialBody == null) {
      AppLogger.info(
        '[TodayStatusRecordPage] state patch baseline missing -> send full body',
      );
      return currentBody;
    }

    final patchBody = <String, dynamic>{};
    final orderedKeys = <String>[
      ...currentBody.keys,
      ...initialBody.keys.where((key) => !currentBody.containsKey(key)),
    ];

    for (final key in orderedKeys) {
      final currentValue = currentBody[key];
      final initialValue = initialBody[key];
      patchBody[key] = _jsonValueEquals(currentValue, initialValue)
          ? null
          : currentValue;
    }

    return patchBody;
  }

  bool _jsonValueEquals(dynamic a, dynamic b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return a == b;
    if (a is num && b is num) {
      return a.toDouble() == b.toDouble();
    }

    final mapA = _asMap(a);
    final mapB = _asMap(b);
    if (mapA != null || mapB != null) {
      if (mapA == null || mapB == null) return false;
      if (mapA.length != mapB.length) return false;
      for (final key in mapA.keys) {
        if (!mapB.containsKey(key)) return false;
        if (!_jsonValueEquals(mapA[key], mapB[key])) return false;
      }
      return true;
    }

    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (!_jsonValueEquals(a[i], b[i])) return false;
      }
      return true;
    }

    return a == b;
  }

  String _buildFeedTime({bool canonical = false}) {
    if (canonical) {
      final h = _feedTime.hour.toString().padLeft(2, '0');
      final m = _feedTime.minute.toString().padLeft(2, '0');
      return '$h:$m:00';
    }
    return '${_feedTime.hour.toString().padLeft(2, '0')} : ${_feedTime.minute.toString().padLeft(2, '0')}';
  }

  String _buildFeedStatus({bool canonical = false}) {
    if (!_mealDone) return canonical ? 'SKIPPED' : '안 먹음';
    switch (_mealTypeIndex) {
      case 1:
        return canonical ? 'INCOMPLETE' : '조금 먹음';
      case 2:
        return canonical ? 'SKIPPED' : '안 먹음';
      default:
        return canonical ? 'COMPLETED' : '잘 먹음';
    }
  }

  String _buildDefecationStatus({bool canonical = false}) {
    switch (_bowelIndex) {
      case 1:
        return canonical ? 'NONE' : '오늘 안함';
      case 2:
        return canonical ? 'DIARRHEA' : '설사';
      case 3:
        return canonical ? 'CONSTIPATED' : '변비';
      default:
        return canonical ? 'NORMAL' : '정상';
    }
  }

  String _buildAppearanceStatus({bool canonical = false}) {
    if (_appearanceIndex == 1) {
      return canonical ? 'ABNORMAL' : '이상있음';
    }
    return canonical ? 'NORMAL' : '정상';
  }

  double _parseTemperature(String raw) {
    return double.tryParse(raw) ?? 0.0;
  }

  int _parseHumidity(String raw) {
    final asInt = int.tryParse(raw);
    if (asInt != null) return asInt;
    final asDouble = double.tryParse(raw);
    if (asDouble != null) return asDouble.round();
    return 0;
  }

  void _applyInitialRecord(Map<String, dynamic> record) {
    final source = _extractSourceRecord(record);
    final feed = _asMap(source['feed']);
    final weight = _asMap(source['weight']);
    final recordAppearance = _asMap(record['appearance']);
    final currentWeight =
        _asMap(weight?['currentWeight']) ??
        _asMap(source['currentWeight']) ??
        _asMap(source['current_weight']);
    final appearance = _asMap(source['appearance']);
    final tempHum = _asMap(source['temperatureNHumidity']);

    final feedDone = _toBool(feed?['feed']);
    if (feedDone != null) {
      _mealDone = feedDone;
      _mealDetailVisible = feedDone;
    }

    final feedStatusRaw =
        (feed?['feedStatus'] ?? source['mealStatus'] ?? source['feedStatus'])
            ?.toString();
    if (feedStatusRaw != null) {
      _mealTypeIndex = _mealTypeIndexFromStatus(
        feedStatusRaw,
        mealDone: _mealDone,
      );
    }

    final feedTime = _parseTimeOfDay(
      (feed?['feedTime'] ?? source['lastMeal'])?.toString(),
    );
    if (feedTime != null) {
      _feedTime = feedTime;
    }

    final defecationRaw = (source['defecation'] ?? source['poopStatus'])
        ?.toString();
    if (defecationRaw != null) {
      _bowelIndex = _bowelIndexFromStatus(defecationRaw);
    }

    final weightUnitRaw = _firstString([
      currentWeight?['unit'],
      weight?['unit'],
      weight?['status'],
      source['weightUnit'],
      source['status'],
      source['unit'],
    ]);
    final normalizedWeightUnit = _normalizeWeightUnit(weightUnitRaw);
    if (normalizedWeightUnit != null) {
      _weightUnitIsKg = normalizedWeightUnit == 'kg';
    }

    final weightValue =
        currentWeight?['weight'] ??
        currentWeight?['value'] ??
        weight?['weight'] ??
        weight?['value'] ??
        weight?['weightStatus'] ??
        source['weightStatus'] ??
        source['todayWeight'] ??
        (source['weight'] is Map<String, dynamic> ? null : source['weight']);
    final parsedWeight = _sanitizeWeightValue(
      weightValue,
      unit: normalizedWeightUnit,
    );
    if (parsedWeight != null) {
      _weightController.text = _formatNumberForInput(parsedWeight);
    }

    final normalStatusRaw =
        (appearance?['normalStatus'] ?? source['normalStatus'])?.toString();
    if (normalStatusRaw != null) {
      _appearanceIndex = _appearanceIndexFromStatus(normalStatusRaw);
    }
    final appearanceMemo = _firstString([
      appearance?['appearanceMemo'],
      appearance?['appearance_memo'],
      appearance?['memo'],
      source['appearanceMemo'],
      source['appearance_memo'],
      recordAppearance?['appearanceMemo'],
      recordAppearance?['appearance_memo'],
      recordAppearance?['memo'],
      record['appearanceMemo'],
      record['appearance_memo'],
      _extractAppearanceMemoDeep(source),
      _extractAppearanceMemoDeep(record),
    ]);
    if (appearanceMemo != null) {
      _page1MemoController.text = appearanceMemo;
    } else {
      AppLogger.info(
        '[TodayStatusRecordPage] appearanceMemo not found '
        'recordKeys=${record.keys.toList()} sourceKeys=${source.keys.toList()}',
      );
    }
    final photoRaw =
        (appearance?['imageUrl'] ??
                source['imageUrl'] ??
                source['photoPath'] ??
                source['photo'])
            ?.toString()
            .trim();
    if (photoRaw != null && photoRaw.isNotEmpty) {
      _photoPath = photoRaw;
    }

    final clean = _toBool(source['clean']);
    if (clean != null) _cleaningO = clean;
    final wash = _toBool(source['wash']);
    if (wash != null) _bathO = wash;

    final temperature = _toNum(
      tempHum?['temperature'] ?? source['temperature'],
    );
    if (temperature != null) {
      _temperatureController.text = _formatNumberForInput(temperature);
    }
    final humidity = _toNum(tempHum?['humidity'] ?? source['humidity']);
    if (humidity != null) {
      _humidityController.text = humidity.round().toString();
    }

    final memo = _firstString([source['memo'], record['memo']]);
    if (memo != null) {
      _page2MemoController.text = memo;
    }
  }

  Map<String, dynamic> _extractSourceRecord(Map<String, dynamic> record) {
    Map<String, dynamic>? toMap(dynamic value) {
      if (value is Map<String, dynamic>) return value;
      if (value is Map) {
        return value.map((k, v) => MapEntry(k.toString(), v));
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
            return decoded.map((k, v) => MapEntry(k.toString(), v));
          }
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    final raw = record['raw'];
    final rawMap = toMap(raw);
    if (rawMap != null) {
      return rawMap;
    }
    final stateRequest =
        toMap(record['stateRequest']) ?? toMap(record['stateEditRequest']);
    if (stateRequest != null) {
      final merged = <String, dynamic>{...stateRequest};
      if (record['photo'] != null) merged['photo'] = record['photo'];
      return merged;
    }
    return record;
  }

  bool? _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1' || normalized == 'y') {
        return true;
      }
      if (normalized == 'false' || normalized == '0' || normalized == 'n') {
        return false;
      }
    }
    return null;
  }

  num? _toNum(dynamic value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value.trim());
    return null;
  }

  String? _firstString(List<dynamic> values) {
    for (final value in values) {
      if (value == null) continue;
      if (value is Map || value is List || value is Set) continue;
      final text = value.toString().trim();
      if (text.isEmpty) continue;
      if (text.toLowerCase() == 'null') continue;
      return text;
    }
    return null;
  }

  String _normalizeLookupKey(String raw) {
    final lower = raw.trim().toLowerCase();
    if (lower.isEmpty) return '';
    return lower.replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  String? _extractAppearanceMemoDeep(
    dynamic node, {
    Set<int>? visited,
    List<String> path = const <String>[],
  }) {
    final seen = visited ?? <int>{};

    Map<String, dynamic>? toMap(dynamic value) {
      if (value is Map<String, dynamic>) return value;
      if (value is Map) {
        return value.map((k, v) => MapEntry(k.toString(), v));
      }
      return null;
    }

    if (node is List) {
      final id = identityHashCode(node);
      if (!seen.add(id)) return null;
      for (final item in node) {
        final found = _extractAppearanceMemoDeep(
          item,
          visited: seen,
          path: path,
        );
        if (found != null) return found;
      }
      return null;
    }

    final map = toMap(node);
    if (map == null) return null;
    final id = identityHashCode(map);
    if (!seen.add(id)) return null;

    final direct = _firstString([
      map['appearanceMemo'],
      map['appearance_memo'],
      map['appearancememo'],
      map['appearanceNote'],
      map['appearance_note'],
    ]);
    if (direct != null) return direct;

    final appearanceMap = _asMap(map['appearance']);
    if (appearanceMap != null) {
      final fromAppearance = _firstString([
        appearanceMap['appearanceMemo'],
        appearanceMap['appearance_memo'],
        appearanceMap['memo'],
        appearanceMap['additionalMemo'],
        appearanceMap['additional_memo'],
        appearanceMap['note'],
      ]);
      if (fromAppearance != null) return fromAppearance;
    }

    for (final entry in map.entries) {
      final key = _normalizeLookupKey(entry.key);
      final value = entry.value;
      final nextPath = <String>[...path, key];
      if (value is Map || value is List) {
        final found = _extractAppearanceMemoDeep(
          value,
          visited: seen,
          path: nextPath,
        );
        if (found != null) return found;
        continue;
      }

      final text = _firstString([value]);
      if (text == null) continue;

      final inAppearanceContext =
          path.contains('appearance') || key.contains('appearance');
      if (key == 'appearancememo' ||
          (inAppearanceContext &&
              (key == 'memo' || key == 'additionalmemo' || key == 'note'))) {
        return text;
      }
    }

    return null;
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    return null;
  }

  String? _normalizeWeightUnit(String? raw) {
    if (raw == null) return null;
    final unit = raw.trim().toLowerCase();
    if (unit == 'kg') return 'kg';
    if (unit == 'g') return 'g';
    return null;
  }

  num? _sanitizeWeightValue(dynamic raw, {String? unit}) {
    final parsed = _toNum(raw);
    if (parsed == null) return null;
    if (parsed <= 0) return null;
    if (parsed > 300000) return null;

    if (unit == 'kg') {
      if (parsed < 0.01 || parsed > 300) return null;
    } else if (unit == 'g') {
      if (parsed < 1 || parsed > 300000) return null;
    }
    return parsed;
  }

  String _formatNumberForInput(num value) {
    final asInt = value.toInt();
    if (value == asInt) return asInt.toString();
    return value.toString();
  }

  TimeOfDay? _parseTimeOfDay(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final match = RegExp(r'(\d{1,2})\s*:\s*(\d{1,2})').firstMatch(raw.trim());
    if (match == null) return null;
    final hour = int.tryParse(match.group(1) ?? '');
    final minute = int.tryParse(match.group(2) ?? '');
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  int _mealTypeIndexFromStatus(String raw, {required bool mealDone}) {
    final normalized = raw.trim().toUpperCase();
    if (normalized == 'INCOMPLETE' || raw.contains('조금')) {
      return 1;
    }
    if (normalized == 'SKIPPED' || raw.contains('안 먹음')) {
      return 2;
    }
    if (!mealDone) return 0;
    return 0;
  }

  int _bowelIndexFromStatus(String raw) {
    final normalized = raw.trim().toUpperCase();
    if (normalized == 'NONE' || raw.contains('오늘 안함')) return 1;
    if (normalized == 'DIARRHEA' || raw.contains('설사')) return 2;
    if (normalized == 'CONSTIPATED' || raw.contains('변비')) return 3;
    return 0;
  }

  int _appearanceIndexFromStatus(String raw) {
    final normalized = raw.trim().toUpperCase();
    if (normalized == 'ABNORMAL' || raw.contains('이상')) return 1;
    if (normalized == 'NORMAL' || raw.contains('정상')) return 0;
    return -1;
  }

  String _buildStateDate() {
    final base = widget.selectedDate ?? DateTime.now();
    final year = base.year.toString().padLeft(4, '0');
    final month = base.month.toString().padLeft(2, '0');
    final day = base.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _toAppearanceImageUrl() {
    final raw = (_photoPath ?? '').trim();
    if (raw.isEmpty) return '';
    final lower = raw.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return raw;
    }
    // 로컬 파일 경로/파일명은 imageUrl 필드에 넣지 않는다.
    // 실제 이미지는 multipart "photo" 파트로 전송된다.
    return '';
  }

  // ═══════════════════════════════════════════════════════
  // Page 1
  // ═══════════════════════════════════════════════════════
  Widget _buildPage1() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: 15.s),
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TodayMealCard(
              mealDone: _mealDone,
              mealDetailVisible: _mealDetailVisible,
              mealTypeIndex: _mealTypeIndex,
              onMealDoneChanged: (v) {
                setState(() {
                  _mealDone = v;
                  _mealDetailVisible = v;
                });
              },
              onMealTypeChanged: (i) => setState(() => _mealTypeIndex = i),
              feedTime: _feedTime,
              onFeedTimeChanged: (t) => setState(() => _feedTime = t),
            ),
            SizedBox(height: 14.s),
            TodayBowelCard(
              bowelIndex: _bowelIndex,
              onChanged: (i) => setState(() => _bowelIndex = i),
            ),
            SizedBox(height: 14.s),
            TodayWeightCard(
              controller: _weightController,
              unitIsKg: _weightUnitIsKg,
              onUnitToggle: () =>
                  setState(() => _weightUnitIsKg = !_weightUnitIsKg),
            ),
            SizedBox(height: 14.s),
            TodayAppearanceCard(
              appearanceIndex: _appearanceIndex,
              onChanged: (i) => setState(() => _appearanceIndex = i),
              memoController: _page1MemoController,
              initialPhotoPath: _photoPath,
              onPhotoChanged: (path) => setState(() => _photoPath = path),
            ),
            SizedBox(height: 24.s),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // Page 2
  // ═══════════════════════════════════════════════════════
  Widget _buildPage2() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: 15.s),
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 청소 + 목욕 ──
            Row(
              children: [
                Expanded(
                  child: TodayOXCard(
                    tag: '청소',
                    isOSelected: _cleaningO,
                    onChanged: (v) => setState(() => _cleaningO = v),
                  ),
                ),
                SizedBox(width: 15.s),
                Expanded(
                  child: TodayOXCard(
                    tag: '목욕',
                    isOSelected: _bathO,
                    onChanged: (v) => setState(() => _bathO = v),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.s),
            TodayTempHumidityCard(
              tempController: _temperatureController,
              humidityController: _humidityController,
            ),
            SizedBox(height: 14.s),
            TodayMemoCard(memoController: _page2MemoController),
            SizedBox(height: 24.s),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // Bottom buttons
  // ═══════════════════════════════════════════════════════
  Widget _outlinedBtn(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 28.s,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.main, width: 1.24.s),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.s),
          ),
          backgroundColor: Colors.white,
          padding: EdgeInsets.zero,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.family,
            fontSize: 12.s,
            fontWeight: FontWeight.w800,
            color: AppColors.main,
          ),
        ),
      ),
    );
  }

  Widget _filledBtn(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 30.s,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.main,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.s),
            side: BorderSide(color: AppColors.main, width: 1.24.s),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.family,
            fontSize: 12.s,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
