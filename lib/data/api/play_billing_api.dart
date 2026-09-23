import 'package:arunika_app/constants/api_paths.dart';
import 'package:arunika_app/network/dio_client.dart';
import 'package:dio/dio.dart';

/// Talks to the backend's Google Play Billing endpoints — creating the
/// PENDING order before a purchase, and verifying the purchase token
/// Google Play returns once it completes.
class PlayBillingApi {
  final Dio dio;

  PlayBillingApi() : dio = DioClient.dio;

  /// POST /payment/play/create — creates a PENDING order for [packageId]
  /// and returns `{order_id, play_product_id}`.
  Future<Map<String, dynamic>> createOrder(String packageId) async {
    final res = await dio.post(
      ApiPaths.paymentPlayCreate,
      data: {'package_id': packageId},
    );
    return res.data['data'] as Map<String, dynamic>;
  }

  /// POST /payment/play/create-product — creates a PENDING order for [productId]
  /// and returns `{order_id, play_product_id}`.
  Future<Map<String, dynamic>> createProductOrder(String productId) async {
    final res = await dio.post(
      ApiPaths.paymentPlayCreateProduct,
      data: {'product_id': productId},
    );
    return res.data['data'] as Map<String, dynamic>;
  }

  /// POST /payment/play/verify — verifies the purchase token Google Play
  /// returned for [productId] and, if valid, grants entitlement.
  ///
  /// [orderId] is omitted when reconciling a purchase Google Play reports
  /// as owned but that the app has no in-memory order id for — e.g. it was
  /// killed between the purchase completing and reporting it back. The
  /// backend then resolves the most recent PENDING order for [productId]
  /// itself (see `PaymentService.ResolvePendingPlayOrder` server-side).
  Future<Map<String, dynamic>> verifyPurchase({
    String? orderId,
    required String productId,
    required String purchaseToken,
  }) async {
    final res = await dio.post(
      ApiPaths.paymentPlayVerify,
      data: {
        if (orderId != null) 'order_id': orderId,
        'product_id': productId,
        'purchase_token': purchaseToken,
      },
    );
    return res.data['data'] as Map<String, dynamic>;
  }

  /// POST /payment/play/report-external — reports a Midtrans-settled order
  /// to Google as a User Choice Billing external transaction, required
  /// whenever the user picked the alternative (Midtrans) payment option in
  /// Google Play's billing choice screen.
  Future<void> reportExternalTransaction({
    required String orderId,
    required String externalTransactionToken,
  }) async {
    await dio.post(
      ApiPaths.paymentPlayReportExternal,
      data: {
        'order_id': orderId,
        'external_transaction_token': externalTransactionToken,
      },
    );
  }
}
