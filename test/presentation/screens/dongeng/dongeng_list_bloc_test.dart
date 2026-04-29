import 'package:arunika_app/data/models/response/dongeng_page.dart';
import 'package:arunika_app/data/models/response/dongeng_response.dart';
import 'package:arunika_app/data/repositories/fairy_tales_repository.dart';
import 'package:arunika_app/presentation/screens/dongeng/dongeng_list_bloc.dart';
import 'package:arunika_app/presentation/screens/dongeng/dongeng_list_event.dart';
import 'package:arunika_app/presentation/screens/dongeng/dongeng_list_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFairyTalesRepository extends Mock implements FairyTalesRepository {}

// ── Helpers ───────────────────────────────────────────────────────────────────

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

DongengResponse _storyWithPages(String id) => DongengResponse(
  id: id,
  title: 'Story $id',
  ageStart: 3,
  ageEnd: 6,
  isFree: true,
  imageUrl: 'https://img/$id.png',
  audioUrl: '',
  duration: '5 min',
  pages: [
    DongengPage(
      id: 'p1',
      dongengId: id,
      pageNumber: 1,
      imageUrl: '',
      text: 'Hello',
    ),
  ],
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
  isDeleted: false,
);

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late MockFairyTalesRepository mockRepo;

  setUp(() {
    mockRepo = MockFairyTalesRepository();
  });

  group('DongengListBloc', () {
    blocTest<DongengListBloc, DongengListState>(
      'emits [Loading, Loaded] on successful load',
      build: () {
        when(() => mockRepo.findAll()).thenAnswer(
          (_) async => DongengListResult(
            items: [_story('1'), _story('2')],
            total: 2,
            page: 1,
          ),
        );
        return DongengListBloc(repository: mockRepo);
      },
      act: (b) => b.add(LoadDongengList()),
      expect: () => [
        isA<DongengListLoading>(),
        isA<DongengListLoaded>().having(
          (s) => s.dongengList.length,
          'count',
          2,
        ),
      ],
    );

    blocTest<DongengListBloc, DongengListState>(
      'emits [Loading, Loaded] with empty list',
      build: () {
        when(() => mockRepo.findAll()).thenAnswer(
          (_) async => DongengListResult(items: [], total: 0, page: 1),
        );
        return DongengListBloc(repository: mockRepo);
      },
      act: (b) => b.add(LoadDongengList()),
      expect: () => [
        isA<DongengListLoading>(),
        isA<DongengListLoaded>().having((s) => s.dongengList, 'list', isEmpty),
      ],
    );

    blocTest<DongengListBloc, DongengListState>(
      'emits [Loading, Error] when repository throws',
      build: () {
        when(() => mockRepo.findAll()).thenThrow(Exception('network'));
        return DongengListBloc(repository: mockRepo);
      },
      act: (b) => b.add(LoadDongengList()),
      expect: () => [isA<DongengListLoading>(), isA<DongengListError>()],
    );

    blocTest<DongengListBloc, DongengListState>(
      'emits [Navigating, NavigateToDongengPlayer] on item selected success',
      build: () {
        when(() => mockRepo.findAll()).thenAnswer(
          (_) async =>
              DongengListResult(items: [_story('1')], total: 1, page: 1),
        );
        when(
          () => mockRepo.findById('1'),
        ).thenAnswer((_) async => _storyWithPages('1'));
        return DongengListBloc(repository: mockRepo);
      },
      seed: () => DongengListLoaded([_story('1')]),
      act: (b) => b.add(DongengItemSelected(_story('1'))),
      expect: () => [
        isA<DongengListNavigating>(),
        isA<NavigateToDongengPlayer>(),
      ],
    );

    blocTest<DongengListBloc, DongengListState>(
      'returns to Loaded when item selected throws',
      build: () {
        when(() => mockRepo.findById('1')).thenThrow(Exception('fail'));
        return DongengListBloc(repository: mockRepo);
      },
      seed: () => DongengListLoaded([_story('1')]),
      act: (b) => b.add(DongengItemSelected(_story('1'))),
      expect: () => [isA<DongengListNavigating>(), isA<DongengListLoaded>()],
    );
  });
}
