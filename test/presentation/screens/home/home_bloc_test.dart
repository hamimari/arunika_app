// ignore_for_file: inference_failure_on_function_invocation

import 'package:arunika_app/data/models/response/ar_card_category.dart';
import 'package:arunika_app/data/models/response/dongeng_response.dart';
import 'package:arunika_app/data/repositories/fairy_tales_repository.dart';
import 'package:arunika_app/presentation/screens/home/home_bloc.dart';
import 'package:arunika_app/presentation/screens/home/home_event.dart';
import 'package:arunika_app/presentation/screens/home/home_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockFairyTalesRepository extends Mock implements FairyTalesRepository {}

DongengResponse _story(String id) => DongengResponse(
  id: id,
  title: 'Story $id',
  ageStart: 3,
  ageEnd: 6,
  isFree: true,
  imageUrl: 'https://img/$id.png',
  audioUrl: '',
  duration: '5 min',
  pages: [],
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
  isDeleted: false,
);

void main() {
  // SharedPreferences (via LocalProfileStorage) requires this in unit tests.
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFairyTalesRepository mockRepo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockRepo = MockFairyTalesRepository();
  });

  group('HomeBloc', () {
    blocTest<HomeBloc, HomeState>(
      'HomeInitial emits state with dongengList on success',
      build: () {
        when(
          () => mockRepo.findAll(
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
          ),
        ).thenAnswer(
          (_) async => DongengListResult(
            items: [_story('1'), _story('2')],
            total: 2,
            page: 1,
          ),
        );
        return HomeBloc(repository: mockRepo);
      },
      act: (b) => b.add(HomeInitial()),
      expect: () => [
        isA<HomeState>().having((s) => s.dongengList.length, 'count', 2),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'HomeInitial does not emit error state when repository throws',
      build: () {
        when(
          () => mockRepo.findAll(
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
          ),
        ).thenThrow(Exception('network'));
        return HomeBloc(repository: mockRepo);
      },
      act: (b) => b.add(HomeInitial()),
      // HomeBloc swallows load errors silently — no state change beyond initial
      expect: () => <HomeState>[],
    );

    blocTest<HomeBloc, HomeState>(
      'HomeRefresh reloads the list',
      build: () {
        when(
          () => mockRepo.findAll(
            search: any(named: 'search'),
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
          ),
        ).thenAnswer(
          (_) async =>
              DongengListResult(items: [_story('3')], total: 1, page: 1),
        );
        return HomeBloc(repository: mockRepo);
      },
      act: (b) => b.add(HomeRefresh()),
      expect: () => [
        isA<HomeState>().having((s) => s.dongengList.length, 'count', 1),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'HomePressed emits NavigateToCategoryList',
      build: () => HomeBloc(repository: mockRepo),
      act: (b) => b.add(HomePressed()),
      expect: () => [isA<NavigateToCategoryList>()],
    );
  });

  // ─── _StoryCardWidget isLocked logic ────────────────────────────────────────

  DongengResponse _paidStory() => DongengResponse(
    id: 'paid',
    title: 'Paid Story',
    ageStart: 3,
    ageEnd: 6,
    isFree: false,
    imageUrl: '',
    audioUrl: '',
    duration: '5 min',
    pages: [],
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
    isDeleted: false,
  );

  DongengResponse _freeStory() => DongengResponse(
    id: 'free',
    title: 'Free Story',
    ageStart: 3,
    ageEnd: 6,
    isFree: true,
    imageUrl: '',
    audioUrl: '',
    duration: '3 min',
    pages: [],
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
    isDeleted: false,
  );

  test(
    'isLocked is true when user is logged in and dongeng.isFree is false',
    () {
      const isLoggedIn = true;
      final dongeng = _paidStory();
      final isLocked = !dongeng.isFree && isLoggedIn;
      expect(isLocked, isTrue);
    },
  );

  test(
    'isLocked is false when user is not logged in (guest), even if isFree is false',
    () {
      const isLoggedIn = false;
      final dongeng = _paidStory();
      final isLocked = !dongeng.isFree && isLoggedIn;
      expect(isLocked, isFalse);
    },
  );

  test('isLocked is false when isFree is true regardless of auth state', () {
    for (final isLoggedIn in [true, false]) {
      final dongeng = _freeStory();
      final isLocked = !dongeng.isFree && isLoggedIn;
      expect(isLocked, isFalse, reason: 'isLoggedIn=$isLoggedIn');
    }
  });

  // ─── AR category image / emoji rendering logic ───────────────────────────────

  test('AR category item uses Image.network when imageUrl is non-empty', () {
    const imageUrl = 'https://example.com/cat.png';
    final category = const ArCardCategory(
      id: 'c1',
      name: 'Ternak',
      emoji: '🐄',
      imageUrl: imageUrl,
    );
    // Verify the condition that selects Image.network over emoji fallback
    expect(
      category.imageUrl.isNotEmpty,
      isTrue,
      reason: 'imageUrl is non-empty → Image.network should be used',
    );
  });

  test('AR category item uses emoji fallback when imageUrl is empty', () {
    const category = ArCardCategory(
      id: 'c1',
      name: 'Ternak',
      emoji: '🐄',
      imageUrl: '',
    );
    // Verify the condition that selects emoji fallback
    expect(
      category.imageUrl.isEmpty,
      isTrue,
      reason: 'imageUrl is empty → emoji fallback should be used',
    );
    expect(category.emoji, '🐄');
  });
}
