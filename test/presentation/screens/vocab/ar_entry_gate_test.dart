import 'package:arunika_app/core/auth/auth_notifier.dart';
import 'package:arunika_app/data/models/purchasable_item.dart';
import 'package:arunika_app/data/models/response/ar_card_response.dart';
import 'package:arunika_app/data/repositories/ar_repository.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/presentation/screens/vocab/collection_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockArRepository extends Mock implements ArRepository {}

// Follows the convention already used in auth_guard_test.dart: extending
// Mock satisfies the rest of AuthNotifier's surface, so this stub only has to
// state the one thing the gate actually reads.
class _StubAuthNotifier extends Mock implements AuthNotifier {
  _StubAuthNotifier(this._loggedIn);
  final bool _loggedIn;

  @override
  bool get isLoggedIn => _loggedIn;
}

ArCardResponse _card({
  required String id,
  required String title,
  required bool unlocked,
  String? productId,
  int? priceIdr,
  int? strikePriceIdr,
  int? discountPercent,
  String? playProductId,
}) => ArCardResponse(
  id: id,
  title: title,
  emoji: '🐯',
  imageUrl: '',
  bgColor: '#FFF3E0',
  isUnlocked: unlocked,
  productId: productId,
  priceIdr: priceIdr,
  strikePriceIdr: strikePriceIdr,
  discountPercent: discountPercent,
  playProductId: playProductId,
);

/// The automatable half of AR testing, per the strategy's AR split.
///
/// What a camera does with a printed card — surface detection, tracking
/// stability, 3D placement — cannot be verified on an emulator, and a test
/// claiming to do so would pass or fail for reasons unrelated to this code.
/// What *can* be verified deterministically is the decision made before any
/// of that starts: whether this user is allowed into the AR experience at
/// all. That gate is the one with money behind it.
void main() {
  late _MockArRepository repo;
  // What the payment route was opened with.
  PurchasableItem? lastPurchase;

  void useAuth({required bool loggedIn}) {
    if (locator.isRegistered<AuthNotifier>()) {
      locator.unregister<AuthNotifier>();
    }
    locator.registerSingleton<AuthNotifier>(_StubAuthNotifier(loggedIn));
  }

  setUp(() {
    repo = _MockArRepository();
    when(() => repo.getCategories()).thenAnswer((_) async => []);
    if (locator.isRegistered<ArRepository>()) {
      locator.unregister<ArRepository>();
    }
    locator.registerSingleton<ArRepository>(repo);
  });

  tearDown(() {
    if (locator.isRegistered<ArRepository>()) {
      locator.unregister<ArRepository>();
    }
    if (locator.isRegistered<AuthNotifier>()) {
      locator.unregister<AuthNotifier>();
    }
  });

  Future<void> pumpCollection(WidgetTester tester) async {
    // The default 800x600 test surface puts grid items below the fold, where
    // a tap silently misses. A taller surface keeps the tests about the gate
    // rather than about scroll position.
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // goToProductPurchase pushes '/payment' via GoRouter, so a signed-in
    // user tapping a locked card needs a real router in the tree, not a bare
    // MaterialApp — otherwise that path throws "No GoRouter found in
    // context" instead of exercising the gate.
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => const CollectionScreen()),
        GoRoute(
          path: '/payment',
          builder: (_, state) {
            lastPurchase = state.extra as PurchasableItem?;
            return const Scaffold(body: Text('Payment screen'));
          },
        ),
        // Reached only as a fallback: goToProductPurchase routes here
        // instead of /payment when a card is missing a linked product or
        // price — a stale-cache case this suite does not otherwise exercise.
        GoRoute(
          path: '/premium',
          builder: (_, __) => const Scaffold(body: Text('Premium screen')),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
  }

  Future<void> tapCard(WidgetTester tester, String title) async {
    final card = find.text(title);
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    await tester.tap(card);
    await tester.pumpAndSettle();
  }

  testWidgets('should_open_the_card_when_the_user_owns_it', (tester) async {
    useAuth(loggedIn: true);
    when(() => repo.findAll()).thenAnswer(
      (_) async => [_card(id: '1', title: 'Harimau', unlocked: true)],
    );

    await pumpCollection(tester);
    await tapCard(tester, 'Harimau');

    // Reaching the detail screen is what "entering AR" means here; the
    // camera work beyond it is out of scope for an automated test.
    expect(find.text('Harimau'), findsWidgets);
  });

  testWidgets('should_ask_an_anonymous_user_to_sign_in_rather_than_to_pay',
      (tester) async {
    useAuth(loggedIn: false);
    when(() => repo.findAll()).thenAnswer(
      (_) async => [_card(id: '2', title: 'Singa', unlocked: false)],
    );

    await pumpCollection(tester);
    await tapCard(tester, 'Singa');

    // Sending a signed-out user straight to checkout would ask them to buy
    // something they may already own on another device.
    expect(find.textContaining('koleksi kartu AR'), findsWidgets);
  });

  testWidgets('should_not_open_a_locked_card_for_a_signed_in_user',
      (tester) async {
    useAuth(loggedIn: true);
    when(() => repo.findAll()).thenAnswer(
      (_) async => [
        _card(
          id: '3',
          title: 'Gajah',
          unlocked: false,
          productId: 'prod-3',
          priceIdr: 25000,
        ),
      ],
    );

    await pumpCollection(tester);
    await tapCard(tester, 'Gajah');

    // The gate must hold: a locked card must never open the AR experience
    // for a signed-in user either — it must route to purchase instead.
    expect(find.byType(CollectionScreen), findsNothing);
    expect(find.text('Payment screen'), findsOneWidget);
  });

  testWidgets('should_distinguish_owned_from_unowned_cards_in_the_grid',
      (tester) async {
    useAuth(loggedIn: true);
    when(() => repo.findAll()).thenAnswer(
      (_) async => [
        _card(id: '1', title: 'Harimau', unlocked: true),
        _card(id: '2', title: 'Singa', unlocked: false),
      ],
    );

    await pumpCollection(tester);

    // Both are listed — locked cards are shown, not hidden, so the catalogue
    // is browsable before purchase.
    expect(find.text('Harimau'), findsOneWidget);
    expect(find.text('Singa'), findsOneWidget);
  });

  testWidgets('should_show_price_and_strike_price_only_on_locked_cards',
      (tester) async {
    useAuth(loggedIn: true);
    when(() => repo.findAll()).thenAnswer(
      (_) async => [
        _card(
          id: '1',
          title: 'Harimau',
          unlocked: true,
          productId: 'prod-1',
          priceIdr: 30000,
        ),
        _card(
          id: '2',
          title: 'Singa',
          unlocked: false,
          productId: 'prod-2',
          priceIdr: 15000,
          strikePriceIdr: 19000,
        ),
      ],
    );

    await pumpCollection(tester);

    expect(find.text('Rp 15.000'), findsOneWidget);
    final strike = tester.widget<Text>(find.text('Rp 19.000'));
    expect(strike.style?.decoration, TextDecoration.lineThrough);
    // An owned card is never priced.
    expect(find.text('Rp 30.000'), findsNothing);
  });

  group('card design', () {
    bool greyscale(WidgetTester tester) => tester
        .widgetList<ColorFiltered>(find.byType(ColorFiltered))
        .any((w) => w.colorFilter.toString().contains('matrix'));

    testWidgets('should_show_a_locked_card_with_price_promo_badge_and_Beli',
        (tester) async {
      useAuth(loggedIn: true);
      when(() => repo.findAll()).thenAnswer(
        (_) async => [
          _card(
            id: '2',
            title: 'Frog',
            unlocked: false,
            productId: 'prod-2',
            priceIdr: 15000,
            strikePriceIdr: 30000,
            discountPercent: 50,
          ),
        ],
      );

      await pumpCollection(tester);

      expect(find.text('Rp 15.000'), findsOneWidget);
      expect(find.text('Rp 30.000'), findsOneWidget);
      expect(find.text('-50%'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Beli'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
      expect(greyscale(tester), isTrue, reason: 'a locked picture is greyscale');
      expect(find.text('Dimiliki'), findsNothing);
    });

    testWidgets('should_not_show_a_promo_badge_without_a_strike_price',
        (tester) async {
      useAuth(loggedIn: true);
      when(() => repo.findAll()).thenAnswer(
        (_) async => [
          _card(
            id: '2',
            title: 'Frog',
            unlocked: false,
            productId: 'prod-2',
            priceIdr: 20000,
          ),
        ],
      );

      await pumpCollection(tester);

      expect(find.text('Rp 20.000'), findsOneWidget);
      expect(find.textContaining('%'), findsNothing);
    });

    testWidgets('should_open_the_purchase_from_Beli_with_the_play_sku',
        (tester) async {
      useAuth(loggedIn: true);
      when(() => repo.findAll()).thenAnswer(
        (_) async => [
          _card(
            id: '2',
            title: 'Frog',
            unlocked: false,
            productId: 'prod-2',
            priceIdr: 15000,
            playProductId: 'sku_frog',
          ),
        ],
      );

      await pumpCollection(tester);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Beli'));
      await tester.pumpAndSettle();

      expect(find.text('Payment screen'), findsOneWidget);
      expect(lastPurchase?.id, 'prod-2');
      expect(lastPurchase?.playProductId, 'sku_frog',
          reason: 'without the SKU the item can never be bought through Play');
    });

    testWidgets('should_ask_a_guest_to_sign_in_from_Beli', (tester) async {
      useAuth(loggedIn: false);
      when(() => repo.findAll()).thenAnswer(
        (_) async => [
          _card(id: '2', title: 'Frog', unlocked: false, productId: 'p', priceIdr: 15000),
        ],
      );

      await pumpCollection(tester);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Beli'));
      await tester.pumpAndSettle();

      expect(find.textContaining('koleksi kartu AR'), findsWidgets);
      expect(find.text('Payment screen'), findsNothing);
    });

    testWidgets('should_show_an_owned_card_in_colour_with_Buka_AR',
        (tester) async {
      useAuth(loggedIn: true);
      when(() => repo.findAll()).thenAnswer(
        (_) async => [
          _card(
            id: '1',
            title: 'Frog',
            unlocked: true,
            productId: 'prod-1',
            priceIdr: 30000,
          ),
        ],
      );

      await pumpCollection(tester);

      expect(find.text('Dimiliki'), findsOneWidget);
      expect(find.text('Sudah jadi milikmu'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Buka AR'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline_rounded), findsNothing);
      expect(find.text('Rp 30.000'), findsNothing);
      expect(find.widgetWithText(ElevatedButton, 'Beli'), findsNothing);
      expect(greyscale(tester), isFalse, reason: 'an owned picture keeps its colours');
    });

    testWidgets('should_fit_a_narrow_phone_with_enlarged_text', (tester) async {
      useAuth(loggedIn: true);
      when(() => repo.findAll()).thenAnswer(
        (_) async => [
          _card(
            id: '1',
            title: 'Frog with a very long name indeed',
            unlocked: false,
            productId: 'p1',
            priceIdr: 1000,
            strikePriceIdr: 2000,
            discountPercent: 50,
          ),
          _card(id: '2', title: 'Owned Frog', unlocked: true),
        ],
      );
      await pumpCollection(tester);
      tester.view.physicalSize = const Size(360 * 3, 780 * 3);
      tester.view.devicePixelRatio = 3;
      tester.platformDispatcher.textScaleFactorTestValue = 1.4;
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'no RenderFlex overflow');
      expect(find.text('-50%'), findsOneWidget);
    });

    testWidgets('should_open_the_card_from_Buka_AR', (tester) async {
      useAuth(loggedIn: true);
      when(() => repo.findAll()).thenAnswer(
        (_) async => [_card(id: '1', title: 'Frog', unlocked: true)],
      );

      await pumpCollection(tester);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Buka AR'));
      await tester.pumpAndSettle();

      expect(find.byType(CollectionScreen), findsNothing,
          reason: 'the card detail screen opened');
    });
  });
}
