import 'package:arunika_app/services/billing_service.dart';
import 'package:arunika_app/services/google_play_billing_service.dart';

/// A [BillingService] that resolves purchases without touching Google Play.
///
/// A real purchase opens Play's UI and charges money, so it can never run in
/// an automated test. This lets a test drive every branch the app has to
/// handle — success, cancellation, error, failed verification, and the User
/// Choice Billing diversion to Midtrans — deterministically.
class FakeBilling implements BillingService {
  FakeBilling({
    this.outcome = PlayPurchaseOutcome.success,
    this.externalTransactionToken,
    this.onPurchase,
  });

  /// What the next purchase resolves to.
  PlayPurchaseOutcome outcome;

  /// Returned alongside [PlayPurchaseOutcome.userChoseAlternativeBilling].
  String? externalTransactionToken;

  /// Optional hook so a test can assert on what was requested, or delay.
  final Future<void> Function(String id, String playProductId)? onPurchase;

  final List<({String id, String playProductId, bool isPackage})> purchases = [];
  int syncCallCount = 0;
  bool disposed = false;

  /// Convenience constructors that read at the call site.
  factory FakeBilling.succeeds() => FakeBilling();
  factory FakeBilling.cancels() =>
      FakeBilling(outcome: PlayPurchaseOutcome.canceled);
  factory FakeBilling.fails() => FakeBilling(outcome: PlayPurchaseOutcome.error);
  factory FakeBilling.failsVerification() =>
      FakeBilling(outcome: PlayPurchaseOutcome.verificationFailed);
  factory FakeBilling.divertsToAlternativeBilling({String token = 'ext-token'}) =>
      FakeBilling(
        outcome: PlayPurchaseOutcome.userChoseAlternativeBilling,
        externalTransactionToken: token,
      );

  @override
  Future<PlayPurchaseResult> purchase({
    required String packageId,
    required String playProductId,
  }) async {
    purchases.add((id: packageId, playProductId: playProductId, isPackage: true));
    await onPurchase?.call(packageId, playProductId);
    return _result();
  }

  @override
  Future<PlayPurchaseResult> purchaseProduct({
    required String productId,
    required String playProductId,
  }) async {
    purchases.add((id: productId, playProductId: playProductId, isPackage: false));
    await onPurchase?.call(productId, playProductId);
    return _result();
  }

  PlayPurchaseResult _result() => PlayPurchaseResult(
    outcome,
    externalTransactionToken:
        outcome == PlayPurchaseOutcome.userChoseAlternativeBilling
        ? externalTransactionToken
        : null,
  );

  @override
  Future<void> syncPendingPurchases() async => syncCallCount++;

  @override
  void dispose() => disposed = true;
}
