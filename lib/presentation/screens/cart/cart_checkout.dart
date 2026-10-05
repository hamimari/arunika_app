import 'dart:math';

import 'package:arunika_app/constants/app_colors.dart';
import 'package:arunika_app/constants/app_text_styles.dart';
import 'package:arunika_app/core/cart/cart_events.dart';
import 'package:arunika_app/core/cart/cart_notifier.dart';
import 'package:arunika_app/core/logger/app_logger.dart';
import 'package:arunika_app/core/utils/price_format.dart';
import 'package:arunika_app/data/api/cart_api.dart';
import 'package:arunika_app/data/models/cart.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/presentation/screens/cart/cart_result_screen.dart';
import 'package:arunika_app/presentation/screens/cart/cart_widgets.dart';
import 'package:arunika_app/presentation/screens/widgets/parental_gate_screen.dart';
import 'package:arunika_app/services/billing_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// How a "Bayar" tap ended, for the cart screen.
enum CheckoutStart { cancelled, changed, failed, paid }

/// Runs "Bayar": parental gate (every time — payment is stricter than the
/// once-per-session gate on the premium screens), POST /orders, the
/// "Ringkasan pembayaran" sheet, then the one Google Play payment, then the
/// result screen.
class CartCheckout {
  final CartApi api;
  final CartNotifier cart;
  final BillingService billing;

  /// Shows the parental gate; resolves true once it is passed. Replaceable
  /// in tests.
  final Future<bool> Function(BuildContext context) parentalGate;

  CartCheckout({
    CartApi? api,
    CartNotifier? cart,
    BillingService? billing,
    Future<bool> Function(BuildContext context)? parentalGate,
  }) : api = api ?? locator<CartApi>(),
       cart = cart ?? locator<CartNotifier>(),
       billing = billing ?? locator<BillingService>(),
       parentalGate = parentalGate ?? _showParentalGate;

  static Future<bool> _showParentalGate(BuildContext context) async {
    final passed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) =>
            ParentalGateScreen(onPassed: () => Navigator.of(ctx).pop(true)),
      ),
    );
    return passed ?? false;
  }

  static String _newKey() {
    final rng = Random.secure();
    return List.generate(
      16,
      (_) => rng.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  Future<CheckoutStart> run(BuildContext context) async {
    final snapshot = cart.cart;
    final ids = [for (final i in snapshot.payable) i.productId];
    if (ids.isEmpty) return CheckoutStart.cancelled;

    if (!await parentalGate(context)) return CheckoutStart.cancelled;
    CartEvents.log(
      CartEvents.parentGatePass,
      productIds: ids,
      itemCount: ids.length,
      totalIdr: snapshot.totalIdr,
    );
    CartEvents.log(
      CartEvents.checkoutStart,
      productIds: ids,
      itemCount: ids.length,
      totalIdr: snapshot.totalIdr,
    );
    if (!context.mounted) return CheckoutStart.cancelled;

    final CheckoutOrder order;
    try {
      order = await api.createOrder(idempotencyKey: _newKey());
    } on CartApiException catch (e) {
      if (e.code == 'CART_CHANGED' && e.cart != null) {
        cart.applyServerCart(e.cart!);
        return CheckoutStart.changed;
      }
      if (context.mounted) {
        showCartSnack(context, _orderErrorMessage(e.code));
      }
      if (e.code == 'SUBSCRIPTION_ACTIVE') cart.setSubscribed(true);
      return CheckoutStart.failed;
    } catch (e) {
      AppLogger.warning(
        'Could not create the cart order',
        name: 'Cart',
        error: e,
      );
      if (context.mounted) {
        showCartSnack(context, 'Gagal membuat pesanan. Coba lagi.');
      }
      return CheckoutStart.failed;
    }
    if (!context.mounted) return CheckoutStart.cancelled;

    final pay = await showPaymentSummary(context, order);
    if (pay != true || !context.mounted) return CheckoutStart.cancelled;

    final outcome = await billing.purchaseCart(
      orderId: order.orderId,
      playProductId: order.playProductId,
    );
    final orderIds = [for (final i in order.items) i.productId];
    switch (outcome) {
      case CartPurchaseOutcome.granted:
        CartEvents.log(
          CartEvents.paymentSuccess,
          productIds: orderIds,
          itemCount: orderIds.length,
          totalIdr: order.totalIdr,
        );
        CartEvents.log(
          CartEvents.grantComplete,
          productIds: orderIds,
          itemCount: orderIds.length,
          totalIdr: order.totalIdr,
        );
        cart.onOrderGranted(orderIds);
      case CartPurchaseOutcome.processing:
        CartEvents.log(
          CartEvents.paymentSuccess,
          productIds: orderIds,
          itemCount: orderIds.length,
          totalIdr: order.totalIdr,
        );
      case CartPurchaseOutcome.canceled:
        CartEvents.log(
          CartEvents.paymentCancel,
          productIds: orderIds,
          itemCount: orderIds.length,
          totalIdr: order.totalIdr,
        );
      default:
        CartEvents.log(
          CartEvents.paymentFail,
          productIds: orderIds,
          itemCount: orderIds.length,
          totalIdr: order.totalIdr,
        );
    }
    if (!context.mounted) return CheckoutStart.paid;
    context.push(
      '/cart/result',
      extra: CartResultArgs(order: order, outcome: outcome),
    );
    return CheckoutStart.paid;
  }

  static String _orderErrorMessage(String code) => switch (code) {
    'AMOUNT_UNAVAILABLE' =>
      'Total ini belum bisa dibayar. Ubah isi keranjang atau coba lagi nanti.',
    'CART_FULL' => CartStrings.full,
    'CART_TOTAL_LIMIT' => CartStrings.totalLimit,
    'CART_EMPTY' => 'Keranjangmu kosong.',
    'SUBSCRIPTION_ACTIVE' => 'Semua item sudah termasuk Akses Premium.',
    _ => 'Gagal membuat pesanan. Coba lagi.',
  };
}

/// "Ringkasan pembayaran": the items and total of the order, shown after
/// the parental gate and before Google Play. Resolves true on "Bayar".
Future<bool?> showPaymentSummary(BuildContext context, CheckoutOrder order) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => _PaymentSummary(order: order),
  );
}

class _PaymentSummary extends StatelessWidget {
  final CheckoutOrder order;
  const _PaymentSummary({required this.order});

  @override
  Widget build(BuildContext context) {
    final saving = order.promoSavingIdr;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.ownedGreySoft,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.freeGreenSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: AppColors.ownedGreen,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Orang tua terverifikasi',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.ownedGreen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text('Ringkasan pembayaran', style: AppTextStyles.heading),
              const SizedBox(height: 4),
              Text(
                'Semua item di bawah dibayar dalam satu kali pembayaran.',
                style: AppTextStyles.body.copyWith(color: AppColors.textMedium),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.ownedGreySoft),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    for (final line in order.items) ...[
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                    line.type == CartItemType.dongeng
                                        ? 'Dongeng'
                                        : 'Kartu AR',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  formatIdr(line.priceIdr),
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (line.normalIdr > line.priceIdr)
                                  Text(
                                    formatIdr(line.normalIdr),
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textLight,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: AppColors.ownedGreySoft),
                    ],
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        color: AppColors.warmPage,
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(18),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total',
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (saving > 0)
                                  Text(
                                    'Hemat ${formatIdr(saving)}',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.ownedGreen,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            formatIdr(order.chargeIdr),
                            style: AppTextStyles.heading.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const _Note(
                icon: Icons.credit_card_rounded,
                text:
                    'Dibayar lewat Google Play. Sekali bayar, bukan langganan.',
              ),
              const SizedBox(height: 8),
              const _Note(
                icon: Icons.verified_user_outlined,
                text:
                    'Item jadi milik akun ini selamanya dan bisa dibuka di semua perangkatmu.',
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ctaRust,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    textStyle: AppTextStyles.button,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text('Bayar ${formatIdr(order.chargeIdr)}'),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Kembali ke keranjang',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textDark,
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

class _Note extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Note({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.textMedium),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.body.copyWith(color: AppColors.textMedium),
          ),
        ),
      ],
    );
  }
}
