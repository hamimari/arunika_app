import 'dart:async';

import 'package:arunika_app/constants/app_colors.dart';
import 'package:arunika_app/constants/app_strings.dart';
import 'package:arunika_app/constants/app_text_styles.dart';
import 'package:arunika_app/data/models/response/angka_response.dart';
import 'package:arunika_app/presentation/screens/angka/angka_cubit.dart';
import 'package:arunika_app/presentation/screens/angka/angka_number_screen.dart';
import 'package:arunika_app/presentation/screens/angka/angka_question_screen.dart';
import 'package:arunika_app/presentation/screens/angka/angka_widgets.dart';
import 'package:arunika_app/presentation/screens/huruf/huruf_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// "Belajar Angka — Kenal angka dan berhitung, yuk!": the Kenal Angka tiles
/// and the Hitung Benda levels. Hosted inside the Belajar tab's navigator.
class AngkaScreen extends StatefulWidget {
  /// Audio player; tests pass a fake.
  final HurufAudio Function()? audioFactory;

  const AngkaScreen({super.key, this.audioFactory});

  @override
  State<AngkaScreen> createState() => _AngkaScreenState();
}

class _AngkaScreenState extends State<AngkaScreen> {
  late final HurufAudio _audio =
      (widget.audioFactory ?? JustAudioHurufAudio.new)();
  Timer? _sequence;

  AngkaCubit get _cubit => context.read<AngkaCubit>();

  @override
  void initState() {
    super.initState();
    // Pick up publishes from the backoffice (at most every 15 minutes).
    _cubit.load();
  }

  @override
  void dispose() {
    _sequence?.cancel();
    _audio.dispose();
    super.dispose();
  }

  void _openNumber(AngkaState state, AngkaManifestNumber n) {
    if (n.locked) {
      openAngkaPaywall(context);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        settings: RouteSettings(name: 'angka-${n.value}'),
        builder: (_) => AngkaNumberScreen(
          value: n.value,
          audioFactory: widget.audioFactory,
        ),
      ),
    );
  }

  void _openLevel(AngkaState state, AngkaManifestLevel l) {
    final s = state.levelState(l);
    if (s == AngkaLevelState.premiumLocked) {
      openAngkaPaywall(context);
      return;
    }
    if (s == AngkaLevelState.prerequisiteLocked) return;
    openAngkaLevel(
      context,
      l,
      restart: s == AngkaLevelState.done,
      audioFactory: widget.audioFactory,
    );
  }

  /// The speaker on the Kenal Angka card counts the open numbers aloud,
  /// using the count audio of the highest one.
  Future<void> _countAloud(AngkaState state) async {
    final open = state.numbers.where((n) => !n.locked).toList();
    if (open.isEmpty) return;
    _sequence?.cancel();
    try {
      final card = await _cubit.number(open.last.value);
      final urls = [
        for (final n in open)
          if (card.countAudio[n.value] case final u?) u,
      ];
      var i = 0;
      void step() {
        if (!mounted || i >= urls.length) return;
        _audio.play(urls[i++]);
        _sequence = Timer(const Duration(milliseconds: 800), step);
      }

      step();
    } catch (_) {
      // Silent: the tiles still play their own numbers.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmPage,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<AngkaCubit, AngkaState>(
          builder: (context, state) => RefreshIndicator(
            color: AppColors.ctaRust,
            onRefresh: () => _cubit.load(force: true),
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

  List<Widget> _body(AngkaState state) {
    switch (state.status) {
      case AngkaStatus.hidden:
      case AngkaStatus.loading:
        return const [
          Padding(
            padding: EdgeInsets.only(top: 80),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.ctaRust),
            ),
          ),
        ];
      case AngkaStatus.noChild:
        return [_Message(text: AppStrings.angkaNoChild)];
      case AngkaStatus.error:
        return [
          _Message(
            text: AppStrings.angkaLoadError,
            action: AppStrings.hurufRetry,
            onAction: () => _cubit.load(force: true),
          ),
        ];
      case AngkaStatus.loaded:
        if (state.numbers.isEmpty && state.levels.isEmpty) {
          return [_Message(text: AppStrings.angkaEmpty)];
        }
        return [
          if (state.numbers.isNotEmpty) ...[
            _KenalAngkaCard(
              state: state,
              onTap: (n) => _openNumber(state, n),
              onSpeaker: () => _countAloud(state),
            ),
            const SizedBox(height: 24),
          ],
          if (state.levels.isNotEmpty) ...[
            Text(
              AppStrings.angkaHitungTitle,
              style: AppTextStyles.heading.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 2),
            Text(
              AppStrings.angkaHitungSubtitle,
              style: AppTextStyles.body.copyWith(color: AppColors.textMedium),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < state.levels.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AngkaLevelCard(
                  level: state.levels[i],
                  number: i + 1,
                  state: state,
                  onTap: () => _openLevel(state, state.levels[i]),
                ),
              ),
          ],
        ];
    }
  }
}

/// Opens a level's question screen in the Belajar navigator.
Future<void> openAngkaLevel(
  BuildContext context,
  AngkaManifestLevel level, {
  bool restart = false,
  HurufAudio Function()? audioFactory,
  bool replace = false,
}) {
  final route = MaterialPageRoute<void>(
    settings: RouteSettings(name: 'angka-level-${level.id}'),
    builder: (_) => AngkaQuestionScreen(
      level: level,
      restart: restart,
      audioFactory: audioFactory,
    ),
  );
  final nav = Navigator.of(context);
  return replace ? nav.pushReplacement(route) : nav.push(route);
}

class _Header extends StatelessWidget {
  final VoidCallback onBack;

  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AngkaSquareButton(
          icon: Icons.chevron_left_rounded,
          label: 'Kembali',
          onPressed: onBack,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.angkaTitle, style: AppTextStyles.displayLarge),
              Text(
                AppStrings.angkaSubtitle,
                style: AppTextStyles.body.copyWith(color: AppColors.textMedium),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KenalAngkaCard extends StatelessWidget {
  final AngkaState state;
  final ValueChanged<AngkaManifestNumber> onTap;
  final VoidCallback onSpeaker;

  const _KenalAngkaCard({
    required this.state,
    required this.onTap,
    required this.onSpeaker,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: AngkaColors.sky,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.angkaKenalTitle,
                      style: AppTextStyles.heading.copyWith(fontSize: 20),
                    ),
                    Text(
                      AppStrings.angkaKenalSubtitle,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textDark.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              AngkaSpeakerButton(
                key: const ValueKey('angka-kenal-speaker'),
                label: AppStrings.angkaKenalSubtitle,
                filled: false,
                onPressed: onSpeaker,
              ),
            ],
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 5,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (final n in state.numbers)
                NumberTile(
                  number: n,
                  showFree: !state.premium && n.isFree,
                  onTap: () => onTap(n),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One Kenal Angka tile; locked ones carry a lock icon, never colour alone.
class NumberTile extends StatelessWidget {
  final AngkaManifestNumber number;
  final bool showFree;
  final VoidCallback onTap;

  const NumberTile({
    super.key,
    required this.number,
    required this.showFree,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (fg, edge) = AngkaColors.numeral(number.value);
    final locked = number.locked;
    return Semantics(
      button: true,
      label:
          'Angka ${number.value}${locked ? ', terkunci' : ''}${showFree ? ', gratis' : ''}',
      excludeSemantics: true,
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          key: ValueKey('angka-number-${number.value}'),
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border(bottom: BorderSide(color: edge, width: 4)),
            ),
            child: Stack(
              children: [
                Center(
                  child: FittedBox(
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text(
                        '${number.value}',
                        style: AppTextStyles.displayLarge.copyWith(
                          fontSize: 28,
                          color: locked ? fg.withValues(alpha: 0.35) : fg,
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
                      size: 13,
                      color: AppColors.textMedium,
                    ),
                  ),
                if (showFree)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 2,
                    child: Center(
                      child: Text(
                        AppStrings.angkaFree,
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 9,
                          color: AppColors.ownedGreen,
                          fontWeight: FontWeight.w700,
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

/// A Hitung Benda level card: range badge, name, stars and one state.
class AngkaLevelCard extends StatelessWidget {
  final AngkaManifestLevel level;
  final int number;
  final AngkaState state;
  final VoidCallback onTap;

  const AngkaLevelCard({
    super.key,
    required this.level,
    required this.number,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = state.levelState(level);
    final p = state.progress[level.id];
    final locked =
        s == AngkaLevelState.premiumLocked ||
        s == AngkaLevelState.prerequisiteLocked;
    final pre = level.prerequisiteId;
    final preNumber = pre == null ? 0 : state.levelNumber(pre);
    final showFree = !state.premium && level.isFree;

    Widget? subtitle;
    switch (s) {
      case AngkaLevelState.prerequisiteLocked:
        subtitle = Text(
          AppStrings.angkaFinishFirst(preNumber),
          style: AppTextStyles.caption.copyWith(color: AppColors.textMedium),
        );
      case AngkaLevelState.inProgress:
        final total = p!.questionCount == 0
            ? level.questionCount
            : p.questionCount;
        subtitle = Row(
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
        );
      case AngkaLevelState.done:
      case AngkaLevelState.notStarted:
      case AngkaLevelState.premiumLocked:
        if ((p?.bestStars ?? 0) > 0) {
          subtitle = AngkaStars(earned: p!.bestStars);
        }
    }

    final stateLabel = switch (s) {
      AngkaLevelState.premiumLocked => 'terkunci, perlu Akses Premium',
      AngkaLevelState.prerequisiteLocked => AppStrings.angkaFinishFirst(
        preNumber,
      ),
      AngkaLevelState.notStarted => 'belum dimulai',
      AngkaLevelState.inProgress => 'sedang dimainkan',
      AngkaLevelState.done => 'selesai, ${p?.bestStars ?? 0} bintang',
    };

    return Semantics(
      button: true,
      label:
          '${AppStrings.angkaLevelLabel(number)}, ${level.name}, $stateLabel${showFree ? ', gratis' : ''}',
      excludeSemantics: true,
      child: Material(
        color: s == AngkaLevelState.prerequisiteLocked
            ? const Color(0xFFF1EBE4)
            : AppColors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          key: ValueKey('angka-level-${level.id}'),
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                AngkaRangeBadge(
                  label: level.rangeLabel,
                  strong: s == AngkaLevelState.inProgress,
                  muted: locked,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            AppStrings.angkaLevelLabel(number),
                            style: AppTextStyles.caption.copyWith(
                              color: locked
                                  ? AppColors.textMedium
                                  : AngkaColors.blueText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (showFree)
                            _Chip(
                              AppStrings.angkaFree,
                              bg: AppColors.freeGreenSoft,
                              fg: AppColors.ownedGreen,
                            ),
                        ],
                      ),
                      Text(
                        level.name,
                        style: AppTextStyles.heading.copyWith(
                          fontSize: 17,
                          color: locked
                              ? AppColors.textDark.withValues(alpha: 0.7)
                              : AppColors.textDark,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 6),
                        subtitle,
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _Trailing(state: s),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Trailing extends StatelessWidget {
  final AngkaLevelState state;

  const _Trailing({required this.state});

  @override
  Widget build(BuildContext context) {
    Widget button(String label, {required bool filled}) => Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: filled ? AppColors.ctaRust : AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.ctaRust, width: 1.5),
      ),
      child: Text(
        label,
        style: AppTextStyles.button.copyWith(
          fontSize: 15,
          color: filled ? AppColors.white : AppColors.ctaRust,
        ),
      ),
    );
    return switch (state) {
      AngkaLevelState.premiumLocked ||
      AngkaLevelState.prerequisiteLocked => Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.lock_outline_rounded,
          color: AppColors.textMedium,
        ),
      ),
      AngkaLevelState.inProgress => button(
        AppStrings.angkaContinue,
        filled: true,
      ),
      AngkaLevelState.done => button(AppStrings.angkaPlayAgain, filled: false),
      AngkaLevelState.notStarted => button(AppStrings.angkaStart, filled: true),
    };
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;

  const _Chip(this.text, {required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          fontSize: 10,
          color: fg,
          fontWeight: FontWeight.w700,
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
