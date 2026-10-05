import 'package:arunika_app/constants/app_colors.dart';
import 'package:arunika_app/constants/app_strings.dart';
import 'package:arunika_app/constants/app_text_styles.dart';
import 'package:arunika_app/core/media/media_cache.dart';
import 'package:arunika_app/core/tracing/letter_trace_session.dart';
import 'package:arunika_app/core/tracing/stroke_evaluator.dart';
import 'package:arunika_app/core/tracing/svg_path.dart';
import 'package:arunika_app/data/models/response/huruf_response.dart';
import 'package:arunika_app/data/repositories/huruf_repository.dart';
import 'package:arunika_app/presentation/screens/huruf/huruf_audio.dart';
import 'package:arunika_app/presentation/screens/huruf/huruf_cubit.dart';
import 'package:arunika_app/presentation/screens/huruf/huruf_widgets.dart';
import 'package:arunika_app/presentation/screens/huruf/tracing_canvas.dart';
import 'package:arunika_app/presentation/screens/widgets/learning_feedback_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';

/// "Huruf A": Kenali, Dengar and Tebalkan for one letter.
class HurufDetailScreen extends StatefulWidget {
  final HurufManifestLetter letter;
  final HurufActivity? initialActivity;

  /// Audio player; tests pass a fake.
  final HurufAudio Function()? audioFactory;

  const HurufDetailScreen({
    super.key,
    required this.letter,
    this.initialActivity,
    this.audioFactory,
  });

  @override
  State<HurufDetailScreen> createState() => _HurufDetailScreenState();
}

class _HurufDetailScreenState extends State<HurufDetailScreen> {
  late final HurufAudio _audio =
      (widget.audioFactory ?? JustAudioHurufAudio.new)();
  final _canvasKey = GlobalKey<TracingCanvasState>();

  HurufLetter? _content;
  LetterTraceSession? _session;
  bool _loadFailed = false;
  late HurufActivity _tab = widget.initialActivity ?? HurufActivity.kenali;

  /// Audio URLs that failed to load: their buttons show a retry icon.
  final Set<String> _audioFailed = {};

  HurufCubit get _cubit => context.read<HurufCubit>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _audio.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loadFailed = false);
    try {
      final content = await _cubit.letter(widget.letter);
      if (!mounted) return;
      setState(() {
        _content = content;
        _session = _buildSession(content);
      });
      // Seeing the letter completes Kenali, which also holds its sounds.
      _cubit.record(content.id, kenali: true, dengar: true);
    } on HurufLockedException {
      // The subscription lapsed: back to the grid, which now shows a lock.
      if (mounted) Navigator.of(context).maybePop();
    } catch (_) {
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  LetterTraceSession _buildSession(HurufLetter c) {
    List<GuideStroke> guide(List<HurufStroke> strokes) => [
      for (final s in strokes)
        if (isValidTracePath(s.path))
          GuideStroke(
            order: s.order,
            label: s.label,
            path: parseTracePath(s.path),
          ),
    ];
    return LetterTraceSession(
      upper: guide(c.upperStrokes),
      lower: guide(c.lowerStrokes),
      lowerRequired: c.lowerRequired,
      thresholds:
          _cubit.state.manifest?.thresholds ?? const TracingThresholds(),
    );
  }

  Future<void> _play(String url) async {
    final ok = await _audio.play(url);
    if (!mounted) return;
    setState(() => ok ? _audioFailed.remove(url) : _audioFailed.add(url));
  }

  void _openNext() {
    final next = _cubit.state.nextLetter(widget.letter.id);
    if (next == null) {
      Navigator.of(context).maybePop();
      return;
    }
    if (next.locked) {
      openHurufPaywall(context);
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        settings: RouteSettings(name: 'huruf-${next.upper}'),
        builder: (_) =>
            HurufDetailScreen(letter: next, audioFactory: widget.audioFactory),
      ),
    );
  }

  void _onTraceEvent(TraceEvent event) {
    final session = _session!;
    switch (event) {
      case TraceEvent.letterDone:
        _cubit.record(
          _content!.id,
          tebalkan: true,
          score: session.score,
          attempt: true,
        );
        _showSuccess();
      case TraceEvent.needsHelp:
        _cubit.record(_content!.id, attempt: true);
        _showRetry(session.lastFailure ?? StrokeFailure.offPath);
      case TraceEvent.caseDone:
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text(AppStrings.hurufLowerNow)),
          );
      case TraceEvent.strokePassed ||
          TraceEvent.strokeFailed ||
          TraceEvent.ignored:
        break;
    }
  }

  void _finishPressed() {
    final session = _session;
    if (session == null) return;
    if (session.letterComplete) {
      _showSuccess();
    } else {
      _showRetry(StrokeFailure.tooShort);
    }
  }

  void _showSuccess() {
    final c = _content!;
    final next = _cubit.state.nextLetter(c.id);
    final freeSample = !_cubit.state.premium && widget.letter.isFree;
    LearningFeedbackDialog.show(
      context,
      LearningFeedbackDialog(
        kind: LearningFeedbackKind.success,
        title: c.successTitle.isEmpty
            ? 'Keren! Huruf ${c.upper} rapi!'
            : c.successTitle,
        subtitle: AppStrings.hurufSuccessBody(c.upper),
        primary: FeedbackAction(
          next == null
              ? AppStrings.hurufBackToList
              : AppStrings.hurufNextLetter(next.upper),
          () {
            Navigator.of(context, rootNavigator: true).pop();
            _openNext();
          },
        ),
        extra: freeSample
            ? FeedbackAction(AppStrings.hurufUnlockAll, () {
                Navigator.of(context, rootNavigator: true).pop();
                openHurufPaywall(context);
              })
            : null,
        secondary: FeedbackAction(AppStrings.hurufTraceAgain, () {
          Navigator.of(context, rootNavigator: true).pop();
          _session!.restart();
          _canvasKey.currentState?.refresh();
          setState(() {});
        }),
      ),
    );
  }

  void _showRetry(StrokeFailure failure) {
    final c = _content!;
    final reason = switch (failure) {
      StrokeFailure.offPath => AppStrings.hurufReasonOffPath(c.upper),
      StrokeFailure.tooShort => AppStrings.hurufReasonTooShort,
      StrokeFailure.wrongDirection => AppStrings.hurufReasonWrongDirection,
    };
    LearningFeedbackDialog.show(
      context,
      LearningFeedbackDialog(
        kind: LearningFeedbackKind.retry,
        title: c.retryTitle.isEmpty ? 'Belum pas, ayo lagi!' : c.retryTitle,
        subtitle: reason,
        hint: c.hint,
        primary: FeedbackAction(AppStrings.hurufTryAgain, () {
          Navigator.of(context, rootNavigator: true).pop();
          _session!.resetCase();
          _canvasKey.currentState?.refresh();
        }),
        secondary: FeedbackAction(AppStrings.hurufShowExample, () {
          Navigator.of(context, rootNavigator: true).pop();
          _session!.resetCase();
          _canvasKey.currentState?.refresh();
          _canvasKey.currentState?.playDemo();
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final next = context.select<HurufCubit, HurufManifestLetter?>(
      (c) => c.state.nextLetter(widget.letter.id),
    );
    final progress = context.select<HurufCubit, HurufProgress?>(
      (c) => c.state.progress[widget.letter.id],
    );
    return Scaffold(
      backgroundColor: AppColors.warmPage,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Row(
              children: [
                HurufBackButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    AppStrings.hurufLetterTitle(widget.letter.upper),
                    style: AppTextStyles.displayLarge,
                  ),
                ),
                if (next != null)
                  _NextLetterButton(letter: next, onPressed: _openNext),
              ],
            ),
            const SizedBox(height: 16),
            _Tabs(
              selected: _tab,
              progress: progress,
              onSelect: (t) => setState(() => _tab = t),
            ),
            const SizedBox(height: 14),
            if (_loadFailed)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Column(
                  children: [
                    Text(AppStrings.hurufLoadError, style: AppTextStyles.body),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: _load,
                      child: const Text(AppStrings.hurufRetry),
                    ),
                  ],
                ),
              )
            else if (_content == null)
              const Padding(
                padding: EdgeInsets.only(top: 60),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.ctaRust),
                ),
              )
            else
              ..._activity(),
          ],
        ),
      ),
    );
  }

  List<Widget> _activity() {
    final c = _content!;
    switch (_tab) {
      case HurufActivity.kenali:
        return [
          _KenaliCard(
            content: c,
            letterAudioFailed: _audioFailed.contains(c.letterAudioUrl),
            wordAudioFailed: _audioFailed.contains(c.wordAudioUrl),
            onLetterSound: () => _play(c.letterAudioUrl),
            onWordSound: () => _play(c.wordAudioUrl),
            onNext: () => setState(() => _tab = HurufActivity.tebalkan),
          ),
        ];
      case HurufActivity.tebalkan:
        final session = _session!;
        final shown = session.currentCase == LetterCase.lower
            ? c.lower
            : c.upper;
        return [
          _LetterCard(
            content: c,
            letterAudioFailed: _audioFailed.contains(c.letterAudioUrl),
            wordAudioFailed: _audioFailed.contains(c.wordAudioUrl),
            onLetterSound: () => _play(c.letterAudioUrl),
            onWordSound: () => _play(c.wordAudioUrl),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 2,
                  children: [
                    Text(
                      AppStrings.hurufTraceTitle(shown),
                      style: AppTextStyles.heading.copyWith(fontSize: 16),
                    ),
                    Text(
                      AppStrings.hurufTraceHint,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF6F1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: TracingCanvas(
                    key: _canvasKey,
                    session: session,
                    onEvent: (e) {
                      setState(() {});
                      _onTraceEvent(e);
                    },
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textDark,
                            side: const BorderSide(color: Color(0xFFE6DFD6)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () {
                            session.resetCase();
                            _canvasKey.currentState?.refresh();
                            setState(() {});
                          },
                          icon: const Icon(Icons.refresh_rounded),
                          label: const FittedBox(
                            child: Text(AppStrings.hurufRepeat),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.ctaRust,
                            foregroundColor: AppColors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: _finishPressed,
                          child: const FittedBox(
                            child: Text(AppStrings.hurufFinish),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ];
    }
  }
}

class _NextLetterButton extends StatelessWidget {
  final HurufManifestLetter letter;
  final VoidCallback onPressed;

  const _NextLetterButton({required this.letter, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label:
          'Huruf berikutnya, ${letter.upper}${letter.locked ? ', terkunci' : ''}',
      excludeSemantics: true,
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          key: const ValueKey('huruf-next'),
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: SizedBox(
            height: 48,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    letter.upper,
                    style: AppTextStyles.button.copyWith(
                      color: HurufColors.teal,
                    ),
                  ),
                  Icon(
                    letter.locked
                        ? Icons.lock_rounded
                        : Icons.chevron_right_rounded,
                    size: letter.locked ? 16 : 22,
                    color: HurufColors.teal,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  final HurufActivity selected;
  final HurufProgress? progress;
  final ValueChanged<HurufActivity> onSelect;

  const _Tabs({
    required this.selected,
    required this.progress,
    required this.onSelect,
  });

  bool _done(HurufActivity a) => switch (a) {
    HurufActivity.kenali => progress?.kenaliDone ?? false,
    HurufActivity.tebalkan => progress?.tebalkanDone ?? false,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: HurufColors.segment,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          for (final a in HurufActivity.values)
            Expanded(
              child: Semantics(
                button: true,
                selected: a == selected,
                label: '${hurufActivityLabel(a)}${_done(a) ? ', selesai' : ''}',
                excludeSemantics: true,
                child: GestureDetector(
                  key: ValueKey('huruf-tab-${a.name}'),
                  onTap: () => onSelect(a),
                  child: Container(
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: a == selected ? AppColors.white : null,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _done(a)
                          ? '${hurufActivityLabel(a)} ✓'
                          : hurufActivityLabel(a),
                      style: AppTextStyles.body.copyWith(
                        fontWeight: a == selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: a == selected
                            ? HurufColors.teal
                            : AppColors.textDark,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The mint card: big "Aa", "Dengar bunyi" and the example word.
class _LetterCard extends StatelessWidget {
  final HurufLetter content;
  final bool letterAudioFailed;
  final bool wordAudioFailed;
  final VoidCallback onLetterSound;
  final VoidCallback onWordSound;

  const _LetterCard({
    required this.content,
    required this.letterAudioFailed,
    required this.wordAudioFailed,
    required this.onLetterSound,
    required this.onWordSound,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HurufColors.mint,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 112,
            height: 112,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: FittedBox(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  '${content.upper}${content.lower}',
                  style: AppTextStyles.displayLarge.copyWith(
                    fontSize: 52,
                    color: HurufColors.teal,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    key: const ValueKey('huruf-letter-sound'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HurufColors.teal,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: onLetterSound,
                    icon: Icon(
                      letterAudioFailed
                          ? Icons.refresh_rounded
                          : Iconsax.volume_high,
                      size: 20,
                    ),
                    label: FittedBox(
                      child: Text(
                        letterAudioFailed
                            ? AppStrings.hurufAudioRetry
                            : AppStrings.hurufListenSound,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: Material(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      key: const ValueKey('huruf-word-sound'),
                      borderRadius: BorderRadius.circular(14),
                      onTap: onWordSound,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (wordAudioFailed)
                            const Icon(Icons.refresh_rounded, size: 18)
                          else if (content.imageUrl.isNotEmpty)
                            Image(
                              image: MediaCache.image(content.imageUrl),
                              width: 26,
                              height: 26,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox(width: 26),
                            ),
                          const SizedBox(width: 6),
                          Flexible(child: HighlightedWord(content: content)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The example word with the letter's positions highlighted (**A**pel).
class HighlightedWord extends StatelessWidget {
  final HurufLetter content;
  final double? fontSize;

  const HighlightedWord({super.key, required this.content, this.fontSize});

  @override
  Widget build(BuildContext context) {
    final chars = content.word.characters.toList();
    return Text.rich(
      TextSpan(
        children: [
          for (var i = 0; i < chars.length; i++)
            TextSpan(
              text: chars[i],
              style: content.highlight.contains(i)
                  ? const TextStyle(
                      color: HurufColors.teal,
                      fontWeight: FontWeight.w800,
                      decoration: TextDecoration.underline,
                    )
                  : null,
            ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.button.copyWith(
        color: AppColors.textDark,
        fontSize: fontSize,
      ),
    );
  }
}

/// Kenali: the example picture, the letter in both cases and the word with
/// the letter highlighted, plus the letter and word sounds. Tapping the
/// picture or the word plays the word.
class _KenaliCard extends StatelessWidget {
  final HurufLetter content;
  final bool letterAudioFailed;
  final bool wordAudioFailed;
  final VoidCallback onLetterSound;
  final VoidCallback onWordSound;
  final VoidCallback onNext;

  const _KenaliCard({
    required this.content,
    required this.letterAudioFailed,
    required this.wordAudioFailed,
    required this.onLetterSound,
    required this.onWordSound,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: HurufColors.mint,
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_outlined,
        size: 64,
        color: HurufColors.teal,
      ),
    );
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Semantics(
              button: true,
              label: content.word,
              excludeSemantics: true,
              child: GestureDetector(
                key: const ValueKey('huruf-kenali-picture'),
                onTap: onWordSound,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: SizedBox.square(
                    dimension: 200,
                    child: content.imageUrl.isEmpty
                        ? placeholder
                        : Image(
                            image: MediaCache.image(content.imageUrl),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => placeholder,
                          ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${content.upper} ${content.lower}',
              style: AppTextStyles.displayLarge.copyWith(
                fontSize: 72,
                height: 1.1,
                color: HurufColors.teal,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: InkWell(
              key: const ValueKey('huruf-word-sound'),
              borderRadius: BorderRadius.circular(14),
              onTap: onWordSound,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      wordAudioFailed
                          ? Icons.refresh_rounded
                          : Iconsax.volume_high,
                      size: 22,
                      color: HurufColors.teal,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: HighlightedWord(content: content, fontSize: 28),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              key: const ValueKey('huruf-letter-sound'),
              style: ElevatedButton.styleFrom(
                backgroundColor: HurufColors.teal,
                foregroundColor: AppColors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: onLetterSound,
              icon: Icon(
                letterAudioFailed ? Icons.refresh_rounded : Iconsax.volume_high,
                size: 20,
              ),
              label: FittedBox(
                child: Text(
                  letterAudioFailed
                      ? AppStrings.hurufAudioRetry
                      : AppStrings.hurufListenSound,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              key: const ValueKey('huruf-kenali-next'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ctaRust,
                foregroundColor: AppColors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: onNext,
              child: const Text(AppStrings.hurufNextTebalkan),
            ),
          ),
        ],
      ),
    );
  }
}
