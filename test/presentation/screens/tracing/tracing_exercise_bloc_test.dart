import 'package:arunika_app/data/models/response/tracing_item.dart';
import 'package:arunika_app/data/repositories/tracing_repository.dart';
import 'package:arunika_app/presentation/screens/tracing/tracing_exercise_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTracingRepository extends Mock implements TracingRepository {}

final _item = const TracingItem(
  id: 'item-1',
  type: 'alphabet',
  label: 'A',
  guidePathJson: '[]',
  difficulty: 1,
);

void main() {
  late MockTracingRepository repo;

  setUp(() {
    repo = MockTracingRepository();
  });

  group('TracingExerciseBloc', () {
    blocTest<TracingExerciseBloc, TracingExerciseState>(
      'emits TracingExerciseReady on LoadTracingExercise',
      build: () => TracingExerciseBloc(repository: repo),
      act: (bloc) =>
          bloc.add(LoadTracingExercise(item: _item, childId: 'child-1')),
      expect: () => [TracingExerciseReady(item: _item, childId: 'child-1')],
    );

    blocTest<TracingExerciseBloc, TracingExerciseState>(
      'emits TracingExercisePassed when passed=true',
      build: () => TracingExerciseBloc(repository: repo),
      setUp: () {
        when(
          () => repo.saveProgress(
            childId: any(named: 'childId'),
            itemId: any(named: 'itemId'),
            score: any(named: 'score'),
            passed: any(named: 'passed'),
          ),
        ).thenAnswer((_) async {});
      },
      seed: () => TracingExerciseReady(item: _item, childId: 'child-1'),
      act: (bloc) =>
          bloc.add(const SubmitTracingResult(score: 90, passed: true)),
      expect: () => [
        TracingExerciseLoading(),
        const TracingExercisePassed(score: 90),
      ],
    );

    blocTest<TracingExerciseBloc, TracingExerciseState>(
      'emits TracingExerciseFailed when passed=false',
      build: () => TracingExerciseBloc(repository: repo),
      setUp: () {
        when(
          () => repo.saveProgress(
            childId: any(named: 'childId'),
            itemId: any(named: 'itemId'),
            score: any(named: 'score'),
            passed: any(named: 'passed'),
          ),
        ).thenAnswer((_) async {});
      },
      seed: () => TracingExerciseReady(item: _item, childId: 'child-1'),
      act: (bloc) =>
          bloc.add(const SubmitTracingResult(score: 40, passed: false)),
      expect: () => [
        TracingExerciseLoading(),
        const TracingExerciseFailed(score: 40),
      ],
    );

    blocTest<TracingExerciseBloc, TracingExerciseState>(
      'emits TracingExerciseError on repository failure',
      build: () => TracingExerciseBloc(repository: repo),
      setUp: () {
        when(
          () => repo.saveProgress(
            childId: any(named: 'childId'),
            itemId: any(named: 'itemId'),
            score: any(named: 'score'),
            passed: any(named: 'passed'),
          ),
        ).thenThrow(Exception('network error'));
      },
      seed: () => TracingExerciseReady(item: _item, childId: 'child-1'),
      act: (bloc) =>
          bloc.add(const SubmitTracingResult(score: 80, passed: true)),
      expect: () => [TracingExerciseLoading(), isA<TracingExerciseError>()],
    );

    blocTest<TracingExerciseBloc, TracingExerciseState>(
      'emits TracingExerciseInitial on RetryTracing',
      build: () => TracingExerciseBloc(repository: repo),
      seed: () => const TracingExerciseFailed(score: 30),
      act: (bloc) => bloc.add(RetryTracing()),
      expect: () => [TracingExerciseInitial()],
    );
  });
}
