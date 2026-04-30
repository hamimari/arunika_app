import 'package:arunika_app/data/models/response/child_response.dart';

abstract class SignupEvent {}

class NameChanged extends SignupEvent {
  final String name;
  NameChanged(this.name);
}

class PhoneChanged extends SignupEvent {
  final String phone;
  PhoneChanged(this.phone);
}

class EmailChanged extends SignupEvent {
  final String email;
  EmailChanged(this.email);
}

class CityChanged extends SignupEvent {
  final String city;
  CityChanged(this.city);
}

class AddressChanged extends SignupEvent {
  final String address;
  AddressChanged(this.address);
}

class PasswordChanged extends SignupEvent {
  final String password;
  PasswordChanged(this.password);
}

class ChildNameChanged extends SignupEvent {
  final String name;
  ChildNameChanged(this.name);
}

class ChildBirthDateChanged extends SignupEvent {
  final DateTime birthDate;
  ChildBirthDateChanged(this.birthDate);
}

class ChildGenderChanged extends SignupEvent {
  final String gender;
  ChildGenderChanged(this.gender);
}

class TncToggled extends SignupEvent {
  final bool accepted;
  TncToggled(this.accepted);
}

class ObscurePasswordToggled extends SignupEvent {
  final bool obscure;
  ObscurePasswordToggled(this.obscure);
}

class NavigateToChildReset extends SignupEvent {
  final bool navigateToChild;
  NavigateToChildReset(this.navigateToChild);
}

class PrefillChildData extends SignupEvent {
  final ChildResponse child;

  PrefillChildData(this.child);
}

class ChildPrefilled extends SignupEvent {
  final String name;
  final String gender;
  final DateTime birthDate;

  ChildPrefilled({
    required this.name,
    required this.gender,
    required this.birthDate,
  });
}

class SignupSubmitted extends SignupEvent {}

class NextButtonPressed extends SignupEvent {}

class ChildRegistrationButtonPressed extends SignupEvent {}

class StartTrialSubmit extends SignupEvent {}
