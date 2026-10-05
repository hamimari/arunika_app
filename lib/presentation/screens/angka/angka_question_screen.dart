import 'dart:async';

import 'package:arunika_app/constants/app_colors.dart';
import 'package:arunika_app/constants/app_strings.dart';
import 'package:arunika_app/constants/app_text_styles.dart';
import 'package:arunika_app/core/angka/question_generator.dart';
import 'package:arunika_app/data/models/response/angka_response.dart';
import 'package:arunika_app/presentation/screens/angka/angka_cubit.dart';
import 'package:arunika_app/presentation/screens/angka/angka_play_cubit.dart';
import 'package:arunika_app/presentation/screens/angka/angka_screen.dart';
import 'package:arunika_app/presentation/screens/angka/angka_widgets.dart';
import 'package:arunika_app/presentation/screens/huruf/huruf_audio.dart';
import 'package:arunika_app/presentation/screens/widgets/learning_feedback_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// "Level 2 · Soal 3 dari 10": one Hitung Benda level, question by question.
class AngkaQuestionScreen extends StatelessWidget {
  final AngkaManifestLevel level;

  /// Start over instead of resuming ("Main lagi").
  final bool restart;

  /// Audio player; tests pass a fake.
  final HurufAudio Function()? audioFactory;

  const AngkaQuestionScreen({
    super.key,
    required this.level,
    this.restart = false,
    this.audioFactory,
  });

  @override
  Widget build(BuildContext context) {
    final angka = context.read<AngkaCubit>();
    return BlocProvider(
      create: (_) => AngkaPlayCubit(
        repository: angka.repository,
        childId: angka.childId ?? '',
        levelId: level.id,
      )..start(restart: restart),
      child: _QuestionView(level: level, audioFactory: audioFactory),
    );
  }
}

class _QuestionView extends StatefulWidget {
  final AngkaManifestLevel level;
  final HurufAudio Function()? audioFactory;

  const _QuestionView({required this.level, this.audioFactory});

  @override
  State<_QuestionView> createState() => _QuestionViewState();
}

class _QuestionViewState extends State<_QuestionView> {
  late final HurufAudio _audio =
      (widget.audioFactory ?? JustAudioHurufAudio.new)();
  late final AngkaCubit _angka = context.read<AngkaCubit>();

  AngkaPlayCubit get _play => context.read<AngkaPlayCubit>();

  @override
  void dispose() {
    _audio.dispose();
    // Back on the list, show the new progress ("Lanjut", stars, unlocks).
    unawaited(_angka.load(force: true));
    super.dispose();
  }

  /// Plays the question audio; only when the child asks for it.
  void _speakQuestion(AngkaPlayState s) {
    final url = s.object?.questionAudioUrl ?? '';
    if (url.isNotEmpty) _audio.play(url);
  }

  void _onState(BuildContext context, AngkaPlayState s) {
    switch (s.phase) {
      case AngkaPlayPhase.success:
        _showSuccess(s);
      case AngkaPlayPhase.retry:
        _showRetry(s);
      case AngkaPlayPhase.done:
        _showLevelDone(s);
      case AngkaPlayPhase.premiumLocked:
      case AngkaPlayPhase.prerequisiteLocked:
        Navigator.of(context).maybePop();
      case AngkaPlayPhase.answering:
      case AngkaPlayPhase.loading:
      case AngkaPlayPhase.completing:
      case AngkaPlayPhase.error:
        break;
    }
  }

  void _closeDialog() => Navigator.of(context, rootNavigator: true).pop();

  void _showSuccess(AngkaPlayState s) {
    final c = s.session!.content;
    LearningFeedbackDialog.show(
      context,
      LearningFeedbackDialog(
        kind: LearningFeedbackKind.success,
        title: c.successTitle.isEmpty ? 'Hebat! Benar!' : c.successTitle,
        subtitle: AppStrings.angkaSuccessBody(s.question!.count, s.benda),
        showStars: s.firstTry,
        primary: FeedbackAction(AppStrings.angkaNextQuestion, () {
          _closeDialog();
          _play.next();
        }),
        secondary: FeedbackAction(AppStrings.angkaBackToMenu, () {
          _closeDialog();
          Navigator.of(context).maybePop();
        }),
      ),
    );
  }

  void _showRetry(AngkaPlayState s) {
    final c = s.session!.content;
    LearningFeedbackDialog.show(
      context,
      LearningFeedbackDialog(
        kind: LearningFeedbackKind.retry,
        title: c.retryTitle.isEmpty ? 'Hampir benar!' : c.retryTitle,
        subtitle: AppStrings.angkaRetryBody(s.lastAnswer ?? 0, s.benda),
        hint: c.hint.replaceAll('{benda}', s.benda),
        primary: FeedbackAction(AppStrings.angkaTryAgain, () {
          _closeDialog();
          _play.tryAgain();
        }),
        secondary: FeedbackAction(AppStrings.angkaListenAgain, () {
          _closeDialog();
          _play.tryAgain();
          _speakQuestion(s);
        }),
      ),
    );
  }

  void _showLevelDone(AngkaPlayState s) {
    final r = s.result!;
    final level = widget.level;
    final total = s.questions.length;
    final angka = _angka.state;
    final freeSample = !angka.premium && level.isFree;
    // A level this one just unlocked, unless it still needs Akses Premium;
    // the list's progress isn't refreshed yet, so it can't tell.
    final unlocked = angka.levels
        .where((l) => r.unlockedLevelIds.contains(l.id) && !l.locked)
        .firstOrNull;
    final next = unlocked ?? angka.nextOpenLevel(level.id);
    LearningFeedbackDialog.show(
      context,
      LearningFeedbackDialog(
        kind: LearningFeedbackKind.success,
        title: AppStrings.angkaLevelDoneTitle,
        subtitle: [
          AppStrings.angkaLevelDoneBody(r.firstCorrect, total),
          if (s.provisional) AppStrings.angkaProvisional,
        ].join(' '),
        starsEarned: r.stars,
        primary: next != null
            ? FeedbackAction(AppStrings.angkaNextLevel, () {
                _closeDialog();
                openAngkaLevel(
                  context,
                  next,
                  audioFactory: widget.audioFactory,
                  replace: true,
                );
              })
            : FeedbackAction(AppStrings.angkaPlayAgain, () {
                _closeDialog();
                _play.start(restart: true);
              }),
        extra: freeSample
            ? FeedbackAction(AppStrings.angkaUnlockAll, () {
                _closeDialog();
                final nav = Navigator.of(context);
                openAngkaPaywall(context).then((_) {
                  if (mounted) nav.maybePop();
                });
              })
            : null,
        secondary: FeedbackAction(AppStrings.angkaBackToMenu, () {
          _closeDialog();
          Navigator.of(context).maybePop();
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmPage,
      body: SafeArea(
        child: BlocConsumer<AngkaPlayCubit, AngkaPlayState>(
          listenWhen: (a, b) => a.phase != b.phase || a.index != b.index,
          listener: _onState,
          builder: (context, s) {
            if (s.phase == AngkaPlayPhase.error) {
              return _Failed(
                onRetry: () => _play.start(),
                onClose: () => Navigator.of(context).maybePop(),
              );
            }
            // Past the last question (completing, done) the last one stays.
            final q =
                s.question ?? (s.questions.isEmpty ? null : s.questions.last);
            if (s.session == null || q == null) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.ctaRust),
              );
            }
            return _question(s, q);
          },
        ),
      ),
    );
  }

  Widget _question(AngkaPlayState s, AngkaQuestion q) {
    final object = s.session!.objects[q.objectId];
    final levelNo = _angka.state.levelNumber(widget.level.id);
    final total = s.questions.length;
    final shown = s.input;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Row(
          children: [
            AngkaSquareButton(
              key: const ValueKey('angka-close'),
              icon: Icons.close_rounded,
              label: 'Tutup',
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.angkaQuestionHeader(
                      levelNo == 0 ? 1 : levelNo,
                      s.index < total ? s.index + 1 : total,
                      total,
                    ),
                    style: AppTextStyles.caption.copyWith(
                      color: AngkaColors.blueText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: total == 0 ? 0 : s.index / total,
                      minHeight: 8,
                      color: AngkaColors.blue,
                      backgroundColor: AngkaColors.track,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Semantics(
              label: '${s.firstCorrect} bintang',
              excludeSemantics: true,
              child: Container(
                key: const ValueKey('angka-star-count'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: AngkaColors.gold,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${s.firstCorrect}',
                      style: AppTextStyles.subheading.copyWith(fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: Text(
                (object?.questionText.isNotEmpty ?? false)
                    ? object!.questionText
                    : AppStrings.angkaQuestionFallback(object?.name ?? ""),
                style: AppTextStyles.displayLarge.copyWith(fontSize: 26),
              ),
            ),
            const SizedBox(width: 12),
            AngkaSpeakerButton(
              key: const ValueKey('angka-question-speaker'),
              label: AppStrings.angkaListen,
              onPressed: () => _speakQuestion(s),
            ),
          ],
        ),
        const SizedBox(height: 14),
        AngkaPictureArea(
          question: q,
          imageUrl: object?.imageUrl ?? '',
          marks: s.marks,
          onTapPicture: (i) {
            final n = _play.mark(i);
            final url = n == null ? null : s.session!.countAudio[n];
            if (url != null) _audio.play(url);
          },
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: Text(
                AppStrings.angkaYourAnswer,
                style: AppTextStyles.subheading,
              ),
            ),
            Semantics(
              label:
                  '${AppStrings.angkaYourAnswer} ${shown.isEmpty ? 'kosong' : int.parse(shown)}',
              excludeSemantics: true,
              child: CustomPaint(
                painter: _DashedBorder(
                  color: shown.isEmpty
                      ? const Color(0xFFD9CFC5)
                      : AngkaColors.blue,
                ),
                child: Container(
                  key: const ValueKey('angka-answer'),
                  width: 104,
                  height: 72,
                  alignment: Alignment.center,
                  child: Text(
                    shown.isEmpty ? '?' : shown,
                    style: AppTextStyles.displayLarge.copyWith(
                      fontSize: 36,
                      color: shown.isEmpty
                          ? const Color(0xFFCFC4B8)
                          : AngkaColors.blue,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AngkaNumberPad(
          onDigit: _play.type,
          onDelete: _play.backspace,
          onCheck: s.input.isEmpty || s.phase != AngkaPlayPhase.answering
              ? null
              : _play.check,
        ),
      ],
    );
  }
}

class _Failed extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onClose;

  const _Failed({required this.onRetry, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            AppStrings.angkaLoadError,
            style: AppTextStyles.body.copyWith(color: AppColors.textMedium),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text(AppStrings.hurufRetry),
          ),
          TextButton(
            onPressed: onClose,
            child: const Text(AppStrings.angkaBackToMenu),
          ),
        ],
      ),
    );
  }
}

/// The dashed rounded box around the answer.
class _DashedBorder extends CustomPainter {
  final Color color;

  _DashedBorder({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(18)),
      );
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 12) {
        canvas.drawPath(metric.extractPath(d, d + 7), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) => old.color != color;
}
