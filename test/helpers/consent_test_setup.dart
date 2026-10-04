import 'package:arunika_app/core/auth/auth_notifier.dart';
import 'package:arunika_app/data/models/response/user_response.dart';
import 'package:arunika_app/data/repositories/user_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockUserRepository extends Mock implements UserRepository {}

/// Always signed in, without touching secure storage.
class SignedInAuthNotifier extends AuthNotifier {
  int logouts = 0;

  @override
  bool get isLoggedIn => true;

  @override
  Future<void> logout() async => logouts++;
}

UserResponse profile({required bool consentRequired}) => UserResponse(
  id: 'u1',
  name: 'Budi',
  phoneNumber: '081',
  emailAddress: 'budi@example.com',
  address: 'Jl.',
  city: 'Jakarta',
  children: const [],
  consentRequired: consentRequired,
);

/// Makes SecureTokenStorage report a signed-in user, `userId`, with an
/// otherwise empty in-memory secure store (so no cached profile).
void mockSecureStorage({String userId = 'u1'}) {
  FlutterSecureStorage.setMockInitialValues({
    'user_id': userId,
    'auth_token': 'token',
    'refresh_token': 'token',
  });
}
