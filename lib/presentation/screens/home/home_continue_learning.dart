import 'package:arunika_app/constants/app_colors.dart';
import 'package:arunika_app/constants/app_strings.dart';
import 'package:arunika_app/constants/app_text_styles.dart';
import 'package:arunika_app/presentation/navigation/main_shell.dart';
import 'package:arunika_app/presentation/screens/belajar/belajar_tab.dart';
import 'package:arunika_app/presentation/screens/huruf/huruf_cubit.dart';
import 'package:arunika_app/presentation/screens/huruf/huruf_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Beranda "Lanjutkan belajar": the Huruf letter in progress. Renders
/// nothing for guests, while `belajar_huruf` is off, when no letter is in
/// progress, or outside the shell.
class HomeContinueLearning extends StatelessWidget {
  const HomeContinueLearning({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<HurufCubit?>();
    if (cubit == null) return const SizedBox.shrink();
    return BlocBuilder<HurufCubit, HurufState>(
      bloc: cubit,
      builder: (context, state) {
        final letter = state.continueLetter;
        if (state.status != HurufStatus.loaded || letter == null) {
          return const SizedBox.shrink();
        }
        final p = state.progress[letter.id];
        final done = [
          p?.kenaliDone ?? false,
          p?.tebalkanDone ?? false,
        ].where((d) => d).length;
        final next = state.nextActivity(letter.id);
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.hurufContinue, style: AppTextStyles.subheading),
              const SizedBox(height: 10),
              Semantics(
                button: true,
                label:
                    '${AppStrings.hurufContinue}: ${AppStrings.hurufLetterTitle(letter.upper)}, '
                    '${hurufActivityLabel(next)} $done dari 3',
                excludeSemantics: true,
                child: Material(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(22),
                  child: InkWell(
                    key: const ValueKey('home-continue-huruf'),
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => MainShell.shellKey.currentState?.openBelajar(
                      BelajarDestination.huruf,
                      hurufLetter: letter,
                      hurufStart: next,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: HurufColors.mint,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '${letter.upper}${letter.lower}',
                              style: AppTextStyles.displayLarge.copyWith(
                                fontSize: 28,
                                color: HurufColors.teal,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'HURUF',
                                  style: AppTextStyles.caption.copyWith(
                                    color: HurufColors.teal,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  AppStrings.hurufLetterTitle(letter.upper),
                                  style: AppTextStyles.heading.copyWith(
                                    fontSize: 17,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: done / 3,
                                          minHeight: 6,
                                          color: HurufColors.teal,
                                          backgroundColor: HurufColors.segment,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${hurufActivityLabel(next)} · $done/2',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.textMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: HurufColors.teal,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: AppColors.white,
                            ),
                          ),
                        ],
                      ),
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
