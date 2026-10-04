import 'package:arunika_app/data/models/purchasable_item.dart';
import 'package:arunika_app/data/models/response/ar_card_response.dart';
import 'package:arunika_app/data/models/response/dongeng_response.dart';
import 'package:arunika_app/data/models/response/subscription_info.dart';
import 'package:arunika_app/data/static/premium_packs.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _dongengJson([Map<String, dynamic> extra = const {}]) => {
  'id': 'd1',
  'title': 'Kancil',
  'age_start': 3,
  'age_end': 6,
  'is_free': false,
  'image_url': 'https://x/img.png',
  'created_at': '2026-01-01T00:00:00Z',
  'updated_at': '2026-01-01T00:00:00Z',
  'is_deleted': false,
  'price_idr': 39000,
  ...extra,
};

Map<String, dynamic> _packJson([Map<String, dynamic> extra = const {}]) => {
  'id': 'p1',
  'name': 'Tahunan',
  'subtitle': '12 bulan',
  'price_idr': 299000,
  'type': 'subscription',
  'duration_days': 365,
  ...extra,
};

const _promo = {
  'strike_price_idr': 49000,
  'discount_percent': 20,
  'promo_ends_at': '2026-10-31T16:59:00Z',
};

void main() {
  group('strike price fields', () {
    test('AR card maps them and tolerates their absence', () {
      final card = ArCardResponse.fromJson({'id': 'a1', 'price_idr': 39000, ..._promo});
      expect(card.strikePriceIdr, 49000);
      expect(card.discountPercent, 20);
      expect(card.promoEndsAt, DateTime.utc(2026, 10, 31, 16, 59));

      final plain = ArCardResponse.fromJson({'id': 'a2', 'strike_price_idr': null});
      expect(plain.strikePriceIdr, isNull);
      expect(plain.promoEndsAt, isNull);
    });

    test('dongeng maps them and tolerates their absence', () {
      final d = DongengResponse.fromJson(_dongengJson(_promo));
      expect(d.strikePriceIdr, 49000);
      expect(d.discountPercent, 20);
      expect(d.promoEndsAt, isNotNull);
      expect(DongengResponse.fromJson(_dongengJson()).strikePriceIdr, isNull);
    });

    test('premium pack maps them plus duration_days', () {
      final pack = PremiumPack.fromJson(_packJson(_promo));
      expect(pack.strikePriceIdr, 49000);
      expect(pack.discountPercent, 20);
      expect(pack.promoEndsAt, isNotNull);
      expect(pack.durationDays, 365);
      expect(pack.isSubscription, isTrue);

      final plain = PremiumPack.fromJson(_packJson());
      expect(plain.strikePriceIdr, isNull);
      expect(plain.discountPercent, isNull);
      expect(plain.promoEndsAt, isNull);
    });

    test('a package purchase carries the promo and savings through', () {
      final item = PurchasableItem.fromPackage(
        PremiumPack.fromJson(_packJson({..._promo, 'price_idr': 39000})),
      );
      expect(item.strikePriceIdr, 49000);
      expect(item.savingsIdr, 10000);
      expect(item.durationDays, 365);
      expect(item.priceRaw, 39000, reason: 'the strike price is never charged');
    });

    test('no savings without a strike price', () {
      final item = PurchasableItem.fromProduct(
        productId: 'prod-1',
        title: 'Harimau',
        priceIdr: 15000,
        contentType: PurchasedContentType.arCard,
      );
      expect(item.savingsIdr, isNull);
    });
  });

  group('SubscriptionInfo renewal fields', () {
    test('maps provider, auto-renew and the renewal window', () {
      final sub = SubscriptionInfo.fromJson({
        'plan_name': 'Bulanan',
        'status': 'premium',
        'expires_at': '2026-10-31T00:00:00Z',
        'provider': 'google_play',
        'auto_renew': true,
        'renewable_from': '2026-10-24T00:00:00Z',
        'can_renew': false,
        'play_product_id': 'sub_monthly',
      });
      expect(sub.isGooglePlay, isTrue);
      expect(sub.autoRenew, isTrue);
      expect(sub.renewableFrom, DateTime.utc(2026, 10, 24));
      expect(sub.canRenew, isFalse);
      expect(sub.playProductId, 'sub_monthly');
    });

    test('defaults when an older backend omits them', () {
      final sub = SubscriptionInfo.fromJson({'plan_name': 'Bulanan', 'status': 'premium'});
      expect(sub.provider, 'midtrans');
      expect(sub.autoRenew, isFalse);
      expect(sub.canRenew, isFalse);
      expect(SubscriptionInfo.fromJson(sub.toJson()).provider, 'midtrans');
    });
  });
}
