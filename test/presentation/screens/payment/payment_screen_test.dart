import 'dart:convert';

import 'package:arunika_app/data/models/purchasable_item.dart';
import 'package:arunika_app/data/models/response/subscription_info.dart';
import 'package:arunika_app/data/repositories/order_repository.dart';
import 'package:arunika_app/data/repositories/premium_pack_repository.dart';
import 'package:arunika_app/data/repositories/profile_loader.dart';
import 'package:arunika_app/data/static/premium_packs.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/network/dio_client.dart';
import 'package:arunika_app/presentation/screens/payment/payment_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

class _MockPacks extends Mock implements PremiumPackRepository {}

class _MockProfiles extends Mock implements ProfileLoader {}

class _MockOrders extends Mock implements OrderRepository {}

/// Records requests and answers every one with [statusCode]/[body].
class _RecordingAdapter implements HttpClientAdapter {
  final int statusCode;
  final Map<String, dynamic> body;
  final List<RequestOptions> requests = [];

  _RecordingAdapter(this.statusCode, this.body);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const _hutan = PremiumPack(
  id: 'pkg-hutan',
  name: 'Paket Hutan',
  subtitle: '8 hewan hutan',
  priceIdr: 79000,
  strikePriceIdr: 99000,
  discountPercent: 20,
);
const _bulanan = PremiumPack(
  id: 'pkg-bulanan',
  name: 'Bulanan',
  subtitle: 'Akses 1 bulan',
  priceIdr: 39000,
  type: 'subscription',
  durationDays: 30,
);

final _card = PurchasableItem.fromProduct(
  productId: 'prod-harimau',
  title: 'Harimau',
  priceIdr: 15000,
  contentType: PurchasedContentType.arCard,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockPacks packs;
  late _MockProfiles profiles;

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('id_ID');
    // The auth interceptor reads the token from secure storage.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (_) async => null,
        );
  });

  void register<T extends Object>(T instance) {
    if (locator.isRegistered<T>()) locator.unregister<T>();
    locator.registerSingleton<T>(instance);
  }

  setUp(() {
    packs = _MockPacks();
    profiles = _MockProfiles();
    when(() => packs.fetchPacks()).thenAnswer((_) async => [_hutan, _bulanan]);
    when(() => profiles.activeSubscription()).thenAnswer((_) async => null);
    register<PremiumPackRepository>(packs);
    register<ProfileLoader>(profiles);
    register<OrderRepository>(_MockOrders());
  });

  Future<void> pumpPayment(WidgetTester tester, PurchasableItem item) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: '/payment',
      routes: [
        GoRoute(
          path: '/payment',
          builder: (_, __) => PaymentScreen(item: item),
        ),
        GoRoute(
          path: '/unlock-success',
          builder: (_, __) => const Text('unlocked'),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
  }

  String totalText(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('payment-total'))).data!;

  testWidgets('lists the item and every package, and never mentions Midtrans', (
    tester,
  ) async {
    await pumpPayment(tester, _card);

    expect(find.text('Beli Harimau saja'), findsOneWidget);
    expect(find.text('Paket Hutan'), findsOneWidget);
    expect(find.text('Bulanan'), findsOneWidget);
    expect(totalText(tester), 'Rp 15.000');
    expect(find.textContaining('Midtrans'), findsNothing);
    expect(find.textContaining('Ingin lebih hemat'), findsNothing);
  });

  testWidgets('tapping a package changes the total and shows the savings', (
    tester,
  ) async {
    await pumpPayment(tester, _card);

    await tester.tap(find.byKey(const Key('payment-option-pkg-hutan')));
    await tester.pumpAndSettle();

    expect(totalText(tester), 'Rp 79.000');
    expect(
      tester.widget<Text>(find.byKey(const Key('payment-summary-name'))).data,
      'Paket Hutan',
    );
    expect(
      tester
          .widget<Text>(find.byKey(const Key('payment-summary-savings')))
          .data,
      'Hemat Rp 20.000',
    );
    expect(find.textContaining('Harga normal'), findsNothing);
  });

  testWidgets('when packages fail the item can still be paid for', (tester) async {
    when(() => packs.fetchPacks()).thenThrow(Exception('offline'));
    await pumpPayment(tester, _card);

    expect(find.text('Gagal memuat paket'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
    expect(find.text('Beli Harimau saja'), findsOneWidget);
    expect(totalText(tester), 'Rp 15.000');
    final pay = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Bayar Sekarang 🔒'),
    );
    expect(pay.onPressed, isNotNull);
  });

  testWidgets('an active subscriber sees no options, prices or pay button', (
    tester,
  ) async {
    when(() => profiles.activeSubscription()).thenAnswer(
      (_) async => SubscriptionInfo(
        planName: 'Tahunan',
        status: 'premium',
        expiresAt: DateTime(2026, 12, 31, 12),
      ),
    );
    await pumpPayment(tester, _card);

    expect(find.text('Langganan aktif'), findsOneWidget);
    expect(find.text('Berlaku sampai 31 Des 2026'), findsOneWidget);
    expect(find.text('Bayar Sekarang 🔒'), findsNothing);
    expect(find.text('Rp 15.000'), findsNothing);
  });

  testWidgets('renewal shows the end date stacked on the current one', (
    tester,
  ) async {
    when(() => profiles.activeSubscription()).thenAnswer(
      (_) async => SubscriptionInfo(
        planName: 'Bulanan',
        status: 'premium',
        expiresAt: DateTime(2026, 10, 31, 12),
        canRenew: true,
      ),
    );
    await pumpPayment(tester, PurchasableItem.fromPackage(_bulanan));

    expect(find.text('Paket Hutan'), findsNothing, reason: 'subscriptions only');
    expect(
      tester
          .widget<Text>(find.byKey(const Key('payment-summary-renewal')))
          .data,
      'Aktif sampai 31 Okt 2026 → 30 Nov 2026',
    );
  });

  testWidgets('pays for the selected package; a 409 shows the subscriber state', (
    tester,
  ) async {
    final adapter = _RecordingAdapter(409, {
      'error': 'subscription is already active',
      'code': 'SUBSCRIPTION_ACTIVE',
    });
    final original = DioClient.dio.httpClientAdapter;
    DioClient.dio.httpClientAdapter = adapter;
    addTearDown(() => DioClient.dio.httpClientAdapter = original);

    await pumpPayment(tester, _card);
    await tester.tap(find.byKey(const Key('payment-option-pkg-hutan')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bayar Sekarang 🔒'));
    await tester.pumpAndSettle();

    expect(adapter.requests, hasLength(1));
    expect(adapter.requests.single.path, endsWith('/payment/create'));
    expect(adapter.requests.single.data, {'plan_name': 'Paket Hutan', 'amount': 79000});
    expect(find.text('Langganan aktif'), findsOneWidget);
    expect(find.text('Bayar Sekarang 🔒'), findsNothing);
  });
}
