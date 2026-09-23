import 'package:arunika_app/data/models/request/signin_request.dart';
import 'package:arunika_app/data/models/request/signup_request.dart';
import 'package:arunika_app/data/models/response/forgot_password_response.dart';
import 'package:arunika_app/data/models/response/signin_response.dart';
import 'package:arunika_app/data/models/response/signup_response.dart';

import '../api/auth_api.dart';

class AuthRepository {
  final AuthApi api;

  AuthRepository(this.api);

  Future<SignUpResponse> signup(SignUpRequest request) async {
    final json = await api.signup(request.toJson());
    return SignUpResponse.fromJson(json);
  }

  /// Asks the backend to send a fresh verification email.
  /// Throws the underlying [DioException] so the caller can distinguish a
  /// rate-limited response from a genuine failure.
  Future<void> resendVerification() => api.resendVerification();

  Future<SignInResponse> signin(SignInRequest request) async {
    final json = await api.signin(request.toJson());
    return SignInResponse.fromJson(json);
  }

  Future<ForgotPasswordResponse> forgotPassword(String email) async {
    final json = await api.forgotPassword({'email': email});
    return ForgotPasswordResponse.fromJson(json);
  }

  /// Returns (emailTaken, phoneTaken).
  Future<(bool, bool)> checkAvailability({
    required String email,
    required String phone,
  }) async {
    final json = await api.checkAvailability(email: email, phone: phone);
    return (json['email_taken'] as bool? ?? false, json['phone_taken'] as bool? ?? false);
  }
}
