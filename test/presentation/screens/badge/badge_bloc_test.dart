import 'package:arunika_app/data/models/response/badge_item.dart';
import 'package:arunika_app/data/repositories/badge_repository.dart';
import 'package:arunika_app/presentation/screens/badge/badge_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockBadgeRepository extends Mock implements BadgeRepository {}

const _unearned = BadgeItem(
  id: 'b-1',
  feature: 'tracing',
  level: 'beginner',
  threshold: 5,
  earned: false,
  progress: 2,
);

const _earned = BadgeItem(
  id: 'b-2',
  feature: 'counting',
  level: 'beginner',
  threshold: 5,
  earned: true,
  progress: 5,
);

void main() {
  late MockBadgeRepository repo;

  setUp(() {
    repo = MockBadgeRepository();
  });

  group('BadgeCubit', () {
    blocTest<BadgeCubit, BadgeState>(
      'emits BadgeLoaded with mixed earned/locked badges',
      build: () => BadgeCubit(repository: repo),
      setUp: () {
        when(
          () => repo.getBadges(),
        ).thenAnswer((_) async => [_unearned, _earned]);
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        BadgeLoading(),
        const BadgeLoaded([_unearned, _earned]),
      ],
    );

    blocTest<BadgeCubit, BadgeState>(
      'emits BadgeLoaded with empty list',
      build: () => BadgeCubit(repository: repo),
      setUp: () {
        when(() => repo.getBadges()).thenAnswer((_) async => []);
      },
      act: (cubit) => cubit.load(),
      expect: () => [BadgeLoading(), const BadgeLoaded([])],
    );

    blocTest<BadgeCubit, BadgeState>(
      'emits BadgeError on repository failure',
      build: () => BadgeCubit(repository: repo),
      setUp: () {
        when(() => repo.getBadges()).thenThrow(Exception('server error'));
      },
      act: (cubit) => cubit.load(),
      expect: () => [BadgeLoading(), isA<BadgeError>()],
    );
  });
}
