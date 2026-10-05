import 'package:arunika_app/services/google_play_billing_service.dart';

/// How paying a cart order ended.
enum CartPurchaseOutcome {
  /// Paid and every item granted.
  granted,

  /// Paid (or still being paid, e.g. a delayed payment method) but not
  /// granted yet — the "Sedang diproses" screen polls the order.
  processing,

  /// The parent closed the Google Play sheet; nothing was charged.
  canceled,

  /// Google Play reported an error; nothing was charged.
  error,

  /// Google Play Billing isn't available on this device.
  storeUnavailable,

  /// Google Play doesn't know the cart total product.
  productNotFound,
}

/// The purchase surface the app depends on.
///
/// Extracted so a test can substitute the whole billing implementation.
/// `GooglePlayBillingService` already accepts an injectable `InAppPurchase`,
/// which is enough for its own unit tests, but an integration test driving
/// the assembled app needs to replace the service itself — a real purchase
/// opens Google Play's UI and charges money, neither of which belongs in an
/// automated run.
///
/// Keeping this an interface rather than reaching for a mocking library at
/// each call site also states, in one place, exactly how much of the billing
/// plugin the rest of the app is allowed to know about: two purchase calls
/// and a reconciliation sweep.
abstract class BillingService {
  /// Buys a premium package, resolving once the purchase is verified,
  /// declined, or diverted to alternative billing.
  Future<PlayPurchaseResult> purchase({
    required String packageId,
    required String playProductId,
  });

  /// Buys a single product (an AR card or a dongeng).
  Future<PlayPurchaseResult> purchaseProduct({
    required String productId,
    required String playProductId,
  });

  /// Pays a cart order (Keranjang Belanja) with the consumable store
  /// product the backend picked for its total, passing the order id to
  /// Google so the server can match the purchase to the order.
  Future<CartPurchaseOutcome> purchaseCart({
    required String orderId,
    required String playProductId,
  });

  /// Re-reports purchases Google Play considers owned but the backend has
  /// not recorded — e.g. the app was killed between paying and verifying.
  Future<void> syncPendingPurchases();

  /// Releases the purchase-stream subscription.
  void dispose();
}
