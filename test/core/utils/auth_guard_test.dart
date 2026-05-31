import 'package:arunika_app/core/auth/auth_notifier.dart';
import 'package:arunika_app/core/utils/auth_guard.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_router/go_router.dart';

class MockAuthNotifier extends Mock implements AuthNotifier {
  @override
  bool get isLoggedIn => _loggedIn;
  bool _loggedIn = false;
  void setLoggedIn(bool value) => _loggedIn = value;
}

void main() {
  late MockAuthNotifier mockAuth;

  setUp(() {
    if (locator.isRegistered<AuthNotifier>()) {
      locator.unregister<AuthNotifier>();
    }
    mockAuth = MockAuthNotifier();
    locator.registerSingleton<AuthNotifier>(mockAuth);
  });

  tearDown(() {
    if (locator.isRegistered<AuthNotifier>()) {
      locator.unregister<AuthNotifier>();
    }
  });

  Widget _buildApp({
    required Widget home,
    List<GoRoute> extraRoutes = const [],
  }) {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => home),
        GoRoute(
          path: '/premium',
          builder: (_, __) => const Scaffold(body: Text('Premium')),
        ),
        GoRoute(
          path: '/signin',
          builder: (_, __) => const Scaffold(body: Text('SignIn')),
        ),
        GoRoute(
          path: '/signup',
          builder: (_, __) => const Scaffold(body: Text('SignUp')),
        ),
        ...extraRoutes,
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }

  testWidgets(
    'guardPremium when user is already logged in navigates to /premium',
    (tester) async {
      mockAuth.setLoggedIn(true);

      late BuildContext capturedContext;
      await tester.pumpWidget(
        _buildApp(
          home: Builder(
            builder: (ctx) {
              capturedContext = ctx;
              return ElevatedButton(
                onPressed: () => guardPremium(ctx),
                child: const Text('Go Premium'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Go Premium'));
      await tester.pumpAndSettle();

      expect(find.text('Premium'), findsOneWidget);
    },
  );

  testWidgets(
    'guardPremium when user is not logged in shows dialog with Login and Daftar Akun',
    (tester) async {
      mockAuth.setLoggedIn(false);

      await tester.pumpWidget(
        _buildApp(
          home: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => guardPremium(ctx),
              child: const Text('Go Premium'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Go Premium'));
      await tester.pumpAndSettle();

      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Daftar Akun'), findsOneWidget);
    },
  );

  testWidgets('guardPremium when dialog is dismissed no navigation occurs', (
    tester,
  ) async {
    mockAuth.setLoggedIn(false);

    await tester.pumpWidget(
      _buildApp(
        home: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () => guardPremium(ctx),
            child: const Text('Go Premium'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Go Premium'));
    await tester.pumpAndSettle();

    // Dismiss by tapping "Nanti Saja"
    await tester.tap(find.text('Nanti Saja'));
    await tester.pumpAndSettle();

    expect(find.text('Premium'), findsNothing);
  });

  testWidgets('guardPremium when user taps Login navigates to /signin', (
    tester,
  ) async {
    mockAuth.setLoggedIn(false);

    await tester.pumpWidget(
      _buildApp(
        home: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () => guardPremium(ctx),
            child: const Text('Go Premium'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Go Premium'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(find.text('SignIn'), findsOneWidget);
  });

  testWidgets('guardPremium when user taps Daftar Akun navigates to /signup', (
    tester,
  ) async {
    mockAuth.setLoggedIn(false);

    await tester.pumpWidget(
      _buildApp(
        home: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () => guardPremium(ctx),
            child: const Text('Go Premium'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Go Premium'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Daftar Akun'));
    await tester.pumpAndSettle();

    expect(find.text('SignUp'), findsOneWidget);
  });
}
