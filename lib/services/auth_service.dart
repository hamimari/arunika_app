import 'package:arunika_app/data/models/request/signup_request.dart';
import 'package:arunika_app/data/models/response/signup_response.dart';

import '../../data/repositories/auth_repository.dart';

class AuthService {
  final AuthRepository repository;

  AuthService(this.repository);

  Future<SignUpResponse> signup(
    String name,
    String phoneNumber,
    String email,
    String address,
    String city,
    String password,
    ChildRequest child,
  ) {
    return repository.signup(
      SignUpRequest(
        name: name,
        password: password,
        phoneNumber: phoneNumber,
        email: email,
        address: address,
        city: city,
        child: child,
      ),
    );
  }
}
