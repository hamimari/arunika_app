import 'dart:io' show Platform;

import 'package:arunika_app/constants/api_paths.dart';
import 'package:arunika_app/constants/app_colors.dart';
import 'package:arunika_app/constants/app_strings.dart';
import 'package:arunika_app/constants/app_text_styles.dart';
import 'package:arunika_app/core/utils/price_format.dart';
import 'package:arunika_app/data/api/play_billing_api.dart';
import 'package:arunika_app/data/models/purchasable_item.dart';
import 'package:arunika_app/data/repositories/order_repository.dart';
import 'package:arunika_app/data/repositories/premium_pack_repository.dart';
import 'package:arunika_app/data/repositories/profile_loader.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/network/api_errors.dart';
import 'package:arunika_app/network/dio_client.dart';
import 'package:arunika_app/presentation/screens/payment/payment_options_cubit.dart';
import 'package:arunika_app/presentation/screens/payment/payment_polling_cubit.dart';
import 'package:arunika_app/presentation/screens/widgets/active_subscription_view.dart';
import 'package:arunika_app/presentation/screens/widgets/price_tag.dart';
import 'package:arunika_app/services/billing_service.dart';
import 'package:arunika_app/services/google_play_billing_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Whether this item's purchase should route through Google Play Billing
/// (Android only, and only for items the backoffice has mapped to a Play
/// product) instead of the Midtrans webview.
bool _usesPlayBilling(PurchasableItem item) =>
    !kIsWeb && Platform.isAndroid && item.isPlayBillingEligible;

class PaymentScreen extends StatefulWidget {
  /// The item the user tapped to get here — a single product or a package.
  /// It's preselected, but the user can switch to any active package on
  /// this screen; "Bayar" pays for whatever is selected.
  final PurchasableItem item;

  const PaymentScreen({super.key, required this.item});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late final PaymentPollingCubit _pollingCubit;
  late final PaymentOptionsCubit _optionsCubit;
  bool _isLoadingToken = false;
  bool _hasError = false;
  String? _snapToken;
  String? _orderId;
  bool _isProcessingPlayPurchase = false;
  // Set when the user picked the alternative (Midtrans) billing option in
  // Google Play's User Choice Billing selection screen — once the Midtrans
  // order below settles, this must be reported to Google before continuing.
  String? _pendingExternalTransactionToken;

  /// What "Bayar" pays for — the option currently selected on screen.
  PurchasableItem get _selected => _optionsCubit.state.selected;

  @override
  void initState() {
    super.initState();
    _pollingCubit = PaymentPollingCubit(locator<OrderRepository>());
    _optionsCubit = PaymentOptionsCubit(
      entry: widget.item,
      packs: locator<PremiumPackRepository>(),
      profiles: locator<ProfileLoader>(),
    )..load();
  }

  @override
  void dispose() {
    _pollingCubit.close();
    _optionsCubit.close();
    super.dispose();
  }

  Future<void> _onPayPressed() async {
    // The selection is frozen until the payment has been started, so what
    // is charged is always what the summary showed.
    _optionsCubit.setLocked(true);
    try {
      if (_usesPlayBilling(_selected)) {
        await _startPlayBillingPurchase();
      } else {
        await _startPayment();
      }
    } finally {
      if (!_optionsCubit.isClosed) _optionsCubit.setLocked(false);
    }
  }

  Future<void> _startPlayBillingPurchase() async {
    final item = _selected;
    setState(() {
      _isProcessingPlayPurchase = true;
      _hasError = false;
    });

    PlayPurchaseResult result;
    try {
      if (item.kind == PurchaseKind.package) {
        result = await locator<BillingService>().purchase(
          packageId: item.id,
          playProductId: item.playProductId!,
        );
      } else {
        result = await locator<BillingService>().purchaseProduct(
          productId: item.id,
          playProductId: item.playProductId!,
        );
      }
    } catch (_) {
      // Backstop: GooglePlayBillingService.purchase()/purchaseProduct() are
      // meant to never throw, but a stuck loading button with no way to
      // retry is worse than an over-cautious catch here.
      if (!mounted) return;
      setState(() {
        _isProcessingPlayPurchase = false;
        _hasError = true;
      });
      return;
    }

    if (!mounted) return;
    setState(() => _isProcessingPlayPurchase = false);

    switch (result.outcome) {
      case PlayPurchaseOutcome.success:
        context.go('/unlock-success', extra: item);
        break;
      case PlayPurchaseOutcome.canceled:
        break;
      case PlayPurchaseOutcome.userChoseAlternativeBilling:
        // User picked Midtrans in Google Play's selection screen — fall
        // back to the Midtrans checkout below; the pending token is
        // reported to Google once that payment settles (see the
        // PaymentPollingPaid listener).
        _pendingExternalTransactionToken = result.externalTransactionToken;
        await _startPayment();
        break;
      case PlayPurchaseOutcome.subscriptionActive:
        _optionsCubit.markSubscriptionActive();
        break;
      case PlayPurchaseOutcome.error:
      case PlayPurchaseOutcome.verificationFailed:
        setState(() => _hasError = true);
        break;
    }
  }

  Future<void> _startPayment() async {
    final item = _selected;
    setState(() {
      _isLoadingToken = true;
      _hasError = false;
    });
    try {
      final isProduct = item.kind == PurchaseKind.product;
      final res = await DioClient.dio.post(
        isProduct ? ApiPaths.paymentCreateProduct : ApiPaths.paymentCreate,
        data: isProduct
            ? {'product_id': item.id}
            : {'plan_name': item.name, 'amount': item.priceRaw},
      );
      final data = res.data['data'] as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _snapToken = data['token'] as String?;
        _orderId = data['order_id'] as String?;
        _isLoadingToken = false;
      });
    } catch (e) {
      // A 401 here may have already triggered a redirect to /landing (expired
      // session) — the screen can be disposed by the time we get here.
      if (!mounted) return;
      if (isSubscriptionActiveError(e)) {
        setState(() => _isLoadingToken = false);
        _optionsCubit.markSubscriptionActive();
        return;
      }
      setState(() {
        _hasError = true;
        _isLoadingToken = false;
      });
    }
  }

  void _resetToSummary() {
    _pollingCubit.reset();
    setState(() {
      _snapToken = null;
      _orderId = null;
    });
  }

  void _startPolling() {
    final orderId = _orderId;
    if (orderId == null) {
      // No order to confirm against — treat as a failure rather than
      // trusting the webview's own callback.
      _pollingCubit.reset();
      return;
    }
    _pollingCubit.start(orderId);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _pollingCubit),
        BlocProvider.value(value: _optionsCubit),
      ],
      child: BlocConsumer<PaymentPollingCubit, PaymentPollingState>(
        listener: (context, state) async {
          if (state is PaymentPollingPaid) {
            final paidItem = _selected;
            final token = _pendingExternalTransactionToken;
            final orderId = _orderId;
            if (token != null && orderId != null) {
              _pendingExternalTransactionToken = null;
              try {
                await locator<PlayBillingApi>().reportExternalTransaction(
                  orderId: orderId,
                  externalTransactionToken: token,
                );
              } catch (_) {
                // Best-effort: the purchase and entitlement are already
                // final via the Midtrans settlement above — a failed report
                // here is a Play Console fee-accounting gap, not a failed
                // purchase for the user, so it must not block them.
              }
            }
            if (context.mounted) context.go('/unlock-success', extra: paidItem);
          }
        },
        builder: (context, state) {
          if (state is PaymentPollingWaiting) {
            return const _WaitingConfirmationView();
          }
          if (state is PaymentPollingFailed) {
            return _PaymentFailedView(onRetry: _resetToSummary);
          }
          return _buildIdleOrWebView(context);
        },
      ),
    );
  }

  Widget _buildIdleOrWebView(BuildContext context) {
    if (_snapToken != null) {
      return _MidtransSnapWebView(
        snapToken: _snapToken!,
        onSuccess: (orderId) => _startPolling(),
        onPending: () => _startPolling(),
        onError: () {
          setState(() => _snapToken = null);
        },
        onClose: () {
          setState(() => _snapToken = null);
        },
      );
    }

    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      appBar: AppBar(
        title: Text(AppStrings.paymentTitle, style: AppTextStyles.subheading),
        backgroundColor: AppColors.creamBackground,
        elevation: 0,
        leading: const BackButton(color: AppColors.deepBrown),
      ),
      body: BlocBuilder<PaymentOptionsCubit, PaymentOptionsState>(
        builder: (context, options) {
          switch (options.status) {
            case PaymentOptionsStatus.loading:
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryOrange,
                ),
              );
            case PaymentOptionsStatus.subscribed:
              return ActiveSubscriptionView(
                subscription: options.subscription,
                onBack: () => Navigator.of(context).maybePop(),
              );
            case PaymentOptionsStatus.ready:
              return Column(
                children: [
                  Expanded(child: _OptionList(options: options)),
                  _SummaryBar(
                    options: options,
                    hasError: _hasError,
                    isBusy: _isLoadingToken || _isProcessingPlayPurchase,
                    onPay: _onPayPressed,
                  ),
                ],
              );
          }
        },
      ),
    );
  }
}

// ── Option list ─────────────────────────────────────────────────────────────────

class _OptionList extends StatelessWidget {
  final PaymentOptionsState options;
  const _OptionList({required this.options});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PaymentOptionsCubit>();
    final single = options.singleItem;

    Widget tile(PurchasableItem item, {String? title}) => _OptionTile(
      item: item,
      title: title ?? item.name,
      selected: options.selected.id == item.id,
      enabled: !options.locked,
      onTap: () => cubit.select(item),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        Text(
          options.renewing ? 'Pilih paket langganan' : 'Pilih paket',
          style: AppTextStyles.subheading.copyWith(color: AppColors.deepBrown),
        ),
        const SizedBox(height: 12),
        if (single != null) ...[
          tile(single, title: 'Beli ${single.name} saja'),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Atau pilih paket yang lebih hemat',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.mediumBrown,
              ),
            ),
          ),
        ],
        if (options.packagesLoading)
          for (var i = 0; i < 3; i++)
            Container(
              key: const Key('payment-packages-loading'),
              margin: const EdgeInsets.only(bottom: 12),
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.pageBackground,
                borderRadius: BorderRadius.circular(18),
              ),
            )
        else if (options.packagesFailed)
          _PackagesRetryRow(onRetry: cubit.loadPackages)
        else
          for (final pack in options.packages) ...[
            tile(pack),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  final PurchasableItem item;
  final String title;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _OptionTile({
    required this.item,
    required this.title,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: GestureDetector(
        key: Key('payment-option-${item.id}'),
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primaryOrange.withValues(alpha: 0.06)
                : AppColors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? AppColors.primaryOrange
                  : AppColors.deepBrown.withValues(alpha: 0.08),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? AppColors.primaryOrange : AppColors.lockGrey,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.badgeLabel != null &&
                        item.badgeLabel!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: item.isBestValue
                              ? AppColors.accentGold
                              : AppColors.premiumBadgeBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.badgeLabel!,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.deepBrown,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      title,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.deepBrown,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.mediumBrown,
                      ),
                    ),
                    const SizedBox(height: 8),
                    PriceTag(
                      price: item.priceIdr,
                      strikePrice: item.strikePriceIdr,
                      discountPercent: item.discountPercent,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PackagesRetryRow extends StatelessWidget {
  final VoidCallback onRetry;
  const _PackagesRetryRow({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Gagal memuat paket',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.mediumBrown,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
        ],
      ),
    );
  }
}

// ── Summary + pay ───────────────────────────────────────────────────────────────

class _SummaryBar extends StatelessWidget {
  final PaymentOptionsState options;
  final bool hasError;
  final bool isBusy;
  final VoidCallback onPay;

  const _SummaryBar({
    required this.options,
    required this.hasError,
    required this.isBusy,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    final item = options.selected;
    final savings = item.savingsIdr;
    final renewedUntil = options.renewedUntil;
    final currentExpiry = options.subscription?.expiresAt;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepBrown.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                item.name,
                key: const Key('payment-summary-name'),
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.deepBrown,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (savings != null) ...[
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      formatIdr(item.strikePriceIdr!),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textLight,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: AppColors.textLight,
                      ),
                    ),
                    Text(
                      item.promoEndsAt != null
                          ? 'Hemat ${formatIdr(savings)} · Promo s/d ${formatShortDate(item.promoEndsAt!)}'
                          : 'Hemat ${formatIdr(savings)}',
                      key: const Key('payment-summary-savings'),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.successGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
              if (renewedUntil != null && currentExpiry != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Aktif sampai ${formatLongDate(currentExpiry)} → ${formatLongDate(renewedUntil)}',
                  key: const Key('payment-summary-renewal'),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.mediumBrown,
                  ),
                ),
              ],
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    item.priceLabel,
                    key: const Key('payment-total'),
                    style: AppTextStyles.subheading.copyWith(
                      color: AppColors.primaryOrange,
                    ),
                  ),
                ],
              ),
              if (hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Gagal memuat halaman pembayaran. Coba lagi.',
                    style: AppTextStyles.caption.copyWith(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: isBusy ? null : onPay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: isBusy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          AppStrings.btnPayNow,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Midtrans Snap WebView ──────────────────────────────────────────────────────

class _MidtransSnapWebView extends StatefulWidget {
  final String snapToken;
  final void Function(String orderId) onSuccess;
  final VoidCallback onPending;
  final VoidCallback onError;
  final VoidCallback onClose;

  const _MidtransSnapWebView({
    required this.snapToken,
    required this.onSuccess,
    required this.onPending,
    required this.onError,
    required this.onClose,
  });

  @override
  State<_MidtransSnapWebView> createState() => _MidtransSnapWebViewState();
}

class _MidtransSnapWebViewState extends State<_MidtransSnapWebView> {
  late final WebViewController _controller;

  static const _snapClientKey = String.fromEnvironment(
    'MIDTRANS_CLIENT_KEY',
    defaultValue: 'Mid-client-5P_BEJCnBYCnPP3W',
  );

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'Flutter',
        onMessageReceived: (msg) {
          final payload = msg.message;
          if (payload.startsWith('success:')) {
            widget.onSuccess(payload.replaceFirst('success:', ''));
          } else if (payload == 'pending') {
            widget.onPending();
          } else if (payload == 'error') {
            widget.onError();
          } else if (payload == 'close') {
            widget.onClose();
          }
        },
      )
      ..loadHtmlString(_buildHtml());
  }

  String _buildHtml() {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <script src="https://app.sandbox.midtrans.com/snap/snap.js"
          data-client-key="$_snapClientKey"></script>
</head>
<body style="margin:0;background:#FFF8F0;display:flex;align-items:center;justify-content:center;height:100vh;">
<script>
  window.onload = function() {
    snap.pay('${widget.snapToken}', {
      onSuccess: function(result) {
        Flutter.postMessage('success:' + (result.order_id || ''));
      },
      onPending: function() {
        Flutter.postMessage('pending');
      },
      onError: function() {
        Flutter.postMessage('error');
      },
      onClose: function() {
        Flutter.postMessage('close');
      }
    });
  };
</script>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      body: SafeArea(child: WebViewWidget(controller: _controller)),
    );
  }
}

// ── Waiting for confirmation ────────────────────────────────────────────────────

class _WaitingConfirmationView extends StatelessWidget {
  const _WaitingConfirmationView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: AppColors.primaryOrange),
                const SizedBox(height: 24),
                Text(
                  'Menunggu konfirmasi pembayaran...',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.deepBrown,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Mohon tunggu sebentar, kami sedang memverifikasi pembayaran Anda.',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.mediumBrown,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Payment failed / timeout ────────────────────────────────────────────────────

class _PaymentFailedView extends StatelessWidget {
  final VoidCallback onRetry;

  const _PaymentFailedView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 64,
                  color: AppColors.primaryOrange,
                ),
                const SizedBox(height: 16),
                Text(
                  'Pembayaran belum berhasil dikonfirmasi.',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.deepBrown,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Silakan coba lagi atau periksa status pembayaran Anda.',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.mediumBrown,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Coba Lagi',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
