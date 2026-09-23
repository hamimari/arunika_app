import 'dart:async';

import 'package:arunika_app/data/api/play_billing_api.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

enum PlayPurchaseOutcome {
  success,
  canceled,
  error,
  verificationFailed,
  // The Google Play User Choice Billing selection screen was shown and the
  // user picked the alternative (Midtrans) payment option instead of Google
  // Play. The caller must complete the purchase via Midtrans and then report
  // it to Google using [PlayPurchaseResult.externalTransactionToken].
  userChoseAlternativeBilling,
}

class PlayPurchaseResult {
  final PlayPurchaseOutcome outcome;
  // Set only when outcome == userChoseAlternativeBilling — required by
  // POST /payment/play/report-external once the Midtrans payment settles.
  final String? externalTransactionToken;

  const PlayPurchaseResult(this.outcome, {this.externalTransactionToken});
}

/// Wraps the platform `in_app_purchase` plugin for a single premium-package
/// purchase under Google Play's User Choice Billing: Google Play shows the
/// user a choice between paying via Google Play or via Arunika's
/// alternative billing (Midtrans). If the user picks Google Play, this
/// completes the purchase and verifies it with the backend as usual. If the
/// user picks the alternative, this resolves with
/// [PlayPurchaseOutcome.userChoseAlternativeBilling] so the caller can fall
/// back to the existing Midtrans checkout.
class GooglePlayBillingService {
  final InAppPurchase _iap;
  final PlayBillingApi _api;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  bool _userChoiceBillingEnabled = false;

  GooglePlayBillingService(this._api, {InAppPurchase? iap})
    : _iap = iap ?? InAppPurchase.instance;

  Future<bool> isAvailable() => _iap.isAvailable();

  InAppPurchaseAndroidPlatformAddition? _androidAddition() {
    try {
      return _iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
    } catch (_) {
      // Not on Android (a different platform addition, or none, is
      // registered) — User Choice Billing simply isn't available.
      return null;
    }
  }

  /// Switches the underlying BillingClient into User Choice Billing mode
  /// (Google Play shows both payment options) the first time it's needed.
  /// Reconnecting the BillingClient is relatively slow, so this is done
  /// once and memoized rather than on every purchase.
  Future<void> _ensureUserChoiceBillingEnabled() async {
    if (_userChoiceBillingEnabled) return;
    final addition = _androidAddition();
    if (addition == null) return;
    try {
      await addition.setBillingChoice(BillingChoiceMode.userChoiceBilling);
      _userChoiceBillingEnabled = true;
    } catch (_) {
      // Fails open to Google Play-only billing — the purchase can still
      // proceed, it just won't offer the alternative payment option.
    }
  }

  /// Buys [playProductId] (mapped to backend package [packageId]) and
  /// resolves once the purchase is verified, the user picked the
  /// alternative billing option, was canceled, or failed.
  Future<PlayPurchaseResult> purchase({
    required String packageId,
    required String playProductId,
  }) async {
    if (!await _iap.isAvailable()) {
      return const PlayPurchaseResult(PlayPurchaseOutcome.error);
    }
    await _ensureUserChoiceBillingEnabled();

    final Map<String, dynamic> order;
    try {
      order = await _api.createOrder(packageId);
    } catch (_) {
      return const PlayPurchaseResult(PlayPurchaseOutcome.error);
    }
    final orderId = order['order_id'] as String?;
    if (orderId == null) {
      return const PlayPurchaseResult(PlayPurchaseOutcome.error);
    }

    return _doPurchase(playProductId, orderId);
  }

  /// Buys [playProductId] (mapped to backend product [productId]) and
  /// resolves once the purchase is verified or failed.
  Future<PlayPurchaseResult> purchaseProduct({
    required String productId,
    required String playProductId,
  }) async {
    if (!await _iap.isAvailable()) {
      return const PlayPurchaseResult(PlayPurchaseOutcome.error);
    }
    await _ensureUserChoiceBillingEnabled();

    final Map<String, dynamic> order;
    try {
      order = await _api.createProductOrder(productId);
    } catch (_) {
      return const PlayPurchaseResult(PlayPurchaseOutcome.error);
    }
    final orderId = order['order_id'] as String?;
    if (orderId == null) {
      return const PlayPurchaseResult(PlayPurchaseOutcome.error);
    }

    return _doPurchase(playProductId, orderId);
  }

  // Never throws — every failure path (including a platform exception from
  // the underlying billing client) resolves to PlayPurchaseOutcome.error, so
  // the caller's loading state always gets reset instead of hanging forever.
  Future<PlayPurchaseResult> _doPurchase(
    String playProductId,
    String orderId,
  ) async {
    StreamSubscription<GooglePlayUserChoiceDetails>? userChoiceSub;
    try {
      final response = await _iap.queryProductDetails({playProductId});
      if (response.productDetails.isEmpty) {
        return const PlayPurchaseResult(PlayPurchaseOutcome.error);
      }

      final completer = Completer<PlayPurchaseResult>();

      await _purchaseSubscription?.cancel();
      _purchaseSubscription = _iap.purchaseStream.listen(
        (purchases) => _onPurchaseUpdate(
          purchases: purchases,
          orderId: orderId,
          playProductId: playProductId,
          completer: completer,
        ),
        onError: (_) {
          if (!completer.isCompleted) completer.complete(const PlayPurchaseResult(PlayPurchaseOutcome.error));
        },
      );

      final addition = _androidAddition();
      userChoiceSub = addition?.userChoiceDetailsStream.listen((details) {
        if (!details.products.any((p) => p.id == playProductId)) return;
        if (!completer.isCompleted) {
          completer.complete(
            PlayPurchaseResult(
              PlayPurchaseOutcome.userChoseAlternativeBilling,
              externalTransactionToken: details.externalTransactionToken,
            ),
          );
        }
      });

      final purchaseParam = PurchaseParam(productDetails: response.productDetails.first);
      final launched = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      if (!launched && !completer.isCompleted) {
        completer.complete(const PlayPurchaseResult(PlayPurchaseOutcome.error));
      }

      return await completer.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () => const PlayPurchaseResult(PlayPurchaseOutcome.error),
      );
    } catch (_) {
      return const PlayPurchaseResult(PlayPurchaseOutcome.error);
    } finally {
      await _purchaseSubscription?.cancel();
      _purchaseSubscription = null;
      await userChoiceSub?.cancel();
    }
  }

  Future<void> _onPurchaseUpdate({
    required List<PurchaseDetails> purchases,
    required String orderId,
    required String playProductId,
    required Completer<PlayPurchaseResult> completer,
  }) async {
    for (final purchase in purchases) {
      if (purchase.productID != playProductId) continue;

      switch (purchase.status) {
        case PurchaseStatus.pending:
          break;
        case PurchaseStatus.canceled:
          if (!completer.isCompleted) {
            completer.complete(const PlayPurchaseResult(PlayPurchaseOutcome.canceled));
          }
          break;
        case PurchaseStatus.error:
          if (!completer.isCompleted) {
            completer.complete(const PlayPurchaseResult(PlayPurchaseOutcome.error));
          }
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          try {
            await _api.verifyPurchase(
              orderId: orderId,
              productId: playProductId,
              purchaseToken: purchase.verificationData.serverVerificationData,
            );
            // Complete the purchase with Google BEFORE returning success
            if (purchase.pendingCompletePurchase) {
              await _iap.completePurchase(purchase);
            }
            if (!completer.isCompleted) {
              completer.complete(const PlayPurchaseResult(PlayPurchaseOutcome.success));
            }
          } catch (_) {
            if (!completer.isCompleted) {
              completer.complete(const PlayPurchaseResult(PlayPurchaseOutcome.verificationFailed));
            }
          }
          break;
      }
    }
  }

  void dispose() {
    _purchaseSubscription?.cancel();
    _purchaseSubscription = null;
  }

  /// Reconciles any Google Play purchase the app hasn't confirmed with the
  /// backend yet — e.g. Google Play finished the purchase but the app was
  /// killed, lost network, or crashed before it could call `verify` and
  /// acknowledge it. Google auto-refunds any purchase left unacknowledged
  /// for 3 days, so per Play Billing's own guidance this must run on every
  /// app start (not only within the [purchase] call that began it) — call
  /// this once, early, regardless of whether a purchase is in progress.
  Future<void> syncPendingPurchases() async {
    if (!await _iap.isAvailable()) return;

    final sub = _iap.purchaseStream.listen(
      _syncPurchases,
      onError: (_) {},
    );
    try {
      await _iap.restorePurchases();
      // restorePurchases() delivers its results asynchronously via
      // purchaseStream rather than returning them — give them a moment to
      // arrive before tearing the listener down.
      await Future.delayed(const Duration(seconds: 3));
    } catch (_) {
      // Best-effort — an unreachable Play Store here just means this
      // reconciliation retries on the next app start.
    } finally {
      await sub.cancel();
    }
  }

  Future<void> _syncPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status != PurchaseStatus.purchased &&
          purchase.status != PurchaseStatus.restored) {
        continue;
      }
      try {
        await _api.verifyPurchase(
          productId: purchase.productID,
          purchaseToken: purchase.verificationData.serverVerificationData,
        );
      } catch (_) {
        // Leave it unacknowledged — Play will redeliver it on the next
        // restore/app start, well within the 3-day auto-refund window.
        continue;
      }
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }
}
