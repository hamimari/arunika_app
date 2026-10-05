import 'package:arunika_app/constants/app_colors.dart';
import 'package:arunika_app/constants/app_strings.dart';
import 'package:arunika_app/constants/app_text_styles.dart';
import 'package:arunika_app/presentation/screens/huruf/huruf_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Belajar Huruf palette (design: teal accents on a warm page).
class HurufColors {
  static const teal = Color(0xFF1F6F66);
  static const mint = Color(0xFFDDF1EE);
  static const segment = Color(0xFFF1EBE4);

  /// Tile colours cycle every five letters, as in the design.
  static const tiles = <(Color bg, Color fg)>[
    (Color(0xFFFDE7D6), Color(0xFFC85A1A)),
    (Color(0xFFE0EBFA), Color(0xFF2F5FA8)),
    (Color(0xFFDDF1EE), Color(0xFF1F7A6A)),
    (Color(0xFFEDE8F8), Color(0xFF6A4FB3)),
    (Color(0xFFFBF0D2), Color(0xFF9A6A0C)),
  ];
}

/// Rounded white square back button used in the Huruf headers.
class HurufBackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const HurufBackButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Kembali',
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: const SizedBox(
            width: 48,
            height: 48,
            child: Icon(Icons.chevron_left_rounded, size: 28),
          ),
        ),
      ),
    );
  }
}

/// "Kenali ✓" style chip: filled when done, outlined when pending.
class ActivityChip extends StatelessWidget {
  final String label;
  final bool done;

  const ActivityChip({super.key, required this.label, required this.done});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: done ? HurufColors.teal : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: HurufColors.teal),
      ),
      child: Text(
        done ? '$label ✓' : label,
        style: AppTextStyles.caption.copyWith(
          color: done ? AppColors.white : HurufColors.teal,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Opens the Akses Premium paywall (behind the parental gate) and refreshes
/// the grid when the parent comes back, so a new subscription unlocks the
/// letters in place.
Future<void> openHurufPaywall(BuildContext context) async {
  final cubit = context.read<HurufCubit>();
  await GoRouter.of(context).push('/premium');
  await cubit.load(force: true);
}

String hurufActivityLabel(HurufActivity a) => switch (a) {
  HurufActivity.kenali => AppStrings.hurufKenali,
  HurufActivity.tebalkan => AppStrings.hurufTebalkan,
};
