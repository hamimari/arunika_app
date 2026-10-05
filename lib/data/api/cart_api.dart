import 'package:arunika_app/constants/api_paths.dart';
import 'package:arunika_app/data/models/cart.dart';
import 'package:arunika_app/network/dio_client.dart';
import 'package:dio/dio.dart';

/// A 409 from the cart API, with the backend's code (CART_FULL,
/// ALREADY_OWNED, CART_CHANGED, ...). [cart] is the new cart for
/// CART_CHANGED.
class CartApiException implements Exception {
  final String code;
  final Cart? cart;
  const CartApiException(this.code, {this.cart});

  @override
  String toString() => 'CartApiException($code)';
}

/// Talks to the backend's Keranjang Belanja endpoints.
class CartApi {
  final Dio dio;

  CartApi({Dio? dio}) : dio = dio ?? DioClient.dio;

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['code'] is String) {
        final cart = data['data'] is Map
            ? Cart.fromJson((data['data'] as Map).cast<String, dynamic>())
            : null;
        throw CartApiException(data['code'] as String, cart: cart);
      }
      rethrow;
    }
  }

  Cart _cart(Response res) =>
      Cart.fromJson(res.data['data'] as Map<String, dynamic>);

  /// GET /cart — the cart at current prices.
  Future<Cart> fetchCart() =>
      _guard(() async => _cart(await dio.get(ApiPaths.cart)));

  /// POST /cart/items — idempotent; also the undo of a removal.
  Future<Cart> addItem(String productId) => _guard(
    () async => _cart(
      await dio.post(ApiPaths.cartItems, data: {'product_id': productId}),
    ),
  );

  /// DELETE /cart/items/:product_id
  Future<Cart> removeItem(String productId) =>
      _guard(() async => _cart(await dio.delete(ApiPaths.cartItem(productId))));

  /// DELETE /cart — "Hapus semua".
  Future<void> clear() => _guard(() => dio.delete(ApiPaths.cart));

  /// POST /orders — freezes the cart (or [productIds], a single "Beli")
  /// into an order. Throws [CartApiException] CART_CHANGED with the new
  /// cart when the parent must look again.
  Future<CheckoutOrder> createOrder({
    List<String>? productIds,
    required String idempotencyKey,
  }) => _guard(() async {
    final res = await dio.post(
      ApiPaths.orders,
      data: {
        'store': 'google',
        if (productIds != null)
          'items': [
            for (final id in productIds) {'product_id': id},
          ],
      },
      options: Options(headers: {'Idempotency-Key': idempotencyKey}),
    );
    return CheckoutOrder.fromJson(res.data['data'] as Map<String, dynamic>);
  });

  /// POST /orders/:id/verify — settles a cart order with its Play purchase.
  Future<OrderPhase> verifyOrder(String orderId, String purchaseToken) async {
    final res = await dio.post(
      ApiPaths.orderVerify(orderId),
      data: {'purchase_token': purchaseToken},
    );
    return orderPhaseFromJson(
      (res.data['data'] as Map<String, dynamic>)['phase'] as String?,
    );
  }

  /// GET /orders/:id — polled by the "Sedang diproses" screen.
  Future<OrderPhase> fetchOrderPhase(String orderId) async {
    final res = await dio.get(ApiPaths.orderById(orderId));
    return orderPhaseFromJson(
      (res.data['data'] as Map<String, dynamic>)['phase'] as String?,
    );
  }

  /// GET /entitlements — product ids the account owns.
  Future<List<String>> fetchEntitlements() async {
    final res = await dio.get(ApiPaths.entitlements);
    return ((res.data['data'] as Map<String, dynamic>)['product_ids']
                as List<dynamic>? ??
            [])
        .cast<String>();
  }
}
