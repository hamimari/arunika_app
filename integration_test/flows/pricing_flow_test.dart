import 'package:arunika_app/constants/app_strings.dart';
import 'package:arunika_app/core/utils/parental_gate_session.dart';
import 'package:arunika_app/presentation/navigation/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arunika_app/presentation/screens/unlock_success/unlock_success_screen.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/belajar.dart';
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
      await openBelajar(tester, AppStrings.navCollection);
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
      // The seeded card has no Google Play product, so it isn't sold here —
      // only Play-mapped packages are (alternative billing is off).
      expect(find.text('Belum tersedia di perangkat ini'), findsOneWidget);
      expect(find.text(AppStrings.btnPayNow), findsNothing);
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
      expect(find.text(AppStrings.btnPayNow), findsOneWidget,
          reason: 'a Play-mapped package can be bought');
      await saveScreenshot(tester, 'pricing_3_package_selected');
      await unmount(tester);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  testWidgets(
    'should_buy_a_mapped_locked_card_from_the_collection_through_google_play',
    (tester) async {
      final title = 'Kartu Beli ${DateTime.now().microsecondsSinceEpoch}';
      await backend.seedPaidArCard(
        title: title,
        priceIdr: 15000,
        playProductId: 'sku_${DateTime.now().microsecondsSinceEpoch}',
      );

      await bootApp(tester); // FakeBilling: Google Play "succeeds"
      await registerAndSignIn();
      AppRouter.router.go('/');
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await openBelajar(tester, AppStrings.navCollection);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // The tile: greyscale picture, lock, price and a Beli button.
      await scrollToText(tester, title);
      await saveScreenshot(tester, 'buy_1_locked_tile');

      ParentalGateSession.passed = true;
      await tester.tap(find.text(title));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // The item carries its Play SKU from the list, so it is purchasable.
      expect(find.text('Beli $title saja'), findsOneWidget);
      expect(find.text('Belum tersedia di perangkat ini'), findsNothing);
      expect(find.text(AppStrings.btnPayNow), findsOneWidget);
      await saveScreenshot(tester, 'buy_2_payment');

      await tester.tap(find.text(AppStrings.btnPayNow));
      // Bounded pumps: the unlock screen animates forever in the full app,
      // so pumpAndSettle() would never return.
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(UnlockSuccessScreen), findsOneWidget);
      await unmount(tester);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  testWidgets(
    'should_show_a_locked_dongeng_with_its_promo_price_and_a_Beli_button',
    (tester) async {
      final title = 'Dongeng Promo ${DateTime.now().microsecondsSinceEpoch}';
      await backend.seedPaidDongeng(title: title, priceIdr: 100000, playProductId: 'sku_tale');
      await backend.setStrikeRule(
        'DONGENG',
        mode: 'PERCENT',
        value: 10,
        endsAt: DateTime.now().add(const Duration(days: 7)),
      );
      addTearDown(() => backend.clearStrikeRule('DONGENG'));

      // The app only loads the first page (10 stories, oldest first), so on
      // a stack that has accumulated more, a new story is never listed.
      if (!(await backend.firstPageDongengTitles()).contains(title)) {
        markTestSkipped(
          'the stack has more than 10 dongeng; the app only shows the first page',
        );
        return;
      }

      await bootApp(tester);
      await registerAndSignIn();
      AppRouter.router.go('/');
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await openBelajar(tester, AppStrings.navDongeng);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.scrollUntilVisible(
        find.text(title),
        300,
        scrollable: find
            .descendant(
              of: find.byType(SingleChildScrollView),
              matching: find.byType(Scrollable),
            )
            .first,
        maxScrolls: 100,
      );
      await tester.pumpAndSettle();

      // A 10% rule on Rp 100.000: the crossed-out price is rounded up to
      // Rp 112.000, which is a real saving of 11%.
      expect(find.text('Hemat 11%'), findsWidgets);
      expect(find.text('Rp 100.000'), findsWidgets);
      expect(find.text('Rp 112.000'), findsWidgets);
      expect(find.widgetWithText(ElevatedButton, 'Beli'), findsWidgets);
      await saveScreenshot(tester, 'dongeng_1_list');
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
