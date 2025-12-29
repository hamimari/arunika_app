class SignupState {
  final String name;
  final String phone;
  final String email;
  final String city;
  final String address;
  final String password;
  final String? nameError;
  final String? phoneError;
  final String? emailError;
  final String? passwordError;
  final String? cityError;
  final String? addressError;
  final bool obscurePassword;

  // child
  final String childName;
  final String? childNameError;
  final DateTime? childBirthDate;
  final String? childBirthDateError;
  final String? childGender;
  final String? childGenderError;
  final bool tncAccepted;

  // navigation
  final bool navigateToChild;
  final bool navigateToTrial;
  final bool isSubmitting;
  final bool isSuccess;
  final bool showErrors;
  final String? error;

  SignupState({
    this.name = '',
    this.phone = '',
    this.email = '',
    this.password = '',
    this.city = '',
    this.address = '',
    this.nameError,
    this.phoneError,
    this.emailError,
    this.passwordError,
    this.cityError,
    this.addressError,
    this.obscurePassword = true,
    this.childName = '',
    this.childNameError,
    this.childBirthDate,
    this.childBirthDateError,
    this.childGender,
    this.childGenderError,
    this.tncAccepted = false,
    this.navigateToChild = false,
    this.navigateToTrial = false,
    this.isSubmitting = false,
    this.isSuccess = false,
    this.showErrors = false,
    this.error = '',
  });

  SignupState copyWith({
    String? name,
    String? phone,
    String? email,
    String? city,
    String? address,
    String? password,
    String? nameError,
    String? phoneError,
    String? emailError,
    String? passwordError,
    String? cityError,
    String? addressError,
    bool? obscurePassword,
    String? childName,
    String? childNameError,
    DateTime? childBirthDate,
    String? childBirthDateError,
    String? childGender,
    String? childGenderError,
    bool? tncAccepted,
    bool? isSubmitting,
    bool? isSuccess,
    bool? showErrors,
    bool? navigateToChild,
    String? error,
  }) {
    return SignupState(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      password: password ?? this.password,
      city: city ?? this.city,
      address: address ?? this.address,
      nameError: nameError,
      phoneError: phoneError,
      emailError: emailError,
      passwordError: passwordError,
      cityError: cityError,
      addressError: addressError,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      childName: childName ?? this.childName,
      childNameError: childNameError,
      childBirthDate: childBirthDate ?? this.childBirthDate,
      childBirthDateError: childBirthDateError,
      childGender: childGender ?? this.childGender,
      childGenderError: childGenderError,
      tncAccepted: tncAccepted ?? this.tncAccepted,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      showErrors: showErrors ?? this.showErrors,
      navigateToChild: navigateToChild ?? this.navigateToChild,
      error: error,
    );
  }
}

class SignupNavigateToNextPage extends SignupState {}

class SignupInitial extends SignupState {}

class SignupChildPage extends SignupState {}

class NavigateToTrialPage extends SignupState {}

class NavigateToHomePage extends SignupState {}
