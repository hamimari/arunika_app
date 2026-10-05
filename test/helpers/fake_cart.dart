import 'package:arunika_app/core/auth/auth_notifier.dart';
import 'package:arunika_app/core/cart/cart_notifier.dart';
import 'package:arunika_app/core/feature_flags/feature_flags_notifier.dart';
import 'package:arunika_app/data/api/cart_api.dart';
import 'package:arunika_app/data/api/feature_flag_api.dart';
import 'package:arunika_app/data/models/cart.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// An in-memory cart backend with the server's rules, for widget and unit
/// tests. Set [failNext] to make the next call fail with that code (or a
/// network error when it is 'NETWORK').
class FakeCartApi extends CartApi {
  FakeCartApi({List<CartItem> items = const []})
    : _items = [...items],
      super(dio: Dio());

  final List<CartItem> _items;
  List<CartNotice> notices = const [];
  String? failNext;
  int addCalls = 0;
  int removeCalls = 0;
  int clearCalls = 0;
  final List<String> orderKeys = [];

  /// What the next createOrder returns or throws.
  CheckoutOrder? nextOrder;
  CartApiException? nextOrderError;
  OrderPhase phase = OrderPhase.granted;

  List<CartItem> get items => List.unmodifiable(_items);

  void _maybeFail() {
    final code = failNext;
    if (code == null) return;
    failNext = null;
    if (code == 'NETWORK') {
      throw DioException(requestOptions: RequestOptions(path: '/cart'));
    }
    throw CartApiException(code);
  }

  Cart _cart() => Cart(items: [..._items], notices: notices);

  @override
  Future<Cart> fetchCart() async {
    _maybeFail();
    return _cart();
  }

  /// Items the fake knows how to add, by product id.
  final Map<String, CartItem> catalog = {};

  @override
  Future<Cart> addItem(String productId) async {
    addCalls++;
    _maybeFail();
    if (!_items.any((i) => i.productId == productId)) {
      final item =
          catalog[productId] ??
          CartItem(
            productId: productId,
            type: CartItemType.arCard,
            title: productId,
            priceIdr: 1000,
          );
      _items.add(item);
    }
    return _cart();
  }

  @override
  Future<Cart> removeItem(String productId) async {
    removeCalls++;
    _maybeFail();
    _items.removeWhere((i) => i.productId == productId);
    return _cart();
  }

  @override
  Future<void> clear() async {
    clearCalls++;
    _maybeFail();
    _items.clear();
  }

  @override
  Future<CheckoutOrder> createOrder({
    List<String>? productIds,
    required String idempotencyKey,
  }) async {
    orderKeys.add(idempotencyKey);
    if (nextOrderError != null) {
      final e = nextOrderError!;
      nextOrderError = null;
      throw e;
    }
    return nextOrder ??
        CheckoutOrder(
          orderId: 'order-1',
          playProductId: 'arunika.cart.t${_cart().totalIdr}',
          subtotalIdr: _cart().subtotalIdr,
          promoSavingIdr: _cart().promoSavingIdr,
          totalIdr: _cart().totalIdr,
          chargeIdr: _cart().totalIdr,
          items: [
            for (final i in _cart().payable)
              OrderLine(
                productId: i.productId,
                title: i.title,
                type: i.type,
                normalIdr: i.normalIdr,
                priceIdr: i.priceIdr,
              ),
          ],
        );
  }

  @override
  Future<OrderPhase> fetchOrderPhase(String orderId) async => phase;
}

class _StaticFlagsApi implements FeatureFlagApi {
  final Map<String, dynamic> flags;
  _StaticFlagsApi(this.flags);

  @override
  Dio get dio => Dio();

  @override
  Future<Map<String, dynamic>> fetchFlags() async => flags;
}

/// A [FeatureFlagsNotifier] with the given flags already applied.
Future<FeatureFlagsNotifier> flagsWith(Map<String, bool> flags) async {
  // refresh() caches the flags; without mock values the platform channel
  // never answers inside testWidgets.
  SharedPreferences.setMockInitialValues({});
  final notifier = FeatureFlagsNotifier(_StaticFlagsApi(flags));
  await notifier.refresh();
  return notifier;
}

/// Registers a [CartNotifier] (disabled unless [enabled]) so screens that
/// show cart controls can be built in tests.
Future<CartNotifier> registerTestCart({
  bool enabled = false,
  FakeCartApi? api,
  AuthNotifier? auth,
}) async {
  if (locator.isRegistered<CartNotifier>()) locator.unregister<CartNotifier>();
  final flags = await flagsWith({'cart': enabled});
  final notifier = CartNotifier(
    api ?? FakeCartApi(),
    flags,
    auth ??
        (locator.isRegistered<AuthNotifier>()
            ? locator<AuthNotifier>()
            : AuthNotifier()),
  );
  locator.registerSingleton<CartNotifier>(notifier);
  return notifier;
}

void unregisterTestCart() {
  if (locator.isRegistered<CartNotifier>()) locator.unregister<CartNotifier>();
}

/// An [AuthNotifier] that reports a signed-in parent.
class LoggedInAuth extends AuthNotifier {
  @override
  bool get isLoggedIn => true;
}

CartItem testItem(
  String id, {
  int price = 1000,
  int? strike,
  CartItemType type = CartItemType.arCard,
  int? priceChangedFrom,
  bool unavailable = false,
}) => CartItem(
  productId: id,
  type: type,
  title: 'Item $id',
  priceIdr: price,
  strikePriceIdr: strike,
  priceChangedFrom: priceChangedFrom,
  unavailable: unavailable,
);
