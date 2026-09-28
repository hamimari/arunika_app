import 'package:arunika_app/data/models/purchasable_item.dart';
import 'package:arunika_app/data/models/response/subscription_info.dart';
import 'package:arunika_app/data/repositories/premium_pack_repository.dart';
import 'package:arunika_app/data/repositories/profile_loader.dart';
import 'package:arunika_app/data/static/premium_packs.dart';
import 'package:arunika_app/presentation/screens/payment/payment_options_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPacks extends Mock implements PremiumPackRepository {}

class _MockProfiles extends Mock implements ProfileLoader {}

const _hutan = PremiumPack(
  id: 'pkg-hutan',
  name: 'Paket Hutan',
  subtitle: '8 hewan',
  priceIdr: 79000,
  strikePriceIdr: 99000,
  discountPercent: 20,
  playProductId: 'pack_hutan',
);
const _bulanan = PremiumPack(
  id: 'pkg-bulanan',
  name: 'Bulanan',
  subtitle: '1 bulan',
  priceIdr: 39000,
  type: 'subscription',
  durationDays: 30,
  playProductId: 'sub_monthly',
);
const _tahunan = PremiumPack(
  id: 'pkg-tahunan',
  name: 'Tahunan',
  subtitle: '12 bulan',
  priceIdr: 299000,
  type: 'subscription',
  durationDays: 365,
  playProductId: 'sub_annual',
);

final _card = PurchasableItem.fromProduct(
  productId: 'prod-harimau',
  title: 'Harimau',
  priceIdr: 15000,
  contentType: PurchasedContentType.arCard,
  playProductId: 'card_harimau',
);

// Not mapped to a Google Play product, so not sold.
const _unmapped = PremiumPack(
  id: 'pkg-unmapped',
  name: 'Paket Lama',
  subtitle: 'Belum di Play',
  priceIdr: 29000,
);

void main() {
  late _MockPacks packs;
  late _MockProfiles profiles;

  setUp(() {
    packs = _MockPacks();
    profiles = _MockProfiles();
    when(() => packs.fetchPacks()).thenAnswer((_) async => [_hutan, _bulanan, _tahunan]);
    when(() => profiles.activeSubscription()).thenAnswer((_) async => null);
  });

  PaymentOptionsCubit build(PurchasableItem entry, {bool play = true}) =>
      PaymentOptionsCubit(
        entry: entry,
        packs: packs,
        profiles: profiles,
        playBillingAvailable: play,
      );

  test('a single product is listed first and preselected, then every package', () async {
    final cubit = build(_card);
    await cubit.load();

    expect(cubit.state.status, PaymentOptionsStatus.ready);
    expect(cubit.state.options.map((o) => o.id), [
      'prod-harimau',
      'pkg-hutan',
      'pkg-bulanan',
      'pkg-tahunan',
    ]);
    expect(cubit.state.selected.id, 'prod-harimau');
    await cubit.close();
  });

  test('selecting a package makes it what gets paid for', () async {
    final cubit = build(_card);
    await cubit.load();

    cubit.select(cubit.state.packages.first);

    expect(cubit.state.selected.id, 'pkg-hutan');
    expect(cubit.state.selected.priceRaw, 79000);
    expect(cubit.state.selected.savingsIdr, 20000);
    await cubit.close();
  });

  test('opened for a package: no single item, that package preselected', () async {
    final cubit = build(PurchasableItem.fromPackage(_tahunan));
    await cubit.load();

    expect(cubit.state.singleItem, isNull);
    expect(cubit.state.selected.id, 'pkg-tahunan');
    await cubit.close();
  });

  test('selection is frozen while a payment is being started', () async {
    final cubit = build(_card);
    await cubit.load();

    cubit.setLocked(true);
    cubit.select(cubit.state.packages.first);

    expect(cubit.state.selected.id, 'prod-harimau');
    await cubit.close();
  });

  test('when packages fail, the entry item stays payable and can retry', () async {
    when(() => packs.fetchPacks()).thenThrow(Exception('offline'));
    final cubit = build(_card);
    await cubit.load();

    expect(cubit.state.packagesFailed, isTrue);
    expect(cubit.state.options.map((o) => o.id), ['prod-harimau']);
    expect(cubit.state.selected.id, 'prod-harimau');

    when(() => packs.fetchPacks()).thenAnswer((_) async => [_hutan]);
    await cubit.loadPackages();
    expect(cubit.state.packagesFailed, isFalse);
    expect(cubit.state.packages.single.id, 'pkg-hutan');
    await cubit.close();
  });

  test('an active subscriber outside the window is offered nothing', () async {
    when(() => profiles.activeSubscription()).thenAnswer(
      (_) async => SubscriptionInfo(
        planName: 'Bulanan',
        status: 'premium',
        expiresAt: DateTime(2026, 12, 31),
      ),
    );
    final cubit = build(_card);
    await cubit.load();

    expect(cubit.state.status, PaymentOptionsStatus.subscribed);
    verifyNever(() => packs.fetchPacks());
    await cubit.close();
  });

  test('a Google Play subscriber inside the window renews in Play, not here', () async {
    when(() => profiles.activeSubscription()).thenAnswer(
      (_) async => SubscriptionInfo(
        planName: 'Bulanan',
        status: 'premium',
        expiresAt: DateTime(2026, 10, 31),
        provider: 'google_play',
        canRenew: true,
      ),
    );
    final cubit = build(PurchasableItem.fromPackage(_bulanan));
    await cubit.load();

    expect(cubit.state.status, PaymentOptionsStatus.subscribed);
    await cubit.close();
  });

  test('renewal: only subscriptions, current plan preselected, end date stacks', () async {
    when(() => profiles.activeSubscription()).thenAnswer(
      (_) async => SubscriptionInfo(
        planName: 'Bulanan',
        status: 'premium',
        expiresAt: DateTime(2026, 10, 31),
        canRenew: true,
      ),
    );
    final cubit = build(_card);
    await cubit.load();

    expect(cubit.state.renewing, isTrue);
    expect(cubit.state.singleItem, isNull);
    expect(cubit.state.options.map((o) => o.id), ['pkg-bulanan', 'pkg-tahunan']);
    expect(cubit.state.selected.id, 'pkg-bulanan');
    expect(cubit.state.renewedUntil, DateTime(2026, 11, 30));

    cubit.select(cubit.state.packages.last);
    expect(cubit.state.renewedUntil, DateTime(2027, 10, 31));
    await cubit.close();
  });

  test('a 409 from the backend switches to the subscriber state', () async {
    final cubit = build(_card);
    await cubit.load();
    cubit.setLocked(true);

    cubit.markSubscriptionActive();

    expect(cubit.state.status, PaymentOptionsStatus.subscribed);
    expect(cubit.state.locked, isFalse);
    await cubit.close();
  });

  test('packages without a Google Play product are not offered', () async {
    when(() => packs.fetchPacks()).thenAnswer((_) async => [_hutan, _unmapped]);
    final cubit = build(_card);
    await cubit.load();

    expect(cubit.state.packages.map((p) => p.id), ['pkg-hutan']);
    await cubit.close();
  });

  test('an unmapped single product is shown but can\'t be bought', () async {
    final unmappedCard = PurchasableItem.fromProduct(
      productId: 'prod-lama',
      title: 'Kartu Lama',
      priceIdr: 15000,
      contentType: PurchasedContentType.arCard,
    );
    final cubit = build(unmappedCard);
    await cubit.load();

    expect(cubit.state.singleItem?.id, 'prod-lama');
    expect(cubit.state.selectedPurchasable, isFalse);

    cubit.select(cubit.state.packages.first);
    expect(cubit.state.selectedPurchasable, isTrue, reason: 'a package can still be chosen');
    cubit.select(unmappedCard);
    expect(cubit.state.selected.id, 'pkg-hutan', reason: 'the unmapped item can\'t be selected');
    await cubit.close();
  });

  test('nothing is sold where Google Play Billing is unavailable (iOS, web)', () async {
    final cubit = build(_card, play: false);
    await cubit.load();

    expect(cubit.state.status, PaymentOptionsStatus.unavailable);
    verifyNever(() => packs.fetchPacks());
    await cubit.close();
  });

  test('a 403 from the backend switches to the unavailable state', () async {
    final cubit = build(_card);
    await cubit.load();

    cubit.markUnavailable();

    expect(cubit.state.status, PaymentOptionsStatus.unavailable);
    await cubit.close();
  });
}
