abstract class SigninEvent {}

class ObscurePasswordToggled extends SigninEvent {
  final bool obscure;
  ObscurePasswordToggled(this.obscure);
}

class EmailChanged extends SigninEvent {
  final String email;
  EmailChanged(this.email);
}

class PasswordChanged extends SigninEvent {
  final String password;
  PasswordChanged(this.password);
}

class SigninSubmitted extends SigninEvent {}