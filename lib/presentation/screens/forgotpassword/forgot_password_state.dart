class ForgotPasswordState{
  final String email;
  final bool isSubmitted;

  ForgotPasswordState({
    this.email = '',
    this.isSubmitted = false,
  });

  ForgotPasswordState copyWith({
    String? email,
    bool? isSubmitted,
  }) {
    return ForgotPasswordState(
      email: email ?? this.email,
      isSubmitted: isSubmitted ?? this.isSubmitted,
    );
  }
}