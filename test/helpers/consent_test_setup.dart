import 'package:arunika_app/core/auth/auth_notifier.dart';
import 'package:arunika_app/data/models/response/user_response.dart';
import 'package:arunika_app/data/repositories/user_repository.dart';
import 'package:flutter/services.dart';
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

/// Makes SecureTokenStorage report a signed-in user, `userId`.
void mockSecureStorage({String userId = 'u1'}) {
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'read') {
          final key = (call.arguments as Map)['key'];
          return key == 'user_id' ? userId : 'token';
        }
        return null;
      });
}
