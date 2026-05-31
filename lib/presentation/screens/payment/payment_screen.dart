import 'package:arunika_app/constants/api_paths.dart';
import 'package:arunika_app/constants/app_colors.dart';
import 'package:arunika_app/constants/app_strings.dart';
import 'package:arunika_app/constants/app_text_styles.dart';
import 'package:arunika_app/data/static/premium_packs.dart';
import 'package:arunika_app/network/dio_client.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentScreen extends StatefulWidget {
  final PremiumPack pack;

  const PaymentScreen({super.key, required this.pack});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isLoadingToken = false;
  bool _hasError = false;
  String? _snapToken;

  Future<void> _startPayment() async {
    setState(() {
      _isLoadingToken = true;
      _hasError = false;
    });
    try {
      final res = await DioClient.dio.post(
        ApiPaths.paymentCreate,
        data: {'plan_name': widget.pack.name, 'amount': widget.pack.priceRaw},
      );
      final data = res.data as Map<String, dynamic>;
      setState(() {
        _snapToken = data['snap_token'] as String?;
        _isLoadingToken = false;
      });
    } catch (_) {
      setState(() {
        _hasError = true;
        _isLoadingToken = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_snapToken != null) {
      return _MidtransSnapWebView(
        snapToken: _snapToken!,
        onSuccess: (orderId) {
          context.go('/unlock-success', extra: widget.pack.name);
        },
        onPending: () {
          context.go('/shell');
        },
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
                  widget.pack.name,
                  style: AppTextStyles.subheading.copyWith(
                    color: AppColors.deepBrown,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.pack.subtitle,
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
                      widget.pack.priceLabel,
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
    defaultValue: 'SB-Mid-client-sandbox-placeholder',
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
      appBar: AppBar(
        title: const Text('Pembayaran'),
        backgroundColor: AppColors.creamBackground,
        elevation: 0,
        leading: BackButton(
          color: AppColors.deepBrown,
          onPressed: widget.onClose,
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
