import 'package:arunika_app/services/google_play_billing_service.dart';

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

  /// Re-reports purchases Google Play considers owned but the backend has
  /// not recorded — e.g. the app was killed between paying and verifying.
  Future<void> syncPendingPurchases();

  /// Releases the purchase-stream subscription.
  void dispose();
}
