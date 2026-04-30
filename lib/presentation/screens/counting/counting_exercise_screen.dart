import 'package:arunika_app/core/storage/LocalProfileStorage.dart';
import 'package:arunika_app/data/models/response/counting_question.dart';
import 'package:arunika_app/data/repositories/counting_repository.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/presentation/screens/counting/counting_exercise_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    if (profile != null && profile.children.isNotEmpty) {
      if (mounted) {
        context.read<CountingExerciseBloc>().add(
          LoadCountingExercise(
            questions: widget.questions,
            childId: profile.children.first.id,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Menghitung')),
      body: BlocBuilder<CountingExerciseBloc, CountingExerciseState>(
        builder: (ctx, state) {
          if (state is CountingExerciseLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CountingExerciseQuestion) {
            return _QuestionView(state: state);
          }
          if (state is CountingExerciseDone) {
            return _DoneView(correct: state.correct, total: state.total);
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

class _QuestionView extends StatelessWidget {
  final CountingExerciseQuestion state;
  const _QuestionView({required this.state});

  List<int> _choices() {
    final correct = state.question.answer;
    final choices = <int>{correct};
    while (choices.length < 4) {
      choices.add((correct + choices.length).clamp(1, 20));
    }
    return choices.toList()..shuffle();
  }

  @override
  Widget build(BuildContext context) {
    final choices = _choices();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${state.index + 1} / ${state.total}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'Berapa jumlahnya?',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.5,
            children: choices.map((c) {
              Color? color;
              if (state.lastAnswer == c) {
                color = state.lastCorrect == true
                    ? Colors.green.shade400
                    : Colors.red.shade400;
              }
              return SizedBox(
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    minimumSize: const Size.fromHeight(56),
                  ),
                  onPressed: state.lastAnswer != null
                      ? null
                      : () => context.read<CountingExerciseBloc>().add(
                          AnswerCounting(c),
                        ),
                  child: Text('$c', style: const TextStyle(fontSize: 20)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _DoneView extends StatelessWidget {
  final int correct;
  final int total;
  const _DoneView({required this.correct, required this.total});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events, size: 80, color: Colors.amber),
          const SizedBox(height: 16),
          Text(
            'Selesai! $correct / $total benar',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kembali'),
          ),
        ],
      ),
    );
  }
}
