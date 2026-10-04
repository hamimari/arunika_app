import 'package:arunika_app/presentation/navigation/app_router.dart';
import 'package:arunika_app/constants/app_strings.dart';
import 'package:arunika_app/data/models/request/signin_request.dart';
import 'package:arunika_app/data/repositories/auth_repository.dart';
import 'package:arunika_app/core/auth/auth_notifier.dart';
import 'package:arunika_app/core/storage/SecureStorageToken.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/belajar.dart';
import '../helpers/boot_app.dart';
import '../helpers/scroll.dart';
import '../helpers/signed_in_session.dart';
import '../helpers/test_backend.dart';

/// What a session outlives, and what it doesn't.
///
/// Entitlements are keyed to the account (`user_id`), never to a device or a
/// stored token — so a reinstall, which destroys the token but not the
/// account, must not touch what the account already owns. This is the
/// journey that proves it against a real backend rather than against
/// whatever a mock happens to be told to return.
///
/// Token-refresh mid-session (E2E flow 6 in the strategy) is deliberately
/// NOT re-proven here: it needs no UI, and arunika-backend's
/// tests/api/auth_test.go already proves the full rotation-and-reuse
/// contract against a real router and database. Waiting out a real 15-minute
/// access-token lifetime in a Flutter integration test would only make this
/// suite slow for a claim already covered more cheaply.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final backend = TestBackend();

  testWidgets(
    'should_show_previously_granted_content_as_unlocked_after_reinstall_and_relogin',
    (tester) async {
      final title = 'Kartu Reinstall ${DateTime.now().microsecondsSinceEpoch}';
      await backend.seedPaidArCard(title: title);

      await bootApp(tester);
      final session = await registerAndSignIn();
      await backend.grantPremium(session.userId);

      // Reinstalling destroys local storage — the token, the cached
      // profile — but the account and everything it owns live on the
      // backend. signOut() models exactly that loss.
      await signOut();

      // Re-launch fresh, as reinstalling would, and sign back in with the
      // same credentials via the real login endpoint.
      await bootApp(tester);
      final response = await locator<AuthRepository>().signin(
        SignInRequest(
          email: session.account.email,
          password: session.account.password,
        ),
      );
      await SecureTokenStorage.saveToken(response.token);
      await SecureTokenStorage.saveRefreshToken(response.refreshToken);
      await SecureTokenStorage.saveUserId(response.userId);
      await locator<AuthNotifier>().checkAuth();
      // A real launch lands on '/' and redirects; the test app is already
      // mounted on '/landing', so do the same navigation explicitly.
      AppRouter.router.go('/');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await openBelajar(tester, AppStrings.navCollection);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // The grant made before the "reinstall" is still there — nothing
      // about owning this card lived in the storage that was wiped.
      expect(await scrollToText(tester, title), findsOneWidget);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
