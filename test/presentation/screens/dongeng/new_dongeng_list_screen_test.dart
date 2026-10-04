import 'package:arunika_app/core/auth/auth_notifier.dart';
import 'package:arunika_app/data/models/response/dongeng_category.dart';
import 'package:arunika_app/data/models/response/dongeng_response.dart';
import 'package:arunika_app/data/repositories/dongeng_history_repository.dart';
import 'package:arunika_app/data/repositories/fairy_tales_repository.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/presentation/screens/dongeng/dongeng_list_bloc.dart';
import 'package:arunika_app/presentation/screens/dongeng/dongeng_list_event.dart';
import 'package:arunika_app/presentation/screens/dongeng/new_dongeng_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:arunika_app/data/models/purchasable_item.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFairyTalesRepository extends Mock implements FairyTalesRepository {}

class MockDongengHistoryRepository extends Mock
    implements DongengHistoryRepository {}

class MockAuthNotifier extends Mock implements AuthNotifier {}

DongengResponse _unlockedStory(String id, String title) => DongengResponse(
  id: id,
  title: title,
  ageStart: 3,
  ageEnd: 6,
  isFree: true,
  imageUrl: 'https://img/$id.png',
  audioUrl: '',
  duration: '5 min',
  pages: const [],
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
  isDeleted: false,
);

DongengResponse _lockedStory(String id, String title) => DongengResponse(
  id: id,
  title: title,
  ageStart: 3,
  ageEnd: 6,
  isFree: false,
  isUnlocked: false,
  imageUrl: 'https://img/$id.png',
  audioUrl: '',
  duration: '5 min',
  pages: const [],
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
  isDeleted: false,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFairyTalesRepository mockRepo;
  late MockAuthNotifier mockAuth;

  setUp(() {
    if (locator.isRegistered<DongengHistoryRepository>()) {
      locator.unregister<DongengHistoryRepository>();
    }
    if (locator.isRegistered<AuthNotifier>()) {
      locator.unregister<AuthNotifier>();
    }

    mockRepo = MockFairyTalesRepository();
    final mockHistoryRepo = MockDongengHistoryRepository();
    mockAuth = MockAuthNotifier();
    when(() => mockAuth.isLoggedIn).thenReturn(false);
    when(
      () => mockRepo.getCategories(),
    ).thenAnswer((_) async => <DongengCategory>[]);

    locator.registerSingleton<DongengHistoryRepository>(mockHistoryRepo);
    locator.registerSingleton<AuthNotifier>(mockAuth);
  });

  tearDown(() {
    if (locator.isRegistered<DongengHistoryRepository>()) {
      locator.unregister<DongengHistoryRepository>();
    }
    if (locator.isRegistered<AuthNotifier>()) {
      locator.unregister<AuthNotifier>();
    }
  });

  Widget buildApp() {
    return MaterialApp(
      home: BlocProvider(
        create: (_) =>
            DongengListBloc(repository: mockRepo)..add(LoadDongengList()),
        child: const NewDongengListScreen(),
      ),
    );
  }

  testWidgets(
    'old "Sudah dibeli saja" chip is gone, replaced by a gear icon',
    (tester) async {
      when(() => mockRepo.findAll()).thenAnswer(
        (_) async => DongengListResult(
          items: [_unlockedStory('1', 'Story A'), _lockedStory('2', 'Story B')],
          total: 2,
          page: 1,
        ),
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
        (_) async => DongengListResult(
          items: [_unlockedStory('1', 'Story A'), _lockedStory('2', 'Story B')],
          total: 2,
          page: 1,
        ),
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
    'selecting Koleksiku and tapping Terapkan filters out locked stories',
    (tester) async {
      when(() => mockRepo.findAll()).thenAnswer(
        (_) async => DongengListResult(
          items: [_unlockedStory('1', 'Story A'), _lockedStory('2', 'Story B')],
          total: 2,
          page: 1,
        ),
      );

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Story A'), findsOneWidget);
      expect(find.text('Story B'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.settings_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Koleksiku'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Terapkan'));
      await tester.pumpAndSettle();

      expect(find.text('Story A'), findsOneWidget);
      expect(find.text('Story B'), findsNothing);
    },
  );

  testWidgets('a locked paid story shows its price and strike price; an owned one does not', (
    tester,
  ) async {
    DongengResponse paid(String id, String title, {required bool owned}) =>
        DongengResponse(
          id: id,
          title: title,
          ageStart: 3,
          ageEnd: 6,
          isFree: false,
          isUnlocked: owned,
          priceIdr: owned ? 25000 : 39000,
          strikePriceIdr: owned ? 30000 : 49000,
          discountPercent: owned ? 17 : 20,
          imageUrl: 'https://img/$id.png',
          audioUrl: '',
          duration: '5 min',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
          isDeleted: false,
        );
    when(() => mockRepo.findAll()).thenAnswer(
      (_) async => DongengListResult(
        items: [
          paid('1', 'Owned Story', owned: true),
          paid('2', 'Locked Story', owned: false),
        ],
        total: 2,
        page: 1,
      ),
    );

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Rp 39.000'), findsWidgets);
    expect(find.text('Rp 49.000'), findsWidgets);
    expect(find.text('Rp 25.000'), findsNothing);
    expect(find.text('Rp 30.000'), findsNothing);
  });

  group('story design', () {
    DongengResponse story(
      String id,
      String title, {
      bool free = false,
      bool owned = false,
      int? price,
      int? strike,
      int? discount,
      String? sku,
    }) => DongengResponse(
      id: id,
      title: title,
      ageStart: 4,
      ageEnd: 8,
      isFree: free,
      isUnlocked: owned || free,
      productId: price == null ? null : 'prod-$id',
      priceIdr: price,
      playProductId: sku,
      strikePriceIdr: strike,
      discountPercent: discount,
      imageUrl: 'https://img/$id.png',
      audioUrl: '',
      duration: '5 min',
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
      isDeleted: false,
    );

    Future<void> pumpList(WidgetTester tester, List<DongengResponse> items) async {
      when(() => mockRepo.findAll()).thenAnswer(
        (_) async => DongengListResult(items: items, total: items.length, page: 1),
      );
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();
    }

    testWidgets('the featured card has the pill, title, meta and a Baca button', (
      tester,
    ) async {
      await pumpList(tester, [story('1', 'Hare and Tortoise', free: true)]);

      expect(find.text('Pilihan minggu ini'), findsOneWidget);
      expect(find.text('Hare and Tortoise'), findsOneWidget);
      expect(find.text('4–8 tahun · 5 min'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Baca'), findsOneWidget);
      expect(find.text('Beli'), findsNothing);
    });

    testWidgets('a locked featured story offers Beli with its price', (
      tester,
    ) async {
      await pumpList(tester, [story('1', 'Hare', price: 50000, sku: 'sku')]);

      expect(find.widgetWithText(ElevatedButton, 'Beli'), findsOneWidget);
      expect(find.text('Rp 50.000'), findsOneWidget);
    });

    testWidgets('a locked row shows lock, Hemat pill, both prices and Beli', (
      tester,
    ) async {
      await pumpList(tester, [
        story('1', 'Featured', free: true),
        story('2', 'Prophet Yunus',
            price: 100000, strike: 112000, discount: 11, sku: 'sku_yunus'),
      ]);

      expect(find.text('Cerita Populer'), findsOneWidget);
      expect(find.text('Prophet Yunus'), findsOneWidget);
      expect(find.text('Hemat 11%'), findsOneWidget);
      final strike = tester.widget<Text>(find.text('Rp 112.000'));
      expect(strike.style?.decoration, TextDecoration.lineThrough);
      expect(find.text('Rp 100.000'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Beli'), findsOneWidget);
    });

    testWidgets('a locked row without a promo has no Hemat pill', (tester) async {
      await pumpList(tester, [
        story('1', 'Featured', free: true),
        story('2', 'Kancil', price: 39000, sku: 'sku'),
      ]);

      expect(find.text('Rp 39.000'), findsOneWidget);
      expect(find.textContaining('Hemat'), findsNothing);
    });

    testWidgets('an owned or free row is compact: Baca, no lock, no price', (
      tester,
    ) async {
      await pumpList(tester, [
        story('1', 'Featured', free: true),
        story('2', 'Owned Story', owned: true, price: 30000, sku: 'sku'),
      ]);

      expect(find.byIcon(Icons.lock_outline_rounded), findsNothing);
      expect(find.text('Rp 30.000'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, 'Baca'), findsNWidgets(2));
      expect(find.text('Beli'), findsNothing);
    });

    testWidgets('Beli opens the purchase with the story and its Play SKU', (
      tester,
    ) async {
      when(() => mockAuth.isLoggedIn).thenReturn(true);
      when(() => mockRepo.findAll()).thenAnswer(
        (_) async => DongengListResult(
          items: [
            story('1', 'Featured', free: true),
            story('2', 'Prophet Yunus', price: 100000, sku: 'sku_yunus'),
          ],
          total: 2,
          page: 1,
        ),
      );
      PurchasableItem? purchase;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => BlocProvider(
              create: (_) =>
                  DongengListBloc(repository: mockRepo)..add(LoadDongengList()),
              child: const NewDongengListScreen(),
            ),
          ),
          GoRoute(
            path: '/payment',
            builder: (_, state) {
              purchase = state.extra as PurchasableItem?;
              return const Scaffold(body: Text('Payment screen'));
            },
          ),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Beli'));
      await tester.pumpAndSettle();

      expect(find.text('Payment screen'), findsOneWidget);
      expect(purchase?.id, 'prod-2');
      expect(purchase?.playProductId, 'sku_yunus');
      expect(purchase?.isDongengPurchase, isTrue);
    });

    testWidgets('a guest tapping Beli is asked to sign in', (tester) async {
      await pumpList(tester, [
        story('1', 'Featured', free: true),
        story('2', 'Prophet Yunus', price: 100000, sku: 'sku'),
      ]);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Beli'));
      await tester.pumpAndSettle();

      expect(find.textContaining('dongeng premium'), findsWidgets);
    });

    testWidgets('fits a narrow phone with enlarged text', (tester) async {
      tester.view.physicalSize = const Size(360 * 3, 780 * 3);
      tester.view.devicePixelRatio = 3;
      tester.platformDispatcher.textScaleFactorTestValue = 1.4;
      addTearDown(() {
        tester.view.reset();
        tester.platformDispatcher.clearAllTestValues();
      });

      await pumpList(tester, [
        story('1', 'Hare and Tortoise', price: 50000, strike: 60000, discount: 17, sku: 's'),
        story('2', 'Prophet Yunus dan Ikan Besar', price: 100000, strike: 112000, discount: 11, sku: 's'),
        story('3', 'Kancil', owned: true, price: 30000, sku: 's'),
      ]);

      expect(tester.takeException(), isNull, reason: 'no RenderFlex overflow');
      expect(find.text('Hemat 11%'), findsOneWidget);
    });

    testWidgets('the filters are still there', (tester) async {
      await pumpList(tester, [story('1', 'Featured', free: true)]);

      expect(find.byIcon(Icons.settings_rounded), findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    });
  });
}
