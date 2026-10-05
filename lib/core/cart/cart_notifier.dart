import 'dart:async';

import 'package:arunika_app/core/auth/auth_notifier.dart';
import 'package:arunika_app/core/cart/cart_events.dart';
import 'package:arunika_app/core/feature_flags/feature_flags_notifier.dart';
import 'package:arunika_app/core/logger/app_logger.dart';
import 'package:arunika_app/data/api/cart_api.dart';
import 'package:arunika_app/data/models/cart.dart';
import 'package:flutter/foundation.dart';

/// What happened to an add-to-cart tap.
enum CartAddResult {
  added,
  full,
  totalLimit,
  owned,
  notForSale,
  subscribed,
  failed,
}

/// The parent's cart, mirrored from GET /cart and shared by the list
/// badges, the "Di keranjang" state on cards and the Keranjang screen.
///
/// Adds and removes are optimistic: the UI changes at once and rolls back if
/// the server refuses. A removal can be undone for [undoWindow] by adding
/// the item again.
class CartNotifier extends ChangeNotifier {
  static const maxItems = 20;
  static const maxTotalIdr = 500000;

  final CartApi _api;
  final FeatureFlagsNotifier _flags;
  final AuthNotifier _auth;
  final Duration undoWindow;

  CartNotifier(
    this._api,
    this._flags,
    this._auth, {
    this.undoWindow = const Duration(seconds: 5),
  }) {
    _flags.addListener(notifyListeners);
    _auth.addListener(_onAuthChanged);
  }

  Cart _cart = Cart.empty;
  bool _subscribed = false;

  /// Bumped whenever a cart order is granted, so the Kartu AR and Dongeng
  /// lists reload and show the new items as owned.
  final ValueNotifier<int> grants = ValueNotifier(0);
  CartItem? _lastRemoved;
  Timer? _undoTimer;

  Cart get cart => _cart;
  int get count => _cart.items.length;
  bool contains(String productId) => _cart.contains(productId);

  /// Cart controls are shown only while the backoffice flag is on, the
  /// parent is signed in and has no Akses Premium (which already includes
  /// everything the cart sells).
  bool get enabled => _flags.cartEnabled && _auth.isLoggedIn && !_subscribed;

  /// Whether another item may be added (shows "Keranjang penuh" otherwise).
  bool canAdd(int priceIdr) =>
      count < maxItems && _cart.totalIdr + priceIdr <= maxTotalIdr;

  /// The item removed last, while its undo is still offered.
  CartItem? get lastRemoved => _lastRemoved;

  void setSubscribed(bool subscribed) {
    if (_subscribed == subscribed) return;
    _subscribed = subscribed;
    if (subscribed) _cart = Cart.empty;
    notifyListeners();
  }

  void _onAuthChanged() {
    if (!_auth.isLoggedIn) {
      _cart = Cart.empty;
      _subscribed = false;
      notifyListeners();
    } else {
      unawaited(refresh());
    }
  }

  void _set(Cart cart) {
    _cart = cart;
    if (cart.notices.any((n) => n.code == CartNoticeCode.subscriptionActive)) {
      _subscribed = true;
    }
    notifyListeners();
  }

  /// Loads the cart from the server. Failures keep what is shown.
  Future<void> refresh() async {
    if (!_auth.isLoggedIn || !_flags.cartEnabled) return;
    try {
      _set(await _api.fetchCart());
    } catch (e) {
      AppLogger.warning('Could not load the cart', name: 'Cart', error: e);
    }
  }

  /// Replaces the cart with one the server sent back (CART_CHANGED).
  void applyServerCart(Cart cart) => _set(cart);

  Future<CartAddResult> add(CartItem item) async {
    if (contains(item.productId)) return CartAddResult.added;
    if (_subscribed) return CartAddResult.subscribed;
    if (count >= maxItems) return CartAddResult.full;
    if (_cart.totalIdr + item.priceIdr > maxTotalIdr) {
      return CartAddResult.totalLimit;
    }
    final before = _cart;
    _cart = _cart.copyWith(items: [..._cart.items, item], notices: const []);
    notifyListeners();
    try {
      _set(await _api.addItem(item.productId));
      CartEvents.log(
        CartEvents.add,
        productIds: [item.productId],
        itemCount: count,
        totalIdr: _cart.totalIdr,
      );
      return CartAddResult.added;
    } on CartApiException catch (e) {
      _cart = before;
      notifyListeners();
      switch (e.code) {
        case 'CART_FULL':
          return CartAddResult.full;
        case 'CART_TOTAL_LIMIT':
          return CartAddResult.totalLimit;
        case 'ALREADY_OWNED':
          return CartAddResult.owned;
        case 'SUBSCRIPTION_ACTIVE':
          setSubscribed(true);
          return CartAddResult.subscribed;
        default:
          return CartAddResult.notForSale;
      }
    } catch (e) {
      _cart = before;
      notifyListeners();
      AppLogger.warning('Add to cart failed', name: 'Cart', error: e);
      return CartAddResult.failed;
    }
  }

  /// Removes an item at once; [undo] puts it back within [undoWindow].
  Future<bool> remove(String productId) async {
    final index = _cart.items.indexWhere((i) => i.productId == productId);
    if (index < 0) return true;
    final removed = _cart.items[index];
    final before = _cart;
    _cart = _cart.copyWith(
      items: [..._cart.items]..removeAt(index),
      notices: const [],
    );
    _lastRemoved = removed;
    _undoTimer?.cancel();
    _undoTimer = Timer(undoWindow, () {
      _lastRemoved = null;
      notifyListeners();
    });
    notifyListeners();
    try {
      final serverCart = await _api.removeItem(productId);
      // Don't overwrite an undo that already put the item back.
      if (!contains(productId)) _set(serverCart);
      CartEvents.log(
        CartEvents.remove,
        productIds: [productId],
        itemCount: count,
        totalIdr: _cart.totalIdr,
      );
      return true;
    } catch (e) {
      _cart = before;
      _lastRemoved = null;
      notifyListeners();
      AppLogger.warning('Remove from cart failed', name: 'Cart', error: e);
      return false;
    }
  }

  /// Puts the last removed item back ("Urungkan").
  Future<CartAddResult> undo() async {
    final item = _lastRemoved;
    if (item == null) return CartAddResult.failed;
    _lastRemoved = null;
    _undoTimer?.cancel();
    final result = await add(item);
    if (result == CartAddResult.added) {
      CartEvents.log(
        CartEvents.undo,
        productIds: [item.productId],
        itemCount: count,
        totalIdr: _cart.totalIdr,
      );
    }
    return result;
  }

  /// "Hapus semua".
  Future<bool> clear() async {
    final before = _cart;
    _cart = Cart.empty;
    notifyListeners();
    try {
      await _api.clear();
      return true;
    } catch (e) {
      _cart = before;
      notifyListeners();
      return false;
    }
  }

  /// Drops granted items locally once an order is granted; the server has
  /// already removed them.
  void onOrderGranted(Iterable<String> productIds) {
    final ids = productIds.toSet();
    _cart = _cart.copyWith(
      items: _cart.items.where((i) => !ids.contains(i.productId)).toList(),
      notices: const [],
    );
    grants.value++;
    notifyListeners();
  }

  @override
  void dispose() {
    _undoTimer?.cancel();
    grants.dispose();
    _flags.removeListener(notifyListeners);
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }
}
