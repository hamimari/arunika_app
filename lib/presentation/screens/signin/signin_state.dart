class SigninState {
  final String email;
  final String password;
  final bool obscurePassword;
  final bool isLoading;
  final String? emailError;
  final String? passwordError;
  final String? error;
  final bool isSuccess;

  SigninState({
    this.email = '',
    this.password = '',
    this.obscurePassword = true,
    this.isLoading = false,
    this.emailError,
    this.passwordError,
    this.error,
    this.isSuccess = false,
  });

  SigninState copyWith({
    String? email,
    String? password,
    bool? obscurePassword,
    bool? isLoading,
    String? emailError,
    String? passwordError,
    String? error,
    bool? isSuccess,
  }) {
    return SigninState(
      email: email ?? this.email,
      password: password ?? this.password,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      isLoading: isLoading ?? this.isLoading,
      emailError: emailError,
      passwordError: passwordError,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}
class SigninInitial extends SigninState {}