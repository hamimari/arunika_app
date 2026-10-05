import 'package:arunika_app/constants/app_colors.dart';
import 'package:arunika_app/constants/app_strings.dart';
import 'package:arunika_app/constants/app_text_styles.dart';
import 'package:arunika_app/data/models/response/angka_response.dart';
import 'package:arunika_app/presentation/navigation/main_shell.dart';
import 'package:arunika_app/presentation/screens/angka/angka_cubit.dart';
import 'package:arunika_app/presentation/screens/angka/angka_widgets.dart';
import 'package:arunika_app/presentation/screens/belajar/belajar_tab.dart';
import 'package:arunika_app/presentation/screens/huruf/huruf_cubit.dart';
import 'package:arunika_app/presentation/screens/huruf/huruf_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Beranda "Lanjutkan belajar": the Huruf letter and the Angka level in
/// progress. Renders nothing for guests, while both modules are off, when
/// nothing is in progress, or outside the shell.
class HomeContinueLearning extends StatelessWidget {
  const HomeContinueLearning({super.key});

  @override
  Widget build(BuildContext context) {
    final huruf = context.read<HurufCubit?>();
    final angka = context.read<AngkaCubit?>();
    if (huruf == null && angka == null) return const SizedBox.shrink();
    Widget withAngka(Widget? hurufCard) {
      if (angka == null) return _Row(cards: [?hurufCard]);
      return BlocBuilder<AngkaCubit, AngkaState>(
        bloc: angka,
        builder: (context, state) =>
            _Row(cards: [?hurufCard, ?_angkaCard(state)]),
      );
    }

    if (huruf == null) return withAngka(null);
    return BlocBuilder<HurufCubit, HurufState>(
      bloc: huruf,
      builder: (context, state) => withAngka(_hurufCard(state)),
    );
  }

  Widget? _angkaCard(AngkaState state) {
    final level = state.continueLevel;
    if (state.status != AngkaStatus.loaded || level == null) return null;
    return _AngkaContinueCard(level: level, state: state);
  }

  Widget? _hurufCard(HurufState state) {
    final letter = state.continueLetter;
    if (state.status != HurufStatus.loaded || letter == null) return null;
    final p = state.progress[letter.id];
    final done = [
      p?.kenaliDone ?? false,
      p?.tebalkanDone ?? false,
    ].where((d) => d).length;
    final next = state.nextActivity(letter.id);
    return Semantics(
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
                        style: AppTextStyles.heading.copyWith(fontSize: 17),
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
                const _PlayDot(color: HurufColors.teal),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The section title and its cards; nothing when there are none.
class _Row extends StatelessWidget {
  final List<Widget> cards;

  const _Row({required this.cards});

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.hurufContinue, style: AppTextStyles.subheading),
          for (final c in cards) ...[const SizedBox(height: 10), c],
        ],
      ),
    );
  }
}

/// The Angka level in progress: "ANGKA", its name and "x/10 soal".
class _AngkaContinueCard extends StatelessWidget {
  final AngkaManifestLevel level;
  final AngkaState state;

  const _AngkaContinueCard({required this.level, required this.state});

  @override
  Widget build(BuildContext context) {
    final p = state.progress[level.id]!;
    final total = p.questionCount == 0 ? level.questionCount : p.questionCount;
    return Semantics(
      button: true,
      label:
          '${AppStrings.hurufContinue}: ${level.name}, '
          '${AppStrings.angkaAnswered(p.answered, total)}',
      excludeSemantics: true,
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          key: const ValueKey('home-continue-angka'),
          borderRadius: BorderRadius.circular(22),
          onTap: () => MainShell.shellKey.currentState?.openBelajar(
            BelajarDestination.angka,
            angkaLevel: level,
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
                    color: AngkaColors.sky,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '123',
                    style: AppTextStyles.displayLarge.copyWith(
                      fontSize: 24,
                      color: AngkaColors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.angkaContinueLabel,
                        style: AppTextStyles.caption.copyWith(
                          color: AngkaColors.blue,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        level.name,
                        style: AppTextStyles.heading.copyWith(fontSize: 17),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: total == 0 ? 0 : p.answered / total,
                                minHeight: 6,
                                color: AngkaColors.blue,
                                backgroundColor: AngkaColors.track,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppStrings.angkaAnswered(p.answered, total),
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
                const _PlayDot(color: AngkaColors.blue),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayDot extends StatelessWidget {
  final Color color;

  const _PlayDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: const Icon(Icons.play_arrow_rounded, color: AppColors.white),
    );
  }
}
