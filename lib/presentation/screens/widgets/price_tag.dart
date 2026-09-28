import 'package:arunika_app/constants/app_colors.dart';
import 'package:arunika_app/constants/app_text_styles.dart';
import 'package:arunika_app/core/utils/price_format.dart';
import 'package:flutter/material.dart';

/// A price with its optional promotional strike price ("harga coret").
///
/// The strike price is display-only — it's shown crossed out next to the
/// real price, which is always what the user pays. [compact] renders a
/// small single-line chip for grid tiles; the regular form can add a
/// "-20%" pill and a "Promo s/d 31 Okt" caption.
class PriceTag extends StatelessWidget {
  final int price;
  final int? strikePrice;
  final int? discountPercent;
  final DateTime? promoEndsAt;
  final bool compact;
  final bool showDiscount;
  final bool showPromoEnd;
  final Color priceColor;
  // Colour of the strike price and promo caption — override on coloured
  // backgrounds where the default grey is illegible.
  final Color? mutedColor;

  const PriceTag({
    super.key,
    required this.price,
    this.strikePrice,
    this.discountPercent,
    this.promoEndsAt,
    this.compact = false,
    this.showDiscount = true,
    this.showPromoEnd = false,
    this.priceColor = AppColors.primaryOrange,
    this.mutedColor,
  });

  bool get _hasStrike => strikePrice != null && strikePrice! > price;

  @override
  Widget build(BuildContext context) {
    if (compact) return _buildCompact();

    final priceText = Text(
      formatIdr(price),
      style: AppTextStyles.bodyLarge.copyWith(
        color: priceColor,
        fontWeight: FontWeight.w700,
      ),
    );
    if (!_hasStrike) return priceText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            priceText,
            _strikeText(fontSize: 12),
            if (showDiscount && discountPercent != null)
              _DiscountPill(percent: discountPercent!),
          ],
        ),
        if (showPromoEnd && promoEndsAt != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              'Promo s/d ${formatShortDate(promoEndsAt!)}',
              style: AppTextStyles.caption.copyWith(
                color: mutedColor ?? AppColors.mediumBrown,
                fontSize: 11,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCompact() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formatIdr(price),
            style: AppTextStyles.caption.copyWith(
              color: priceColor,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
          if (_hasStrike) ...[
            const SizedBox(width: 4),
            _strikeText(fontSize: 10),
          ],
        ],
      ),
    );
  }

  Widget _strikeText({required double fontSize}) {
    return Text(
      formatIdr(strikePrice!),
      style: AppTextStyles.caption.copyWith(
        color: mutedColor ?? AppColors.textLight,
        fontSize: fontSize,
        decoration: TextDecoration.lineThrough,
        decorationColor: mutedColor ?? AppColors.textLight,
      ),
    );
  }
}

class _DiscountPill extends StatelessWidget {
  final int percent;
  const _DiscountPill({required this.percent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '-$percent%',
        style: AppTextStyles.caption.copyWith(
          color: Colors.red.shade700,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}
