import 'package:arunika_app/data/models/request/signin_request.dart';
import 'package:arunika_app/data/models/request/signup_request.dart';
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

  Future<SignInResponse> signin(SignInRequest request) async {
    final json = await api.signin(request.toJson());
    return SignInResponse.fromJson(json);
  }
}
