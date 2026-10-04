import 'package:arunika_app/core/auth/auth_notifier.dart';
import 'package:arunika_app/core/auth/consent_gate.dart';
import 'package:arunika_app/data/models/request/consent_request.dart';
import 'package:arunika_app/data/repositories/user_repository.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/presentation/screens/consent/consent_screen.dart';
import 'package:arunika_app/presentation/screens/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/consent_test_setup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockUserRepository users;
  late SignedInAuthNotifier auth;

  setUpAll(() => registerFallbackValue(const ConsentRequest.current()));

  setUp(() {
    mockSecureStorage();
    ConsentGate.reset();
    users = MockUserRepository();
    auth = SignedInAuthNotifier();
    locator.registerSingleton<UserRepository>(users);
    locator.registerSingleton<AuthNotifier>(auth);
  });

  tearDown(locator.reset);

  Future<GoRouter> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: '/consent',
      routes: [
        GoRoute(path: '/consent', builder: (_, __) => const ConsentScreen()),
        GoRoute(path: '/shell', builder: (_, __) => const Text('SHELL')),
        GoRoute(path: '/landing', builder: (_, __) => const Text('LANDING')),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    return router;
  }

  final terms = find.byKey(const Key('consent_terms_checkbox'));
  final parental = find.byKey(const Key('consent_parental_checkbox'));
  bool acceptEnabled(WidgetTester t) =>
      t.widget<AppButton>(find.byType(AppButton)).enabled;

  testWidgets('should_block_until_both_boxes_are_ticked', (tester) async {
    await pumpScreen(tester);
    expect(acceptEnabled(tester), isFalse);

    await tester.tap(terms);
    await tester.pump();
    expect(acceptEnabled(tester), isFalse);

    await tester.tap(parental);
    await tester.pump();
    expect(acceptEnabled(tester), isTrue);
  });

  testWidgets('should_record_consent_and_continue_to_the_shell', (
    tester,
  ) async {
    when(() => users.recordConsent(any())).thenAnswer((_) async => false);
    await pumpScreen(tester);

    await tester.tap(terms);
    await tester.tap(parental);
    await tester.pump();
    await tester.tap(find.byType(AppButton));
    await tester.pumpAndSettle();

    final sent =
        verify(() => users.recordConsent(captureAny())).captured.single
            as ConsentRequest;
    expect(sent.toJson(), const ConsentRequest.current().toJson());
    expect(find.text('SHELL'), findsOneWidget);
  });

  testWidgets(
    'should_stay_put_and_explain_when_the_backend_wants_a_newer_version',
    (tester) async {
      when(() => users.recordConsent(any())).thenAnswer((_) async => true);
      await pumpScreen(tester);

      await tester.tap(terms);
      await tester.tap(parental);
      await tester.pump();
      await tester.tap(find.byType(AppButton));
      await tester.pumpAndSettle();

      expect(find.text('SHELL'), findsNothing);
      expect(find.textContaining('perbarui aplikasi'), findsOneWidget);
    },
  );

  testWidgets('should_stay_put_when_saving_fails', (tester) async {
    when(() => users.recordConsent(any())).thenThrow(Exception('boom'));
    await pumpScreen(tester);

    await tester.tap(terms);
    await tester.tap(parental);
    await tester.pump();
    await tester.tap(find.byType(AppButton));
    await tester.pumpAndSettle();

    expect(find.text('SHELL'), findsNothing);
    expect(find.textContaining('Gagal menyimpan persetujuan'), findsOneWidget);
  });

  testWidgets('should_sign_out_and_return_to_landing_on_keluar', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Keluar'));
    await tester.pumpAndSettle();

    expect(auth.logouts, 1);
    expect(find.text('LANDING'), findsOneWidget);
    verifyNever(() => users.recordConsent(any()));
  });

  testWidgets('should_offer_account_deletion', (tester) async {
    await pumpScreen(tester);
    expect(find.text('Hapus Akun'), findsOneWidget);
  });

  testWidgets('should_have_no_back_navigation', (tester) async {
    await pumpScreen(tester);

    final popScope = tester.widget<PopScope>(find.byType(PopScope).first);
    expect(popScope.canPop, isFalse);
    expect(find.byType(BackButton), findsNothing);
    expect(find.byType(AppBar), findsNothing);
  });
}
