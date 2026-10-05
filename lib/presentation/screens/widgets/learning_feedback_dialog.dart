import 'dart:math' as math;

import 'package:arunika_app/constants/app_colors.dart';
import 'package:arunika_app/constants/app_strings.dart';
import 'package:arunika_app/constants/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

enum LearningFeedbackKind { success, retry }

/// One button of the pop-up.
class FeedbackAction {
  final String label;
  final VoidCallback onPressed;

  const FeedbackAction(this.label, this.onPressed);
}

const _successGreen = Color(0xFF1F6F4A);
const _retryBrown = Color(0xFF7A3A12);

/// The shared learning pop-up (Huruf and Angka): a cheerful success
/// variant, and a gentle retry variant with a hint. Never red, never a
/// failure sound.
class LearningFeedbackDialog extends StatelessWidget {
  final LearningFeedbackKind kind;
  final String title;
  final String subtitle;

  /// Shown in a "Petunjuk:" box (retry only).
  final String? hint;
  final FeedbackAction primary;
  final FeedbackAction? secondary;

  /// An extra action, e.g. "Buka semua huruf" for non-subscribers.
  final FeedbackAction? extra;

  /// Success only: whether to show the star row ("+1 bintang").
  final bool showStars;

  /// Success only: when set, the row shows this many of three stars earned
  /// (a level result) instead of the celebratory "+1 bintang".
  final int? starsEarned;

  const LearningFeedbackDialog({
    super.key,
    required this.kind,
    required this.title,
    required this.subtitle,
    this.hint,
    required this.primary,
    this.secondary,
    this.extra,
    this.showStars = true,
    this.starsEarned,
  });

  /// Shows the pop-up; it can't be dismissed by tapping outside, so a child
  /// always picks a clear next step.
  static Future<void> show(BuildContext context, LearningFeedbackDialog d) =>
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => d,
      );

  bool get _success => kind == LearningFeedbackKind.success;

  @override
  Widget build(BuildContext context) {
    final accent = _success ? _successGreen : AppColors.ctaRust;
    return Dialog(
      backgroundColor: AppColors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Stack(
        children: [
          if (_success) const Positioned.fill(child: _Confetti()),
          // Scrolls rather than overflowing on short phones with large text.
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Mascot(success: _success),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.displayLarge.copyWith(
                    fontSize: 24,
                    color: _success ? _successGreen : _retryBrown,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(color: AppColors.textDark),
                ),
                if (_success && showStars) ...[
                  const SizedBox(height: 14),
                  _Stars(earned: starsEarned),
                ],
                if (!_success && hint != null && hint!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _HintBox(hint: hint!),
                ],
                const SizedBox(height: 18),
                _PrimaryButton(action: primary, color: accent),
                if (extra != null) ...[
                  const SizedBox(height: 10),
                  _OutlinedAction(action: extra!, color: AppColors.ctaRust),
                ],
                if (secondary != null) ...[
                  const SizedBox(height: 10),
                  _OutlinedAction(action: secondary!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Mascot extends StatelessWidget {
  final bool success;

  const _Mascot({required this.success});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      height: 112,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: success
                  ? const Color(0xFFE4F2EA)
                  : const Color(0xFFFDEBD3),
            ),
            alignment: Alignment.center,
            child: Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFFD9A8),
              ),
              child: const Icon(
                Iconsax.happyemoji,
                size: 48,
                color: AppColors.deepBrown,
              ),
            ),
          ),
          Positioned(
            right: 2,
            bottom: 6,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: success ? _successGreen : AppColors.ctaRust,
                border: Border.all(color: AppColors.white, width: 3),
              ),
              child: Icon(
                success ? Icons.check_rounded : Icons.refresh_rounded,
                color: AppColors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  /// Stars earned out of three; null for the celebratory "+1 bintang" row.
  final int? earned;

  const _Stars({this.earned});

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFE3A21A);
    const empty = Color(0xFFE6DED5);
    final n = earned;
    if (n != null) {
      return Semantics(
        label: AppStrings.angkaStarsLabel(n),
        excludeSemantics: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              Icon(
                i < n ? Icons.star_rounded : Icons.star_outline_rounded,
                color: i < n ? gold : empty,
                size: i == 1 ? 48 : 40,
              ),
          ],
        ),
      );
    }
    // Scales down rather than overflowing with large system text.
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: gold, size: 32),
          const Icon(Icons.star_rounded, color: gold, size: 40),
          const Icon(Icons.star_rounded, color: gold, size: 32),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFDF0D5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              AppStrings.hurufPlusStar,
              style: AppTextStyles.buttonSmall.copyWith(
                color: AppColors.mediumBrown,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HintBox extends StatelessWidget {
  final String hint;

  const _HintBox({required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warmPage,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFDE7C8),
            ),
            child: const Icon(
              Iconsax.lamp_on,
              size: 16,
              color: AppColors.ctaRust,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${AppStrings.hurufHintLabel} ',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: hint),
                ],
              ),
              style: AppTextStyles.body.copyWith(
                fontSize: 13,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final FeedbackAction action;
  final Color color;

  const _PrimaryButton({required this.action, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: action.onPressed,
        child: Text(
          action.label,
          style: AppTextStyles.button.copyWith(color: AppColors.white),
        ),
      ),
    );
  }
}

class _OutlinedAction extends StatelessWidget {
  final FeedbackAction action;
  final Color? color;

  const _OutlinedAction({required this.action, this.color});

  @override
  Widget build(BuildContext context) {
    final fg = color ?? AppColors.textDark;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: fg,
          side: BorderSide(color: color ?? const Color(0xFFE6DFD6)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: action.onPressed,
        child: Text(
          action.label,
          style: AppTextStyles.button.copyWith(color: fg, fontSize: 15),
        ),
      ),
    );
  }
}

/// A few static confetti shapes, as in the design.
class _Confetti extends StatelessWidget {
  const _Confetti();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(child: CustomPaint(painter: _ConfettiPainter()));
  }
}

class _ConfettiPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const pieces = [
      (0.12, 0.08, Color(0xFFE3A21A), 0),
      (0.22, 0.04, Color(0xFF1F7A6A), 1),
      (0.08, 0.2, Color(0xFF1F7A4D), 2),
      (0.2, 0.28, Color(0xFF2F5FA8), 1),
      (0.86, 0.06, Color(0xFFD9452F), 1),
      (0.82, 0.13, Color(0xFFC85A1A), 0),
      (0.74, 0.26, Color(0xFF1F7A6A), 1),
      (0.9, 0.24, Color(0xFF6A4FB3), 2),
    ];
    for (final (x, y, color, shape) in pieces) {
      final c = Offset(size.width * x, size.height * y);
      final paint = Paint()..color = color;
      switch (shape) {
        case 0:
          canvas.save();
          canvas.translate(c.dx, c.dy);
          canvas.rotate(math.pi / 5);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              const Rect.fromLTWH(-5, -8, 10, 16),
              const Radius.circular(2),
            ),
            paint,
          );
          canvas.restore();
        case 1:
          canvas.drawCircle(c, 5, paint);
        default:
          canvas.drawPath(
            Path()
              ..moveTo(c.dx, c.dy - 6)
              ..lineTo(c.dx + 6, c.dy + 5)
              ..lineTo(c.dx - 6, c.dy + 5)
              ..close(),
            paint,
          );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
