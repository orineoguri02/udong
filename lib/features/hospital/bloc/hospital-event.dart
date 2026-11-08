sealed class HospitalEvent {
  const HospitalEvent();
}

final class HospitalLoadRequested extends HospitalEvent {
  const HospitalLoadRequested();
}

final class HospitalOpenFilterToggled extends HospitalEvent {
  const HospitalOpenFilterToggled();
}
