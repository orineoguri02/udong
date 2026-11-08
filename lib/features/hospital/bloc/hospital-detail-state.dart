import '../models/hospital.dart';

class HospitalDetailState {
  const HospitalDetailState({
    required this.hospital,
    this.isLoading = false,
    this.errorMessage,
  });

  static const Object _noChange = Object();

  final Hospital hospital;
  final bool isLoading;
  final String? errorMessage;

  HospitalDetailState copyWith({
    Hospital? hospital,
    bool? isLoading,
    Object? errorMessage = _noChange,
  }) {
    return HospitalDetailState(
      hospital: hospital ?? this.hospital,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage == _noChange
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}
