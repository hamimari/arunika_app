import 'package:arunika_app/constants/api_paths.dart';
import 'package:arunika_app/constants/app_colors.dart';
import 'package:arunika_app/constants/app_strings.dart';
import 'package:arunika_app/constants/app_text_styles.dart';
import 'package:arunika_app/data/models/purchasable_item.dart';
import 'package:arunika_app/data/repositories/order_repository.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/network/dio_client.dart';
import 'package:arunika_app/presentation/screens/payment/payment_polling_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentScreen extends StatefulWidget {
  final PurchasableItem item;

  const PaymentScreen({super.key, required this.item});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late final PaymentPollingCubit _pollingCubit;
  bool _isLoadingToken = false;
  bool _hasError = false;
  String? _snapToken;
  String? _orderId;

  @override
  void initState() {
    super.initState();
    _pollingCubit = PaymentPollingCubit(locator<OrderRepository>());
  }

  @override
  void dispose() {
    _pollingCubit.close();
    super.dispose();
  }

  Future<void> _startPayment() async {
    setState(() {
      _isLoadingToken = true;
      _hasError = false;
    });
    try {
      final isProduct = widget.item.kind == PurchaseKind.product;
      final res = await DioClient.dio.post(
        isProduct ? ApiPaths.paymentCreateProduct : ApiPaths.paymentCreate,
        data: isProduct
            ? {'product_id': widget.item.id}
            : {'plan_name': widget.item.name, 'amount': widget.item.priceRaw},
      );
      final data = res.data['data'] as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _snapToken = data['token'] as String?;
        _orderId = data['order_id'] as String?;
        _isLoadingToken = false;
      });
    } catch (_) {
      // A 401 here may have already triggered a redirect to /landing (expired
      // session) — the screen can be disposed by the time we get here.
      if (!mounted) return;
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
    return BlocProvider.value(
      value: _pollingCubit,
      child: BlocConsumer<PaymentPollingCubit, PaymentPollingState>(
        listener: (context, state) {
          if (state is PaymentPollingPaid) {
            context.go('/unlock-success', extra: widget.item);
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
      body: Column(
        children: [
          // Order summary card
          Container(
            margin: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.deepBrown.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.item.name,
                  style: AppTextStyles.subheading.copyWith(
                    color: AppColors.deepBrown,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.item.subtitle,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.mediumBrown,
                  ),
                ),
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
                      widget.item.priceLabel,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.primaryOrange,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Info note
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.primaryOrange,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Pembayaran diproses melalui Midtrans yang aman dan terpercaya. Anda akan diarahkan ke halaman pembayaran.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primaryOrange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Offer to browse bundles/subscriptions instead of a single item —
          // only relevant when buying a single product.
          if (widget.item.kind == PurchaseKind.product)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: GestureDetector(
                onTap: () => context.push('/premium'),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.pageBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primaryOrangeDark.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.workspace_premium_rounded,
                        color: AppColors.primaryOrangeDark,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Ingin lebih hemat? Lihat paket konten & langganan premium.',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.deepBrown,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: AppColors.primaryOrangeDark,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          const Spacer(),

          // Error message
          if (_hasError)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'Gagal memuat halaman pembayaran. Coba lagi.',
                style: AppTextStyles.caption.copyWith(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),

          // Pay button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoadingToken ? null : _startPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isLoadingToken
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
          ),
        ],
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
      body: SafeArea(
        child: WebViewWidget(controller: _controller),
      ),
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
                  style: AppTextStyles.body.copyWith(color: AppColors.mediumBrown),
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
                  style: AppTextStyles.body.copyWith(color: AppColors.mediumBrown),
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
