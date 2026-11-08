/// 병원 찾기 화면(UI) 파일입니다.
///
/// - 역할: 가까운 병원 목록 표시, 진료여부 필터, 전국 병원 찾기 링크
/// - Chip: common-chip.dart 공통 컴포넌트 사용
/// - 상태관리: HospitalBloc

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:udon/core/theme/app-theme.dart';
import 'package:udon/core/utils/app-size.dart';
import 'package:udon/core/widgets/common-app-bar.dart';
import 'package:udon/core/widgets/open-my-page-from-app-bar.dart';
import 'package:udon/features/hospital/bloc/hospital-bloc.dart';
import 'package:udon/features/hospital/bloc/hospital-event.dart';
import 'package:udon/features/hospital/bloc/hospital-state.dart';
import 'package:udon/features/hospital/models/hospital.dart';
import 'package:udon/features/hospital/repository/hospital-repository.dart';
import 'package:udon/pages/hospital/widgets/hospital-card.dart';
import 'package:udon/pages/hospital/hospital-detail-page.dart';
import 'package:udon/pages/hospital/hospital-location-page.dart';

class HospitalFindPage extends StatelessWidget {
  const HospitalFindPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HospitalBloc>(
      create: (context) =>
          HospitalBloc(context.read<HospitalRepository>())
            ..add(const HospitalLoadRequested()),
      child: const _HospitalFindView(),
    );
  }
}

class _HospitalFindView extends StatelessWidget {
  const _HospitalFindView();

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return BlocBuilder<HospitalBloc, HospitalState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: CommonAppBar(
            showBackButton: true,
            // 알림 (비활성화)
            onNotificationPressed: null,
            onMyPagePressed: () => openMyPageFromAppBar(context),
          ),
          body: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : (state.errorMessage != null && state.allHospitals.isEmpty)
              ? _buildLoadError(context)
              : CustomScrollView(
                  slivers: [
                    const SliverToBoxAdapter(child: SizedBox(height: 2)),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      sliver: SliverToBoxAdapter(
                        child: _buildFilterSection(
                          context,
                          isOn: state.isOpenOnly,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 5)),
                    SliverPadding(
                      padding: const EdgeInsets.only(left: 13.8, right: 20),
                      sliver: SliverToBoxAdapter(
                        child: _buildAllHospitalsLink(
                          context,
                          state.allHospitals,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 14)),
                    _buildHospitalListSliver(state.filteredHospitals),
                    const SliverToBoxAdapter(child: SizedBox(height: 35)),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildLoadError(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '병원 정보를 불러오지 못했어요.',
              style: TextStyle(
                fontFamily: AppFonts.family,
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppColors.font,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '잠시 후 다시 시도해주세요.',
              style: TextStyle(
                fontFamily: AppFonts.family,
                fontWeight: FontWeight.w400,
                fontSize: 13,
                color: AppColors.fontLight,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                context.read<HospitalBloc>().add(const HospitalLoadRequested());
              },
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(BuildContext context, {required bool isOn}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ 왼쪽은 남는 공간만큼만 차지 (오버플로우 방지)
        Expanded(
          child: Text.rich(
            TextSpan(
              children: const [
                TextSpan(
                  text: '보호자님',
                  style: TextStyle(
                    fontFamily: AppFonts.family,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    height: 25.2869 / 15.8043,
                    color: AppColors.main,
                  ),
                ),
                TextSpan(
                  text: '에게 가까운 거리의 병원 순으로 측정되었습니다.',
                  style: TextStyle(
                    fontFamily: AppFonts.family,
                    fontWeight: FontWeight.w700,
                    fontSize: 15.8043,
                    height: 25.2869 / 15.8043,
                    color: AppColors.font,
                  ),
                ),
              ],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // ✅ 피그마에서 텍스트와 오른쪽 영역 사이 간격 (예: 33.29)
        const SizedBox(width: 30.29),

        // ✅ 오른쪽 영역은 고정폭 (divider 길이 기준)
        SizedBox(
          width: 129.99,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildTreatmentFilterToggle(context, isOn: isOn),
              const SizedBox(height: 6),
              Container(
                width: 110,
                height: 4.2,
                decoration: BoxDecoration(
                  color: AppColors.font,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTreatmentFilterToggle(
    BuildContext context, {
    required bool isOn,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 핀포인트 아이콘 (19x23)
            Image.asset(
              isOn
                  ? 'assets/images/hospital/hospital-icon-on.webp'
                  : 'assets/images/hospital/hospital-icon-off.webp',
              width: 19,
              height: 23,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 4),
            // 진료여부 텍스트 (11.39pt, weight 800)
            const Text(
              '진료여부',
              style: TextStyle(
                fontFamily: AppFonts.family,
                fontWeight: FontWeight.w800,
                fontSize: 11.39,
                height: 1.0,
                color: AppColors.font,
              ),
            ),
            const SizedBox(width: 2),
            // 토글 스위치 (42x18, border 1px, radius 17.56)
            GestureDetector(
              onTap: () {
                context.read<HospitalBloc>().add(
                  const HospitalOpenFilterToggled(),
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 38,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(
                    color: isOn ? AppColors.main : AppColors.font,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(17.56),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // on/off 텍스트
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      left: isOn ? 4 : null,
                      right: isOn ? null : 4,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Text(
                          isOn ? 'on' : 'off',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 11.39,
                            height: 1.0,
                            color: isOn ? AppColors.main : AppColors.font,
                          ),
                        ),
                      ),
                    ),
                    // 원형 인디케이터 (12x12)
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      left: isOn ? 21 : 2,
                      top: 2,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isOn ? AppColors.main : AppColors.font,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _openNationwideMap(BuildContext context, List<Hospital> hospitals) {
    if (hospitals.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('병원 데이터를 불러오는 데 실패했습니다.')));
      return;
    }

    final mapItems = hospitals
        .where(
          (hospital) =>
              hospital.clinicId != null &&
              hospital.latitude != null &&
              hospital.longitude != null,
        )
        .map(
          (hospital) => HospitalMapItem(
            clinicId: hospital.clinicId!,
            latitude: hospital.latitude!,
            longitude: hospital.longitude!,
            hospital: hospital,
          ),
        )
        .toList();

    if (mapItems.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('지도에 표시할 병원 좌표가 없습니다.')));
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HospitalLocationPage(mapItems: mapItems),
      ),
    );
  }

  Widget _buildAllHospitalsLink(
    BuildContext context,
    List<Hospital> allHospitals,
  ) {
    return GestureDetector(
      onTap: () => _openNationwideMap(context, allHospitals),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '전국 병원 찾기',
            style: TextStyle(
              fontFamily: AppFonts.family,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: -0.22,
            ),
          ),
          const SizedBox(width: 2),
          Icon(
            Icons.arrow_forward_ios,
            size: 12,
            color: AppColors.font.withValues(alpha: 0.9),
          ),
        ],
      ),
    );
  }

  Widget _buildHospitalListSliver(List<Hospital> hospitals) {
    if (hospitals.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: Text(
              '병원 정보가 없습니다.',
              style: TextStyle(
                fontFamily: AppFonts.family,
                fontSize: 14,
                color: AppColors.fontLight,
              ),
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 13.8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index.isOdd) {
            return const SizedBox(height: 14);
          }
          final hospital = hospitals[index ~/ 2];
          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => HospitalDetailPage(hospital: hospital),
                ),
              );
            },
            child: HospitalCard(hospital: hospital),
          );
        }, childCount: hospitals.length * 2 - 1),
      ),
    );
  }
}
