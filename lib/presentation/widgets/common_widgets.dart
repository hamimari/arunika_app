import 'package:flutter/material.dart';
import 'package:arunika_app/constants/app_colors.dart';
import 'package:arunika_app/constants/app_text_styles.dart';

// ─── Section Header ───────────────────────────────────────────────────────────
/// A row with a bold section title on the left and an optional "Lihat Semua"
/// (or custom) action link on the right.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.subheading),
        if (actionLabel != null && onAction != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primaryOrange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── App Card ─────────────────────────────────────────────────────────────────
/// White card with rounded corners (24px) and soft shadow.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double borderRadius;
  final Color? color;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppColors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─── Pill Badge ───────────────────────────────────────────────────────────────
/// Small rounded pill badge with color background and text.
class PillBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;

  const PillBadge({
    super.key,
    required this.label,
    this.backgroundColor = const Color(0xFFFFE0B2),
    this.textColor = AppColors.primaryOrange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── Gradient Card ────────────────────────────────────────────────────────────
/// Card with a linear gradient background and rounded corners.
class GradientCard extends StatelessWidget {
  final List<Color> colors;
  final Widget child;
  final double borderRadius;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;
  final List<BoxShadow>? boxShadow;

  const GradientCard({
    super.key,
    required this.colors,
    required this.child,
    this.borderRadius = 24,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: begin, end: end),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: boxShadow,
      ),
      child: child,
    );
  }
}

// ─── Orange Button ────────────────────────────────────────────────────────────
/// Rounded orange button with a glow shadow.
class OrangeButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final double? width;
  final EdgeInsets padding;

  const OrangeButton({
    super.key,
    required this.label,
    this.onTap,
    this.width,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: padding,
        decoration: BoxDecoration(
          color: AppColors.primaryOrange,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryOrange.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(child: Text(label, style: AppTextStyles.buttonSmall)),
      ),
    );
  }
}

// ─── Emoji Icon Box ───────────────────────────────────────────────────────────
/// A rounded square container with a centred emoji — used for categories, etc.
class EmojiIconBox extends StatelessWidget {
  final String emoji;
  final Color backgroundColor;
  final double size;
  final double emojiSize;
  final double borderRadius;

  const EmojiIconBox({
    super.key,
    required this.emoji,
    required this.backgroundColor,
    this.size = 64,
    this.emojiSize = 30,
    this.borderRadius = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: Text(emoji, style: TextStyle(fontSize: emojiSize)),
      ),
    );
  }
}

// ─── Bottom Sheet Handle ──────────────────────────────────────────────────────
/// Drag handle widget shown at the top of modal bottom sheets.
class BottomSheetHandle extends StatelessWidget {
  const BottomSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.lockGrey,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
