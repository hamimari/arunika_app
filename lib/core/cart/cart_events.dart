import 'package:arunika_app/core/logger/app_logger.dart';

/// The PRD's cart funnel events (cart_add ... grant_complete), each with the
/// item ids, item count and total. The app has no analytics SDK yet, so
/// they go to the structured log (and Crashlytics breadcrumbs through
/// AppLogger); swapping in an analytics sink only touches [CartEvents.sink].
class CartEvents {
  CartEvents._();

  static void Function(String name, Map<String, Object> params) sink =
      (name, params) => AppLogger.info('$name $params', name: 'CartEvent');

  static void log(
    String name, {
    required List<String> productIds,
    required int itemCount,
    required int totalIdr,
  }) {
    sink(name, {
      'item_ids': productIds.join(','),
      'item_count': itemCount,
      'total_idr': totalIdr,
    });
  }

  static const add = 'cart_add';
  static const remove = 'cart_remove';
  static const undo = 'cart_undo';
  static const view = 'cart_view';
  static const checkoutStart = 'checkout_start';
  static const parentGatePass = 'parent_gate_pass';
  static const paymentSuccess = 'payment_success';
  static const paymentCancel = 'payment_cancel';
  static const paymentFail = 'payment_fail';
  static const grantComplete = 'grant_complete';
}
