import 'dart:async';

import 'package:arunika_app/constants/app_colors.dart';
import 'package:arunika_app/constants/app_text_styles.dart';
import 'package:arunika_app/core/cart/cart_events.dart';
import 'package:arunika_app/core/cart/cart_notifier.dart';
import 'package:arunika_app/core/utils/price_format.dart';
import 'package:arunika_app/data/api/cart_api.dart';
import 'package:arunika_app/data/models/cart.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/presentation/navigation/main_shell.dart';
import 'package:arunika_app/presentation/screens/belajar/belajar_tab.dart';
import 'package:arunika_app/services/billing_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CartResultArgs {
  final CheckoutOrder order;
  final CartPurchaseOutcome outcome;
  const CartResultArgs({required this.order, required this.outcome});
}

enum _View { granted, cancelled, processing }

/// After a cart payment: "Berhasil" lists every item with Buka / Baca,
/// "Dibatalkan" says nothing was charged and the cart is intact, and
/// "Sedang diproses" polls the order until the grant lands.
class CartResultScreen extends StatefulWidget {
  final CartResultArgs args;
  final CartApi? api;
  final Duration pollEvery;
  final Duration pollFor;

  const CartResultScreen({
    super.key,
    required this.args,
    this.api,
    this.pollEvery = const Duration(seconds: 5),
    this.pollFor = const Duration(minutes: 1),
  });

  @override
  State<CartResultScreen> createState() => _CartResultScreenState();
}

class _CartResultScreenState extends State<CartResultScreen> {
  late _View _view;
  Timer? _poll;
  DateTime? _pollStarted;

  CartApi get _api => widget.api ?? locator<CartApi>();
  CheckoutOrder get _order => widget.args.order;

  @override
  void initState() {
    super.initState();
    _view = switch (widget.args.outcome) {
      CartPurchaseOutcome.granted => _View.granted,
      CartPurchaseOutcome.processing => _View.processing,
      _ => _View.cancelled,
    };
    if (_view == _View.processing) _startPolling();
  }

  void _startPolling() {
    _pollStarted = DateTime.now();
    _poll = Timer.periodic(widget.pollEvery, (_) => _check());
  }

  Future<void> _check() async {
    if (DateTime.now().difference(_pollStarted!) > widget.pollFor) {
      // Stop polling; a push notification tells the parent when it lands.
      _poll?.cancel();
      return;
    }
    try {
      final phase = await _api.fetchOrderPhase(_order.orderId);
      if (!mounted || phase != OrderPhase.granted) return;
      _poll?.cancel();
      final ids = [for (final i in _order.items) i.productId];
      locator<CartNotifier>().onOrderGranted(ids);
      CartEvents.log(
        CartEvents.grantComplete,
        productIds: ids,
        itemCount: ids.length,
        totalIdr: _order.totalIdr,
      );
      setState(() => _view = _View.granted);
    } catch (_) {
      // Keep polling.
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  void _openList(CartItemType type) {
    Navigator.of(context).popUntil((r) => r.isFirst);
    MainShell.shellKey.currentState?.openBelajar(
      type == CartItemType.dongeng
          ? BelajarDestination.dongeng
          : BelajarDestination.kartuAr,
    );
  }

  void _close() {
    if (context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmPage,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: switch (_view) {
            _View.granted => _granted(),
            _View.cancelled => _cancelled(),
            _View.processing => _processing(),
          },
        ),
      ),
    );
  }

  Widget _header(
    IconData icon,
    Color color,
    Color bg,
    String title,
    String body,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 34),
        ),
        const SizedBox(height: 18),
        Text(title, style: AppTextStyles.heading),
        const SizedBox(height: 8),
        Text(
          body,
          style: AppTextStyles.body.copyWith(color: AppColors.textMedium),
        ),
      ],
    );
  }

  Widget _granted() {
    final n = _order.items.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(
          Icons.celebration_rounded,
          AppColors.ownedGreen,
          AppColors.freeGreenSoft,
          'Hore, $n item sudah jadi milikmu!',
          'Pembayaran ${formatIdr(_order.chargeIdr)} berhasil. Semuanya bisa langsung dibuka.',
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.separated(
            itemCount: n,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final line = _order.items[i];
              final isDongeng = line.type == CartItemType.dongeng;
              return Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            line.title,
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            isDongeng ? 'Dongeng' : 'Kartu AR',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () => _openList(line.type),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.ctaRustSoft,
                        foregroundColor: AppColors.ctaRust,
                        side: const BorderSide(color: AppColors.ctaRust),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(isDongeng ? 'Baca' : 'Buka'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        _primary('Selesai', _close),
      ],
    );
  }

  Widget _cancelled() {
    final n = _order.items.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(
          Icons.close_rounded,
          AppColors.discountRed,
          AppColors.discountRedSoft,
          'Pembayaran dibatalkan',
          'Tidak ada biaya yang ditagih. Keranjangmu masih utuh, $n item menunggu dibayar.',
        ),
        const Spacer(),
        _primary('Coba bayar lagi', _close),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () {
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
            child: Text(
              'Lanjut belanja',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _processing() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(
          Icons.hourglass_top_rounded,
          AppColors.mediumBrown,
          AppColors.premiumBadgeBg,
          'Pembayaranmu sedang kami proses',
          'Toko sudah menerima pembayaran. Item akan masuk ke akunmu sebentar lagi, '
              'dan kami kabari lewat notifikasi. Kamu tidak perlu membayar lagi.',
        ),
        const SizedBox(height: 24),
        const Center(
          child: CircularProgressIndicator(color: AppColors.ctaRust),
        ),
        const Spacer(),
        _primary('Kembali', _close),
      ],
    );
  }

  Widget _primary(String label, VoidCallback onPressed) => SizedBox(
    width: double.infinity,
    height: 52,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.ctaRust,
        foregroundColor: AppColors.white,
        elevation: 0,
        textStyle: AppTextStyles.button,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Text(label),
    ),
  );
}
