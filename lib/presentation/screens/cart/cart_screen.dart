import 'package:arunika_app/constants/app_colors.dart';
import 'package:arunika_app/constants/app_text_styles.dart';
import 'package:arunika_app/core/cart/cart_events.dart';
import 'package:arunika_app/core/cart/cart_notifier.dart';
import 'package:arunika_app/core/media/media_cache.dart';
import 'package:arunika_app/core/utils/price_format.dart';
import 'package:arunika_app/data/models/cart.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/presentation/navigation/main_shell.dart';
import 'package:arunika_app/presentation/screens/belajar/belajar_tab.dart';
import 'package:arunika_app/presentation/screens/cart/cart_checkout.dart';
import 'package:arunika_app/presentation/screens/cart/cart_widgets.dart';
import 'package:arunika_app/presentation/screens/widgets/header_icon_button.dart';
import 'package:flutter/material.dart';

/// Keranjang: the parent's items with current prices, delete with undo,
/// "Hapus semua", the price breakdown and one "Bayar" for everything.
/// Anyone can browse it; paying goes through the parental gate.
class CartScreen extends StatefulWidget {
  final CartNotifier? cart;
  final CartCheckout? checkout;

  const CartScreen({super.key, this.cart, this.checkout});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late final CartNotifier _cart = widget.cart ?? locator<CartNotifier>();
  late final CartCheckout _checkout = widget.checkout ?? CartCheckout();
  bool _paying = false;

  @override
  void initState() {
    super.initState();
    _cart.refresh().then((_) {
      final c = _cart.cart;
      CartEvents.log(
        CartEvents.view,
        productIds: [for (final i in c.items) i.productId],
        itemCount: c.itemCount,
        totalIdr: c.totalIdr,
      );
    });
  }

  Future<void> _delete(CartItem item) async {
    final ok = await _cart.remove(item.productId);
    if (!mounted) return;
    if (!ok) {
      showCartSnack(context, CartStrings.failed);
      return;
    }
    showCartSnack(
      context,
      CartStrings.itemRemoved,
      actionLabel: CartStrings.undo,
      duration: _cart.undoWindow,
      onAction: () async {
        final result = await _cart.undo();
        if (mounted && result != CartAddResult.added) {
          showCartSnack(context, cartAddMessage(result));
        }
      },
    );
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus semua item?'),
        content: const Text('Semua item akan dikeluarkan dari keranjang.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Hapus semua',
              style: TextStyle(color: AppColors.discountRed),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await _cart.clear();
    if (mounted && !ok) showCartSnack(context, CartStrings.failed);
  }

  Future<void> _pay() async {
    if (_paying) return;
    setState(() => _paying = true);
    try {
      await _checkout.run(context);
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  void _openList(BelajarDestination destination) {
    Navigator.of(context).popUntil((r) => r.isFirst);
    MainShell.shellKey.currentState?.openBelajar(destination);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _cart,
      builder: (context, _) {
        final cart = _cart.cart;
        return Scaffold(
          backgroundColor: AppColors.warmPage,
          bottomNavigationBar: cart.isEmpty ? null : _bottomBar(cart),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(cart),
                Expanded(child: cart.isEmpty ? _empty() : _list(cart)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _header(Cart cart) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeaderIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            color: AppColors.textDark,
            semanticLabel: 'Kembali',
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(CartStrings.title, style: AppTextStyles.heading),
                Text(
                  cart.isEmpty
                      ? 'Belum ada item'
                      : '${cart.itemCount} item siap dibayar sekaligus',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),
          if (!cart.isEmpty)
            TextButton(
              onPressed: _clearAll,
              child: Text(
                'Hapus semua',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.discountRed,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _empty() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              color: AppColors.ctaRustSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              size: 42,
              color: AppColors.ctaRust,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Keranjangmu masih kosong',
            style: AppTextStyles.subheading,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Tambahkan Kartu AR atau Dongeng, lalu bayar semuanya sekaligus.',
            style: AppTextStyles.body.copyWith(color: AppColors.textMedium),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _openList(BelajarDestination.kartuAr),
                  style: _outlined(),
                  child: const Text('Kartu AR'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _openList(BelajarDestination.dongeng),
                  style: _outlined(),
                  child: const Text('Dongeng'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  ButtonStyle _outlined() => OutlinedButton.styleFrom(
    backgroundColor: AppColors.ctaRustSoft,
    foregroundColor: AppColors.ctaRust,
    side: const BorderSide(color: AppColors.ctaRust),
    minimumSize: const Size.fromHeight(46),
    textStyle: AppTextStyles.buttonSmall,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  );

  Widget _list(Cart cart) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        if (cart.hasChanges) ...[
          _ChangesBanner(cart: cart),
          const SizedBox(height: 14),
        ],
        for (final item in cart.items) ...[
          _CartRow(item: item, onDelete: () => _delete(item)),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 4),
        _Breakdown(cart: cart),
        const SizedBox(height: 14),
        Text(
          'Langganan Akses Premium dibeli terpisah, tidak lewat keranjang.',
          textAlign: TextAlign.center,
          style: AppTextStyles.caption.copyWith(color: AppColors.textMedium),
        ),
      ],
    );
  }

  Widget _bottomBar(Cart cart) {
    final canPay = cart.itemCount > 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total ${cart.itemCount} item',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMedium,
                    ),
                  ),
                  Text(
                    formatIdr(cart.totalIdr),
                    key: const ValueKey('cart-total'),
                    style: AppTextStyles.heading.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (cart.promoSavingIdr > 0)
                    Text(
                      'Hemat ${formatIdr(cart.promoSavingIdr)}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.ownedGreen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: canPay && !_paying ? _pay : null,
                // Disabled while a checkout is open; the gate, the summary
                // and the Play sheet sit on top of it.
                icon: const Icon(Icons.lock_outline_rounded, size: 20),
                label: Text(cart.hasChanges ? 'Bayar lagi' : 'Bayar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ctaRust,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  minimumSize: const Size(150, 52),
                  textStyle: AppTextStyles.button,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Ada perubahan sejak kamu menambahkan item": what the server changed.
class _ChangesBanner extends StatelessWidget {
  final Cart cart;
  const _ChangesBanner({required this.cart});

  String _describe() {
    final parts = <String>[];
    for (final n in cart.notices) {
      final name = n.title.isNotEmpty ? n.title : 'Satu item';
      parts.add(switch (n.code) {
        CartNoticeCode.alreadyOwned =>
          '$name sudah kamu miliki, jadi kami keluarkan.',
        CartNoticeCode.becameFree =>
          '$name sekarang gratis dan sudah bisa dibuka.',
        CartNoticeCode.subscriptionActive =>
          '$name sudah termasuk Akses Premium.',
        CartNoticeCode.notForSale => '$name tidak dijual lagi.',
        CartNoticeCode.other => '$name berubah.',
      });
    }
    for (final i in cart.items.where((i) => i.priceChangedFrom != null)) {
      parts.add('Harga ${i.title} naik.');
    }
    parts.add('Cek lagi, lalu bayar.');
    return parts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('cart-changes-banner'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.premiumBadgeBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accentGold),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.deepBrown),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ada perubahan sejak kamu menambahkan item',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepBrown,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _describe(),
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.deepBrown,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CartRow extends StatelessWidget {
  final CartItem item;
  final VoidCallback onDelete;
  const _CartRow({required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isDongeng = item.type == CartItemType.dongeng;
    final row = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 72,
              height: 72,
              child: item.imageUrl.isEmpty
                  ? Container(color: AppColors.textDark)
                  : Image(
                      image: MediaCache.image(item.imageUrl),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: AppColors.textDark),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isDongeng
                        ? AppColors.categoryPurpleBg
                        : AppColors.ctaRustSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isDongeng ? 'Dongeng' : 'Kartu AR',
                    style: AppTextStyles.caption.copyWith(
                      color: isDongeng
                          ? AppColors.premiumPurpleDark
                          : AppColors.ctaRust,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                if (item.unavailable)
                  Text(
                    'Tidak tersedia lagi',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMedium,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                else
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    children: [
                      Text(
                        formatIdr(item.priceIdr),
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.ctaRust,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (item.onPromo)
                        Text(
                          formatIdr(item.normalIdr),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textLight,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                    ],
                  ),
                if (item.priceChangedFrom != null && !item.unavailable)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.premiumBadgeBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Harga naik dari ${formatIdr(item.priceChangedFrom!)}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.deepBrown,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Semantics(
            button: true,
            label: 'Hapus ${item.title}',
            child: InkWell(
              key: ValueKey('cart-delete-${item.productId}'),
              onTap: onDelete,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.ownedGreySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.textMedium,
                ),
              ),
            ),
          ),
        ],
      ),
    );
    return item.unavailable ? Opacity(opacity: 0.5, child: row) : row;
  }
}

class _Breakdown extends StatelessWidget {
  final Cart cart;
  const _Breakdown({required this.cart});

  @override
  Widget build(BuildContext context) {
    final muted = AppTextStyles.body.copyWith(color: AppColors.textDark);
    final green = AppTextStyles.body.copyWith(
      color: AppColors.ownedGreen,
      fontWeight: FontWeight.w700,
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rincian harga',
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _line(
            'Harga normal (${cart.itemCount} item)',
            formatIdr(cart.subtotalIdr),
            muted,
          ),
          if (cart.promoSavingIdr > 0) ...[
            const SizedBox(height: 6),
            _line('Hemat promo', '-${formatIdr(cart.promoSavingIdr)}', green),
          ],
          const Divider(height: 22, color: AppColors.ownedGreySoft),
          // The total is the only bold number on the screen body.
          _line(
            'Total',
            formatIdr(cart.totalIdr),
            AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _line(String label, String value, TextStyle style) => Row(
    children: [
      Expanded(child: Text(label, style: style)),
      Text(value, style: style),
    ],
  );
}
