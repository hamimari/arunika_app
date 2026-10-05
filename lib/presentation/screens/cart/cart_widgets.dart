import 'package:arunika_app/constants/app_colors.dart';
import 'package:arunika_app/constants/app_text_styles.dart';
import 'package:arunika_app/core/cart/cart_notifier.dart';
import 'package:arunika_app/data/models/cart.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/presentation/screens/widgets/header_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Strings of the cart UI (Indonesian, from the PRD and the design).
class CartStrings {
  CartStrings._();
  static const title = 'Keranjang';
  static const added = 'Ditambahkan ke keranjang';
  static const removed = 'Dikeluarkan dari keranjang';
  static const itemRemoved = 'Item dihapus';
  static const undo = 'Urungkan';
  static const view = 'Lihat';
  static const inCart = 'Di keranjang';
  static const full = 'Keranjang penuh';
  static const totalLimit = 'Total keranjang maksimal Rp 500.000';
  static const owned = 'Item ini sudah kamu miliki';
  static const notForSale = 'Item ini tidak bisa dibeli saat ini';
  static const subscribed = 'Sudah termasuk Akses Premium';
  static const failed = 'Gagal memperbarui keranjang. Coba lagi.';
  static const addSemantic = 'Tambah ke keranjang';
  static const removeSemantic = 'Keluarkan dari keranjang';
}

CartNotifier get _cart => locator<CartNotifier>();

void showCartSnack(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 3),
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        action: actionLabel == null
            ? null
            : SnackBarAction(
                label: actionLabel,
                textColor: AppColors.accentGold,
                onPressed: onAction ?? () {},
              ),
      ),
    );
}

String cartAddMessage(CartAddResult result) => switch (result) {
  CartAddResult.added => CartStrings.added,
  CartAddResult.full => CartStrings.full,
  CartAddResult.totalLimit => CartStrings.totalLimit,
  CartAddResult.owned => CartStrings.owned,
  CartAddResult.notForSale => CartStrings.notForSale,
  CartAddResult.subscribed => CartStrings.subscribed,
  CartAddResult.failed => CartStrings.failed,
};

void openCart(BuildContext context) => context.push('/cart');

/// The cart icon with a count badge for the Kartu AR and Dongeng headers.
/// Hidden while the cart is unavailable (flag off, signed out, Premium) and
/// the badge is hidden while the cart is empty.
class CartHeaderButton extends StatelessWidget {
  const CartHeaderButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _cart,
      builder: (context, _) {
        if (!_cart.enabled) return const SizedBox.shrink();
        final count = _cart.count;
        return Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              HeaderIconButton(
                icon: Icons.shopping_cart_outlined,
                semanticLabel: count > 0
                    ? '${CartStrings.title}, $count item'
                    : CartStrings.title,
                onTap: () => openCart(context),
              ),
              if (count > 0)
                Positioned(
                  top: -6,
                  right: -6,
                  child: Container(
                    key: const ValueKey('cart-badge'),
                    constraints: const BoxConstraints(minWidth: 20),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.discountRed,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.white, width: 2),
                    ),
                    child: Text(
                      '$count',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// The square add-to-cart button next to "Beli". Green with a check while
/// the item is in the cart; tapping it then takes the item out.
class CartToggleButton extends StatefulWidget {
  final CartItem item;
  final double size;

  const CartToggleButton({super.key, required this.item, this.size = 38});

  @override
  State<CartToggleButton> createState() => _CartToggleButtonState();
}

class _CartToggleButtonState extends State<CartToggleButton> {
  bool _busy = false;

  Future<void> _toggle() async {
    if (_busy) return;
    setState(() => _busy = true);
    final id = widget.item.productId;
    if (_cart.contains(id)) {
      final ok = await _cart.remove(id);
      if (mounted) {
        showCartSnack(context, ok ? CartStrings.removed : CartStrings.failed);
      }
    } else {
      final result = await _cart.add(widget.item);
      if (mounted) {
        showCartSnack(
          context,
          cartAddMessage(result),
          actionLabel: result == CartAddResult.added ? CartStrings.view : null,
          onAction: result == CartAddResult.added
              ? () => openCart(context)
              : null,
        );
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _cart,
      builder: (context, _) {
        if (!_cart.enabled) return const SizedBox.shrink();
        final inCart = _cart.contains(widget.item.productId);
        final full = !inCart && !_cart.canAdd(widget.item.priceIdr);
        return Semantics(
          button: true,
          label: inCart
              ? CartStrings.removeSemantic
              : full
              ? CartStrings.full
              : CartStrings.addSemantic,
          child: InkWell(
            key: ValueKey('cart-toggle-${widget.item.productId}'),
            onTap: full
                ? () => showCartSnack(context, CartStrings.full)
                : _toggle,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: inCart ? AppColors.freeGreenSoft : AppColors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: inCart
                      ? AppColors.ownedGreen.withValues(alpha: 0.5)
                      : full
                      ? AppColors.lockGrey
                      : AppColors.ctaRust,
                  width: 1.5,
                ),
              ),
              child: Icon(
                inCart ? Icons.check_rounded : Icons.add_shopping_cart_rounded,
                size: 20,
                color: inCart
                    ? AppColors.ownedGreen
                    : full
                    ? AppColors.lockGrey
                    : AppColors.ctaRust,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// "Di keranjang · Lihat" under a card whose item is in the cart.
class InCartLink extends StatelessWidget {
  final String productId;
  const InCartLink({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _cart,
      builder: (context, _) {
        if (!_cart.enabled || !_cart.contains(productId)) {
          return const SizedBox.shrink();
        }
        return GestureDetector(
          onTap: () => openCart(context),
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '${CartStrings.inCart} · ${CartStrings.view}',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.ownedGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      },
    );
  }
}
