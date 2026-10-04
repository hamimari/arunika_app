import 'package:arunika_app/constants/app_colors.dart';
import 'package:arunika_app/constants/app_text_styles.dart';
import 'package:arunika_app/data/models/response/order_response.dart';
import 'package:arunika_app/data/models/response/payment_history_item.dart';
import 'package:arunika_app/data/repositories/order_repository.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/presentation/screens/payment_history/payment_history_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

class PaymentHistoryScreen extends StatelessWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PaymentHistoryCubit(locator<OrderRepository>())..load(),
      child: Scaffold(
        backgroundColor: AppColors.creamBackground,
        appBar: AppBar(
          title: Text('Riwayat Pembayaran', style: AppTextStyles.subheading),
          backgroundColor: AppColors.creamBackground,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: const BackButton(color: AppColors.deepBrown),
        ),
        body: const _PaymentHistoryBody(),
      ),
    );
  }
}

class _PaymentHistoryBody extends StatelessWidget {
  const _PaymentHistoryBody();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PaymentHistoryCubit, PaymentHistoryState>(
      listenWhen: (prev, curr) =>
          curr.error != null &&
          curr.items.isNotEmpty &&
          prev.error != curr.error,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(state.error!)));
      },
      builder: (context, state) {
        final cubit = context.read<PaymentHistoryCubit>();

        if (state.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryOrange),
          );
        }
        if (state.items.isEmpty) {
          return RefreshIndicator(
            color: AppColors.primaryOrange,
            onRefresh: cubit.load,
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: constraints.maxHeight,
                  child: state.error != null
                      ? _MessageView(
                          icon: Iconsax.wifi_square,
                          title: 'Oops!',
                          message: state.error!,
                          actionLabel: 'Coba Lagi',
                          onAction: cubit.load,
                        )
                      : const _MessageView(
                          icon: Iconsax.receipt_2,
                          title: 'Belum ada pembayaran',
                          message:
                              'Pembelian kartu AR, dongeng, dan paket kamu akan muncul di sini.',
                        ),
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.primaryOrange,
          onRefresh: cubit.load,
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.metrics.extentAfter < 400) cubit.loadMore();
              return false;
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              itemCount: state.items.length + (state.hasMore ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                if (i == state.items.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.primaryOrange,
                        ),
                      ),
                    ),
                  );
                }
                return PaymentHistoryCard(item: state.items[i]);
              },
            ),
          ),
        );
      },
    );
  }
}

class PaymentHistoryCard extends StatelessWidget {
  final PaymentHistoryItem item;

  const PaymentHistoryCard({super.key, required this.item});

  static final _dateFormat = DateFormat('d MMM yyyy, HH:mm', 'id_ID');
  static final _priceFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    final type = _typeStyle(item);
    final status = _statusStyle(item.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryOrange.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Item + status ────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: type.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(type.icon, color: type.foreground, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.itemName.isNotEmpty ? item.itemName : type.label,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.deepBrown,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      type.label,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: status.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.label,
                  style: AppTextStyles.caption.copyWith(
                    color: status.color,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF1E6D8)),
          ),

          // ── Details ──────────────────────────────────────────────────
          _DetailRow(
            label: 'Harga',
            value: _priceFormat.format(item.amountIdr),
            emphasize: true,
          ),
          _DetailRow(
            label: 'Metode',
            value: item.paymentMethod.isNotEmpty ? item.paymentMethod : '-',
          ),
          _DetailRow(
            label: 'Waktu Pesan',
            value: _dateFormat.format(item.createdAt),
          ),
          if (item.status != OrderStatus.pending)
            _DetailRow(
              label: item.status == OrderStatus.paid
                  ? 'Waktu Bayar'
                  : 'Diperbarui',
              value: _dateFormat.format(item.updatedAt),
            ),
          const SizedBox(height: 4),
          _OrderIdRow(orderId: item.orderId),
        ],
      ),
    );
  }

  static _TypeStyle _typeStyle(PaymentHistoryItem item) {
    switch (item.itemType) {
      case PaymentItemType.arCard:
        return const _TypeStyle(
          'Kartu AR',
          Iconsax.card,
          AppColors.mutedBlue,
          AppColors.categoryBlueBg,
        );
      case PaymentItemType.dongeng:
        return const _TypeStyle(
          'Dongeng',
          Iconsax.book_1,
          AppColors.categoryGreen,
          AppColors.categoryGreenBg,
        );
      case PaymentItemType.package:
        return item.packageType == 'subscription'
            ? const _TypeStyle(
                'Paket Langganan',
                Iconsax.crown_1,
                AppColors.premiumPurple,
                AppColors.categoryPurpleBg,
              )
            : const _TypeStyle(
                'Paket Konten',
                Iconsax.box_1,
                AppColors.premiumPurple,
                AppColors.categoryPurpleBg,
              );
      case PaymentItemType.unknown:
        return const _TypeStyle(
          'Pembelian',
          Iconsax.receipt_2,
          AppColors.primaryOrange,
          AppColors.creamCard,
        );
    }
  }

  static ({String label, Color color}) _statusStyle(OrderStatus status) {
    switch (status) {
      case OrderStatus.paid:
        return (label: 'Berhasil', color: AppColors.successGreen);
      case OrderStatus.pending:
        return (label: 'Menunggu', color: AppColors.primaryOrangeDark);
      case OrderStatus.failed:
        return (label: 'Gagal', color: const Color(0xFFE53935));
      case OrderStatus.expired:
        return (label: 'Kedaluwarsa', color: AppColors.textMedium);
      case OrderStatus.unknown:
        return (label: '-', color: AppColors.textMedium);
    }
  }
}

class _TypeStyle {
  final String label;
  final IconData icon;
  final Color foreground;
  final Color background;

  const _TypeStyle(this.label, this.icon, this.foreground, this.background);
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;

  const _DetailRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textMedium,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: (emphasize ? AppTextStyles.bodyLarge : AppTextStyles.body)
                  .copyWith(
                    fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
                    color: AppColors.textDark,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderIdRow extends StatelessWidget {
  final String orderId;

  const _OrderIdRow({required this.orderId});

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: orderId));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(
          content: Text('ID pesanan disalin'),
          duration: Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.pageBackground,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _copy(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ID Pesanan',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMedium,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      orderId,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Salin ID pesanan',
                onPressed: () => _copy(context),
                icon: const Icon(
                  Iconsax.copy,
                  size: 18,
                  color: AppColors.primaryOrange,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _MessageView({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.creamCard,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 36, color: AppColors.primaryOrange),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppTextStyles.subheading,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: AppTextStyles.body.copyWith(color: AppColors.textMedium),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 20),
            ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
