abstract class ProfileEvent {}

class ProfileInitial extends ProfileEvent {}

class ChildNameChanged extends ProfileEvent {
  final String name;
  ChildNameChanged(this.name);
}

class ChildBirthDateChanged extends ProfileEvent {
  final DateTime birthDate;
  ChildBirthDateChanged(this.birthDate);
}

class ChildGenderChanged extends ProfileEvent {
  final String gender;
  ChildGenderChanged(this.gender);
}

class NameChanged extends ProfileEvent {
  final String name;
  NameChanged(this.name);
}

class PhoneChanged extends ProfileEvent {
  final String phone;
  PhoneChanged(this.phone);
}

class EmailChanged extends ProfileEvent {
  final String email;
  EmailChanged(this.email);
}

class CityChanged extends ProfileEvent {
  final String city;
  CityChanged(this.city);
}

class AddressChanged extends ProfileEvent {
  final String address;
  AddressChanged(this.address);
}

class ChildPrefilled extends ProfileEvent {
  final String name;
  final String gender;
  final DateTime birthDate;

  ChildPrefilled({
    required this.name,
    required this.gender,
    required this.birthDate,
  });
}


class EditSubmitted extends ProfileEvent {}
