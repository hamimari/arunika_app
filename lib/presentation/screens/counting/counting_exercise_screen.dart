import 'package:arunika_app/constants/app_colors.dart';
import 'package:arunika_app/constants/app_text_styles.dart';
import 'package:arunika_app/core/storage/LocalProfileStorage.dart';
import 'package:arunika_app/data/models/response/counting_question.dart';
import 'package:arunika_app/data/repositories/counting_repository.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/presentation/screens/counting/counting_exercise_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class CountingExerciseScreen extends StatelessWidget {
  final List<CountingQuestion> questions;
  const CountingExerciseScreen({super.key, required this.questions});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          CountingExerciseBloc(repository: locator<CountingRepository>()),
      child: _CountingExerciseView(questions: questions),
    );
  }
}

class _CountingExerciseView extends StatefulWidget {
  final List<CountingQuestion> questions;
  const _CountingExerciseView({required this.questions});

  @override
  State<_CountingExerciseView> createState() => _CountingExerciseViewState();
}

class _CountingExerciseViewState extends State<_CountingExerciseView> {
  @override
  void initState() {
    super.initState();
    _loadChild();
  }

  Future<void> _loadChild() async {
    final profile = await LocalProfileStorage.get();
    if (profile != null && profile.children.isNotEmpty && mounted) {
      context.read<CountingExerciseBloc>().add(
        LoadCountingExercise(
          questions: widget.questions,
          childId: profile.children.first.id,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFEDD5),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFEDD5), AppColors.pageBackground],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text('Menghitung', style: AppTextStyles.heading),
                  ],
                ),
              ),
              // ── Body ────────────────────────────────────────────────
              Expanded(
                child: BlocBuilder<CountingExerciseBloc, CountingExerciseState>(
                  builder: (ctx, state) {
                    if (state is CountingExerciseLoading ||
                        state is CountingExerciseInitial) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryOrange,
                        ),
                      );
                    }
                    if (state is CountingExerciseQuestion) {
                      return _QuestionView(state: state);
                    }
                    if (state is CountingExerciseDone) {
                      return _DoneView(
                        correct: state.correct,
                        total: state.total,
                        onBack: () => context.pop(),
                      );
                    }
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryOrange,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Question view ──────────────────────────────────────────────────────────────

class _QuestionView extends StatelessWidget {
  final CountingExerciseQuestion state;
  const _QuestionView({required this.state});

  List<int> _choices() {
    final correct = state.question.answer;
    final choices = <int>{correct};
    int offset = 1;
    while (choices.length < 4) {
      choices.add((correct + offset).clamp(0, 30));
      if (choices.length < 4) choices.add((correct - offset).clamp(0, 30));
      offset++;
    }
    final list = choices.toList()..shuffle();
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final choices = _choices();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Progress indicator
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (state.index + 1) / state.total,
                    minHeight: 8,
                    backgroundColor: AppColors.primaryOrange.withValues(
                      alpha: 0.15,
                    ),
                    valueColor: const AlwaysStoppedAnimation(
                      AppColors.primaryOrange,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${state.index + 1}/${state.total}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMedium,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Question card
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryOrange.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.calculate_rounded,
                  size: 56,
                  color: AppColors.primaryOrange,
                ),
                const SizedBox(height: 16),
                Text(
                  'Berapa jumlahnya?',
                  style: AppTextStyles.subheading.copyWith(
                    color: AppColors.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Answer choices
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.2,
              physics: const NeverScrollableScrollPhysics(),
              children: choices.map((c) {
                Color bgColor = AppColors.white;
                Color textColor = AppColors.textDark;
                if (state.lastAnswer == c) {
                  if (state.lastCorrect == true) {
                    bgColor = const Color(0xFF4CAF50);
                    textColor = Colors.white;
                  } else {
                    bgColor = const Color(0xFFE53935);
                    textColor = Colors.white;
                  }
                }
                return GestureDetector(
                  onTap: state.lastAnswer != null
                      ? null
                      : () => context.read<CountingExerciseBloc>().add(
                          AnswerCounting(c),
                        ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryOrange.withValues(
                            alpha: 0.08,
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '$c',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Done view ──────────────────────────────────────────────────────────────────

class _DoneView extends StatelessWidget {
  final int correct;
  final int total;
  final VoidCallback onBack;
  const _DoneView({
    required this.correct,
    required this.total,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0 : (correct / total * 100).round();
    final passed = pct >= 70;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: passed
                  ? const Color(0xFF4CAF50).withValues(alpha: 0.10)
                  : AppColors.primaryOrange.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              passed ? Icons.emoji_events_rounded : Icons.refresh_rounded,
              size: 72,
              color: passed ? const Color(0xFF4CAF50) : AppColors.primaryOrange,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            passed ? 'Bagus Sekali! 🎉' : 'Terus Semangat!',
            style: AppTextStyles.heading,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '$correct dari $total jawaban benar ($pct%)',
            style: AppTextStyles.body.copyWith(color: AppColors.textMedium),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onBack,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Kembali',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
