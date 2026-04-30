import 'package:arunika_app/data/models/response/growth_record.dart';
import 'package:arunika_app/data/repositories/growth_repository.dart';
import 'package:arunika_app/presentation/screens/growth/growth_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGrowthRepository extends Mock implements GrowthRepository {}

final _record1 = GrowthRecord(
  id: 'gr-1',
  childId: 'child-1',
  recordedAt: DateTime(2026, 1, 1),
  weightKg: 15.5,
  heightCm: 100.0,
);

final _record2 = GrowthRecord(
  id: 'gr-2',
  childId: 'child-1',
  recordedAt: DateTime(2026, 2, 1),
  weightKg: 16.0,
  heightCm: 102.0,
);

void main() {
  late MockGrowthRepository repo;

  setUp(() {
    repo = MockGrowthRepository();
  });

  group('GrowthBloc', () {
    blocTest<GrowthBloc, GrowthState>(
      'emits GrowthLoaded on LoadGrowthHistory success',
      build: () => GrowthBloc(repository: repo),
      setUp: () {
        when(
          () => repo.getHistory('child-1'),
        ).thenAnswer((_) async => [_record1, _record2]);
      },
      act: (bloc) => bloc.add(const LoadGrowthHistory('child-1')),
      expect: () => [
        GrowthLoading(),
        GrowthLoaded([_record1, _record2]),
      ],
    );

    blocTest<GrowthBloc, GrowthState>(
      'emits GrowthError on LoadGrowthHistory failure',
      build: () => GrowthBloc(repository: repo),
      setUp: () {
        when(() => repo.getHistory(any())).thenThrow(Exception('error'));
      },
      act: (bloc) => bloc.add(const LoadGrowthHistory('child-1')),
      expect: () => [GrowthLoading(), isA<GrowthError>()],
    );

    blocTest<GrowthBloc, GrowthState>(
      'emits GrowthSaved then updated history on SaveGrowthRecord',
      build: () => GrowthBloc(repository: repo),
      setUp: () {
        when(
          () => repo.saveRecord(
            childId: any(named: 'childId'),
            weightKg: any(named: 'weightKg'),
            heightCm: any(named: 'heightCm'),
            recordedAt: any(named: 'recordedAt'),
          ),
        ).thenAnswer((_) async => _record2);
        when(
          () => repo.getHistory('child-1'),
        ).thenAnswer((_) async => [_record1, _record2]);
      },
      act: (bloc) => bloc.add(
        const SaveGrowthRecord(
          childId: 'child-1',
          weightKg: 16.0,
          heightCm: 102.0,
        ),
      ),
      expect: () => [
        GrowthLoading(),
        GrowthSaved([_record1, _record2]),
      ],
    );

    blocTest<GrowthBloc, GrowthState>(
      'emits GrowthError on SaveGrowthRecord failure',
      build: () => GrowthBloc(repository: repo),
      setUp: () {
        when(
          () => repo.saveRecord(
            childId: any(named: 'childId'),
            weightKg: any(named: 'weightKg'),
            heightCm: any(named: 'heightCm'),
            recordedAt: any(named: 'recordedAt'),
          ),
        ).thenThrow(Exception('save failed'));
      },
      act: (bloc) => bloc.add(
        const SaveGrowthRecord(
          childId: 'child-1',
          weightKg: 16.0,
          heightCm: 102.0,
        ),
      ),
      expect: () => [GrowthLoading(), isA<GrowthError>()],
    );
  });
}
