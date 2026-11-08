import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/app-logger.dart';
import '../repository/hospital-repository.dart';
import 'hospital-event.dart';
import 'hospital-state.dart';

class HospitalBloc extends Bloc<HospitalEvent, HospitalState> {
  HospitalBloc(this._repository) : super(const HospitalState()) {
    on<HospitalLoadRequested>(_onHospitalLoadRequested);
    on<HospitalOpenFilterToggled>(_onHospitalOpenFilterToggled);
  }

  final HospitalRepository _repository;

  Future<void> _onHospitalLoadRequested(
    HospitalLoadRequested event,
    Emitter<HospitalState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final hospitals = await _repository.getHospitals();
      emit(
        state.copyWith(
          allHospitals: hospitals,
          isLoading: false,
          errorMessage: null,
        ),
      );
    } catch (e) {
      AppLogger.error('병원 목록 로딩 실패', error: e);
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  void _onHospitalOpenFilterToggled(
    HospitalOpenFilterToggled event,
    Emitter<HospitalState> emit,
  ) {
    emit(state.copyWith(isOpenOnly: !state.isOpenOnly));
  }
}
