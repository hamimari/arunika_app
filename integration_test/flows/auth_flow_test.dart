import 'package:arunika_app/presentation/navigation/app_router.dart';
import 'package:arunika_app/presentation/navigation/main_shell.dart';
import 'package:arunika_app/presentation/screens/signin/signin_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/boot_app.dart';
import '../helpers/signed_in_session.dart';

/// Flow 1: a new user reaches home with a real backend behind every request.
///
/// Run with:
///   flutter test integration_test/flows/auth_flow_test.dart -d macos \
///     --dart-define=API_BASE_URL=http://localhost:8099
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'should_reach_home_after_registering_a_real_account',
    (tester) async {
      await bootApp(tester);

      // The wizard's own field-by-field mechanics are unit-tested against a
      // mocked repository in test/presentation/screens/signup/. What this
      // proves instead is the thing nothing else does: a signup against a
      // *real* backend yields a session the rest of the app can actually use.
      await registerAndSignIn();

      // AuthNotifier.checkAuth() calls notifyListeners(); the router's
      // refreshListenable picks that up and re-evaluates '/' -> '/shell'
      // without the test remounting anything.
      // A real launch lands on '/' and redirects; the test app is already
      // mounted on '/landing', so do the same navigation explicitly.
      AppRouter.router.go('/');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byType(MainShell), findsOneWidget);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  testWidgets(
    'should_sign_in_through_the_real_form_after_registering',
    (tester) async {
      await bootApp(tester);
      final session = await registerAndSignIn();
      await signOut();

      // Re-launch signed out; bootApp remounts the router fresh, so it
      // re-evaluates '/' with no token present and lands on '/landing'.
      await bootApp(tester);

      // From here on this is real UI input against a real backend: typed
      // text, a tapped button, a server round trip, a router redirect.
      final signIn = find.byType(SignInScreen);
      if (signIn.evaluate().isEmpty) {
        // Landing screen sits in front of sign-in; find its way there.
        final signInEntry = find.text('Sudah punya akun? Masuk');
        await tester.ensureVisible(signInEntry);
        await tester.tap(signInEntry);
        await tester.pumpAndSettle();
      }

      await tester.enterText(
        find.byType(TextField).at(0),
        session.account.email,
      );
      await tester.enterText(
        find.byType(TextField).at(1),
        session.account.password,
      );
      await tester.tap(find.text('Masuk').last);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byType(MainShell), findsOneWidget);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
