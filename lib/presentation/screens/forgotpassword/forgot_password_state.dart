class ForgotPasswordState{
  final String email;
  final bool isSubmitted;
  final bool isLoading;
  final String? error;

  ForgotPasswordState({
    this.email = '',
    this.isSubmitted = false,
    this.isLoading = false,
    this.error,
  });

  ForgotPasswordState copyWith({
    String? email,
    bool? isSubmitted,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ForgotPasswordState(
      email: email ?? this.email,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}