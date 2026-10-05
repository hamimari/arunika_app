import 'package:arunika_app/core/cart/cart_notifier.dart';
import 'package:arunika_app/data/api/cart_api.dart';
import 'package:arunika_app/data/models/cart.dart';
import 'package:arunika_app/presentation/screens/cart/cart_checkout.dart';
import 'package:arunika_app/presentation/screens/cart/cart_result_screen.dart';
import 'package:arunika_app/presentation/screens/cart/cart_screen.dart';
import 'package:arunika_app/services/billing_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../helpers/fake_billing.dart';
import '../../../helpers/fake_cart.dart';

void main() {
  late FakeCartApi api;
  late CartNotifier cart;
  late FakeBilling billing;
  late bool gatePasses;
  late int gateShown;

  Future<void> pump(WidgetTester tester, List<CartItem> items) async {
    api = FakeCartApi(items: items);
    for (final i in items) {
      api.catalog[i.productId] = i;
    }
    cart = await registerTestCart(
      enabled: true,
      api: api,
      auth: LoggedInAuth(),
    );
    await cart.refresh();
    billing = FakeBilling();
    gatePasses = true;
    gateShown = 0;
    final checkout = CartCheckout(
      api: api,
      cart: cart,
      billing: billing,
      parentalGate: (_) async {
        gateShown++;
        return gatePasses;
      },
    );
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => CartScreen(cart: cart, checkout: checkout),
        ),
        GoRoute(
          path: '/cart/result',
          builder: (_, state) => CartResultScreen(
            args: state.extra as CartResultArgs,
            api: api,
            pollEvery: const Duration(milliseconds: 100),
          ),
        ),
      ],
    );
    // A tall phone, so the whole cart fits without scrolling.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
  }

  tearDown(unregisterTestCart);

  testWidgets('an empty cart shows the empty state with links', (tester) async {
    await pump(tester, []);
    expect(find.text('Keranjangmu masih kosong'), findsOneWidget);
    expect(find.text('Kartu AR'), findsOneWidget);
    expect(find.text('Dongeng'), findsOneWidget);
    expect(find.text('Bayar'), findsNothing);
  });

  testWidgets('lists items with the price breakdown', (tester) async {
    await pump(tester, [
      testItem('a', price: 1000, strike: 2000),
      testItem('b', price: 5000),
      testItem('c', price: 100000, strike: 112000, type: CartItemType.dongeng),
    ]);
    expect(find.text('3 item siap dibayar sekaligus'), findsOneWidget);
    expect(find.text('Harga normal (3 item)'), findsOneWidget);
    expect(find.text('-Rp 13.000'), findsOneWidget);
    expect(find.byKey(const ValueKey('cart-total')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('cart-total'))).data,
      'Rp 106.000',
    );
    expect(
      find.text(
        'Langganan Akses Premium dibeli terpisah, tidak lewat keranjang.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('delete removes at once and Urungkan brings it back', (
    tester,
  ) async {
    await pump(tester, [testItem('a'), testItem('b')]);
    await tester.tap(find.byKey(const ValueKey('cart-delete-a')));
    await tester.pumpAndSettle();
    expect(find.text('Item a'), findsNothing);
    expect(find.text('Item dihapus'), findsOneWidget);

    await tester.tap(find.text('Urungkan'));
    await tester.pumpAndSettle();
    expect(find.text('Item a'), findsOneWidget);
    expect(cart.count, 2);
  });

  testWidgets('Hapus semua asks first', (tester) async {
    await pump(tester, [testItem('a')]);
    await tester.tap(find.text('Hapus semua'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(cart.count, 1);

    await tester.tap(find.text('Hapus semua'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus semua').last);
    await tester.pumpAndSettle();
    expect(cart.count, 0);
    expect(find.text('Keranjangmu masih kosong'), findsOneWidget);
  });

  testWidgets('a child who fails the gate cannot start a payment', (
    tester,
  ) async {
    await pump(tester, [testItem('a')]);
    gatePasses = false;
    await tester.tap(find.text('Bayar'));
    await tester.pumpAndSettle();
    expect(gateShown, 1);
    expect(api.orderKeys, isEmpty);
    expect(billing.cartPurchases, isEmpty);
  });

  testWidgets('Bayar: gate, summary, one payment, Berhasil', (tester) async {
    await pump(tester, [
      testItem('a', price: 1000),
      testItem('b', price: 5000),
    ]);
    await tester.tap(find.text('Bayar'));
    await tester.pumpAndSettle();

    expect(find.text('Ringkasan pembayaran'), findsOneWidget);
    expect(
      find.text('Dibayar lewat Google Play. Sekali bayar, bukan langganan.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Bayar Rp 6.000'));
    await tester.pumpAndSettle();

    expect(billing.cartPurchases.single.playProductId, 'arunika.cart.t6000');
    expect(find.text('Hore, 2 item sudah jadi milikmu!'), findsOneWidget);
    expect(find.text('Buka'), findsNWidgets(2));
    expect(cart.count, 0);
    expect(cart.grants.value, 1);
  });

  testWidgets('a cancelled payment keeps the cart', (tester) async {
    await pump(tester, [testItem('a')]);
    billing.cartOutcome = CartPurchaseOutcome.canceled;
    await tester.tap(find.text('Bayar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bayar Rp 1.000'));
    await tester.pumpAndSettle();

    expect(find.text('Pembayaran dibatalkan'), findsOneWidget);
    expect(find.textContaining('Tidak ada biaya yang ditagih'), findsOneWidget);
    expect(cart.count, 1);
  });

  testWidgets('Kembali ke keranjang does not pay', (tester) async {
    await pump(tester, [testItem('a')]);
    await tester.tap(find.text('Bayar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kembali ke keranjang'));
    await tester.pumpAndSettle();
    expect(billing.cartPurchases, isEmpty);
    expect(find.text('Bayar'), findsOneWidget);
  });

  testWidgets('CART_CHANGED shows what changed and Bayar lagi', (tester) async {
    await pump(tester, [
      testItem('a', price: 1000),
      testItem('b', price: 5000),
    ]);
    api.nextOrderError = CartApiException(
      'CART_CHANGED',
      cart: Cart(
        items: [testItem('a', price: 2000, priceChangedFrom: 1000)],
        notices: const [
          CartNotice(
            code: CartNoticeCode.alreadyOwned,
            productId: 'b',
            title: 'Prophet Yunus',
          ),
        ],
      ),
    );
    await tester.tap(find.text('Bayar'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('cart-changes-banner')), findsOneWidget);
    expect(
      find.textContaining('Prophet Yunus sudah kamu miliki'),
      findsOneWidget,
    );
    expect(find.text('Harga naik dari Rp 1.000'), findsOneWidget);
    expect(find.text('Bayar lagi'), findsOneWidget);
    expect(billing.cartPurchases, isEmpty);
  });

  testWidgets('paid but not granted polls until Berhasil', (tester) async {
    await pump(tester, [testItem('a')]);
    billing.cartOutcome = CartPurchaseOutcome.processing;
    api.phase = OrderPhase.processing;
    await tester.tap(find.text('Bayar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bayar Rp 1.000'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Pembayaranmu sedang kami proses'), findsOneWidget);

    api.phase = OrderPhase.granted;
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('Hore, 1 item sudah jadi milikmu!'), findsOneWidget);
    expect(cart.count, 0);
  });
}
