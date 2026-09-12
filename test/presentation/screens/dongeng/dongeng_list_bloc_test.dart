import 'package:arunika_app/core/auth/auth_notifier.dart';
import 'package:arunika_app/data/models/response/dongeng_category.dart';
import 'package:arunika_app/data/models/response/dongeng_page.dart';
import 'package:arunika_app/data/models/response/dongeng_response.dart';
import 'package:arunika_app/data/repositories/dongeng_history_repository.dart';
import 'package:arunika_app/data/repositories/fairy_tales_repository.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/presentation/screens/dongeng/dongeng_list_bloc.dart';
import 'package:arunika_app/presentation/screens/dongeng/dongeng_list_event.dart';
import 'package:arunika_app/presentation/screens/dongeng/dongeng_list_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFairyTalesRepository extends Mock implements FairyTalesRepository {}

class MockDongengHistoryRepository extends Mock
    implements DongengHistoryRepository {}

class MockAuthNotifier extends Mock implements AuthNotifier {}

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

DongengResponse _lockedStory(String id) => DongengResponse(
  id: id,
  title: 'Locked $id',
  ageStart: 3,
  ageEnd: 6,
  isFree: false,
  isUnlocked: false,
  imageUrl: 'https://img/$id.png',
  audioUrl: '',
  duration: '5 min',
  pages: [],
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
  isDeleted: false,
);

DongengResponse _storyWithProduct(String id, String productId) =>
    DongengResponse(
      id: id,
      title: 'Story $id',
      ageStart: 3,
      ageEnd: 6,
      isFree: false,
      isUnlocked: true,
      productId: productId,
      imageUrl: 'https://img/$id.png',
      audioUrl: '',
      duration: '5 min',
      pages: [],
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
      isDeleted: false,
    );

DongengResponse _storyWithCategory(
  String id, {
  String? categoryId,
  String? subCategoryId,
}) => DongengResponse(
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
  categoryId: categoryId,
  subCategoryId: subCategoryId,
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
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFairyTalesRepository mockRepo;

  setUp(() async {
    if (locator.isRegistered<DongengHistoryRepository>()) {
      await locator.unregister<DongengHistoryRepository>();
    }
    if (locator.isRegistered<AuthNotifier>()) {
      await locator.unregister<AuthNotifier>();
    }

    mockRepo = MockFairyTalesRepository();
    final mockHistoryRepo = MockDongengHistoryRepository();
    final mockAuth = MockAuthNotifier();
    when(() => mockAuth.isLoggedIn).thenReturn(false);
    when(
      () => mockRepo.getCategories(),
    ).thenAnswer((_) async => <DongengCategory>[]);

    locator.registerSingleton<DongengHistoryRepository>(mockHistoryRepo);
    locator.registerSingleton<AuthNotifier>(mockAuth);
  });

  tearDown(() async {
    if (locator.isRegistered<DongengHistoryRepository>()) {
      await locator.unregister<DongengHistoryRepository>();
    }
    if (locator.isRegistered<AuthNotifier>()) {
      await locator.unregister<AuthNotifier>();
    }
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

    blocTest<DongengListBloc, DongengListState>(
      'FilterOwnedOnly filters to only unlocked stories',
      build: () {
        when(() => mockRepo.findAll()).thenAnswer(
          (_) async => DongengListResult(
            items: [_story('1'), _lockedStory('2')],
            total: 2,
            page: 1,
          ),
        );
        return DongengListBloc(repository: mockRepo);
      },
      act: (b) async {
        b.add(LoadDongengList());
        await Future.delayed(Duration.zero);
        b.add(FilterOwnedOnly(true));
      },
      skip: 2, // [Loading, Loaded(all 2)]
      expect: () => [
        isA<DongengListLoaded>()
            .having((s) => s.dongengList.length, 'count', 1)
            .having((s) => s.dongengList.single.id, 'id', '1')
            .having((s) => s.ownedOnly, 'ownedOnly', true),
      ],
    );

    blocTest<DongengListBloc, DongengListState>(
      'FilterOwnedOnly(false) restores the full list',
      build: () {
        when(() => mockRepo.findAll()).thenAnswer(
          (_) async => DongengListResult(
            items: [_story('1'), _lockedStory('2')],
            total: 2,
            page: 1,
          ),
        );
        return DongengListBloc(repository: mockRepo);
      },
      act: (b) async {
        b.add(LoadDongengList());
        await Future.delayed(Duration.zero);
        b.add(FilterOwnedOnly(true));
        await Future.delayed(Duration.zero);
        b.add(FilterOwnedOnly(false));
      },
      skip: 3, // [Loading, Loaded(all 2), Loaded(owned-only 1)]
      expect: () => [
        isA<DongengListLoaded>()
            .having((s) => s.dongengList.length, 'count', 2)
            .having((s) => s.ownedOnly, 'ownedOnly', false),
      ],
    );

    blocTest<DongengListBloc, DongengListState>(
      'search and FilterOwnedOnly combine',
      build: () {
        when(() => mockRepo.findAll()).thenAnswer(
          (_) async => DongengListResult(
            items: [_story('1'), _lockedStory('2')],
            total: 2,
            page: 1,
          ),
        );
        return DongengListBloc(repository: mockRepo);
      },
      act: (b) async {
        b.add(LoadDongengList());
        await Future.delayed(Duration.zero);
        b.add(FilterOwnedOnly(true));
        await Future.delayed(Duration.zero);
        // Matches the locked story's title but it must stay excluded since
        // ownedOnly is still active.
        b.add(SearchDongeng('Locked'));
      },
      skip: 3, // [Loading, Loaded(all 2), Loaded(owned-only 1)]
      expect: () => [
        isA<DongengListLoaded>()
            .having((s) => s.dongengList, 'list', isEmpty)
            .having((s) => s.ownedOnly, 'ownedOnly', true),
      ],
    );

    blocTest<DongengListBloc, DongengListState>(
      'LoadDongengList with highlightProductId pins that story to the '
      'front without dropping the rest of the list (regression: previously '
      'the just-purchased item was searched-for, hiding every other story)',
      build: () {
        when(() => mockRepo.findAll()).thenAnswer(
          (_) async => DongengListResult(
            items: [
              _story('1'),
              _storyWithProduct('2', 'prod-2'),
              _story('3'),
            ],
            total: 3,
            page: 1,
          ),
        );
        return DongengListBloc(repository: mockRepo);
      },
      act: (b) => b.add(LoadDongengList(highlightProductId: 'prod-2')),
      expect: () => [
        isA<DongengListLoading>(),
        isA<DongengListLoaded>()
            .having((s) => s.dongengList.length, 'count', 3)
            .having((s) => s.dongengList.first.id, 'featured id', '2'),
      ],
    );

    blocTest<DongengListBloc, DongengListState>(
      'the pinned highlight survives a later FilterOwnedOnly toggle',
      build: () {
        when(() => mockRepo.findAll()).thenAnswer(
          (_) async => DongengListResult(
            items: [_story('1'), _storyWithProduct('2', 'prod-2')],
            total: 2,
            page: 1,
          ),
        );
        return DongengListBloc(repository: mockRepo);
      },
      act: (b) async {
        b.add(LoadDongengList(highlightProductId: 'prod-2'));
        await Future.delayed(Duration.zero);
        b.add(FilterOwnedOnly(false));
      },
      skip: 2, // [Loading, Loaded(highlighted)]
      expect: () => [
        isA<DongengListLoaded>()
            .having((s) => s.dongengList.length, 'count', 2)
            .having((s) => s.dongengList.first.id, 'featured id', '2'),
      ],
    );

    blocTest<DongengListBloc, DongengListState>(
      'LoadDongengList exposes categories fetched alongside the story list',
      build: () {
        when(() => mockRepo.findAll()).thenAnswer(
          (_) async =>
              DongengListResult(items: [_story('1')], total: 1, page: 1),
        );
        when(() => mockRepo.getCategories()).thenAnswer(
          (_) async => [
            const DongengCategory(id: 'cat-1', name: 'Fairy Tales', emoji: '🧚'),
            const DongengCategory(id: 'cat-2', name: 'Islamic', emoji: '🕌'),
          ],
        );
        return DongengListBloc(repository: mockRepo);
      },
      act: (b) => b.add(LoadDongengList()),
      expect: () => [
        isA<DongengListLoading>(),
        isA<DongengListLoaded>().having(
          (s) => s.categories.map((c) => c.name),
          'category names',
          ['Fairy Tales', 'Islamic'],
        ),
      ],
    );

    blocTest<DongengListBloc, DongengListState>(
      'FilterByDongengCategory filters to stories in that category',
      build: () {
        when(() => mockRepo.findAll()).thenAnswer(
          (_) async => DongengListResult(
            items: [
              _storyWithCategory('1', categoryId: 'cat-1'),
              _storyWithCategory('2', categoryId: 'cat-2'),
            ],
            total: 2,
            page: 1,
          ),
        );
        return DongengListBloc(repository: mockRepo);
      },
      act: (b) async {
        b.add(LoadDongengList());
        await Future.delayed(Duration.zero);
        b.add(FilterByDongengCategory('cat-1'));
      },
      skip: 2, // [Loading, Loaded(all 2)]
      expect: () => [
        isA<DongengListLoaded>()
            .having((s) => s.dongengList.length, 'count', 1)
            .having((s) => s.dongengList.single.id, 'id', '1')
            .having((s) => s.activeCategoryId, 'activeCategoryId', 'cat-1'),
      ],
    );

    blocTest<DongengListBloc, DongengListState>(
      'FilterByDongengSubCategory narrows within the active category',
      build: () {
        when(() => mockRepo.findAll()).thenAnswer(
          (_) async => DongengListResult(
            items: [
              _storyWithCategory('1', categoryId: 'cat-1', subCategoryId: 'sub-1'),
              _storyWithCategory('2', categoryId: 'cat-1', subCategoryId: 'sub-2'),
            ],
            total: 2,
            page: 1,
          ),
        );
        return DongengListBloc(repository: mockRepo);
      },
      act: (b) async {
        b.add(LoadDongengList());
        await Future.delayed(Duration.zero);
        b.add(FilterByDongengCategory('cat-1'));
        await Future.delayed(Duration.zero);
        b.add(FilterByDongengSubCategory('sub-2'));
      },
      skip: 3, // [Loading, Loaded(all 2), Loaded(cat-1: 2)]
      expect: () => [
        isA<DongengListLoaded>()
            .having((s) => s.dongengList.length, 'count', 1)
            .having((s) => s.dongengList.single.id, 'id', '2')
            .having(
              (s) => s.activeSubCategoryId,
              'activeSubCategoryId',
              'sub-2',
            ),
      ],
    );

    blocTest<DongengListBloc, DongengListState>(
      'selecting a new category clears the previously active sub-category',
      build: () {
        when(() => mockRepo.findAll()).thenAnswer(
          (_) async => DongengListResult(
            items: [
              _storyWithCategory('1', categoryId: 'cat-1', subCategoryId: 'sub-1'),
              _storyWithCategory('2', categoryId: 'cat-2'),
            ],
            total: 2,
            page: 1,
          ),
        );
        return DongengListBloc(repository: mockRepo);
      },
      act: (b) async {
        b.add(LoadDongengList());
        await Future.delayed(Duration.zero);
        b.add(FilterByDongengCategory('cat-1'));
        await Future.delayed(Duration.zero);
        b.add(FilterByDongengSubCategory('sub-1'));
        await Future.delayed(Duration.zero);
        b.add(FilterByDongengCategory('cat-2'));
      },
      skip: 4, // [Loading, Loaded(all 2), Loaded(cat-1), Loaded(cat-1/sub-1)]
      expect: () => [
        isA<DongengListLoaded>()
            .having((s) => s.dongengList.length, 'count', 1)
            .having((s) => s.dongengList.single.id, 'id', '2')
            .having((s) => s.activeSubCategoryId, 'activeSubCategoryId', null),
      ],
    );

    blocTest<DongengListBloc, DongengListState>(
      'category filter combines with ownedOnly and the highlight pin',
      build: () {
        when(() => mockRepo.findAll()).thenAnswer(
          (_) async => DongengListResult(
            items: [
              DongengResponse(
                id: '1',
                title: 'Story 1',
                ageStart: 3,
                ageEnd: 6,
                isFree: false,
                isUnlocked: false,
                categoryId: 'cat-1',
                imageUrl: 'https://img/1.png',
                audioUrl: '',
                duration: '5 min',
                pages: const [],
                createdAt: DateTime(2024),
                updatedAt: DateTime(2024),
                isDeleted: false,
              ),
              DongengResponse(
                id: '2',
                title: 'Story 2',
                ageStart: 3,
                ageEnd: 6,
                isFree: false,
                isUnlocked: true,
                productId: 'prod-2',
                categoryId: 'cat-1',
                imageUrl: 'https://img/2.png',
                audioUrl: '',
                duration: '5 min',
                pages: const [],
                createdAt: DateTime(2024),
                updatedAt: DateTime(2024),
                isDeleted: false,
              ),
              _lockedStory('3'),
            ],
            total: 3,
            page: 1,
          ),
        );
        return DongengListBloc(repository: mockRepo);
      },
      act: (b) async {
        b.add(LoadDongengList(highlightProductId: 'prod-2'));
        await Future.delayed(Duration.zero);
        b.add(FilterByDongengCategory('cat-1'));
        await Future.delayed(Duration.zero);
        b.add(FilterOwnedOnly(true));
      },
      skip: 3, // [Loading, Loaded(highlighted), Loaded(cat-1)]
      expect: () => [
        isA<DongengListLoaded>()
            .having((s) => s.dongengList.length, 'count', 1)
            .having((s) => s.dongengList.first.id, 'featured id', '2'),
      ],
    );
  });
}
