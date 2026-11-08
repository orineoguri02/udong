/// 병원 위치(찾아가기) 페이지
///
/// - 역할: 병원 목록을 카카오 지도에 마커로 표시하는 화면
/// - 진료중(is_open=true): hospital-location-icon.png (오렌지)
/// - 휴진(is_open=false): hospital-location-close.png (회색)
/// - 마커 탭 → 바텀시트에 병원명 표시
/// - 내 위치 파란 점 표시

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'dart:math' as math;

import 'package:udon/core/theme/app-theme.dart';
import 'package:udon/core/utils/app-size.dart';
import 'package:udon/core/widgets/common-app-bar.dart';
import 'package:udon/core/widgets/open-my-page-from-app-bar.dart';
import 'package:udon/features/hospital/models/hospital.dart';
import 'package:udon/pages/hospital/hospital-detail-bottom-sheet.dart';

class HospitalMapItem {
  final int clinicId;
  final double latitude;
  final double longitude;
  final Hospital hospital;

  const HospitalMapItem({
    required this.clinicId,
    required this.latitude,
    required this.longitude,
    required this.hospital,
  });
}

class HospitalLocationPage extends StatefulWidget {
  final List<HospitalMapItem> mapItems;

  const HospitalLocationPage({super.key, required this.mapItems});

  @override
  State<HospitalLocationPage> createState() => _HospitalLocationPageState();
}

class _HospitalLocationPageState extends State<HospitalLocationPage> {
  KakaoMapController? _mapController;
  LatLng? _currentLocation;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isMapCreated = false;

  static MarkerIcon? _cachedOpenIcon;
  static MarkerIcon? _cachedCloseIcon;

  MarkerIcon? _openIcon;
  MarkerIcon? _closeIcon;
  List<Marker> _markers = [];
  final Map<String, HospitalMapItem> _markerItemById =
      <String, HospitalMapItem>{};

  bool _isBottomSheetOpen = false;

  static const double _defaultLat = 37.5665;
  static const double _defaultLng = 126.9780;
  static const double _radiusMeters = 5000; // 5km
  static const double _earthRadiusMeters = 6371000;

  /// 지도 중심: 첫 번째 병원 좌표 우선, 없으면 현재 위치
  LatLng get _mapCenter {
    if (widget.mapItems.isNotEmpty) {
      final first = widget.mapItems.first;
      return LatLng(first.latitude, first.longitude);
    }
    return _currentLocation ?? LatLng(_defaultLat, _defaultLng);
  }

  /// 내 위치 파란 점 CustomOverlay
  List<CustomOverlay> get _locationOverlays {
    if (_currentLocation == null) return [];
    return [
      CustomOverlay(
        customOverlayId: 'current_location',
        latLng: _currentLocation!,
        content:
            '<div style="width:14px;height:14px;background:#4285F4;border-radius:50%;'
            'border:3px solid white;box-shadow:0 2px 6px rgba(0,0,0,0.4);"></div>',
        xAnchor: 0.5,
        yAnchor: 0.5,
        zIndex: 10,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _loadMarkerIcons();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _fetchCurrentLocation();
    });
  }

  /// 아이콘 준비 즉시 지도 렌더링 시작 (위치 조회 완료를 기다리지 않음)
  void _onIconsReady() {
    _buildMarkers();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadMarkerIcons() async {
    if (_cachedOpenIcon != null || _cachedCloseIcon != null) {
      _openIcon = _cachedOpenIcon;
      _closeIcon = _cachedCloseIcon;
      _onIconsReady();
      return;
    }

    try {
      _openIcon = await MarkerIcon.fromAsset(
        'assets/images/hospital/hospital-location-icon.webp',
      );
      _closeIcon = await MarkerIcon.fromAsset(
        'assets/images/hospital/hospital-location-close.webp',
      );
      _cachedOpenIcon = _openIcon;
      _cachedCloseIcon = _closeIcon;
    } catch (_) {
      // 아이콘 로드 실패 시 기본 마커 사용
    }
    _onIconsReady();
  }

  void _buildMarkers() {
    // 원본 비율 유지: open(208x286) → 36x50 / close(208x324) → 32x50
    final markerItemById = <String, HospitalMapItem>{};
    _markers = widget.mapItems.asMap().entries.map((entry) {
      final i = entry.key;
      final item = entry.value;
      final h = item.hospital;
      final markerId = 'hospital_marker_${item.clinicId}_$i';
      markerItemById[markerId] = item;
      return Marker(
        markerId: markerId,
        latLng: LatLng(item.latitude, item.longitude),
        icon: h.isOpen ? _openIcon : _closeIcon,
        width: h.isOpen ? 36 : 32,
        height: 50,
      );
    }).toList();
    _markerItemById
      ..clear()
      ..addAll(markerItemById);
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      LocationPermission resolved = permission;

      if (permission == LocationPermission.denied) {
        resolved = await Geolocator.requestPermission();
      }

      if (resolved == LocationPermission.deniedForever) {
        if (!mounted) return;
        _applyLocationResult(
          location: LatLng(_defaultLat, _defaultLng),
          errorMessage: '위치 권한이 거부되었습니다. 설정에서 허용해 주세요.',
        );
        return;
      }

      if (resolved == LocationPermission.denied) {
        if (!mounted) return;
        _applyLocationResult(
          location: LatLng(_defaultLat, _defaultLng),
          errorMessage: '위치 권한이 필요합니다.',
        );
        return;
      }

      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null && mounted) {
        _applyLocationResult(
          location: LatLng(lastKnown.latitude, lastKnown.longitude),
          errorMessage: null,
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 4),
        ),
      );
      if (!mounted) return;
      _applyLocationResult(
        location: LatLng(position.latitude, position.longitude),
        errorMessage: null,
      );
    } catch (_) {
      if (!mounted) return;
      _applyLocationResult(
        location: LatLng(_defaultLat, _defaultLng),
        errorMessage: '위치를 가져오는 데 실패했습니다.',
      );
    }
  }

  void _applyLocationResult({
    required LatLng location,
    required String? errorMessage,
  }) {
    _currentLocation = location;
    _errorMessage = errorMessage;
    if (!mounted) return;

    // WebView/JS 초기화 이전에는 setState로 didUpdateWidget을 유발하지 않는다.
    if (!_isMapCreated) return;
    setState(() {});
  }

  void _onMarkerTap(String markerId, LatLng latLng, int zoomLevel) {
    if (_isBottomSheetOpen) return;
    final item = _markerItemById[markerId];
    if (item == null) return;
    _showHospitalBottomSheet(item.hospital);
  }

  void _showHospitalBottomSheet(Hospital hospital) {
    if (_isBottomSheetOpen) return;
    _isBottomSheetOpen = true;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.s)),
      ),
      builder: (ctx) => HospitalDetailBottomSheet(hospital: hospital),
    ).whenComplete(() => _isBottomSheetOpen = false);
  }

  Future<void> _moveToCurrentLocation() async {
    if (_currentLocation == null || _mapController == null) return;

    final bounds = _buildRadiusBounds(
      _currentLocation!,
      radiusMeters: _radiusMeters,
    );
    try {
      await _mapController!.fitBounds(bounds);
    } catch (_) {
      _mapController!.panTo(_currentLocation!);
    }
  }

  List<LatLng> _buildRadiusBounds(
    LatLng center, {
    required double radiusMeters,
  }) {
    final latRad = center.latitude * math.pi / 180.0;
    final latDelta = (radiusMeters / _earthRadiusMeters) * (180.0 / math.pi);
    final cosLat = math.cos(latRad).abs();
    final safeCosLat = cosLat < 1e-6 ? 1e-6 : cosLat;
    final lngDelta =
        (radiusMeters / (_earthRadiusMeters * safeCosLat)) * (180.0 / math.pi);

    return <LatLng>[
      LatLng(center.latitude - latDelta, center.longitude - lngDelta),
      LatLng(center.latitude + latDelta, center.longitude + lngDelta),
    ];
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: CommonAppBar(
        showBackButton: true,
        onMyPagePressed: () => openMyPageFromAppBar(context),
      ),
      body: Stack(
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (kIsWeb)
            // kakao_map_plugin은 WebView 기반이라 웹에서는 지도를 그릴 수 없다.
            const Center(child: Text('지도는 앱에서 확인할 수 있어요.'))
          else
            KakaoMap(
              onMapCreated: (controller) {
                _mapController = controller;
                if (!mounted) return;
                setState(() {
                  _isMapCreated = true;
                });
              },
              center: _mapCenter,
              currentLevel: 7,
              markers: _markers,
              customOverlays: _locationOverlays,
              onMarkerTap: _onMarkerTap,
            ),

          // 내 위치 정렬 버튼
          if (!_isLoading)
            Positioned(
              right: 16.s,
              bottom: _errorMessage != null ? 60.s : 24.s,
              child: GestureDetector(
                onTap: _moveToCurrentLocation,
                child: Container(
                  width: 44.s,
                  height: 44.s,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8.s,
                        offset: Offset(0, 2.s),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.my_location,
                    size: 22.s,
                    color: AppColors.main,
                  ),
                ),
              ),
            ),

          if (_errorMessage != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildErrorBanner(),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      color: AppColors.font.withValues(alpha: 0.8),
      padding: EdgeInsets.symmetric(horizontal: 20.s, vertical: 12.s),
      child: Row(
        children: [
          Icon(Icons.location_off, color: Colors.white, size: 18.s),
          SizedBox(width: 8.s),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13.s,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          GestureDetector(
            onTap: Geolocator.openAppSettings,
            child: Text(
              '설정 열기',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13.s,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
                decorationColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
