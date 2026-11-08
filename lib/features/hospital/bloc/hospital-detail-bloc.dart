import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/app-logger.dart';
import '../repository/hospital-repository.dart';
import 'hospital-detail-event.dart';
import 'hospital-detail-state.dart';

class HospitalDetailBloc
    extends Bloc<HospitalDetailEvent, HospitalDetailState> {
  HospitalDetailBloc({
    required HospitalRepository repository,
    required HospitalDetailState initialState,
  }) : _repository = repository,
       super(initialState) {
    on<HospitalDetailLoadRequested>(_onHospitalDetailLoadRequested);
  }

  final HospitalRepository _repository;

  Future<void> _onHospitalDetailLoadRequested(
    HospitalDetailLoadRequested event,
    Emitter<HospitalDetailState> emit,
  ) async {
    final clinicId = state.hospital.clinicId;
    if (clinicId == null) return;

    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final detail = await _repository.getHospitalDetail(clinicId: clinicId);
      emit(
        state.copyWith(hospital: detail, isLoading: false, errorMessage: null),
      );
    } catch (e) {
      AppLogger.error('병원 상세 로딩 실패', error: e);
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }
}
