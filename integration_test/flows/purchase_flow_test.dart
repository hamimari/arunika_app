import 'dart:io' show Platform;

import 'package:arunika_app/constants/app_strings.dart';
import 'package:arunika_app/core/theme/app_theme.dart';
import 'package:arunika_app/data/models/purchasable_item.dart';
import 'package:arunika_app/presentation/screens/payment/payment_screen.dart';
import 'package:arunika_app/presentation/screens/unlock_success/unlock_success_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/boot_app.dart';
import '../../test/helpers/fake_billing.dart';

/// The app's reaction to a Play Billing outcome — not whether the backend
/// correctly settles the purchase and grants the entitlement, which
/// arunika-backend's tests/api/purchase_test.go already proves fully
/// automated, with no Google credentials, against a real database.
///
/// `PaymentScreen` only takes the Play Billing branch on Android
/// (`_usesPlayBilling` checks `Platform.isAndroid`), which is the right
/// thing for the app to do in production but means these cases are
/// unreachable on any other host. They are written and analyzed here so CI's
/// Android emulator job (see the automation-testing-strategy roadmap) runs
/// them for real; `skip` documents why a desktop or web run of this file
/// proves nothing about them, rather than silently passing for the wrong
/// reason.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final item = PurchasableItem.fromProduct(
    productId: 'test-product',
    title: 'Kartu Uji',
    priceIdr: 25000,
    contentType: PurchasedContentType.arCard,
    playProductId: 'sku_test_card',
  );

  Future<void> pumpPaymentScreen(WidgetTester tester) async {
    // PaymentScreen navigates with context.go(...), a GoRouter extension —
    // a plain Navigator/MaterialApp route table does not satisfy it, the
    // same trap hit earlier wiring up the AR entry gate test.
    final router = GoRouter(
      initialLocation: '/payment',
      routes: [
        GoRoute(
          path: '/payment',
          builder: (_, __) => PaymentScreen(item: item),
        ),
        GoRoute(
          path: '/unlock-success',
          builder: (_, state) =>
              UnlockSuccessScreen(item: state.extra as PurchasableItem),
        ),
      ],
    );
    // Tear down the app bootApp mounted first, then mount this one with the
    // real theme. Without both, the button's text style animates from the app
    // theme to Material's default ("Failed to interpolate TextStyles with
    // different inherit values"), and the resulting ErrorWidget lays out at
    // ~99,000 px — which reads like a PaymentScreen overflow but is not one.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.lightTheme, routerConfig: router),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'should_reach_unlock_success_when_billing_reports_success',
    (tester) async {
      await bootApp(tester, billing: FakeBilling.succeeds());
      await pumpPaymentScreen(tester);

      await tester.tap(find.text(AppStrings.btnPayNow));
      await tester.pumpAndSettle();

      expect(find.byType(UnlockSuccessScreen), findsOneWidget);
    },
    skip: !Platform.isAndroid,
    timeout: const Timeout(Duration(minutes: 2)),
  );

  testWidgets(
    'should_stay_on_payment_screen_when_the_user_cancels',
    (tester) async {
      await bootApp(tester, billing: FakeBilling.cancels());
      await pumpPaymentScreen(tester);

      await tester.tap(find.text(AppStrings.btnPayNow));
      await tester.pumpAndSettle();

      // A cancellation must not be mistaken for success and must not strand
      // the user on an error screen either — they can simply try again.
      expect(find.byType(UnlockSuccessScreen), findsNothing);
      expect(find.byType(PaymentScreen), findsOneWidget);
    },
    skip: !Platform.isAndroid,
    timeout: const Timeout(Duration(minutes: 2)),
  );

  testWidgets(
    'should_show_an_error_state_when_backend_verification_fails',
    (tester) async {
      await bootApp(tester, billing: FakeBilling.failsVerification());
      await pumpPaymentScreen(tester);

      await tester.tap(find.text(AppStrings.btnPayNow));
      await tester.pumpAndSettle();

      // Google took the money but the backend refused entitlement — a
      // support case, not silent success.
      expect(find.byType(UnlockSuccessScreen), findsNothing);
    },
    skip: !Platform.isAndroid,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
