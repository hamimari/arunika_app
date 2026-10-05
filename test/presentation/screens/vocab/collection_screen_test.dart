import 'package:arunika_app/data/models/response/ar_card_response.dart';
import 'package:arunika_app/data/repositories/ar_repository.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/presentation/screens/vocab/collection_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arunika_app/core/feature_flags/feature_flags_notifier.dart';
import 'package:arunika_app/data/api/feature_flag_api.dart';
import '../../../helpers/fake_cart.dart';

class MockArRepository extends Mock implements ArRepository {}

ArCardResponse _unlockedCard(String id, String title) => ArCardResponse(
  id: id,
  title: title,
  emoji: '🐄',
  imageUrl: '',
  bgColor: '#FFF8E1',
  isUnlocked: true,
);

ArCardResponse _lockedCard(String id, String title) => ArCardResponse(
  id: id,
  title: title,
  emoji: '🐯',
  imageUrl: '',
  bgColor: '#FFF3E0',
  isUnlocked: false,
);

void main() {
  late MockArRepository mockRepo;

  setUp(() async {
    await registerTestCart();
    mockRepo = MockArRepository();
    when(() => mockRepo.getCategories()).thenAnswer((_) async => []);
    if (locator.isRegistered<ArRepository>()) {
      locator.unregister<ArRepository>();
    }
    locator.registerSingleton<ArRepository>(mockRepo);
    // The Kartu AR header reads qr_scan for its scan icon.
    if (locator.isRegistered<FeatureFlagsNotifier>()) {
      locator.unregister<FeatureFlagsNotifier>();
    }
    locator.registerSingleton<FeatureFlagsNotifier>(
      FeatureFlagsNotifier(_NoFlagsApi()),
    );
  });

  tearDown(() {
    unregisterTestCart();
    if (locator.isRegistered<ArRepository>()) {
      locator.unregister<ArRepository>();
    }
    if (locator.isRegistered<FeatureFlagsNotifier>()) {
      locator.unregister<FeatureFlagsNotifier>();
    }
  });

  Widget buildApp() {
    return const MaterialApp(home: CollectionScreen());
  }

  testWidgets(
    'old "Sudah dibeli saja" chip is gone, replaced by a gear icon',
    (tester) async {
      when(() => mockRepo.findAll()).thenAnswer(
        (_) async => [_unlockedCard('1', 'Card A'), _lockedCard('2', 'Card B')],
      );

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Sudah dibeli saja'), findsNothing);
      expect(find.byIcon(Icons.settings_rounded), findsOneWidget);
    },
  );

  testWidgets(
    'tapping the gear icon opens the Filter sheet with Kepemilikan options',
    (tester) async {
      when(() => mockRepo.findAll()).thenAnswer(
        (_) async => [_unlockedCard('1', 'Card A'), _lockedCard('2', 'Card B')],
      );

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.settings_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Filter'), findsOneWidget);
      expect(find.text('Kepemilikan'), findsOneWidget);
      expect(
        find.widgetWithText(RadioListTile<bool>, 'Semua'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(RadioListTile<bool>, 'Koleksiku'),
        findsOneWidget,
      );
      expect(find.text('Terapkan'), findsOneWidget);
    },
  );

  testWidgets(
    'selecting Koleksiku and tapping Terapkan filters out locked cards',
    (tester) async {
      when(() => mockRepo.findAll()).thenAnswer(
        (_) async => [_unlockedCard('1', 'Card A'), _lockedCard('2', 'Card B')],
      );

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Card A'), findsOneWidget);
      expect(find.text('Card B'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.settings_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Koleksiku'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Terapkan'));
      await tester.pumpAndSettle();

      expect(find.text('Card A'), findsOneWidget);
      expect(find.text('Card B'), findsNothing);
    },
  );

  group('scan entry in the Kartu AR header', () {
    Future<void> pumpWithFlags(
      WidgetTester tester,
      Map<String, dynamic> flags,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final api = _NoFlagsApi();
      when(() => api.fetchFlags()).thenAnswer((_) async => flags);
      final notifier = FeatureFlagsNotifier(api);
      await notifier.refresh();
      locator.unregister<FeatureFlagsNotifier>();
      locator.registerSingleton<FeatureFlagsNotifier>(notifier);
      when(() => mockRepo.findAll()).thenAnswer((_) async => []);
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();
    }

    testWidgets('shows the scan icon while qr_scan is on', (tester) async {
      await pumpWithFlags(tester, {'qr_scan': true});
      expect(find.byIcon(Icons.qr_code_scanner_rounded), findsOneWidget);
    });

    testWidgets('hides the scan icon while qr_scan is off', (tester) async {
      await pumpWithFlags(tester, {'qr_scan': false});
      expect(find.byIcon(Icons.qr_code_scanner_rounded), findsNothing);
    });

    testWidgets('no back button when it is the first screen', (tester) async {
      await pumpWithFlags(tester, {});
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsNothing);
    });
  });
  group('Keranjang Belanja', () {
    ArCardResponse paidCard(String id, String title, {bool owned = false}) =>
        ArCardResponse(
          id: id,
          title: title,
          emoji: '🐸',
          imageUrl: '',
          bgColor: '#FFF3E0',
          isUnlocked: owned,
          productId: 'prod-$id',
          priceIdr: 1000,
          strikePriceIdr: 2000,
        );

    testWidgets(
      'a paid card gets the cart button; adding shows the toast and in-cart state',
      (tester) async {
        final api = FakeCartApi();
        final cart = await registerTestCart(
          enabled: true,
          api: api,
          auth: LoggedInAuth(),
        );
        when(() => mockRepo.findAll()).thenAnswer(
          (_) async => [
            paidCard('1', 'Frog'),
            paidCard('2', 'Owned', owned: true),
          ],
        );

        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('cart-toggle-prod-1')),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('cart-toggle-prod-2')), findsNothing);
        expect(find.byKey(const ValueKey('cart-badge')), findsNothing);

        await tester.tap(find.byKey(const ValueKey('cart-toggle-prod-1')));
        await tester.pumpAndSettle();

        expect(cart.contains('prod-1'), isTrue);
        expect(find.text('Ditambahkan ke keranjang'), findsOneWidget);
        expect(find.text('Di keranjang · Lihat'), findsOneWidget);
        expect(find.byKey(const ValueKey('cart-badge')), findsOneWidget);
        expect(find.byIcon(Icons.check_rounded), findsWidgets);

        // Tapping the green button takes it out again.
        await tester.tap(find.byKey(const ValueKey('cart-toggle-prod-1')));
        await tester.pumpAndSettle();
        expect(cart.contains('prod-1'), isFalse);
        expect(find.text('Di keranjang · Lihat'), findsNothing);
        // Let the undo window close.
        await tester.pump(const Duration(seconds: 6));
      },
    );

    testWidgets('no cart controls while the cart flag is off', (tester) async {
      await registerTestCart(enabled: false, auth: LoggedInAuth());
      when(
        () => mockRepo.findAll(),
      ).thenAnswer((_) async => [paidCard('1', 'Frog')]);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('cart-toggle-prod-1')), findsNothing);
      expect(
        find.byIcon(Icons.shopping_cart_outlined),
        findsWidgets,
      ); // the Beli icon only
    });
  });
}

class _NoFlagsApi extends Mock implements FeatureFlagApi {}
