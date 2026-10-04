import 'package:arunika_app/data/models/purchasable_item.dart';
import 'package:arunika_app/data/static/premium_packs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PremiumPack.fromJson', () {
    test('parses a non-null play_product_id', () {
      final pack = PremiumPack.fromJson({
        'id': 'pkg-1',
        'name': 'Paket Hutan',
        'subtitle': '8 Hewan Hutan',
        'price_idr': 29000,
        'type': 'content',
        'play_product_id': 'pack_hutan_bundle',
      });

      expect(pack.playProductId, 'pack_hutan_bundle');
    });

    test('defaults play_product_id to null when absent', () {
      final pack = PremiumPack.fromJson({
        'id': 'pkg-1',
        'name': 'Paket Hutan',
        'subtitle': '8 Hewan Hutan',
        'price_idr': 29000,
        'type': 'content',
      });

      expect(pack.playProductId, isNull);
    });
  });

  group('PurchasableItem.isPlayBillingEligible', () {
    test('true for a package with a non-empty play_product_id', () {
      const pack = PremiumPack(
        id: 'pkg-1',
        name: 'Paket Hutan',
        subtitle: '8 Hewan Hutan',
        priceIdr: 29000,
        playProductId: 'pack_hutan_bundle',
      );
      final item = PurchasableItem.fromPackage(pack);

      expect(item.isPlayBillingEligible, isTrue);
    });

    test('false for a package with no play_product_id mapping', () {
      const pack = PremiumPack(
        id: 'pkg-1',
        name: 'Paket Hutan',
        subtitle: '8 Hewan Hutan',
        priceIdr: 29000,
      );
      final item = PurchasableItem.fromPackage(pack);

      expect(item.isPlayBillingEligible, isFalse);
    });

    test('false for a single-product purchase even if playProductId were set', () {
      final item = PurchasableItem.fromProduct(
        productId: 'prod-1',
        title: 'Singa',
        priceIdr: 5000,
        contentType: PurchasedContentType.arCard,
      );

      expect(item.isPlayBillingEligible, isFalse);
    });
  });
}
