import 'package:arunika_app/core/auth/auth_notifier.dart';
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
          builder: (_, __) => const Scaffold(body: Text('Payment screen')),
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
}
