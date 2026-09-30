import 'dart:async';

import 'package:arunika_app/data/api/play_billing_api.dart';
import 'package:arunika_app/services/google_play_billing_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:mocktail/mocktail.dart';

class _MockIap extends Mock implements InAppPurchase {}

/// The backend's refusal for a user whose subscription already covers
/// everything.
DioException _subscriptionActive() {
  final options = RequestOptions(path: '/payment/play/create');
  return DioException(
    requestOptions: options,
    response: Response(
      requestOptions: options,
      statusCode: 409,
      data: {'error': 'subscription is already active', 'code': 'SUBSCRIPTION_ACTIVE'},
    ),
  );
}

class _MockPlayBillingApi extends Mock implements PlayBillingApi {}

class _MockAndroidAddition extends Mock
    implements InAppPurchaseAndroidPlatformAddition {}

class _FakeProductDetails extends Fake implements ProductDetails {
  _FakeProductDetails(this._id);
  final String _id;
  @override
  String get id => _id;
}

class _FakePurchaseParam extends Fake implements PurchaseParam {}

class _FakePurchaseDetails extends Fake implements PurchaseDetails {
  _FakePurchaseDetails({
    required this.productID,
    required this.status,
    this.pendingCompletePurchase = false,
  });

  @override
  final String productID;
  @override
  final PurchaseStatus status;
  @override
  final bool pendingCompletePurchase;
  @override
  IAPError? get error => null;

  static const _token = 'purchase-token';

  @override
  PurchaseVerificationData get verificationData => PurchaseVerificationData(
    localVerificationData: _token,
    serverVerificationData: _token,
    source: 'google_play',
  );
}

/// The billing service sat at 6% coverage while being the only thing standing
/// between a user's money and their content. Its contract is narrow but
/// unforgiving: every path must resolve, because the caller's loading state
/// is only cleared when it does — a purchase that neither succeeds nor fails
/// leaves the user staring at a spinner.
void main() {
  late _MockIap iap;
  late _MockPlayBillingApi api;
  late StreamController<List<PurchaseDetails>> purchaseStream;
  late GooglePlayBillingService service;

  setUpAll(() {
    registerFallbackValue(BillingChoiceMode.playBillingOnly);
    registerFallbackValue(_FakePurchaseParam());
    registerFallbackValue(_FakePurchaseDetails(
      productID: 'x',
      status: PurchaseStatus.purchased,
    ));
  });

  setUp(() {
    iap = _MockIap();
    api = _MockPlayBillingApi();
    purchaseStream = StreamController<List<PurchaseDetails>>.broadcast();

    when(() => iap.isAvailable()).thenAnswer((_) async => true);
    when(() => iap.purchaseStream).thenAnswer((_) => purchaseStream.stream);
    when(() => iap.queryProductDetails(any())).thenAnswer(
      (_) async => ProductDetailsResponse(
        productDetails: [_FakeProductDetails('sku_card')],
        notFoundIDs: const [],
      ),
    );
    when(() => iap.buyNonConsumable(purchaseParam: any(named: 'purchaseParam')))
        .thenAnswer((_) async => true);
    when(() => iap.completePurchase(any())).thenAnswer((_) async {});
    when(() => api.createProductOrder(any()))
        .thenAnswer((_) async => {'order_id': 'order-1'});
    when(() => api.createOrder(any()))
        .thenAnswer((_) async => {'order_id': 'order-1'});
    when(() => api.verifyPurchase(
          orderId: any(named: 'orderId'),
          productId: any(named: 'productId'),
          purchaseToken: any(named: 'purchaseToken'),
        )).thenAnswer((_) async => {'status': 'PAID'});

    service = GooglePlayBillingService(api, iap: iap);
  });

  tearDown(() {
    service.dispose();
    purchaseStream.close();
  });

  /// Starts a product purchase and pushes [status] onto the purchase stream.
  Future<PlayPurchaseResult> purchaseWith(
    PurchaseStatus status, {
    bool pendingCompletePurchase = false,
  }) async {
    final future = service.purchaseProduct(
      productId: 'product-1',
      playProductId: 'sku_card',
    );
    // Let the service subscribe before the platform reports anything.
    await Future<void>.delayed(Duration.zero);
    purchaseStream.add([
      _FakePurchaseDetails(
        productID: 'sku_card',
        status: status,
        pendingCompletePurchase: pendingCompletePurchase,
      ),
    ]);
    return future;
  }

  group('purchaseProduct', () {
    test('should_verify_with_the_backend_and_succeed_when_play_reports_purchased',
        () async {
      final result = await purchaseWith(PurchaseStatus.purchased);

      expect(result.outcome, PlayPurchaseOutcome.success);
      verify(() => api.verifyPurchase(
            orderId: 'order-1',
            productId: 'sku_card',
            purchaseToken: 'purchase-token',
          )).called(1);
    });

    test('should_treat_a_restored_purchase_as_success', () async {
      // A reinstall replays owned purchases as `restored`; the user has
      // already paid, so this must unlock content exactly like `purchased`.
      final result = await purchaseWith(PurchaseStatus.restored);

      expect(result.outcome, PlayPurchaseOutcome.success);
    });

    test('should_report_cancellation_when_the_user_backs_out', () async {
      final result = await purchaseWith(PurchaseStatus.canceled);

      expect(result.outcome, PlayPurchaseOutcome.canceled);
      verifyNever(() => api.verifyPurchase(
            orderId: any(named: 'orderId'),
            productId: any(named: 'productId'),
            purchaseToken: any(named: 'purchaseToken'),
          ));
    });

    // What the Android plugin actually emits when the user closes the Google
    // Play sheet: no purchase comes back, so the update carries no productID.
    Future<PlayPurchaseResult> purchaseWithProductlessUpdate(
      PurchaseStatus status,
    ) async {
      final future = service.purchaseProduct(
        productId: 'product-1',
        playProductId: 'sku_card',
      );
      await Future<void>.delayed(Duration.zero);
      purchaseStream.add([_FakePurchaseDetails(productID: '', status: status)]);
      return future.timeout(
        const Duration(seconds: 1),
        onTimeout: () => fail('purchase never resolved; the button would keep spinning'),
      );
    }

    test('should_report_cancellation_when_the_sheet_is_closed_without_a_product_id',
        () async {
      final result = await purchaseWithProductlessUpdate(PurchaseStatus.canceled);

      expect(result.outcome, PlayPurchaseOutcome.canceled);
    });

    test('should_report_an_error_when_play_fails_without_a_product_id', () async {
      final result = await purchaseWithProductlessUpdate(PurchaseStatus.error);

      expect(result.outcome, PlayPurchaseOutcome.error);
    });

    test('should_never_grant_a_purchase_from_an_update_without_a_product_id',
        () async {
      final future = service.purchaseProduct(
        productId: 'product-1',
        playProductId: 'sku_card',
      );
      await Future<void>.delayed(Duration.zero);
      purchaseStream.add([
        _FakePurchaseDetails(productID: '', status: PurchaseStatus.purchased),
      ]);
      await Future<void>.delayed(Duration.zero);

      var resolved = false;
      unawaited(future.then((_) => resolved = true));
      await Future<void>.delayed(Duration.zero);
      expect(resolved, isFalse);
      verifyNever(() => api.verifyPurchase(
            orderId: any(named: 'orderId'),
            productId: any(named: 'productId'),
            purchaseToken: any(named: 'purchaseToken'),
          ));

      purchaseStream.add([
        _FakePurchaseDetails(productID: 'sku_card', status: PurchaseStatus.canceled),
      ]);
      expect((await future).outcome, PlayPurchaseOutcome.canceled);
    });

    test('should_report_an_error_when_play_reports_one', () async {
      final result = await purchaseWith(PurchaseStatus.error);

      expect(result.outcome, PlayPurchaseOutcome.error);
    });

    test('should_complete_the_purchase_with_play_when_it_is_pending_completion',
        () async {
      // Google marks some purchases as needing an explicit completePurchase
      // call before it considers them settled; the service must ask for
      // that exactly when the platform says pendingCompletePurchase is true.
      await purchaseWith(PurchaseStatus.purchased, pendingCompletePurchase: true);

      verify(() => iap.completePurchase(any())).called(1);
    });

    test('should_not_complete_the_purchase_with_play_when_not_pending',
        () async {
      await purchaseWith(PurchaseStatus.purchased, pendingCompletePurchase: false);

      verifyNever(() => iap.completePurchase(any()));
    });

    test('should_report_verification_failure_when_the_backend_rejects_it',
        () async {
      when(() => api.verifyPurchase(
            orderId: any(named: 'orderId'),
            productId: any(named: 'productId'),
            purchaseToken: any(named: 'purchaseToken'),
          )).thenThrow(Exception('rejected'));

      final result = await purchaseWith(PurchaseStatus.purchased);

      // Distinct from `error`: Google took the money but the backend would
      // not grant entitlement, which is a support case, not a retry.
      expect(result.outcome, PlayPurchaseOutcome.verificationFailed);
    });

    test('should_not_complete_the_purchase_with_play_if_verification_failed',
        () async {
      when(() => api.verifyPurchase(
            orderId: any(named: 'orderId'),
            productId: any(named: 'productId'),
            purchaseToken: any(named: 'purchaseToken'),
          )).thenThrow(Exception('rejected'));

      await purchaseWith(PurchaseStatus.purchased);

      // Acknowledging to Google before the backend has granted access would
      // lose the only signal that the purchase still needs reconciling.
      verifyNever(() => iap.completePurchase(any()));
    });

    test('should_ignore_updates_for_a_different_product', () async {
      final future = service.purchaseProduct(
        productId: 'product-1',
        playProductId: 'sku_card',
      );
      await Future<void>.delayed(Duration.zero);

      // A stray update for an unrelated SKU must not resolve this purchase.
      purchaseStream.add([
        _FakePurchaseDetails(
          productID: 'sku_something_else',
          status: PurchaseStatus.purchased,
        ),
      ]);
      await Future<void>.delayed(Duration.zero);

      var resolved = false;
      unawaited(future.then((_) => resolved = true));
      await Future<void>.delayed(Duration.zero);
      expect(resolved, isFalse);

      // The real one still resolves it.
      purchaseStream.add([
        _FakePurchaseDetails(
          productID: 'sku_card',
          status: PurchaseStatus.purchased,
        ),
      ]);
      expect((await future).outcome, PlayPurchaseOutcome.success);
    });

    test('should_stay_pending_until_play_reaches_a_terminal_state', () async {
      final future = service.purchaseProduct(
        productId: 'product-1',
        playProductId: 'sku_card',
      );
      await Future<void>.delayed(Duration.zero);

      purchaseStream.add([
        _FakePurchaseDetails(
          productID: 'sku_card',
          status: PurchaseStatus.pending,
        ),
      ]);
      await Future<void>.delayed(Duration.zero);

      var resolved = false;
      unawaited(future.then((_) => resolved = true));
      await Future<void>.delayed(Duration.zero);
      expect(resolved, isFalse,
          reason: 'a pending purchase is not yet an outcome');

      purchaseStream.add([
        _FakePurchaseDetails(
          productID: 'sku_card',
          status: PurchaseStatus.purchased,
        ),
      ]);
      expect((await future).outcome, PlayPurchaseOutcome.success);
    });
  });

  group('failure paths that must never hang', () {
    test('should_report_the_store_unavailable_when_billing_is_unavailable', () async {
      when(() => iap.isAvailable()).thenAnswer((_) async => false);

      final result = await service.purchaseProduct(
        productId: 'product-1',
        playProductId: 'sku_card',
      );

      expect(result.outcome, PlayPurchaseOutcome.storeUnavailable);
      verifyNever(() => api.createProductOrder(any()));
    });

    test('should_report_a_failed_order_when_the_backend_will_not_create_one', () async {
      when(() => api.createProductOrder(any())).thenThrow(Exception('down'));

      final result = await service.purchaseProduct(
        productId: 'product-1',
        playProductId: 'sku_card',
      );

      expect(result.outcome, PlayPurchaseOutcome.orderFailed);
      // No Play UI should open for an order that does not exist.
      verifyNever(() =>
          iap.buyNonConsumable(purchaseParam: any(named: 'purchaseParam')));
    });

    test('should_report_an_active_subscription_when_the_backend_refuses_with_409',
        () async {
      when(() => api.createProductOrder(any())).thenThrow(_subscriptionActive());
      when(() => api.createOrder(any())).thenThrow(_subscriptionActive());

      final product = await service.purchaseProduct(
        productId: 'product-1',
        playProductId: 'sku_card',
      );
      final package = await service.purchase(
        packageId: 'package-1',
        playProductId: 'sku_card',
      );

      expect(product.outcome, PlayPurchaseOutcome.subscriptionActive);
      expect(package.outcome, PlayPurchaseOutcome.subscriptionActive);
      // Nothing is charged: Play's purchase UI never opens.
      verifyNever(() =>
          iap.buyNonConsumable(purchaseParam: any(named: 'purchaseParam')));
    });

    test('should_report_a_failed_order_when_the_response_carries_no_id', () async {
      when(() => api.createProductOrder(any())).thenAnswer((_) async => {});

      final result = await service.purchaseProduct(
        productId: 'product-1',
        playProductId: 'sku_card',
      );

      expect(result.outcome, PlayPurchaseOutcome.orderFailed);
    });

    test('should_report_product_not_found_when_the_sku_is_unknown_to_play', () async {
      when(() => iap.queryProductDetails(any())).thenAnswer(
        (_) async => ProductDetailsResponse(
          productDetails: const [],
          notFoundIDs: const ['sku_card'],
        ),
      );

      final result = await service.purchaseProduct(
        productId: 'product-1',
        playProductId: 'sku_card',
      );

      expect(result.outcome, PlayPurchaseOutcome.productNotFound);
    });

    test('should_error_when_the_purchase_flow_will_not_launch', () async {
      when(() => iap.buyNonConsumable(purchaseParam: any(named: 'purchaseParam')))
          .thenAnswer((_) async => false);

      final result = await service.purchaseProduct(
        productId: 'product-1',
        playProductId: 'sku_card',
      );

      expect(result.outcome, PlayPurchaseOutcome.error);
    });

    test('should_error_rather_than_throw_when_the_platform_throws', () async {
      when(() => iap.buyNonConsumable(purchaseParam: any(named: 'purchaseParam')))
          .thenThrow(Exception('platform exploded'));

      // The whole point of the catch-all: the caller's spinner must stop.
      final result = await service.purchaseProduct(
        productId: 'product-1',
        playProductId: 'sku_card',
      );

      expect(result.outcome, PlayPurchaseOutcome.error);
    });

    test('should_error_when_the_purchase_stream_itself_errors', () async {
      final future = service.purchaseProduct(
        productId: 'product-1',
        playProductId: 'sku_card',
      );
      await Future<void>.delayed(Duration.zero);

      purchaseStream.addError(Exception('stream died'));

      expect((await future).outcome, PlayPurchaseOutcome.error);
    });
  });

  group('purchase (package)', () {
    test('should_create_a_package_order_rather_than_a_product_order', () async {
      final future = service.purchase(
        packageId: 'package-1',
        playProductId: 'sku_card',
      );
      await Future<void>.delayed(Duration.zero);
      purchaseStream.add([
        _FakePurchaseDetails(
          productID: 'sku_card',
          status: PurchaseStatus.purchased,
        ),
      ]);

      expect((await future).outcome, PlayPurchaseOutcome.success);
      verify(() => api.createOrder('package-1')).called(1);
      verifyNever(() => api.createProductOrder(any()));
    });
  });

  group('billing choice', () {
    late _MockAndroidAddition addition;

    setUp(() {
      addition = _MockAndroidAddition();
      when(
        () => iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>(),
      ).thenReturn(addition);
      when(() => addition.setBillingChoice(any())).thenAnswer((_) async {});
      when(
        () => addition.userChoiceDetailsStream,
      ).thenAnswer((_) => const Stream.empty());
    });

    Future<void> cancelledPurchase(GooglePlayBillingService svc) async {
      final future = svc.purchaseProduct(
        productId: 'product-1',
        playProductId: 'sku_card',
      );
      await Future<void>.delayed(Duration.zero);
      purchaseStream.add([
        _FakePurchaseDetails(productID: 'sku_card', status: PurchaseStatus.canceled),
      ]);
      await future;
    }

    test('should_never_enable_user_choice_billing_while_alternative_billing_is_off',
        () async {
      await cancelledPurchase(service);

      verifyNever(() => addition.setBillingChoice(any()));
    });

    test('should_follow_the_flag_on_and_back_off', () async {
      var allowed = true;
      final svc = GooglePlayBillingService(
        api,
        iap: iap,
        alternativeBillingAllowed: () => allowed,
      );
      addTearDown(svc.dispose);

      await cancelledPurchase(svc);
      verify(
        () => addition.setBillingChoice(BillingChoiceMode.userChoiceBilling),
      ).called(1);

      await cancelledPurchase(svc);
      verifyNever(() => addition.setBillingChoice(BillingChoiceMode.playBillingOnly));

      allowed = false;
      await cancelledPurchase(svc);
      verify(
        () => addition.setBillingChoice(BillingChoiceMode.playBillingOnly),
      ).called(1);
    });
  });
}
