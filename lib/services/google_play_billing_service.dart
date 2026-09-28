import 'dart:async';

import 'package:arunika_app/core/logger/app_logger.dart';
import 'package:arunika_app/data/api/play_billing_api.dart';
import 'package:arunika_app/network/api_errors.dart';
import 'package:arunika_app/services/billing_service.dart';
import 'package:dio/dio.dart';
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
  // The backend refused to create the order (409 SUBSCRIPTION_ACTIVE): the
  // user's active subscription already covers everything, so nothing was
  // charged.
  subscriptionActive,
  // Google Play Billing can't be used on this device: no Play Store, or the
  // billing client isn't ready.
  storeUnavailable,
  // Google Play doesn't know the product's SKU — it isn't set up in Play
  // Console, or the build wasn't installed through Google Play (an internal
  // testing track, with a license-tester account).
  productNotFound,
  // The backend didn't create the order, so nothing was started or charged.
  orderFailed,
}

const _log = 'PlayBilling';

/// Maps a failure to create the backend order to a purchase outcome, logging
/// what the backend said so a support case can see why.
PlayPurchaseOutcome _orderFailureOutcome(Object error) {
  if (isSubscriptionActiveError(error)) {
    return PlayPurchaseOutcome.subscriptionActive;
  }
  final detail = error is DioException
      ? '${error.response?.statusCode} ${error.response?.data}'
      : '$error';
  AppLogger.warning('Backend did not create the order: $detail', name: _log);
  return PlayPurchaseOutcome.orderFailed;
}

class PlayPurchaseResult {
  final PlayPurchaseOutcome outcome;
  // Set only when outcome == userChoseAlternativeBilling — required by
  // POST /payment/play/report-external once the Midtrans payment settles.
  final String? externalTransactionToken;

  const PlayPurchaseResult(this.outcome, {this.externalTransactionToken});
}

/// Wraps the platform `in_app_purchase` plugin for a single purchase through
/// Google Play Billing. Only while the backoffice's `alternative_billing`
/// flag is on does it switch to Google Play's User Choice Billing, where
/// Google Play shows the user a choice between Google Play and Arunika's
/// alternative billing (Midtrans); picking the alternative resolves with
/// [PlayPurchaseOutcome.userChoseAlternativeBilling] so the caller can fall
/// back to the Midtrans checkout. With the flag off, Google Play's own sheet
/// is the only payment path.
class GooglePlayBillingService implements BillingService {
  final InAppPurchase _iap;
  final PlayBillingApi _api;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  // The BillingClient's current mode: false = Google Play only (its
  // default), true = User Choice Billing.
  bool _userChoiceBillingEnabled = false;
  // Whether alternative billing is allowed right now (the backoffice flag).
  final bool Function() _alternativeBillingAllowed;

  GooglePlayBillingService(
    this._api, {
    InAppPurchase? iap,
    bool Function()? alternativeBillingAllowed,
  }) : _iap = iap ?? InAppPurchase.instance,
       _alternativeBillingAllowed =
           alternativeBillingAllowed ?? (() => false);

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

  /// Puts the BillingClient in User Choice Billing mode (Google Play shows
  /// both payment options) only while alternative billing is allowed, and
  /// back to Google Play only when it isn't. Reconnecting the BillingClient
  /// is relatively slow, so the mode is only changed when it differs.
  Future<void> _syncBillingChoice() async {
    final wanted = _alternativeBillingAllowed();
    if (wanted == _userChoiceBillingEnabled) return;
    final addition = _androidAddition();
    if (addition == null) return;
    try {
      await addition.setBillingChoice(
        wanted
            ? BillingChoiceMode.userChoiceBilling
            : BillingChoiceMode.playBillingOnly,
      );
      _userChoiceBillingEnabled = wanted;
    } catch (_) {
      // Failing to switch to User Choice Billing leaves Google Play only,
      // which is always allowed — the purchase can still proceed.
    }
  }

  /// Buys [playProductId] (mapped to backend package [packageId]) and
  /// resolves once the purchase is verified, the user picked the
  /// alternative billing option, was canceled, or failed.
  @override
  Future<PlayPurchaseResult> purchase({
    required String packageId,
    required String playProductId,
  }) async {
    if (!await _iap.isAvailable()) {
      AppLogger.warning('Google Play Billing is not available', name: _log);
      return const PlayPurchaseResult(PlayPurchaseOutcome.storeUnavailable);
    }
    await _syncBillingChoice();

    final Map<String, dynamic> order;
    try {
      order = await _api.createOrder(packageId);
    } catch (e) {
      return PlayPurchaseResult(_orderFailureOutcome(e));
    }
    final orderId = order['order_id'] as String?;
    if (orderId == null) {
      AppLogger.warning('Order response carried no order_id', name: _log);
      return const PlayPurchaseResult(PlayPurchaseOutcome.orderFailed);
    }

    return _doPurchase(playProductId, orderId);
  }

  /// Buys [playProductId] (mapped to backend product [productId]) and
  /// resolves once the purchase is verified or failed.
  @override
  Future<PlayPurchaseResult> purchaseProduct({
    required String productId,
    required String playProductId,
  }) async {
    if (!await _iap.isAvailable()) {
      AppLogger.warning('Google Play Billing is not available', name: _log);
      return const PlayPurchaseResult(PlayPurchaseOutcome.storeUnavailable);
    }
    await _syncBillingChoice();

    final Map<String, dynamic> order;
    try {
      order = await _api.createProductOrder(productId);
    } catch (e) {
      return PlayPurchaseResult(_orderFailureOutcome(e));
    }
    final orderId = order['order_id'] as String?;
    if (orderId == null) {
      AppLogger.warning('Order response carried no order_id', name: _log);
      return const PlayPurchaseResult(PlayPurchaseOutcome.orderFailed);
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
        AppLogger.warning(
          'Google Play does not know product "$playProductId" '
          '(notFound: ${response.notFoundIDs}, error: ${response.error?.message})',
          name: _log,
        );
        return const PlayPurchaseResult(PlayPurchaseOutcome.productNotFound);
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
        AppLogger.warning('Google Play refused to launch the purchase', name: _log);
        completer.complete(const PlayPurchaseResult(PlayPurchaseOutcome.error));
      }

      return await completer.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () => const PlayPurchaseResult(PlayPurchaseOutcome.error),
      );
    } catch (e, st) {
      AppLogger.error(
        'Google Play purchase threw',
        name: _log,
        error: e,
        stackTrace: st,
      );
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
          AppLogger.warning(
            'Google Play reported a purchase error: ${purchase.error?.message}',
            name: _log,
          );
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
          } catch (e) {
            // Google took the payment but the backend couldn't confirm it.
            // Left unacknowledged, it is retried on the next app start
            // (syncPendingPurchases) — the user must not pay again.
            AppLogger.error(
              'Backend could not verify the Google Play purchase',
              name: _log,
              error: e,
            );
            if (!completer.isCompleted) {
              completer.complete(const PlayPurchaseResult(PlayPurchaseOutcome.verificationFailed));
            }
          }
          break;
      }
    }
  }

  @override
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
  @override
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
