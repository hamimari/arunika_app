import 'package:arunika_app/constants/app_strings.dart';
import 'package:arunika_app/core/utils/parental_gate_session.dart';
import 'package:arunika_app/presentation/navigation/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/boot_app.dart';
import '../helpers/screenshot.dart';
import '../helpers/scroll.dart';
import '../helpers/signed_in_session.dart';
import '../helpers/test_backend.dart';

/// Promotional strike prices and the payment screen's inline package
/// options, against real backend-served prices — the promo rule is set
/// through the same admin API the backoffice's "Harga Coret" page uses.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final backend = TestBackend();

  bool isPackageOption(Widget w, String productId) {
    final key = w.key;
    return key is ValueKey<String> &&
        key.value.startsWith('payment-option-') &&
        key.value != 'payment-option-$productId';
  }

  String total(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('payment-total'))).data!;

  // A route pushed over MainShell (which keeps a platform view mounted)
  // leaves that view's per-frame offset callback running into the next test
  // in this process, where it fails against a torn-down transition
  // ("RenderBox was not laid out" after the test completed). Leave the shell
  // and unmount the app so nothing outlives the test.
  Future<void> unmount(WidgetTester tester) async {
    AppRouter.router.go('/landing');
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  }

  testWidgets(
    'should_show_a_promo_price_and_let_the_user_switch_to_a_package',
    (tester) async {
      final title = 'Kartu Promo ${DateTime.now().microsecondsSinceEpoch}';
      final seeded = await backend.seedPaidArCard(title: title, priceIdr: 15000);
      await backend.setStrikeRule(
        'AR_CARD',
        mode: 'PERCENT',
        value: 20,
        endsAt: DateTime.now().add(const Duration(days: 7)),
      );
      addTearDown(() => backend.clearStrikeRule('AR_CARD'));

      await bootApp(tester);
      await registerAndSignIn();
      AppRouter.router.go('/');
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await tester.tap(find.text(AppStrings.navCollection));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Rp 15.000 at 20% → a crossed-out Rp 19.000 next to the real price.
      await scrollToText(tester, title);
      expect(find.text('Rp 15.000'), findsWidgets);
      expect(find.text('Rp 19.000'), findsWidgets);
      await saveScreenshot(tester, 'pricing_1_collection');

      // A parent has already passed the purchase gate this session.
      ParentalGateSession.passed = true;
      await tester.tap(find.text(title));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Beli $title saja'), findsOneWidget);
      expect(total(tester), 'Rp 15.000');
      expect(find.textContaining('Midtrans'), findsNothing);
      await saveScreenshot(tester, 'pricing_2_payment');

      // Switching to a package changes what is paid for, and the total.
      final package = find.byWidgetPredicate(
        (w) => isPackageOption(w, seeded.productId),
      );
      expect(package, findsWidgets);
      await tester.ensureVisible(package.first);
      await tester.tap(package.first);
      await tester.pumpAndSettle();
      expect(total(tester), isNot('Rp 15.000'));
      await saveScreenshot(tester, 'pricing_3_package_selected');
      await unmount(tester);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  testWidgets(
    'should_offer_nothing_to_buy_to_an_active_subscriber',
    (tester) async {
      await bootApp(tester);
      final session = await registerAndSignIn();
      await backend.grantPremium(session.userId);

      ParentalGateSession.passed = true;
      AppRouter.router.go('/');
      await tester.pumpAndSettle(const Duration(seconds: 2));
      AppRouter.router.push('/premium');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Langganan aktif'), findsOneWidget);
      expect(find.text(AppStrings.btnPayNow), findsNothing);
      await saveScreenshot(tester, 'pricing_4_subscriber');
      await unmount(tester);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
