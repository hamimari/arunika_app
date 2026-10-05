import 'package:arunika_app/constants/app_colors.dart';
import 'package:arunika_app/constants/app_strings.dart';
import 'package:arunika_app/constants/app_text_styles.dart';
import 'package:arunika_app/core/angka/question_generator.dart';
import 'package:arunika_app/core/media/media_cache.dart';
import 'package:arunika_app/presentation/screens/angka/angka_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Belajar Angka palette (design: blue accents on a warm page).
class AngkaColors {
  static const blue = Color(0xFF255C9E);
  static const blueText = Color(0xFF2F5FA8);
  static const sky = Color(0xFFE3EDFB);
  static const peach = Color(0xFFFDEEDD);
  static const track = Color(0xFFE6DED5);
  static const gold = Color(0xFFE3A21A);

  /// Numeral colours cycle every five numbers, as in the design.
  static const numerals = <(Color fg, Color edge)>[
    (Color(0xFFC85A1A), Color(0xFFF6C9A6)),
    (Color(0xFF2F5FA8), Color(0xFFB9CDEE)),
    (Color(0xFF1F7A6A), Color(0xFFAEDDD3)),
    (Color(0xFF6A4FB3), Color(0xFFD3C8F0)),
    (Color(0xFF9A6A0C), Color(0xFFF1DDA6)),
  ];

  static (Color, Color) numeral(int value) =>
      numerals[(value - 1) % numerals.length];
}

/// Opens the Akses Premium paywall (behind the parental gate) and refreshes
/// Belajar Angka when the parent comes back, so a new subscription unlocks
/// numbers and levels in place.
Future<void> openAngkaPaywall(BuildContext context) async {
  final cubit = context.read<AngkaCubit>();
  await GoRouter.of(context).push('/premium');
  await cubit.load(force: true);
}

/// Rounded white square icon button used in the Angka headers.
class AngkaSquareButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const AngkaSquareButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: SizedBox(width: 48, height: 48, child: Icon(icon, size: 26)),
        ),
      ),
    );
  }
}

/// The round blue speaker button.
class AngkaSpeakerButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final bool filled;

  const AngkaSpeakerButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: filled ? AngkaColors.blue : AppColors.white,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 52,
            height: 52,
            child: Icon(
              Icons.volume_up_rounded,
              color: filled ? AppColors.white : AngkaColors.blue,
            ),
          ),
        ),
      ),
    );
  }
}

/// Three stars, [earned] of them filled.
class AngkaStars extends StatelessWidget {
  final int earned;
  final double size;

  const AngkaStars({super.key, required this.earned, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppStrings.angkaStarsLabel(earned),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Icon(
              i < earned ? Icons.star_rounded : Icons.star_outline_rounded,
              size: size,
              color: i < earned ? AngkaColors.gold : AngkaColors.track,
            ),
        ],
      ),
    );
  }
}

/// A library picture: the object's image, or a soft dot while it loads or
/// when there's none.
class AngkaPicture extends StatelessWidget {
  final String url;
  final double size;

  const AngkaPicture({super.key, required this.url, required this.size});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFF2B8A0),
      ),
    );
    if (url.isEmpty) return placeholder;
    return Image(
      image: MediaCache.image(url),
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => placeholder,
    );
  }
}

/// The question's pictures at their generated positions, scaled from the
/// 320 × 180 box. Marked pictures carry their count number.
class AngkaPictureArea extends StatelessWidget {
  final AngkaQuestion question;
  final String imageUrl;
  final List<int> marks;
  final ValueChanged<int>? onTapPicture;

  const AngkaPictureArea({
    super.key,
    required this.question,
    required this.imageUrl,
    this.marks = const [],
    this.onTapPicture,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AngkaColors.peach,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(10),
      child: AspectRatio(
        aspectRatio: AngkaGenerator.areaWidth / AngkaGenerator.areaHeight,
        child: LayoutBuilder(
          builder: (context, c) {
            final scale = c.maxWidth / AngkaGenerator.areaWidth;
            final side = question.size * scale;
            return Stack(
              children: [
                for (var i = 0; i < question.points.length; i++)
                  Positioned(
                    left: question.points[i].x * scale - side / 2,
                    top: question.points[i].y * scale - side / 2,
                    width: side,
                    height: side,
                    child: _Picture(
                      key: ValueKey('angka-picture-$i'),
                      url: imageUrl,
                      size: side,
                      number: _numberOf(i),
                      onTap: onTapPicture == null
                          ? null
                          : () => onTapPicture!(i),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  int? _numberOf(int i) {
    final m = marks.indexOf(i);
    return m < 0 ? null : m + 1;
  }
}

class _Picture extends StatelessWidget {
  final String url;
  final double size;
  final int? number;
  final VoidCallback? onTap;

  const _Picture({
    super.key,
    required this.url,
    required this.size,
    this.number,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final n = number;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedScale(
            scale: n == null ? 1 : 1.08,
            duration: const Duration(milliseconds: 180),
            child: AngkaPicture(url: url, size: size),
          ),
          if (n != null)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                constraints: const BoxConstraints(minWidth: 22),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: AngkaColors.blue,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.white, width: 2),
                ),
                child: Text(
                  '$n',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The answer pad: 1–9, delete, 0 and "Periksa". Keys are at least 56 px
/// tall and Periksa is disabled while the box is empty.
class AngkaNumberPad extends StatelessWidget {
  final ValueChanged<int> onDigit;
  final VoidCallback onDelete;
  final VoidCallback? onCheck;

  const AngkaNumberPad({
    super.key,
    required this.onDigit,
    required this.onDelete,
    required this.onCheck,
  });

  @override
  Widget build(BuildContext context) {
    Widget row(List<Widget> keys) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          for (var i = 0; i < keys.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(child: keys[i]),
          ],
        ],
      ),
    );
    Widget digit(int d) => _PadKey(
      key: ValueKey('angka-key-$d'),
      label: '$d',
      onTap: () => onDigit(d),
    );
    return Column(
      children: [
        row([digit(1), digit(2), digit(3)]),
        row([digit(4), digit(5), digit(6)]),
        row([digit(7), digit(8), digit(9)]),
        row([
          _PadKey(
            key: const ValueKey('angka-key-delete'),
            label: AppStrings.angkaDelete,
            icon: Icons.backspace_outlined,
            background: const Color(0xFFF1EBE4),
            onTap: onDelete,
          ),
          digit(0),
          _PadKey(
            key: const ValueKey('angka-key-check'),
            label: AppStrings.angkaCheck,
            background: AppColors.ctaRust,
            foreground: AppColors.white,
            onTap: onCheck,
          ),
        ]),
      ],
    );
  }
}

class _PadKey extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color background;
  final Color foreground;
  final VoidCallback? onTap;

  const _PadKey({
    super.key,
    required this.label,
    this.icon,
    this.background = AppColors.white,
    this.foreground = AppColors.textDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Semantics(
      button: true,
      enabled: !disabled,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: disabled ? background.withValues(alpha: 0.4) : background,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 58),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: const Border(
                bottom: BorderSide(color: Color(0x14000000), width: 3),
              ),
            ),
            child: icon != null
                ? Icon(icon, color: foreground)
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      style: AppTextStyles.heading.copyWith(
                        fontSize: label.length > 1 ? 18 : 26,
                        color: foreground,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// The "1–10" badge of a level card.
class AngkaRangeBadge extends StatelessWidget {
  final String label;
  final bool strong;
  final bool muted;

  const AngkaRangeBadge({
    super.key,
    required this.label,
    this.strong = false,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = strong
        ? AngkaColors.blue
        : muted
        ? AppColors.white
        : AngkaColors.sky;
    final fg = strong
        ? AppColors.white
        : muted
        ? AppColors.textMedium
        : AngkaColors.blue;
    return Container(
      width: 64,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Text(
            label,
            style: AppTextStyles.heading.copyWith(fontSize: 20, color: fg),
          ),
        ),
      ),
    );
  }
}
