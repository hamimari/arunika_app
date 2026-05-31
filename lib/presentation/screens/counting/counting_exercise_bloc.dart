import 'package:arunika_app/data/models/response/counting_question.dart';
import 'package:arunika_app/data/repositories/counting_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ── Events ────────────────────────────────────────────────────────────────────
abstract class CountingExerciseEvent extends Equatable {
  const CountingExerciseEvent();
  @override
  List<Object?> get props => [];
}

class LoadCountingExercise extends CountingExerciseEvent {
  final List<CountingQuestion> questions;
  final String childId;
  const LoadCountingExercise({required this.questions, required this.childId});
  @override
  List<Object?> get props => [questions, childId];
}

class AnswerCounting extends CountingExerciseEvent {
  final int selectedAnswer;
  const AnswerCounting(this.selectedAnswer);
  @override
  List<Object?> get props => [selectedAnswer];
}

// ── States ────────────────────────────────────────────────────────────────────
abstract class CountingExerciseState extends Equatable {
  const CountingExerciseState();
  @override
  List<Object?> get props => [];
}

class CountingExerciseInitial extends CountingExerciseState {}

class CountingExerciseLoading extends CountingExerciseState {}

class CountingExerciseQuestion extends CountingExerciseState {
  final CountingQuestion question;
  final int index;
  final int total;
  final String childId;
  final int? lastAnswer;
  final bool? lastCorrect;
  const CountingExerciseQuestion({
    required this.question,
    required this.index,
    required this.total,
    required this.childId,
    this.lastAnswer,
    this.lastCorrect,
  });
  @override
  List<Object?> get props => [question.id, index, lastAnswer, lastCorrect];
}

class CountingExerciseDone extends CountingExerciseState {
  final int correct;
  final int total;
  const CountingExerciseDone({required this.correct, required this.total});
  @override
  List<Object?> get props => [correct, total];
}

class CountingExerciseError extends CountingExerciseState {
  final String message;
  const CountingExerciseError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── BLoC ──────────────────────────────────────────────────────────────────────
class CountingExerciseBloc
    extends Bloc<CountingExerciseEvent, CountingExerciseState> {
  final CountingRepository repository;
  List<CountingQuestion> _questions = [];
  String _childId = '';
  int _currentIndex = 0;
  int _correctCount = 0;

  CountingExerciseBloc({required this.repository})
    : super(CountingExerciseInitial()) {
    on<LoadCountingExercise>(_onLoad);
    on<AnswerCounting>(_onAnswer);
  }

  void _onLoad(
    LoadCountingExercise event,
    Emitter<CountingExerciseState> emit,
  ) {
    _questions = event.questions;
    _childId = event.childId;
    _currentIndex = 0;
    _correctCount = 0;
    if (_questions.isEmpty) {
      emit(CountingExerciseDone(correct: 0, total: 0));
      return;
    }
    emit(
      CountingExerciseQuestion(
        question: _questions[0],
        index: 0,
        total: _questions.length,
        childId: _childId,
      ),
    );
  }

  Future<void> _onAnswer(
    AnswerCounting event,
    Emitter<CountingExerciseState> emit,
  ) async {
    if (_questions.isEmpty || _currentIndex >= _questions.length) return;

    final current = _questions[_currentIndex];
    final isCorrect = event.selectedAnswer == current.answer;
    if (isCorrect) _correctCount++;

    emit(CountingExerciseLoading());
    try {
      await repository.saveProgress(
        childId: _childId,
        questionId: current.id,
        isCorrect: isCorrect,
      );
    } catch (_) {}

    // Show feedback state momentarily before advancing.
    emit(
      CountingExerciseQuestion(
        question: current,
        index: _currentIndex,
        total: _questions.length,
        childId: _childId,
        lastAnswer: event.selectedAnswer,
        lastCorrect: isCorrect,
      ),
    );

    await Future.delayed(const Duration(milliseconds: 800));

    _currentIndex++;
    if (_currentIndex >= _questions.length) {
      emit(
        CountingExerciseDone(correct: _correctCount, total: _questions.length),
      );
    } else {
      emit(
        CountingExerciseQuestion(
          question: _questions[_currentIndex],
          index: _currentIndex,
          total: _questions.length,
          childId: _childId,
        ),
      );
    }
  }
}
