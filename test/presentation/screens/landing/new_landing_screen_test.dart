import 'package:arunika_app/constants/app_strings.dart';
import 'package:arunika_app/presentation/screens/landing/new_landing_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// `NewLandingScreen` is what `/` redirects an anonymous visitor to (see
/// app_router.dart), so its three exits are the whole first-run funnel:
/// sign up, sign in, or skip straight into the app. No bloc, no backend call
/// — every meaningful thing this screen does is pick where `context.go`
/// sends the user next, so that's what these tests pin.
void main() {
  // The default 800x600 test surface is shorter than this screen's content,
  // which overflows and fails the test on a rendering error that has
  // nothing to do with what these tests are about. A taller surface avoids
  // it without touching the screen itself.
  void useTallSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1000, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  testWidgets('should_show_the_explore_and_sign_in_calls_to_action', (
    tester,
  ) async {
    useTallSurface(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Navigator(
            onGenerateRoute: (_) => MaterialPageRoute(
              builder: (_) => const NewLandingScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.btnExplore), findsOneWidget);
    expect(find.text('Sudah punya akun? Masuk'), findsOneWidget);
  });

  testWidgets('should_go_to_signup_when_explore_is_tapped', (tester) async {
    useTallSurface(tester);
    String? lastRoute;
    final router = GoRouter(
      initialLocation: '/landing',
      routes: [
        GoRoute(path: '/landing', builder: (_, __) => const NewLandingScreen()),
        GoRoute(
          path: '/signup',
          builder: (_, __) {
            lastRoute = '/signup';
            return const SizedBox.shrink();
          },
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.btnExplore));
    await tester.pumpAndSettle();

    expect(lastRoute, '/signup');
  });

  testWidgets('should_go_to_signin_when_the_sign_in_link_is_tapped', (
    tester,
  ) async {
    useTallSurface(tester);
    String? lastRoute;
    final router = GoRouter(
      initialLocation: '/landing',
      routes: [
        GoRoute(path: '/landing', builder: (_, __) => const NewLandingScreen()),
        GoRoute(
          path: '/signin',
          builder: (_, __) {
            lastRoute = '/signin';
            return const SizedBox.shrink();
          },
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sudah punya akun? Masuk'));
    await tester.pumpAndSettle();

    expect(lastRoute, '/signin');
  });

  testWidgets(
    'should_let_an_anonymous_visitor_skip_straight_into_the_app',
    (tester) async {
      // The "try demo" link bypasses auth entirely — worth pinning precisely
      // because it is the one path here that does NOT lead to signup/signin.
      useTallSurface(tester);
      String? lastRoute;
      final router = GoRouter(
        initialLocation: '/landing',
        routes: [
          GoRoute(
            path: '/landing',
            builder: (_, __) => const NewLandingScreen(),
          ),
          GoRoute(
            path: '/shell',
            builder: (_, __) {
              lastRoute = '/shell';
              return const SizedBox.shrink();
            },
          ),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.btnTryDemo));
      await tester.pumpAndSettle();

      expect(lastRoute, '/shell');
    },
  );
}
