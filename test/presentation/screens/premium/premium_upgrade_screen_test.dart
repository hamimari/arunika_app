import 'package:arunika_app/data/models/response/subscription_info.dart';
import 'package:arunika_app/data/repositories/premium_pack_repository.dart';
import 'package:arunika_app/data/repositories/profile_loader.dart';
import 'package:arunika_app/data/static/premium_packs.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/presentation/screens/premium/premium_upgrade_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

class _MockPacks extends Mock implements PremiumPackRepository {}

class _MockProfiles extends Mock implements ProfileLoader {}

final _hutan = PremiumPack(
  id: 'pkg-hutan',
  name: 'Paket Hutan',
  subtitle: '8 hewan hutan',
  priceIdr: 79000,
  strikePriceIdr: 99000,
  discountPercent: 20,
  promoEndsAt: DateTime(2026, 10, 31, 12),
);
const _bulanan = PremiumPack(
  id: 'pkg-bulanan',
  name: 'Bulanan',
  subtitle: 'Akses 1 bulan',
  priceIdr: 39000,
  type: 'subscription',
  durationDays: 30,
);

void main() {
  late _MockPacks packs;
  late _MockProfiles profiles;

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('id_ID');
  });

  void register<T extends Object>(T instance) {
    if (locator.isRegistered<T>()) locator.unregister<T>();
    locator.registerSingleton<T>(instance);
  }

  setUp(() {
    packs = _MockPacks();
    profiles = _MockProfiles();
    when(() => packs.fetchPacks(type: 'content')).thenAnswer((_) async => [_hutan]);
    when(() => packs.fetchPacks(type: 'subscription')).thenAnswer((_) async => [_bulanan]);
    when(() => profiles.activeSubscription()).thenAnswer((_) async => null);
    register<PremiumPackRepository>(packs);
    register<ProfileLoader>(profiles);
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: PremiumUpgradeScreen()));
    await tester.pumpAndSettle();
  }

  testWidgets('package cards show the price, strike price, badge and promo end', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Paket Hutan'), findsOneWidget);
    expect(find.text('Rp 79.000'), findsOneWidget);
    expect(find.text('Rp 99.000'), findsOneWidget);
    expect(find.text('-20%'), findsOneWidget);
    expect(find.text('Promo s/d 31 Okt'), findsOneWidget);
  });

  testWidgets('an active subscriber sees no packages or prices', (tester) async {
    when(() => profiles.activeSubscription()).thenAnswer(
      (_) async => SubscriptionInfo(
        planName: 'Tahunan',
        status: 'premium',
        expiresAt: DateTime(2026, 12, 31, 12),
      ),
    );
    await pump(tester);

    expect(find.text('Langganan aktif'), findsOneWidget);
    expect(find.text('Berlaku sampai 31 Des 2026'), findsOneWidget);
    expect(find.text('Paket Hutan'), findsNothing);
    expect(find.text('Rp 79.000'), findsNothing);
  });

  testWidgets('an auto-renewing Play subscriber is told when it renews', (tester) async {
    when(() => profiles.activeSubscription()).thenAnswer(
      (_) async => SubscriptionInfo(
        planName: 'Bulanan',
        status: 'premium',
        expiresAt: DateTime(2026, 10, 31, 12),
        provider: 'google_play',
        autoRenew: true,
      ),
    );
    await pump(tester);

    expect(find.text('Diperpanjang otomatis pada 31 Okt 2026'), findsOneWidget);
    expect(find.text('Perpanjang di Google Play'), findsNothing);
  });

  testWidgets('a cancelled Play subscriber in the window is sent to Google Play', (
    tester,
  ) async {
    when(() => profiles.activeSubscription()).thenAnswer(
      (_) async => SubscriptionInfo(
        planName: 'Bulanan',
        status: 'premium',
        expiresAt: DateTime(2026, 10, 31, 12),
        provider: 'google_play',
        canRenew: true,
        playProductId: 'sub_monthly',
      ),
    );
    await pump(tester);

    expect(find.text('Perpanjang di Google Play'), findsOneWidget);
    expect(find.text('Bulanan'), findsOneWidget, reason: 'plan name only, no packages');
    expect(find.text('Rp 39.000'), findsNothing);
  });

  testWidgets('renewal window: subscriptions only, new period from old expiry', (
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
    await pump(tester);

    expect(
      find.text('Masa aktif baru ditambahkan mulai 31 Okt 2026'),
      findsOneWidget,
    );
    expect(find.text('Rp 39.000'), findsOneWidget);
    expect(find.text('Paket Hutan'), findsNothing);
    verifyNever(() => packs.fetchPacks(type: 'content'));
  });
}
