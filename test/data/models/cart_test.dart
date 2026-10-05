import 'package:arunika_app/data/models/cart.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'totals use the strike price as the normal price and skip unavailable items',
    () {
      final cart = Cart.fromJson({
        'items': [
          {
            'product_id': 'a',
            'item_type': 'ar_card',
            'title': 'Frog',
            'price_idr': 1000,
            'strike_price_idr': 2000,
          },
          {
            'product_id': 'b',
            'item_type': 'ar_card',
            'title': 'Kartu',
            'price_idr': 5000,
          },
          {
            'product_id': 'c',
            'item_type': 'dongeng',
            'title': 'Hare and Tortoise',
            'price_idr': 100000,
            'strike_price_idr': 112000,
          },
          {
            'product_id': 'd',
            'item_type': 'dongeng',
            'title': 'Off sale',
            'price_idr': 9000,
            'unavailable': true,
          },
        ],
        'notices': [],
      });

      // The design's example: Rp 119.000 normal, Rp 13.000 promo, Rp 106.000.
      expect(cart.itemCount, 3);
      expect(cart.subtotalIdr, 119000);
      expect(cart.promoSavingIdr, 13000);
      expect(cart.totalIdr, 106000);
      expect(cart.items[2].type, CartItemType.dongeng);
      expect(cart.hasChanges, isFalse);
    },
  );

  test('a notice or a price rise means the parent must look again', () {
    expect(
      Cart.fromJson({
        'items': [],
        'notices': [
          {
            'code': 'ALREADY_OWNED',
            'product_id': 'a',
            'title': 'Prophet Yunus',
          },
        ],
      }).hasChanges,
      isTrue,
    );
    expect(
      Cart.fromJson({
        'items': [
          {
            'product_id': 'a',
            'item_type': 'ar_card',
            'title': 'Frog',
            'price_idr': 2000,
            'price_changed_from': 1000,
          },
        ],
      }).hasChanges,
      isTrue,
    );
  });

  test('order phases map from the backend words', () {
    expect(orderPhaseFromJson('diberikan'), OrderPhase.granted);
    expect(orderPhaseFromJson('diproses'), OrderPhase.processing);
    expect(orderPhaseFromJson('menunggu'), OrderPhase.waiting);
  });
}
