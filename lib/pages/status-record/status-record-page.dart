/// 상태 기록 화면
///
/// - 월별 상태 기록 API(`/pet/{pet_id}/state/month`)를 호출해 캘린더/요약을 갱신합니다.
/// - 선택한 날짜 기준으로 현재 체중·마지막 식사·사진이 해당 날짜 데이터로 표시됩니다.

import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app-theme.dart';
import '../../core/utils/app-logger.dart';
import '../../core/utils/app-size.dart';
import '../../core/widgets/common-app-bar.dart';
import '../../core/widgets/open-my-page-from-app-bar.dart';
import '../../features/auth/models/user.dart';
import '../../features/home/bloc/home-bloc.dart';
import '../../features/home/bloc/home-event.dart';
import '../../features/home/bloc/home-state.dart';
import '../../features/home/models/pet-profile.dart';
import '../pet-family-settings/pet-family-settings-page.dart';
import 'today-status-record-page.dart';

class StatusRecordPage extends StatefulWidget {
  final User user;

  const StatusRecordPage({super.key, required this.user});

  @override
  State<StatusRecordPage> createState() => _StatusRecordPageState();
}

class _StatusRecordPageState extends State<StatusRecordPage> {
  List<PetProfile> _profiles = [];
  int _selectedProfileIndex = 0;

  late DateTime _viewMonth;
  late DateTime _selectedDate;

  // 월별 API 응답에서 기록이 있는 날짜를 캘린더 마커용으로 관리.
  final Set<DateTime> _recordedDates = {};

  /// 날짜 키 "YYYY-MM-DD" → 해당 날짜 상태 기록 (체중, 마지막 식사, 배지, photoPath 등)
  Map<String, Map<String, dynamic>> _recordsByDate = {};
  int _recordsLoadSeq = 0;
  final Map<String, Map<String, dynamic>?> _briefDetailsByDate = {};
  int _briefDetailLoadSeq = 0;
  final Map<int, Set<String>> _localSavedDateKeysByPet = {};
  String? _loadingBriefDateKey;
  Map<String, dynamic>? _loadingFallbackRecord;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _viewMonth = DateTime(now.year, now.month);
    _selectedDate = now;
    // 1) HomeBloc(/pet/main) 캐시로 빠르게 초기 UI 표시
    _primeProfilesFromHomeState();
    // 2) /pet/me로 petId 포함 전체 데이터 로드 (기록 조회에 petId 필수)
    final homeState = context.read<HomeBloc>().state;
    if (homeState.user.id != 'guest') {
      unawaited(_fetchMyProfiles());
    }
  }

  void _primeProfilesFromHomeState() {
    final homeState = context.read<HomeBloc>().state;
    if (homeState.profiles.isEmpty) {
      _profiles = List<PetProfile>.from(defaultPetProfiles);
      _selectedProfileIndex = 0;
      unawaited(_loadStatusRecordsForViewMonth(petIdOverride: null));
      return;
    }

    final cachedProfiles = List<PetProfile>.from(homeState.profiles);
    var cachedIndex = homeState.selectedProfileIndex;
    if (cachedIndex < 0 || cachedIndex >= cachedProfiles.length) {
      cachedIndex = 0;
    }

    _profiles = cachedProfiles;
    _selectedProfileIndex = cachedIndex;

    final petId = cachedProfiles[cachedIndex].petId;
    unawaited(_loadStatusRecordsForViewMonth(petIdOverride: petId));
  }

  /// /pet/me로 petId가 포함된 전체 프로필 목록을 로드.
  ///
  /// [targetPetId]가 주어지면 해당 반려동물을 선택 상태로 만든다.
  /// 없으면 현재 선택된 반려동물을 petId → name 순으로 매칭해 유지한다.
  Future<void> _fetchMyProfiles({int? targetPetId}) async {
    try {
      final loaded = await _requestMyPetProfiles();
      if (!mounted || loaded.isEmpty) return;

      var newIndex = 0;
      if (targetPetId != null) {
        final found = loaded.indexWhere((p) => p.petId == targetPetId);
        if (found >= 0) newIndex = found;
      } else {
        final current = _profiles.isNotEmpty
            ? _profiles[_selectedProfileIndex]
            : null;
        if (current != null) {
          if (current.petId != null) {
            final found = loaded.indexWhere((p) => p.petId == current.petId);
            if (found >= 0) newIndex = found;
          } else if (current.name.trim().isNotEmpty) {
            final found = loaded.indexWhere(
              (p) => p.name.trim() == current.name.trim(),
            );
            if (found >= 0) newIndex = found;
          }
        }
      }

      final petId = loaded[newIndex].petId;
      final previousRecord = _displayRecord;
      final selectedDateKey = _dateKey(_selectedDate);
      setState(() {
        _profiles = List<PetProfile>.from(loaded);
        _selectedProfileIndex = newIndex;
        _briefDetailsByDate.clear();
        _loadingBriefDateKey = selectedDateKey;
        _loadingFallbackRecord = previousRecord == null
            ? null
            : Map<String, dynamic>.from(previousRecord);
      });
      if (petId != null) {
        unawaited(_loadStatusRecordsForViewMonth(petIdOverride: petId));
      }
    } catch (_) {}
  }

  /// HomeBloc 상태 변화를 감지해 **외부에서** 선택된 반려동물이 바뀐 경우에만
  /// /pet/me를 재조회한다.
  ///
  /// 이 페이지 내에서 직접 선택한 경우에는 [_selectedPetId]가 이미 동기화된
  /// 상태이므로 petId가 일치해 아무 일도 일어나지 않는다.
  void _syncFromHomeState(HomeState state) {
    if (state.user.id != 'guest' && state.profiles.isEmpty) return;

    final incomingPetId = state.selectedPet?.petId;
    if (incomingPetId == null) return;
    if (incomingPetId == _selectedPetId) return;

    // 외부(홈 화면 등)에서 선택된 반려동물이 바뀐 경우 → /pet/me 재조회
    unawaited(_fetchMyProfiles(targetPetId: incomingPetId));
  }

  int? get _selectedPetId {
    if (_profiles.isNotEmpty &&
        _selectedProfileIndex >= 0 &&
        _selectedProfileIndex < _profiles.length) {
      return _profiles[_selectedProfileIndex].petId;
    }
    return null;
  }

  /// 상태 기록 화면 프로필 목록은 `/pet/me`만 사용한다.
  Future<List<PetProfile>> _requestMyPetProfiles() {
    final completer = Completer<List<PetProfile>>();
    context.read<HomeBloc>().add(
      FetchMyPetProfilesRequested(completer: completer),
    );
    return completer.future;
  }

  Future<Map<String, Map<String, dynamic>>> _requestPetStateRecordsByMonth({
    required int petId,
    required int year,
    required int month,
  }) {
    final completer = Completer<Map<String, Map<String, dynamic>>>();
    context.read<HomeBloc>().add(
      FetchPetStateRecordsByMonthRequested(
        petId: petId,
        year: year,
        month: month,
        completer: completer,
      ),
    );
    return completer.future;
  }

  Future<Map<String, dynamic>?> _requestPetStateRecordDetail({
    required int petId,
    required String date,
    required String view,
  }) {
    final completer = Completer<Map<String, dynamic>?>();
    context.read<HomeBloc>().add(
      FetchPetStateRecordDetailRequested(
        petId: petId,
        date: date,
        view: view,
        completer: completer,
      ),
    );
    return completer.future;
  }

  Future<void> _loadStatusRecordsForViewMonth({int? petIdOverride}) async {
    final petId = petIdOverride ?? _selectedPetId;
    final requestSeq = ++_recordsLoadSeq;
    final selectedDateAtRequest = _selectedDate;
    if (petId == null) {
      _clearLoadingFallbackForDate(selectedDateAtRequest);
      return;
    }

    final year = _viewMonth.year;
    final month = _viewMonth.month;
    final localSavedKeys = _localSavedDateKeysByPet[petId] ?? const <String>{};
    try {
      final byDate = await _requestPetStateRecordsByMonth(
        petId: petId,
        year: year,
        month: month,
      );
      if (!mounted || requestSeq != _recordsLoadSeq) return;
      final mergedByDate = <String, Map<String, dynamic>>{...byDate};
      for (final key in localSavedKeys) {
        mergedByDate.putIfAbsent(key, () => <String, dynamic>{'date': key});
      }
      final dates = mergedByDate.keys
          .map(_parseFlexibleDateKey)
          .whereType<DateTime>()
          .toSet();
      setState(() {
        _recordsByDate = mergedByDate;
        _recordedDates
          ..clear()
          ..addAll(dates);
      });
      await _loadBriefDetailForSelectedDate(
        petIdOverride: petId,
        dateOverride: selectedDateAtRequest,
      );
      if (!mounted || requestSeq != _recordsLoadSeq) return;
      _clearLoadingFallbackForDate(selectedDateAtRequest);
      AppLogger.info(
        '[StatusRecordPage] month records loaded '
        'petId=$petId year=$year month=$month keys=${mergedByDate.keys.toList()}',
      );
    } catch (e) {
      if (!mounted || requestSeq != _recordsLoadSeq) return;
      AppLogger.info(
        '[StatusRecordPage] month records load failed '
        'petId=$petId year=$year month=$month error=$e',
      );
      final localOnly = <String, Map<String, dynamic>>{};
      for (final key in localSavedKeys) {
        localOnly[key] = <String, dynamic>{'date': key};
      }
      if (localOnly.isEmpty) {
        _clearLoadingFallbackForDate(selectedDateAtRequest);
        return;
      }
      final localDates = localOnly.keys
          .map(_parseFlexibleDateKey)
          .whereType<DateTime>()
          .toSet();
      setState(() {
        _recordsByDate = localOnly;
        _recordedDates
          ..clear()
          ..addAll(localDates);
      });
      await _loadBriefDetailForSelectedDate(
        petIdOverride: petId,
        dateOverride: selectedDateAtRequest,
      );
      if (!mounted || requestSeq != _recordsLoadSeq) return;
      _clearLoadingFallbackForDate(selectedDateAtRequest);
    }
  }

  Future<void> _loadBriefDetailForSelectedDate({
    int? petIdOverride,
    DateTime? dateOverride,
  }) async {
    final petId = petIdOverride ?? _selectedPetId;
    if (petId == null) return;
    final targetDate = dateOverride ?? _selectedDate;
    final dateKey = _dateKey(targetDate);
    final requestSeq = ++_briefDetailLoadSeq;

    // 월 캘린더(GET) 응답에 없는 날짜는 상세 조회를 호출하지 않는다.
    if (!_isDateInMonthCalendarResponse(targetDate)) {
      if (!mounted || requestSeq != _briefDetailLoadSeq) return;
      if (_briefDetailsByDate.containsKey(dateKey)) {
        setState(() {
          _briefDetailsByDate.remove(dateKey);
        });
      }
      AppLogger.info(
        '[StatusRecordPage] brief detail skipped '
        'petId=$petId date=$dateKey reason=not-in-month-calendar',
      );
      return;
    }

    try {
      final detail = await _requestPetStateRecordDetail(
        petId: petId,
        date: dateKey,
        view: 'brief',
      );
      if (!mounted || requestSeq != _briefDetailLoadSeq) return;
      setState(() {
        _briefDetailsByDate[dateKey] = detail;
      });
      AppLogger.info(
        '[StatusRecordPage] brief detail loaded '
        'petId=$petId date=$dateKey exists=${detail != null}',
      );
    } catch (e) {
      if (!mounted || requestSeq != _briefDetailLoadSeq) return;
      setState(() {
        _briefDetailsByDate.remove(dateKey);
      });
      AppLogger.info(
        '[StatusRecordPage] brief detail load failed '
        'petId=$petId date=$dateKey error=$e',
      );
    }
  }

  void _onViewMonthChanged(DateTime nextMonth) {
    final normalized = DateTime(nextMonth.year, nextMonth.month);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isCurrentMonth =
        normalized.year == today.year && normalized.month == today.month;
    final nextSelected = isCurrentMonth
        ? today
        : DateTime(normalized.year, normalized.month, 1);

    setState(() {
      _viewMonth = normalized;
      _selectedDate = nextSelected;
      _loadingBriefDateKey = null;
      _loadingFallbackRecord = null;
    });
    unawaited(_loadStatusRecordsForViewMonth());
  }

  bool get _isSelectedDateBriefLoading =>
      _loadingBriefDateKey == _dateKey(_selectedDate);

  Future<void> _handleCalendarDateTap(DateTime day) async {
    final isSameDate =
        day.year == _selectedDate.year &&
        day.month == _selectedDate.month &&
        day.day == _selectedDate.day;
    if (isSameDate && !_isSelectedDateBriefLoading) return;

    final dayKey = _dateKey(day);
    final previousRecord = _selectedRecord;
    setState(() {
      _selectedDate = day;
      _loadingBriefDateKey = dayKey;
      _loadingFallbackRecord = previousRecord == null
          ? null
          : Map<String, dynamic>.from(previousRecord);
    });

    try {
      await _loadBriefDetailForSelectedDate(dateOverride: day);
    } finally {
      final shouldClear = mounted && _loadingBriefDateKey == dayKey;
      if (shouldClear) {
        setState(() {
          _loadingBriefDateKey = null;
          _loadingFallbackRecord = null;
        });
      }
    }
  }

  Map<String, dynamic>? get _displayRecord {
    if (_isSelectedDateBriefLoading && _loadingFallbackRecord != null) {
      return _loadingFallbackRecord;
    }
    return _selectedRecord;
  }

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  DateTime? _parseFlexibleDateKey(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    final match = RegExp(
      r'^(\d{4})[-./](\d{1,2})[-./](\d{1,2})',
    ).firstMatch(value);
    if (match != null) {
      final year = int.tryParse(match.group(1) ?? '');
      final month = int.tryParse(match.group(2) ?? '');
      final day = int.tryParse(match.group(3) ?? '');
      if (year != null && month != null && day != null) {
        return DateTime(year, month, day);
      }
    }
    final parsed = DateTime.tryParse(value);
    if (parsed != null) {
      return DateTime(parsed.year, parsed.month, parsed.day);
    }
    return null;
  }

  /// 선택한 날짜의 기록. 없으면 null (기본 UI 표시).
  Map<String, dynamic>? get _selectedRecord {
    final selectedKey = _dateKey(_selectedDate);
    if (_briefDetailsByDate.containsKey(selectedKey)) {
      return _briefDetailsByDate[selectedKey];
    }

    final exact = _recordsByDate[_dateKey(_selectedDate)];
    if (exact != null) return exact;
    for (final entry in _recordsByDate.entries) {
      final parsed = _parseFlexibleDateKey(entry.key);
      if (parsed == null) continue;
      if (parsed.year == _selectedDate.year &&
          parsed.month == _selectedDate.month &&
          parsed.day == _selectedDate.day) {
        return entry.value;
      }
    }
    return null;
  }

  /// 기록된 날짜들 오름차순 정렬 (과거 → 최신).
  List<DateTime> get _sortedRecordDates {
    final list = _recordsByDate.keys
        .map((k) {
          final p = k.split('-');
          if (p.length != 3) return null;
          return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
        })
        .whereType<DateTime>()
        .toList();
    list.sort((a, b) => a.compareTo(b));
    return list;
  }

  /// 선택한 날짜의 체중과 그 이전 기록 중 가장 최신 체중의 차이를 배지 문자열로 반환.
  /// (가장 최근 입력값 = 선택일, 과거 중 가장 최신 = 그 이전 기록)
  String get _computedWeightChange {
    final r = _displayRecord;
    if (r == null) return '-';
    final serverWeightChange = _toDisplayText(r['weightChange']);
    if (serverWeightChange != null) return serverWeightChange;
    if (_isSelectedDateBriefLoading) return '-';
    final currentUnit = _normalizeWeightUnit(r['weightUnit']) ?? 'g';
    final currentWeight = _parseWeight(r['weight'], unit: currentUnit);
    if (currentWeight == null) return '-';
    final key = _dateKey(_selectedDate);
    final sorted = _sortedRecordDates;
    final idx = sorted.indexWhere((d) => _dateKey(d) == key);
    if (idx <= 0) return '-'; // 이전 기록 없음
    final prevKey = _dateKey(sorted[idx - 1]);
    final prevRecord = _recordsByDate[prevKey];
    if (prevRecord == null) return '-';
    final prevUnit = _normalizeWeightUnit(prevRecord['weightUnit']) ?? 'g';
    final prevWeight = _parseWeight(prevRecord['weight'], unit: prevUnit);
    if (prevWeight == null) return '-';

    final currentGrams = _toGrams(currentWeight, unit: currentUnit);
    final prevGrams = _toGrams(prevWeight, unit: prevUnit);
    if (currentGrams == null || prevGrams == null) return '-';

    final diffGrams = currentGrams - prevGrams;
    final displayDiff = currentUnit == 'kg' ? diffGrams / 1000 : diffGrams;
    final displayText = _formatWeightValue(displayDiff.abs());
    return diffGrams >= 0
        ? '+ $displayText $currentUnit'
        : '- $displayText $currentUnit';
  }

  static num? _parseWeight(dynamic value, {String? unit}) {
    final parsed = _toNum(value);
    if (parsed == null) return null;
    if (parsed <= 0) return null;
    if (parsed > 300000) return null;

    final normalizedUnit = _normalizeWeightUnit(unit);
    if (normalizedUnit == 'kg') {
      if (parsed < 0.01 || parsed > 300) return null;
    } else if (normalizedUnit == 'g') {
      if (parsed < 1 || parsed > 300000) return null;
    }
    return parsed;
  }

  static String? _normalizeWeightUnit(dynamic raw) {
    if (raw == null) return null;
    final unit = raw.toString().trim().toLowerCase();
    if (unit == 'kg') return 'kg';
    if (unit == 'g') return 'g';
    return null;
  }

  static num? _toGrams(num value, {required String unit}) {
    if (unit == 'kg') return value * 1000;
    if (unit == 'g') return value;
    return null;
  }

  static num? _toNum(dynamic value) {
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

  static String _formatWeightValue(num value) {
    final rounded = (value * 1000).round() / 1000;
    final asInt = rounded.toInt();
    if (rounded == asInt) return asInt.toString();
    return rounded.toString();
  }

  static String? _toDisplayText(dynamic value) {
    if (value == null) return null;
    if (value is Map || value is List || value is Set) return null;
    final text = value.toString().trim();
    if (text.isEmpty || text == '{}' || text == '[]') return null;
    if (text.toLowerCase() == 'null') return null;
    return text;
  }

  Future<void> _selectProfile(int index) async {
    if (index < 0 || index >= _profiles.length) return;

    final selected = _profiles[index];
    final previousRecord = _displayRecord;
    final selectedDateKey = _dateKey(_selectedDate);
    setState(() {
      _selectedProfileIndex = index;
      _loadingBriefDateKey = selectedDateKey;
      _loadingFallbackRecord = previousRecord == null
          ? null
          : Map<String, dynamic>.from(previousRecord);
    });
    _briefDetailsByDate.clear();

    final petId = selected.petId;

    AppLogger.info(
      '[StatusRecordPage] profile selected '
      'index=$index petId=$petId name=${selected.name}',
    );
    if (petId == null) {
      _clearLoadingFallbackForDate(_selectedDate);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('프로필 정보를 불러오지 못했습니다.')));
      }
      return;
    }
    if (!mounted) return;
    context.read<HomeBloc>().add(
      ProfilesUpdated(
        profiles: List<PetProfile>.from(_profiles),
        selectedIndex: index,
      ),
    );
    unawaited(_loadStatusRecordsForViewMonth(petIdOverride: petId));
  }

  void _clearLoadingFallbackForDate(DateTime date) {
    if (!mounted) return;
    final loadingKey = _loadingBriefDateKey;
    if (loadingKey == null) return;
    if (loadingKey != _dateKey(date)) return;
    setState(() {
      _loadingBriefDateKey = null;
      _loadingFallbackRecord = null;
    });
  }

  List<DateTime?> _buildDays() {
    final first = DateTime(_viewMonth.year, _viewMonth.month, 1);
    final last = DateTime(_viewMonth.year, _viewMonth.month + 1, 0);
    final startWeekday = first.weekday % 7;
    final days = <DateTime?>[];
    for (int i = 0; i < startWeekday; i++) {
      days.add(null);
    }
    for (int d = 1; d <= last.day; d++) {
      days.add(DateTime(_viewMonth.year, _viewMonth.month, d));
    }
    return days;
  }

  bool _hasRecord(DateTime day) {
    return _isDateInMonthCalendarResponse(day);
  }

  bool _isDateInMonthCalendarResponse(DateTime day) {
    final inRecordedDates = _recordedDates.any(
      (d) => d.year == day.year && d.month == day.month && d.day == day.day,
    );
    if (inRecordedDates) return true;

    final exact = _dateKey(day);
    if (_recordsByDate.containsKey(exact)) return true;
    for (final key in _recordsByDate.keys) {
      final parsed = _parseFlexibleDateKey(key);
      if (parsed == null) continue;
      if (parsed.year == day.year &&
          parsed.month == day.month &&
          parsed.day == day.day) {
        return true;
      }
    }
    return false;
  }

  void _rememberLocalSavedDate({required int petId, required String dateKey}) {
    if (dateKey.trim().isEmpty) return;
    final set = _localSavedDateKeysByPet.putIfAbsent(petId, () => <String>{});
    set.add(dateKey);
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final showNoRecordState = _shouldShowNoRecordState;

    return BlocListener<HomeBloc, HomeState>(
      listenWhen: (previous, current) {
        return previous.selectedProfileIndex != current.selectedProfileIndex ||
            !HomeState.areSameProfiles(previous.profiles, current.profiles);
      },
      listener: (context, state) {
        _syncFromHomeState(state);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: CommonAppBar(
          showBackButton: true,
          onNotificationPressed: null,
          onMyPagePressed: () => openMyPageFromAppBar(context),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 15.s),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4.s),
                      _buildProfileRow(),
                      SizedBox(height: 14.s),
                      // ── 캘린더 ──
                      _buildSectionTab('캘린더'),
                      _buildCalendar(),
                      if (showNoRecordState) ...[
                        SizedBox(height: 24.s),
                        _buildNoRecordSection(),
                        SizedBox(height: 20.s),
                      ] else ...[
                        SizedBox(height: 16.s),
                        // ── 오늘의 상태 ──
                        _buildSectionTab('오늘의 상태'),
                        _buildStatusCards(),
                        SizedBox(height: 14.s),
                        _buildPoopSection(),
                        if (_toDisplayText(_displayRecord?['appearanceMemo']) !=
                            null) ...[
                          SizedBox(height: 12.s),
                          _buildAppearanceMemoSection(),
                        ],
                        SizedBox(height: 16.s),
                        // ── 사진 ──
                        _buildSectionTab('사진'),
                        _buildPhotoSection(),
                        SizedBox(height: 20.s),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // 프로필 선택 행 (pet-family-settings 재활용)
  // ══════════════════════════════════════════════════════
  Widget _buildProfileRow() {
    // petId가 하나라도 있으면 진짜 프로필이 있는 것으로 판단.
    // defaultPetProfiles(petId=null, name='')만 있는 경우는 미설정 상태.
    final hasRealProfiles = _profiles.any(
      (p) => p.petId != null || p.name.trim().isNotEmpty,
    );

    if (!hasRealProfiles) {
      return SizedBox(
        height: 84.s,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.only(left: 15.s, right: 15.s),
          physics: const BouncingScrollPhysics(),
          children: [
            Padding(
              padding: EdgeInsets.only(top: 4.s),
              child: GestureDetector(
                onTap: () async {
                  final result = await Navigator.of(context)
                      .push<PetFamilySettingsResult>(
                        MaterialPageRoute<PetFamilySettingsResult>(
                          builder: (_) => PetFamilySettingsPage(
                            initialSelectedIndex: 0,
                            initialProfiles: const [],
                            startWithAddProfile: true,
                          ),
                        ),
                      );
                  if (!mounted) return;
                  if (result != null && result.profiles.isNotEmpty) {
                    final nextIndex =
                        result.selectedIndex >= 0 &&
                            result.selectedIndex < result.profiles.length
                        ? result.selectedIndex
                        : 0;
                    setState(() {
                      _profiles = List<PetProfile>.from(result.profiles);
                      _selectedProfileIndex = nextIndex;
                    });
                    context.read<HomeBloc>().add(
                      ProfilesUpdated(
                        profiles: List<PetProfile>.from(result.profiles),
                        selectedIndex: nextIndex,
                      ),
                    );
                    return;
                  }
                  context.read<HomeBloc>().add(const RefreshHome());
                },
                child: Column(
                  children: [
                    Container(
                      width: 53.s,
                      height: 53.s,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(
                            'assets/images/record-state/pet_plus_icon.webp',
                          ),
                          fit: BoxFit.contain,
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(height: 11.s),
                    Text(
                      '추가',
                      style: TextStyle(
                        fontFamily: AppFonts.family,
                        fontSize: 11.s,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xCC383838),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final children = <Widget>[
      ..._profiles.asMap().entries.map((e) {
        final isSelected = e.key == _selectedProfileIndex;
        final rawName = e.value.name.trim();
        final label = rawName.isEmpty
            ? '프로필 ${e.key + 1}'
            : (rawName.length <= 8 ? rawName : '${rawName.substring(0, 8)}...');
        return Padding(
          padding: EdgeInsets.only(right: 16.s),
          child: GestureDetector(
            onTap: () => _selectProfile(e.key),
            child: Column(
              children: [
                // 이중 링: 바깥 오렌지 → 안쪽 흰색 → 이미지
                Container(
                  width: 60.s,
                  height: 60.s,
                  decoration: isSelected
                      ? BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.main,
                            width: 1.67.s,
                          ),
                        )
                      : null,
                  child: Padding(
                    padding: EdgeInsets.all(isSelected ? 1.67.s : 3.34.s),
                    child: ClipOval(
                      child: _buildProfileImage(e.value.imageUrl),
                    ),
                  ),
                ),
                SizedBox(height: 6.s),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppFonts.family,
                    fontSize: 11.s,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF383838),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
      Padding(
        padding: EdgeInsets.only(top: 4.s),
        child: GestureDetector(
          onTap: () async {
            final result = await Navigator.of(context)
                .push<PetFamilySettingsResult>(
                  MaterialPageRoute<PetFamilySettingsResult>(
                    builder: (_) => PetFamilySettingsPage(
                      initialSelectedIndex: _selectedProfileIndex,
                      initialProfiles: _profiles,
                      startWithAddProfile: true,
                    ),
                  ),
                );
            if (!mounted) return;
            if (result != null && result.profiles.isNotEmpty) {
              final nextIndex =
                  result.selectedIndex >= 0 &&
                      result.selectedIndex < result.profiles.length
                  ? result.selectedIndex
                  : 0;
              setState(() {
                _profiles = List<PetProfile>.from(result.profiles);
                _selectedProfileIndex = nextIndex;
              });
              context.read<HomeBloc>().add(
                ProfilesUpdated(
                  profiles: List<PetProfile>.from(result.profiles),
                  selectedIndex: nextIndex,
                ),
              );
              return;
            }
            context.read<HomeBloc>().add(const RefreshHome());
          },
          child: Column(
            children: [
              Container(
                width: 53.s,
                height: 53.s,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(
                      'assets/images/record-state/pet_plus_icon.webp',
                    ),
                    fit: BoxFit.contain,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(height: 11.s),
              Text(
                '추가',
                style: TextStyle(
                  fontFamily: AppFonts.family,
                  fontSize: 11.s,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xCC383838),
                ),
              ),
            ],
          ),
        ),
      ),
    ];

    return SizedBox(
      height: 84.s,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.only(left: 15.s, right: 15.s),
        physics: const BouncingScrollPhysics(),
        children: children,
      ),
    );
  }

  Widget _buildProfileImage(String? imageUrl) {
    final raw = imageUrl?.trim();
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final cacheSize = (60.s * devicePixelRatio).round();
    if (raw != null && raw.isNotEmpty) {
      final localPath = _normalizeLocalPath(raw);
      if (localPath != null) {
        return Image.file(
          File(localPath),
          fit: BoxFit.cover,
          cacheWidth: cacheSize,
          cacheHeight: cacheSize,
          filterQuality: FilterQuality.low,
          errorBuilder: (_, __, ___) => Image.asset(
            'assets/icons/profile-placeholder.webp',
            fit: BoxFit.cover,
            filterQuality: FilterQuality.low,
          ),
        );
      }
      return CachedNetworkImage(
        imageUrl: raw,
        fit: BoxFit.cover,
        memCacheWidth: cacheSize,
        memCacheHeight: cacheSize,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        placeholder: (_, __) => Image.asset(
          'assets/icons/profile-placeholder.webp',
          fit: BoxFit.cover,
          filterQuality: FilterQuality.low,
        ),
        errorWidget: (_, __, ___) => Image.asset(
          'assets/icons/profile-placeholder.webp',
          fit: BoxFit.cover,
          filterQuality: FilterQuality.low,
        ),
      );
    }

    return Image.asset(
      'assets/icons/profile-placeholder.webp',
      fit: BoxFit.cover,
    );
  }

  String? _normalizeLocalPath(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return null;
    }
    if (value.startsWith('file://')) {
      return value.replaceFirst('file://', '');
    }
    if (value.startsWith('/')) {
      return value;
    }
    return null;
  }

  // ══════════════════════════════════════════════════════
  // 섹션 탭 (오렌지, 위쪽만 둥근 모서리)
  // Figma: 102×26, border-radius 13.52 14.16 0 0
  // ══════════════════════════════════════════════════════
  Widget _buildSectionTab(String text) {
    return Padding(
      padding: EdgeInsets.only(left: 15.s),
      child: Container(
        width: 102.s,
        height: 26.s,
        decoration: BoxDecoration(
          color: AppColors.main,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(13.52.s),
            topRight: Radius.circular(14.16.s),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            fontFamily: AppFonts.family,
            fontSize: 13.s,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.26.s,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // 캘린더
  // Figma: 363×315, white, borderRadius 12.64
  // ══════════════════════════════════════════════════════
  Widget _buildCalendar() {
    final days = _buildDays();
    const weekdays = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.64.s),
      ),
      padding: EdgeInsets.fromLTRB(14.s, 14.s, 21.s, 10.s),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 년/월 드롭다운 (왼쪽 정렬, 월 버튼 폭 넓혀 드롭다운과 겹침 방지)
          Align(
            alignment: Alignment.centerLeft,
            child: _StatusRecordMonthYearDropdown(
              month: _viewMonth.month,
              year: _viewMonth.year,
              onMonthChanged: (m) =>
                  _onViewMonthChanged(DateTime(_viewMonth.year, m)),
              onYearChanged: (y) =>
                  _onViewMonthChanged(DateTime(y, _viewMonth.month)),
            ),
          ),
          SizedBox(height: 12.s),
          // 요일 헤더 (Figma: 10.5px, w800, #FF9645)
          Row(
            children: weekdays
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: TextStyle(
                          fontFamily: AppFonts.family,
                          fontSize: 10.5.s,
                          fontWeight: FontWeight.w800,
                          color: AppColors.main,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          SizedBox(height: 10.s),
          // 날짜 그리드 (터치 영역만 확대 + 오늘 날짜 구분, 비율 유지)
          GridView.builder(
            shrinkWrap: true,
            primary: false,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 2.s,
              crossAxisSpacing: 0,
              mainAxisExtent: 46.s,
            ),
            itemCount: days.length,
            itemBuilder: (_, i) {
              final day = days[i];
              if (day == null) return const SizedBox.shrink();

              final now = DateTime.now();
              final isToday =
                  day.year == now.year &&
                  day.month == now.month &&
                  day.day == now.day;
              final hasRecord = _hasRecord(day);
              final isSelected =
                  day.year == _selectedDate.year &&
                  day.month == _selectedDate.month &&
                  day.day == _selectedDate.day;

              return GestureDetector(
                onTap: () {
                  unawaited(_handleCalendarDateTap(day));
                },
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: double.infinity,
                  height: 46.s,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        width: 35.54.s,
                        height: 35.54.s,
                        decoration: isSelected
                            ? BoxDecoration(
                                color: const Color(0x1AFF9645),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.main,
                                  width: 1.24.s,
                                ),
                              )
                            : isToday
                            ? BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFBDBDBD),
                                  width: 1.5.s,
                                ),
                              )
                            : null,
                        alignment: Alignment.center,
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            fontFamily: AppFonts.family,
                            fontSize: 12.923.s,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF383838),
                          ),
                        ),
                      ),
                      // 기록 있는 날: 토끼 마커 (추후 백엔드 연동)
                      if (hasRecord)
                        Transform.translate(
                          offset: Offset(0, -8.s),
                          child: Padding(
                            padding: EdgeInsets.only(top: 0.s),
                            child: Image.asset(
                              'assets/images/record-state/calendar-marker.webp',
                              width: 12.s,
                              height: 9.s,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // 오늘의 상태 카드 (Figma: 174×121 each, gap 15)
  // 과거 날짜 선택 시 식사 시간은 백엔드 mealTime/mealStatus로 식사 시간 카드 표시.
  // ══════════════════════════════════════════════════════
  Widget _buildStatusCards() {
    SizeConfig.init(context);
    final r = _displayRecord;
    final weightUnit = _normalizeWeightUnit(r?['weightUnit']) ?? 'g';
    final weightValue = _parseWeight(r?['weight'], unit: weightUnit);
    final weight = weightValue != null
        ? '${_formatWeightValue(weightValue)}$weightUnit'
        : '-';
    final weightChange = _computedWeightChange;
    final lastMeal = _toDisplayText(r?['lastMeal']) ?? '';
    final mealStatus = _toDisplayText(r?['mealStatus']) ?? '정상';
    final parsedTime = _parseMealTime(lastMeal);

    return Row(
      children: [
        Expanded(
          child: _StatusCard(
            label: '현재 체중',
            value: weight,
            valueFontSize: 22.s,
            badgeText: weightChange,
          ),
        ),
        SizedBox(width: 15.s),
        Expanded(
          child: parsedTime != null
              ? _MealTimeCard(
                  hour12: parsedTime.$1,
                  isAm: parsedTime.$2,
                  minute: parsedTime.$3,
                  mealStatus: mealStatus,
                )
              : _StatusCard(
                  label: '마지막 식사',
                  value: lastMeal.isNotEmpty ? lastMeal : '2시간 전',
                  valueFontSize: 20.s,
                  badgeText: mealStatus,
                ),
        ),
      ],
    );
  }

  /// "HH:mm" / "HH:mm:ss" 형식이면 (12h, isAm, minute) 반환. 아니면 null.
  static (int, bool, int)? _parseMealTime(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.trim().split(RegExp(r'[:\s]+'));
    if (parts.length < 2) return null;
    final hour24 = int.tryParse(parts[0].trim());
    final minute = int.tryParse(parts[1].trim());
    if (hour24 == null ||
        minute == null ||
        hour24 < 0 ||
        hour24 > 23 ||
        minute < 0 ||
        minute > 59)
      return null;
    final isAm = hour24 < 12;
    final hour12 = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24);
    return (hour12, isAm, minute);
  }

  // ══════════════════════════════════════════════════════
  // 배변 상태 (Figma: 363×99, Union 토끼 아이콘 사용)
  // ══════════════════════════════════════════════════════
  Widget _buildPoopSection() {
    final displayRecord = _displayRecord;
    return Container(
      width: double.infinity,
      height: 99.s,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.6434.s),
      ),
      padding: EdgeInsets.fromLTRB(17.s, 18.s, 17.s, 17.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '배변 상태',
            style: TextStyle(
              fontFamily: AppFonts.family,
              fontSize: 12.s,
              fontWeight: FontWeight.w800,
              height: 15 / 12,
              color: const Color(0xFF383838),
            ),
          ),
          SizedBox(height: 7.s),
          // Figma: 329×38, bg rgba(255,150,69,0.1), border 1.24 #FF9645, radius 9
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0x1AFF9645),
                border: Border.all(color: AppColors.main, width: 1.24.s),
                borderRadius: BorderRadius.circular(9.s),
              ),
              padding: EdgeInsets.symmetric(horizontal: 13.s),
              child: Row(
                children: [
                  Text(
                    _toDisplayText(displayRecord?['poopStatus']) ?? '정상',
                    style: TextStyle(
                      fontFamily: AppFonts.family,
                      fontSize: 15.s,
                      fontWeight: FontWeight.w800,
                      color: AppColors.main,
                    ),
                  ),
                  const Spacer(),
                  // Union.png 토끼 아이콘 (Figma: 19.01×16)
                  Image.asset(
                    'assets/images/record-state/calendar-marker.webp',
                    width: 19.01.s,
                    height: 16.s,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceMemoSection() {
    final memo = _toDisplayText(_displayRecord?['appearanceMemo']) ?? '';
    if (memo.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.6434.s),
      ),
      padding: EdgeInsets.fromLTRB(17.s, 14.s, 17.s, 14.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '외관 메모',
            style: TextStyle(
              fontFamily: AppFonts.family,
              fontSize: 12.s,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF383838),
            ),
          ),
          SizedBox(height: 7.s),
          Text(
            memo,
            style: TextStyle(
              fontFamily: AppFonts.family,
              fontSize: 12.s,
              fontWeight: FontWeight.w600,
              color: const Color(0xCC383838),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // 사진 (카드 최대 높이 271.s). 원본 비율 유지(BoxFit.contain), 여백은 흰 배경.
  // 선택한 날짜에 저장된 사진이 없을 때만 플레이스홀더 표시.
  // ══════════════════════════════════════════════════════
  Widget _buildPhotoSection() {
    final resolvedPhotoUrl =
        (_toDisplayText(_displayRecord?['photoPath']) ?? '').trim();
    final hasPhoto = resolvedPhotoUrl.isNotEmpty;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final screenW = MediaQuery.sizeOf(context).width;
    final memCacheWidth = (screenW * dpr).round();

    return Container(
      width: double.infinity,
      height: 271.s,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.6434.s),
      ),
      child: hasPhoto
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12.6434.s),
              child: CachedNetworkImage(
                imageUrl: resolvedPhotoUrl,
                fit: BoxFit.contain,
                alignment: Alignment.center,
                width: double.infinity,
                height: double.infinity,
                memCacheWidth: memCacheWidth,
                fadeInDuration: Duration.zero,
                fadeOutDuration: Duration.zero,
                placeholder: (_, __) => _buildPhotoPlaceholder(),
                errorWidget: (_, __, ___) => _buildPhotoPlaceholder(),
              ),
            )
          : _buildPhotoPlaceholder(),
    );
  }

  Widget _buildPhotoPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_outlined, size: 42.s, color: AppColors.fontMuted),
          SizedBox(height: 4.s),
          Text(
            '기록된 사진이 없어요',
            style: TextStyle(
              fontFamily: AppFonts.family,
              fontSize: 11.s,
              fontWeight: FontWeight.w700,
              height: 20 / 11,
              letterSpacing: -0.15,
              color: const Color(0x80383838),
            ),
          ),
        ],
      ),
    );
  }

  bool get _shouldShowNoRecordState {
    if (_isSelectedDateBriefLoading && _loadingFallbackRecord != null) {
      return false;
    }
    final selected = _displayRecord;
    if (selected == null) return true;
    return !_hasMeaningfulFields(selected);
  }

  bool _hasMeaningfulFields(Map<String, dynamic> record) {
    bool hasText(dynamic value) => _toDisplayText(value) != null;
    final normalizedWeight = _parseWeight(
      record['weight'],
      unit: _normalizeWeightUnit(record['weightUnit']),
    );
    return normalizedWeight != null ||
        _toDisplayText(record['weightChange']) != null ||
        hasText(record['lastMeal']) ||
        hasText(record['mealStatus']) ||
        hasText(record['poopStatus']) ||
        hasText(record['appearanceMemo']) ||
        hasText(record['photoPath']);
  }

  Widget _buildNoRecordSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 36.s),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/icons/ character.webp',
            width: 118.s,
            height: 118.s,
            fit: BoxFit.contain,
          ),
          SizedBox(height: 12.s),
          Text(
            '아직 기록이 없어요',
            style: TextStyle(
              fontFamily: AppFonts.family,
              fontSize: 14.s,
              fontWeight: FontWeight.w700,
              color: const Color(0x80383838),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // 하단 버튼 (Figma: 363×35, border 1.24 #FF9645, radius 18.2)
  // ══════════════════════════════════════════════════════
  Widget _buildBottomButton() {
    final hasRealProfiles = _profiles.any(
      (p) => p.petId != null || p.name.trim().isNotEmpty,
    );

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(15.s, 8.s, 15.s, 12.s),
        child: SizedBox(
          width: double.infinity,
          height: 35.s,
          child: OutlinedButton(
            onPressed: hasRealProfiles
                ? () async {
                    final selectedPetId = _selectedPetId;
                    final selectedDate = DateTime(
                      _selectedDate.year,
                      _selectedDate.month,
                      _selectedDate.day,
                    );
                    final hasExistingRecord =
                        selectedPetId != null && _hasRecord(selectedDate);
                    Map<String, dynamic>? initialFullRecord;

                    if (hasExistingRecord) {
                      final dateKey = _dateKey(selectedDate);
                      try {
                        initialFullRecord = await _requestPetStateRecordDetail(
                          petId: selectedPetId,
                          date: dateKey,
                          view: 'full',
                        );
                        AppLogger.info(
                          '[StatusRecordPage] full detail prefetch loaded '
                          'petId=$selectedPetId date=$dateKey '
                          'exists=${initialFullRecord != null}',
                        );
                      } catch (e) {
                        AppLogger.info(
                          '[StatusRecordPage] full detail prefetch failed '
                          'petId=$selectedPetId date=$dateKey error=$e',
                        );
                      }
                    }

                    if (!mounted) return;
                    final result = await Navigator.of(context).push<Object?>(
                      MaterialPageRoute<Object?>(
                        builder: (_) => TodayStatusRecordPage(
                          user: widget.user,
                          selectedPetId: selectedPetId,
                          selectedDate: selectedDate,
                          initialRecord: initialFullRecord,
                          hasExistingRecord: hasExistingRecord,
                        ),
                      ),
                    );
                    if (!mounted) return;
                    if (selectedPetId != null && result is String) {
                      final parsed = _parseFlexibleDateKey(result);
                      if (parsed != null) {
                        _rememberLocalSavedDate(
                          petId: selectedPetId,
                          dateKey: _dateKey(parsed),
                        );
                      }
                    }
                    unawaited(
                      _loadStatusRecordsForViewMonth(
                        petIdOverride: selectedPetId,
                      ),
                    );
                    unawaited(
                      _loadBriefDetailForSelectedDate(
                        petIdOverride: selectedPetId,
                        dateOverride: selectedDate,
                      ),
                    );
                  }
                : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: hasRealProfiles
                  ? AppColors.main
                  : const Color(0xFFCBCBCB),
              side: BorderSide(
                color: hasRealProfiles
                    ? AppColors.main
                    : const Color(0xFFCBCBCB),
                width: 1.24.s,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18.2.s),
              ),
              padding: EdgeInsets.zero,
            ),
            child: Text(
              hasRealProfiles ? '오늘의 상태 기록하기' : '반려동물을 설정해주세요',
              style: TextStyle(
                fontFamily: AppFonts.family,
                fontSize: 14.s,
                fontWeight: FontWeight.w800,
                color: hasRealProfiles
                    ? AppColors.main
                    : const Color(0xFFCBCBCB),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// 식사 시간 카드 (과거 날짜 선택 시, 백엔드 mealTime/mealStatus 표시)
// Figma: 174×121, white, radius 12.6434
// ══════════════════════════════════════════════════════
class _MealTimeCard extends StatelessWidget {
  final int hour12;
  final bool isAm;
  final int minute;
  final String mealStatus;

  const _MealTimeCard({
    required this.hour12,
    required this.isAm,
    required this.minute,
    required this.mealStatus,
  });

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final radius = 8.47.s;
    final borderW = 0.89.s;
    final leftWidth = 53.s;
    final period = isAm ? 'AM' : 'PM';
    final timeStr =
        '${hour12.toString().padLeft(2, '0')} : ${minute.toString().padLeft(2, '0')}';

    return Container(
      height: 121.s,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.6434.s),
      ),
      padding: EdgeInsets.fromLTRB(17.s, 14.s, 17.s, 14.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '식사 시간',
            style: TextStyle(
              fontFamily: AppFonts.family,
              fontSize: 12.s,
              fontWeight: FontWeight.w800,
              height: 15 / 12,
              color: const Color(0xFF383838),
            ),
          ),
          SizedBox(height: 10.s),
          // 시간 표시: 왼쪽 AM/PM (주황 배경), 오른쪽 "11 : 55" (주황 글자)
          Container(
            height: 34.s,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.main, width: borderW),
              borderRadius: BorderRadius.circular(radius),
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              children: [
                Container(
                  width: leftWidth,
                  height: 34.s,
                  decoration: BoxDecoration(
                    color: AppColors.main,
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(radius - borderW),
                      right: Radius.zero,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    period,
                    style: TextStyle(
                      fontFamily: AppFonts.family,
                      fontSize: 10.88.s,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      timeStr,
                      style: TextStyle(
                        fontFamily: AppFonts.family,
                        fontSize: 13.6.s,
                        fontWeight: FontWeight.w800,
                        height: 15 / 13.6,
                        color: AppColors.main,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10.s),
          // 식사 상태 배지 (잘 먹음 / 조금 먹음 / 안 먹음)
          Container(
            width: double.infinity,
            height: 22.s,
            decoration: BoxDecoration(
              color: const Color(0x1AFF9645),
              border: Border.all(color: AppColors.main, width: 1.24.s),
              borderRadius: BorderRadius.circular(6.s),
            ),
            alignment: Alignment.center,
            child: Text(
              mealStatus,
              style: TextStyle(
                fontFamily: AppFonts.family,
                fontSize: 12.s,
                fontWeight: FontWeight.w800,
                height: 15 / 12,
                color: AppColors.main,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// 상태 카드 위젯 (Figma: 174×121, white, radius 12.6434)
// ══════════════════════════════════════════════════════
class _StatusCard extends StatelessWidget {
  final String label;
  final String value;
  final double valueFontSize;
  final String badgeText;

  const _StatusCard({
    required this.label,
    required this.value,
    required this.valueFontSize,
    required this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return Container(
      height: 121.s,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.6434.s),
      ),
      padding: EdgeInsets.only(left: 17.s, right: 17.s, bottom: 14.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Figma: font-size 12, w800, #383838
          Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.family,
              fontSize: 12.s,
              fontWeight: FontWeight.w800,
              height: 15 / 12,
              color: const Color(0xFF383838),
            ),
          ),
          SizedBox(height: 3.s),
          // Figma: 현재체중 22px / 마지막식사 20px, w800
          Text(
            value,
            style: TextStyle(
              fontFamily: AppFonts.family,
              fontSize: valueFontSize,
              fontWeight: FontWeight.w800,
              height: 1.18,
              color: const Color(0xFF383838),
            ),
          ),
          SizedBox(height: 9.s),
          // Figma: 140×22, bg rgba(255,150,69,0.1), border 1.24 #FF9645, radius 6
          Container(
            width: double.infinity,
            height: 22.s,
            decoration: BoxDecoration(
              color: const Color(0x1AFF9645),
              border: Border.all(color: AppColors.main, width: 1.24.s),
              borderRadius: BorderRadius.circular(6.s),
            ),
            alignment: Alignment.center,
            child: Text(
              badgeText,
              style: TextStyle(
                fontFamily: AppFonts.family,
                fontSize: 12.s,
                fontWeight: FontWeight.w800,
                height: 15 / 12,
                color: AppColors.main,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 상태기록 전용 연·월 드롭다운 (calendar-picker와 동일 동작, 여백 등 자유 조정) ───

class _StatusRecordMonthYearDropdown extends StatelessWidget {
  final int month;
  final int year;
  final ValueChanged<int> onMonthChanged;
  final ValueChanged<int> onYearChanged;

  static const int _minYear = 2000;
  static const int _maxYear = 2030;

  const _StatusRecordMonthYearDropdown({
    required this.month,
    required this.year,
    required this.onMonthChanged,
    required this.onYearChanged,
  });

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StatusRecordHeaderDropdown<int>(
          value: year,
          items: List.generate(_maxYear - _minYear + 1, (i) => _minYear + i),
          labelBuilder: (v) => '${v}년',
          onChanged: (v) {
            if (v != null) onYearChanged(v);
          },
          backgroundColor: AppColors.main,
          width: 76.s,
          buttonHeight: 28.s,
          borderRadius: 6.s,
          fontSize: 10.63.s,
          iconSize: 14.s,
          textOverflow: TextOverflow.visible,
        ),
        SizedBox(width: 6.s),
        _StatusRecordHeaderDropdown<int>(
          value: month,
          items: List.generate(12, (i) => i + 1),
          labelBuilder: (v) => '$v월',
          onChanged: (v) {
            if (v != null) onMonthChanged(v);
          },
          backgroundColor: AppColors.main,
          width: 56.s,
          buttonHeight: 28.s,
          borderRadius: 6.s,
          fontSize: 10.63.s,
          iconSize: 14.s,
          textOverflow: TextOverflow.visible,
        ),
      ],
    );
  }
}

class _StatusRecordHeaderDropdown<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final String Function(T) labelBuilder;
  final ValueChanged<T?> onChanged;
  final Color backgroundColor;
  final double width;
  final double? buttonHeight;
  final double? borderRadius;
  final double? fontSize;
  final double? iconSize;
  final TextOverflow? textOverflow;

  const _StatusRecordHeaderDropdown({
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
    required this.backgroundColor,
    required this.width,
    this.buttonHeight,
    this.borderRadius,
    this.fontSize,
    this.iconSize,
    this.textOverflow,
  });

  static const Color _menuBorderColor = Color(0xFF383838);
  static final Color _dividerColor = Color.fromRGBO(56, 56, 56, 0.10);

  Future<void> _openMenu(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    SizeConfig.init(context);
    final overlayState = Overlay.of(context);
    final overlay = overlayState.context.findRenderObject() as RenderBox;
    final pos = box.localToGlobal(Offset.zero, ancestor: overlay);
    final size = box.size;
    final menuW = width;
    final left = pos.dx + (size.width - menuW) / 2;
    final top = pos.dy + size.height;

    final completer = Completer<T?>();
    late OverlayEntry entry;

    void close(T? value) {
      if (!completer.isCompleted) {
        entry.remove();
        completer.complete(value);
      }
    }

    entry = OverlayEntry(
      builder: (ctx) => _StatusRecordDropdownOverlay<T>(
        left: left,
        top: top,
        menuWidth: menuW,
        items: items,
        labelBuilder: labelBuilder,
        dividerColor: _dividerColor,
        menuBorderColor: _menuBorderColor,
        onSelect: close,
      ),
    );
    overlayState.insert(entry);

    final selected = await completer.future;
    if (selected != null) onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final height = buttonHeight ?? 36.s;
    final radius = borderRadius ?? 5.s;
    final fs = fontSize ?? 13.s;
    final icon = iconSize ?? 17.s;
    return SizedBox(
      width: width,
      height: height,
      child: GestureDetector(
        onTap: () => _openMenu(context),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.s, vertical: 4.s),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(radius),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  labelBuilder(value),
                  style: TextStyle(
                    fontFamily: AppFonts.family,
                    fontSize: fs,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  overflow: textOverflow ?? TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 2.s),
              Icon(Icons.keyboard_arrow_down, size: icon, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusRecordDropdownOverlay<T> extends StatefulWidget {
  final double left;
  final double top;
  final double menuWidth;
  final List<T> items;
  final String Function(T) labelBuilder;
  final Color dividerColor;
  final Color menuBorderColor;
  final void Function(T?) onSelect;

  const _StatusRecordDropdownOverlay({
    required this.left,
    required this.top,
    required this.menuWidth,
    required this.items,
    required this.labelBuilder,
    required this.dividerColor,
    required this.menuBorderColor,
    required this.onSelect,
  });

  @override
  State<_StatusRecordDropdownOverlay<T>> createState() =>
      _StatusRecordDropdownOverlayState<T>();
}

class _StatusRecordDropdownOverlayState<T>
    extends State<_StatusRecordDropdownOverlay<T>>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildMenuContent() {
    return Material(
      color: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5.s),
        side: BorderSide(color: widget.menuBorderColor, width: 1.143.s),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: widget.menuWidth,
          maxHeight: 280.s,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          children: [
            for (var i = 0; i < widget.items.length; i++) ...[
              if (i > 0)
                Center(
                  child: Container(
                    width: 43.s,
                    height: 0.5.s,
                    color: widget.dividerColor,
                  ),
                ),
              InkWell(
                onTap: () => widget.onSelect(widget.items[i]),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.s,
                    vertical: 10.s,
                  ),
                  child: Center(
                    child: Text(
                      widget.labelBuilder(widget.items[i]),
                      style: TextStyle(
                        fontFamily: AppFonts.family,
                        fontSize: 13.s,
                        fontWeight: FontWeight.w700,
                        color: AppColors.font,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => widget.onSelect(null),
          ),
        ),
        Positioned(
          left: widget.left,
          top: widget.top,
          child: SizeTransition(
            sizeFactor: _animation,
            axisAlignment: -1,
            child: _buildMenuContent(),
          ),
        ),
      ],
    );
  }
}
