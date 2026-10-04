import 'package:arunika_app/core/auth/auth_notifier.dart';
import 'package:arunika_app/core/theme/app_theme.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/presentation/navigation/app_router.dart';
import 'package:arunika_app/services/billing_service.dart';
import 'package:arunika_app/services/push_notification_service.dart';
import 'package:arunika_app/services/push_link.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

// Reuses the same fake used by the unit tests in test/helpers, rather than a
// second copy — one implementation of "what does a fake purchase look like"
// for the whole test suite.
import '../../test/helpers/fake_billing.dart';

/// Boots the real app against a real backend, for tests that need more than
/// a single screen — the router, DI wiring and HTTP calls all have to work
/// as they do in production.
///
/// Deliberately lighter than `main()`: Firebase, Crashlytics and the native
/// splash screen are skipped, and [PushNotificationService] — the only locator
/// entry that touches Firebase, and one `MainShell` resolves as soon as it
/// mounts — is replaced by a no-op fake. Initialising Firebase in a test
/// process is exactly the kind of environment coupling that makes a suite
/// flaky; real push behaviour is covered by the Patrol suite.
///
/// `API_BASE_URL` must point at a running backend, e.g.:
///   flutter test integration_test/flows/auth_flow_test.dart \
///     --dart-define=API_BASE_URL=http://localhost:8080 -d macos
///
/// [billing] defaults to a successful [FakeBilling] — a real purchase opens
/// Google Play's UI and charges money, neither of which can run here.
Future<void> bootApp(WidgetTester tester, {BillingService? billing}) async {
  // setupLocator() is only safe to call once per process — it registers
  // singletons unconditionally. Individual tests isolate themselves by using
  // distinct accounts (see helpers/test_accounts.dart) rather than by
  // resetting the whole container between tests.
  if (!locator.isRegistered<AuthNotifier>()) {
    setupLocator();
  }
  if (locator.isRegistered<BillingService>()) {
    locator.unregister<BillingService>();
  }
  locator.registerSingleton<BillingService>(billing ?? FakeBilling.succeeds());
  if (locator.isRegistered<PushNotificationService>()) {
    locator.unregister<PushNotificationService>();
  }
  locator.registerSingleton<PushNotificationService>(_NoopPush());

  await initializeDateFormatting('id_ID');

  // A signed-in session from an earlier test in the same run must not leak
  // into this one.
  await locator<AuthNotifier>().logout();

  // AppRouter.router is a process-wide singleton, so it keeps the previous
  // test's location. A real launch always starts at '/'; do the same.
  AppRouter.router.go('/');

  await tester.pumpWidget(
    MaterialApp.router(
      title: 'Arunika World',
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
    ),
  );
  await tester.pumpAndSettle();
}

class _NoopPush extends Fake implements PushNotificationService {
  @override
  Future<void> init() async {}

  @override
  void consumePendingLink() {}

  @override
  Future<void> openLink(PushLink link) async {}
}
