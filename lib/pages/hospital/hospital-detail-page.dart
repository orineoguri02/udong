/// 병원 상세 페이지
///
/// - 역할: 병원 상세 조회 + 병원 소개/찾아가기 탭 표시
/// - 상세 조회는 HospitalDetailBloc(Flux) 경유

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:udon/core/widgets/common-app-bar.dart';
import 'package:udon/core/widgets/open-my-page-from-app-bar.dart';
import 'package:udon/features/hospital/bloc/hospital-detail-bloc.dart';
import 'package:udon/features/hospital/bloc/hospital-detail-event.dart';
import 'package:udon/features/hospital/bloc/hospital-detail-state.dart';
import 'package:udon/features/hospital/models/hospital.dart';
import 'package:udon/features/hospital/repository/hospital-repository.dart';
import 'package:udon/pages/hospital/widgets/hospital-detail-content.dart';

class HospitalDetailPage extends StatelessWidget {
  const HospitalDetailPage({super.key, required this.hospital});

  final Hospital hospital;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HospitalDetailBloc>(
      create: (context) => HospitalDetailBloc(
        repository: context.read<HospitalRepository>(),
        initialState: HospitalDetailState(hospital: hospital),
      )..add(const HospitalDetailLoadRequested()),
      child: const _HospitalDetailView(),
    );
  }
}

class _HospitalDetailView extends StatelessWidget {
  const _HospitalDetailView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonAppBar(
        showBackButton: true,
        backgroundColor: Colors.white,
        onNotificationPressed: null,
        onMyPagePressed: () => openMyPageFromAppBar(context),
      ),
      body: BlocBuilder<HospitalDetailBloc, HospitalDetailState>(
        builder: (context, state) {
          return Stack(
            children: [
              SingleChildScrollView(
                child: HospitalDetailContent(
                  hospital: state.hospital,
                  initialTab: 0,
                ),
              ),
              if (state.isLoading)
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              if (state.errorMessage != null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: _DetailErrorBanner(
                    onRetry: () {
                      context.read<HospitalDetailBloc>().add(
                        const HospitalDetailLoadRequested(),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _DetailErrorBanner extends StatelessWidget {
  const _DetailErrorBanner({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF3C3C3C),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                '병원 상세 정보를 새로고침하지 못했습니다.',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('재시도'),
            ),
          ],
        ),
      ),
    );
  }
}
