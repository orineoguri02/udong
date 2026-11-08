import '../models/hospital.dart';

class HospitalState {
  const HospitalState({
    this.allHospitals = const [],
    this.isLoading = false,
    this.isOpenOnly = false,
    this.errorMessage,
  });

  static const Object _noChange = Object();

  final List<Hospital> allHospitals;
  final bool isLoading;
  final bool isOpenOnly;
  final String? errorMessage;

  List<Hospital> get filteredHospitals {
    if (isOpenOnly) {
      return allHospitals.where((hospital) => hospital.isOpen).toList();
    }
    return allHospitals;
  }

  HospitalState copyWith({
    List<Hospital>? allHospitals,
    bool? isLoading,
    bool? isOpenOnly,
    Object? errorMessage = _noChange,
  }) {
    return HospitalState(
      allHospitals: allHospitals ?? this.allHospitals,
      isLoading: isLoading ?? this.isLoading,
      isOpenOnly: isOpenOnly ?? this.isOpenOnly,
      errorMessage: errorMessage == _noChange
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}
