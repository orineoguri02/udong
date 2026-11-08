/// 병원 상세 바텀시트
///
/// - 역할: 마커 선택 시 병원 상세를 바텀시트로 표시
/// - 상세 조회는 HospitalDetailBloc(Flux) 경유

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:udon/features/hospital/bloc/hospital-detail-bloc.dart';
import 'package:udon/features/hospital/bloc/hospital-detail-event.dart';
import 'package:udon/features/hospital/bloc/hospital-detail-state.dart';
import 'package:udon/features/hospital/models/hospital.dart';
import 'package:udon/features/hospital/repository/hospital-repository.dart';
import 'package:udon/pages/hospital/widgets/hospital-detail-content.dart';

class HospitalDetailBottomSheet extends StatelessWidget {
  const HospitalDetailBottomSheet({super.key, required this.hospital});

  final Hospital hospital;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HospitalDetailBloc>(
      create: (context) => HospitalDetailBloc(
        repository: context.read<HospitalRepository>(),
        initialState: HospitalDetailState(hospital: hospital),
      )..add(const HospitalDetailLoadRequested()),
      child: const _HospitalDetailBottomSheetBody(),
    );
  }
}

class _HospitalDetailBottomSheetBody extends StatelessWidget {
  const _HospitalDetailBottomSheetBody();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: SizedBox(
                    width: 40,
                    child: Divider(thickness: 4, height: 4),
                  ),
                ),
              ),
              Expanded(
                child: BlocBuilder<HospitalDetailBloc, HospitalDetailState>(
                  builder: (context, state) {
                    return Stack(
                      children: [
                        SingleChildScrollView(
                          controller: scrollController,
                          child: HospitalDetailContent(
                            hospital: state.hospital,
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
                            child: _BottomSheetErrorBanner(
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
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BottomSheetErrorBanner extends StatelessWidget {
  const _BottomSheetErrorBanner({required this.onRetry});

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
