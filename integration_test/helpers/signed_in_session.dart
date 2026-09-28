import 'package:arunika_app/core/auth/auth_notifier.dart';
import 'package:arunika_app/core/storage/SecureStorageToken.dart';
import 'package:arunika_app/data/models/request/signup_request.dart';
import 'package:arunika_app/data/repositories/auth_repository.dart';
import 'package:arunika_app/di/locator.dart';

import 'test_accounts.dart';

/// Registers a fresh account through the real signup endpoint and leaves the
/// session signed in, exactly as `signup_bloc.dart` does on success (save
/// token, save refresh token, save user id, notify `AuthNotifier`).
///
/// The multi-step signup wizard's own mechanics (name/phone/email/address/
/// city/password/child fields, validation, terms and privacy screens) are
/// already covered by `test/presentation/screens/signup/signup_bloc_test.dart`
/// against a mocked repository. What nothing proves anywhere else is that a
/// signup against a *real* backend produces a session the rest of the app can
/// actually use — that is this helper's job, and driving it through the
/// repository rather than by tapping through the wizard keeps these flows
/// about that claim instead of about wizard navigation.
///
/// Returns the account and its backend user id, as returned by signup.
class SignedInSession {
  SignedInSession({required this.account, required this.userId});

  final TestAccount account;
  final String userId;
}

Future<SignedInSession> registerAndSignIn() async {
  final account = TestAccount();
  final repo = locator<AuthRepository>();

  final response = await repo.signup(
    SignUpRequest(
      name: account.name,
      phoneNumber: account.phone,
      email: account.email,
      address: 'Jl. Integration Test',
      city: 'Jakarta',
      password: account.password,
      child: ChildRequest(
        name: account.childName,
        gender: 'M',
        dateOfBirth: '2020-01-02T00:00:00.000',
      ),
    ),
  );

  await SecureTokenStorage.saveToken(response.token);
  await SecureTokenStorage.saveRefreshToken(response.refreshToken);
  await SecureTokenStorage.saveUserId(response.id);
  await locator<AuthNotifier>().checkAuth();

  return SignedInSession(account: account, userId: response.id);
}

/// Signs the current session out, clearing the token and cached profile —
/// what a reinstall loses (the session) without losing the account itself.
Future<void> signOut() async {
  await locator<AuthNotifier>().logout();
}
