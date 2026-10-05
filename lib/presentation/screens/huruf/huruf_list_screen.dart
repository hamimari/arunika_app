import 'package:arunika_app/constants/app_colors.dart';
import 'package:arunika_app/constants/app_strings.dart';
import 'package:arunika_app/constants/app_text_styles.dart';
import 'package:arunika_app/data/models/response/huruf_response.dart';
import 'package:arunika_app/presentation/screens/huruf/huruf_cubit.dart';
import 'package:arunika_app/presentation/screens/huruf/huruf_detail_screen.dart';
import 'package:arunika_app/presentation/screens/huruf/huruf_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// "Belajar Huruf — Kenal huruf A sampai Z": continue card and the A–Z grid.
/// Hosted inside the Belajar tab's navigator.
class HurufListScreen extends StatefulWidget {
  /// Builds the letter detail; overridable in tests.
  final Widget Function(HurufManifestLetter letter, HurufActivity? start)?
  detailBuilder;

  const HurufListScreen({super.key, this.detailBuilder});

  @override
  State<HurufListScreen> createState() => _HurufListScreenState();
}

class _HurufListScreenState extends State<HurufListScreen> {
  @override
  void initState() {
    super.initState();
    // Pick up publishes from the backoffice (at most every 15 minutes).
    context.read<HurufCubit>().load();
  }

  void _open(HurufManifestLetter l, {HurufActivity? start}) {
    if (l.locked) {
      openHurufPaywall(context);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        settings: RouteSettings(name: 'huruf-${l.upper}'),
        builder: (_) =>
            widget.detailBuilder?.call(l, start) ??
            HurufDetailScreen(letter: l, initialActivity: start),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmPage,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<HurufCubit, HurufState>(
          builder: (context, state) => RefreshIndicator(
            color: AppColors.ctaRust,
            onRefresh: () => context.read<HurufCubit>().load(force: true),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _Header(onBack: () => Navigator.of(context).maybePop()),
                const SizedBox(height: 18),
                ..._body(state),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _body(HurufState state) {
    switch (state.status) {
      case HurufStatus.hidden:
      case HurufStatus.loading:
        return const [
          Padding(
            padding: EdgeInsets.only(top: 80),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.ctaRust),
            ),
          ),
        ];
      case HurufStatus.noChild:
        return [_Message(text: AppStrings.hurufNoChild)];
      case HurufStatus.error:
        return [
          _Message(
            text: AppStrings.hurufLoadError,
            action: AppStrings.hurufRetry,
            onAction: () => context.read<HurufCubit>().load(force: true),
          ),
        ];
      case HurufStatus.loaded:
        if (state.letters.isEmpty) {
          return [_Message(text: AppStrings.hurufEmpty)];
        }
        final cont = state.continueLetter;
        return [
          if (cont != null) ...[
            ContinueLetterCard(
              letter: cont,
              progress: state.progress[cont.id],
              onTap: () => _open(cont, start: state.nextActivity(cont.id)),
            ),
            const SizedBox(height: 22),
          ],
          Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.hurufAll,
                  style: AppTextStyles.heading.copyWith(fontSize: 18),
                ),
              ),
              Text(
                AppStrings.hurufDoneCount(
                  state.doneCount,
                  state.letters.length,
                ),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _LetterGrid(state: state, onTap: _open),
        ];
    }
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onBack;

  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        HurufBackButton(onPressed: onBack),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.hurufTitle, style: AppTextStyles.displayLarge),
              Text(
                AppStrings.hurufSubtitle,
                style: AppTextStyles.body.copyWith(color: AppColors.textMedium),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The mint "Lanjutkan belajar" card for the letter in progress.
class ContinueLetterCard extends StatelessWidget {
  final HurufManifestLetter letter;
  final HurufProgress? progress;
  final VoidCallback onTap;

  const ContinueLetterCard({
    super.key,
    required this.letter,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = progress;
    return Semantics(
      button: true,
      label:
          '${AppStrings.hurufContinue}, ${AppStrings.hurufLetterTitle(letter.upper)}',
      child: Material(
        color: HurufColors.mint,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 84,
                  height: 84,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    '${letter.upper}${letter.lower}',
                    style: AppTextStyles.displayLarge.copyWith(
                      fontSize: 34,
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
                        AppStrings.hurufContinue,
                        style: AppTextStyles.caption.copyWith(
                          color: HurufColors.teal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        AppStrings.hurufLetterTitle(letter.upper),
                        style: AppTextStyles.heading.copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          ActivityChip(
                            label: AppStrings.hurufKenali,
                            done: p?.kenaliDone ?? false,
                          ),
                          ActivityChip(
                            label: AppStrings.hurufTebalkan,
                            done: p?.tebalkanDone ?? false,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LetterGrid extends StatelessWidget {
  final HurufState state;
  final void Function(HurufManifestLetter) onTap;

  const _LetterGrid({required this.state, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        // Six columns as designed; fewer on narrow screens with large text.
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final columns = c.maxWidth / textScale < 300 ? 5 : 6;
        return GridView.count(
          crossAxisCount: columns,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (var i = 0; i < state.letters.length; i++)
              LetterTile(
                letter: state.letters[i],
                index: i,
                tileState: state.tileState(state.letters[i]),
                showFree: !state.premium && state.letters[i].isFree,
                onTap: () => onTap(state.letters[i]),
              ),
          ],
        );
      },
    );
  }
}

/// One "Aa" tile. Its state is shown by an icon or ring plus the semantics
/// label, never by colour alone.
class LetterTile extends StatelessWidget {
  final HurufManifestLetter letter;
  final int index;
  final LetterTileState tileState;
  final bool showFree;
  final VoidCallback onTap;

  const LetterTile({
    super.key,
    required this.letter,
    required this.index,
    required this.tileState,
    required this.showFree,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = HurufColors.tiles[index % HurufColors.tiles.length];
    final locked = tileState == LetterTileState.locked;
    final stateLabel = switch (tileState) {
      LetterTileState.locked => 'terkunci',
      LetterTileState.notStarted => 'belum dimulai',
      LetterTileState.inProgress => 'sedang dipelajari',
      LetterTileState.done => 'selesai',
    };
    return Semantics(
      button: true,
      label: 'Huruf ${letter.upper}, $stateLabel${showFree ? ', gratis' : ''}',
      excludeSemantics: true,
      child: Material(
        color: locked ? bg.withValues(alpha: 0.55) : bg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          key: ValueKey('huruf-tile-${letter.upper}'),
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            decoration: tileState == LetterTileState.inProgress
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.ctaRust, width: 2.5),
                  )
                : null,
            child: Stack(
              children: [
                Center(
                  child: FittedBox(
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text(
                        '${letter.upper}${letter.lower}',
                        style: AppTextStyles.heading.copyWith(
                          fontSize: 20,
                          color: locked ? fg.withValues(alpha: 0.45) : fg,
                        ),
                      ),
                    ),
                  ),
                ),
                if (locked)
                  const Positioned(
                    right: 4,
                    top: 4,
                    child: Icon(
                      Icons.lock_rounded,
                      size: 14,
                      color: AppColors.textMedium,
                    ),
                  ),
                if (tileState == LetterTileState.done)
                  Positioned(
                    right: 3,
                    top: 3,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: HurufColors.teal,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(2),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 12,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                if (showFree)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 3,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.freeGreenSoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          AppStrings.hurufFree,
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 9,
                            color: AppColors.ownedGreen,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final String text;
  final String? action;
  final VoidCallback? onAction;

  const _Message({required this.text, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: AppColors.textMedium),
          ),
          if (action != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onAction, child: Text(action!)),
          ],
        ],
      ),
    );
  }
}
