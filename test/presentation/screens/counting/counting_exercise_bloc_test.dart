import 'package:arunika_app/data/models/response/counting_question.dart';
import 'package:arunika_app/data/repositories/counting_repository.dart';
import 'package:arunika_app/presentation/screens/counting/counting_exercise_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCountingRepository extends Mock implements CountingRepository {}

final _q1 = const CountingQuestion(
  id: 'q-1',
  level: 'easy',
  questionJson: {'objects': 3},
  answer: 3,
);

final _q2 = const CountingQuestion(
  id: 'q-2',
  level: 'easy',
  questionJson: {'objects': 5},
  answer: 5,
);

void main() {
  late MockCountingRepository repo;

  setUp(() {
    repo = MockCountingRepository();
    when(
      () => repo.saveProgress(
        childId: any(named: 'childId'),
        questionId: any(named: 'questionId'),
        isCorrect: any(named: 'isCorrect'),
      ),
    ).thenAnswer((_) async {});
  });

  group('CountingExerciseBloc', () {
    blocTest<CountingExerciseBloc, CountingExerciseState>(
      'emits CountingExerciseQuestion on LoadCountingExercise',
      build: () => CountingExerciseBloc(repository: repo),
      act: (bloc) => bloc.add(
        LoadCountingExercise(questions: [_q1, _q2], childId: 'child-1'),
      ),
      expect: () => [
        CountingExerciseQuestion(
          question: _q1,
          index: 0,
          total: 2,
          childId: 'child-1',
        ),
      ],
    );

    blocTest<CountingExerciseBloc, CountingExerciseState>(
      'emits Done with 0 correct after empty questions',
      build: () => CountingExerciseBloc(repository: repo),
      act: (bloc) =>
          bloc.add(LoadCountingExercise(questions: [], childId: 'child-1')),
      expect: () => [const CountingExerciseDone(correct: 0, total: 0)],
    );

    blocTest<CountingExerciseBloc, CountingExerciseState>(
      'advances to next question on correct answer',
      build: () => CountingExerciseBloc(repository: repo),
      act: (bloc) async {
        bloc.add(
          LoadCountingExercise(questions: [_q1, _q2], childId: 'child-1'),
        );
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(const AnswerCounting(3)); // correct answer for q1
      },
      wait: const Duration(seconds: 2),
      skip: 1, // skip initial question state
      expect: () => [
        CountingExerciseLoading(),
        CountingExerciseQuestion(
          question: _q1,
          index: 0,
          total: 2,
          childId: 'child-1',
          lastAnswer: 3,
          lastCorrect: true,
        ),
        CountingExerciseQuestion(
          question: _q2,
          index: 1,
          total: 2,
          childId: 'child-1',
        ),
      ],
    );

    blocTest<CountingExerciseBloc, CountingExerciseState>(
      'marks lastCorrect=false on wrong answer',
      build: () => CountingExerciseBloc(repository: repo),
      act: (bloc) async {
        bloc.add(
          LoadCountingExercise(questions: [_q1, _q2], childId: 'child-1'),
        );
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(const AnswerCounting(99)); // wrong answer
      },
      wait: const Duration(seconds: 2),
      skip: 1,
      expect: () => [
        CountingExerciseLoading(),
        CountingExerciseQuestion(
          question: _q1,
          index: 0,
          total: 2,
          childId: 'child-1',
          lastAnswer: 99,
          lastCorrect: false,
        ),
        CountingExerciseQuestion(
          question: _q2,
          index: 1,
          total: 2,
          childId: 'child-1',
        ),
      ],
    );
  });
}
