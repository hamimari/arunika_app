import 'package:arunika_app/data/models/response/user_response.dart';

class ProfileState {
  final UserResponse? user;

  final String name;
  final String phone;
  final String email;
  final String city;
  final String address;

  final String? nameError;
  final String? phoneError;
  final String? emailError;
  final String? cityError;
  final String? addressError;

  // child
  final String childName;
  final String? childNameError;
  final DateTime? childBirthDate;
  final String? childBirthDateError;
  final String? childGender;
  final String? childGenderError;

  final bool isSubmitting;
  final bool isSuccess;
  final String? error;

  ProfileState({
    this.user,
    this.name = '',
    this.phone = '',
    this.email = '',
    this.city = '',
    this.address = '',
    this.nameError,
    this.phoneError,
    this.emailError,
    this.cityError,
    this.addressError,
    this.childName = '',
    this.childNameError,
    this.childBirthDate,
    this.childBirthDateError,
    this.childGender,
    this.childGenderError,
    this.isSubmitting = false,
    this.isSuccess = false,
    this.error,
  });

  ProfileState copyWith({
    UserResponse? user,
    String? name,
    String? phone,
    String? email,
    String? city,
    String? address,
    String? nameError,
    String? phoneError,
    String? emailError,
    String? cityError,
    String? addressError,
    String? childName,
    String? childNameError,
    DateTime? childBirthDate,
    String? childBirthDateError,
    String? childGender,
    String? childGenderError,
    bool? isSubmitting,
    bool? isSuccess,
    String? error,
  }) {
    return ProfileState(
      user: user ?? this.user,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      city: city ?? this.city,
      address: address ?? this.address,
      nameError: nameError,
      phoneError: phoneError,
      emailError: emailError,
      cityError: cityError,
      addressError: addressError,
      childName: childName ?? this.childName,
      childNameError: childNameError,
      childBirthDate: childBirthDate ?? this.childBirthDate,
      childBirthDateError: childBirthDateError,
      childGender: childGender ?? this.childGender,
      childGenderError: childGenderError,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      error: error,
    );
  }
}
