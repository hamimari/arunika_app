import 'package:arunika_app/core/cart/cart_notifier.dart';
import 'package:arunika_app/data/models/cart.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_cart.dart';

void main() {
  late FakeCartApi api;
  late CartNotifier cart;

  Future<CartNotifier> build({
    bool enabled = true,
    List<CartItem> items = const [],
  }) async {
    api = FakeCartApi(items: items);
    final flags = await flagsWith({'cart': enabled});
    cart = CartNotifier(api, flags, LoggedInAuth());
    await cart.refresh();
    return cart;
  }

  test('is hidden while the flag is off, signed out or subscribed', () async {
    await build(enabled: false);
    expect(cart.enabled, isFalse);

    await build();
    expect(cart.enabled, isTrue);
    cart.setSubscribed(true);
    expect(cart.enabled, isFalse);
  });

  test('add is optimistic and never adds an item twice', () async {
    await build();
    api.catalog['a'] = testItem('a');
    expect(await cart.add(testItem('a')), CartAddResult.added);
    expect(await cart.add(testItem('a')), CartAddResult.added);
    expect(cart.count, 1);
    expect(api.addCalls, 1);
  });

  test('a refused add rolls back and reports why', () async {
    await build();
    api.failNext = 'ALREADY_OWNED';
    expect(await cart.add(testItem('a')), CartAddResult.owned);
    expect(cart.contains('a'), isFalse);

    api.failNext = 'NETWORK';
    expect(await cart.add(testItem('b')), CartAddResult.failed);
    expect(cart.count, 0);
  });

  test('limits: 20 items and Rp 500.000', () async {
    await build(items: [for (var i = 0; i < 20; i++) testItem('i$i')]);
    expect(await cart.add(testItem('x')), CartAddResult.full);
    expect(api.addCalls, 0);

    await build(items: [testItem('big', price: 450000)]);
    expect(cart.canAdd(60000), isFalse);
    expect(
      await cart.add(testItem('x', price: 60000)),
      CartAddResult.totalLimit,
    );
  });

  test('a SUBSCRIPTION_ACTIVE refusal hides the cart', () async {
    await build();
    api.failNext = 'SUBSCRIPTION_ACTIVE';
    expect(await cart.add(testItem('a')), CartAddResult.subscribed);
    expect(cart.enabled, isFalse);
  });

  test('remove can be undone within 5 seconds, not after', () {
    fakeAsync((async) {
      build(items: [testItem('a'), testItem('b')]);
      async.flushMicrotasks();
      api.catalog['a'] = testItem('a');

      cart.remove('a');
      async.flushMicrotasks();
      expect(cart.contains('a'), isFalse);
      expect(cart.lastRemoved?.productId, 'a');

      cart.undo();
      async.flushMicrotasks();
      expect(cart.contains('a'), isTrue);

      cart.remove('b');
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 6));
      expect(cart.lastRemoved, isNull);
    });
  });

  test('a granted order drops only its items and bumps grants', () async {
    await build(items: [testItem('a'), testItem('b'), testItem('c')]);
    cart.onOrderGranted(['a', 'b']);
    expect(cart.cart.items.map((i) => i.productId), ['c']);
    expect(cart.grants.value, 1);
  });

  test('clear rolls back when the server fails', () async {
    await build(items: [testItem('a')]);
    api.failNext = 'NETWORK';
    expect(await cart.clear(), isFalse);
    expect(cart.count, 1);
  });
}
