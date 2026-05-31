import 'package:arunika_app/data/models/response/ar_card_response.dart';
import 'package:arunika_app/data/models/response/animal_response.dart';
import 'package:arunika_app/data/repositories/ar_repository.dart';
import 'package:arunika_app/presentation/screens/vocab/collection_bloc.dart';
import 'package:arunika_app/presentation/screens/vocab/collection_bloc_handler.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockArRepository extends Mock implements ArRepository {}

const _catId = 'cat-binatang';
const _subHutan = 'sub-hutan';
const _subLaut = 'sub-laut';
const _subTernak = 'sub-ternak';

// Sample AR cards used throughout tests
final _ternak = ArCardResponse(
  id: '1',
  title: 'Sapi',
  emoji: '🐄',
  categoryId: _catId,
  subCategoryId: _subTernak,
  imageUrl: '',
  bgColor: '#FFF8E1',
  isUnlocked: true,
);

final _hutan = ArCardResponse(
  id: '2',
  title: 'Harimau',
  emoji: '🐯',
  categoryId: _catId,
  subCategoryId: _subHutan,
  imageUrl: '',
  bgColor: '#FFF3E0',
  isUnlocked: true,
);

final _laut = ArCardResponse(
  id: '3',
  title: 'Lumba-lumba',
  emoji: '🐬',
  categoryId: _catId,
  subCategoryId: _subLaut,
  imageUrl: '',
  bgColor: '#B2EBF2',
  isUnlocked: false,
);

final _allCards = [_ternak, _hutan, _laut];

void main() {
  late MockArRepository mockRepo;

  setUp(() {
    mockRepo = MockArRepository();
  });

  group('CollectionBlocHandler', () {
    blocTest<CollectionBlocHandler, CollectionState>(
      'initial load emits CollectionLoaded with all cards and no active category filter',
      build: () {
        when(() => mockRepo.findAll()).thenAnswer((_) async => _allCards);
        when(() => mockRepo.getCategories()).thenAnswer((_) async => []);
        return CollectionBlocHandler(repository: mockRepo);
      },
      act: (bloc) => bloc.add(LoadArCards()),
      expect: () => [
        isA<CollectionLoading>(),
        isA<CollectionLoaded>()
            .having((s) => s.displayed.length, 'all cards', 3)
            .having((s) => s.activeCategoryId, 'no active category', isNull),
      ],
    );

    blocTest<CollectionBlocHandler, CollectionState>(
      'FilterByCategory emits CollectionLoaded with only matching cards',
      build: () {
        when(() => mockRepo.findAll()).thenAnswer((_) async => _allCards);
        when(() => mockRepo.getCategories()).thenAnswer((_) async => []);
        return CollectionBlocHandler(repository: mockRepo);
      },
      seed: () => CollectionLoaded(all: _allCards, displayed: _allCards),
      act: (bloc) => bloc.add(FilterByCategory(_catId)),
      expect: () => [
        isA<CollectionLoaded>()
            .having((s) => s.activeCategoryId, 'active category', _catId)
            .having((s) => s.displayed.length, 'all 3 belong to cat', 3),
      ],
    );

    blocTest<CollectionBlocHandler, CollectionState>(
      'FilterByCategory(null) resets filter and emits all cards',
      build: () {
        when(() => mockRepo.findAll()).thenAnswer((_) async => _allCards);
        when(() => mockRepo.getCategories()).thenAnswer((_) async => []);
        return CollectionBlocHandler(repository: mockRepo);
      },
      seed: () => CollectionLoaded(
        all: _allCards,
        displayed: [_hutan],
        activeCategoryId: _catId,
      ),
      act: (bloc) => bloc.add(FilterByCategory(null)),
      expect: () => [
        isA<CollectionLoaded>()
            .having((s) => s.activeCategoryId, 'cleared category', isNull)
            .having((s) => s.displayed.length, 'all cards', 3),
      ],
    );

    blocTest<CollectionBlocHandler, CollectionState>(
      'FilterBySubCategory(null) clears sub-category, retains parent filter',
      build: () {
        when(() => mockRepo.findAll()).thenAnswer((_) async => _allCards);
        when(() => mockRepo.getCategories()).thenAnswer((_) async => []);
        return CollectionBlocHandler(repository: mockRepo);
      },
      seed: () => CollectionLoaded(
        all: _allCards,
        displayed: [_hutan],
        activeCategoryId: _catId,
        activeSubCategoryId: _subHutan,
      ),
      act: (bloc) => bloc.add(FilterBySubCategory(null)),
      expect: () => [
        isA<CollectionLoaded>()
            .having((s) => s.activeSubCategoryId, 'cleared sub', isNull)
            .having((s) => s.activeCategoryId, 'parent kept', _catId),
      ],
    );

    blocTest<CollectionBlocHandler, CollectionState>(
      'LoadArCards with initialCategoryId pre-filters on load',
      build: () {
        when(() => mockRepo.findAll()).thenAnswer((_) async => _allCards);
        when(() => mockRepo.getCategories()).thenAnswer((_) async => []);
        return CollectionBlocHandler(repository: mockRepo);
      },
      act: (bloc) => bloc.add(LoadArCards(initialCategoryId: _catId)),
      expect: () => [
        isA<CollectionLoading>(),
        isA<CollectionLoaded>().having(
          (s) => s.activeCategoryId,
          'pre-filtered category',
          _catId,
        ),
      ],
    );

    blocTest<CollectionBlocHandler, CollectionState>(
      'emits [CollectionLoading, CollectionLoaded] on LoadArCards success',
      build: () {
        when(() => mockRepo.findAll()).thenAnswer((_) async => _allCards);
        when(() => mockRepo.getCategories()).thenAnswer((_) async => []);
        return CollectionBlocHandler(repository: mockRepo);
      },
      act: (bloc) => bloc.add(LoadArCards()),
      expect: () => [
        isA<CollectionLoading>(),
        isA<CollectionLoaded>().having(
          (s) => s.displayed.length,
          'displayed count',
          3,
        ),
      ],
    );

    blocTest<CollectionBlocHandler, CollectionState>(
      'emits CollectionError when repository throws',
      build: () {
        when(() => mockRepo.findAll()).thenThrow(Exception('network error'));
        when(
          () => mockRepo.getCategories(),
        ).thenThrow(Exception('network error'));
        return CollectionBlocHandler(repository: mockRepo);
      },
      act: (bloc) => bloc.add(LoadArCards()),
      expect: () => [
        isA<CollectionLoading>(),
        isA<CollectionError>().having(
          (s) => s.message,
          'message',
          contains('Gagal'),
        ),
      ],
    );

    blocTest<CollectionBlocHandler, CollectionState>(
      'FilterBySubCategory filters by sub-category ID',
      build: () {
        when(() => mockRepo.findAll()).thenAnswer((_) async => _allCards);
        when(() => mockRepo.getCategories()).thenAnswer((_) async => []);
        return CollectionBlocHandler(repository: mockRepo);
      },
      seed: () => CollectionLoaded(
        all: _allCards,
        displayed: _allCards,
        activeCategoryId: _catId,
      ),
      act: (bloc) => bloc.add(FilterBySubCategory(_subHutan)),
      expect: () => [
        isA<CollectionLoaded>()
            .having((s) => s.displayed.length, 'only Hutan', 1)
            .having((s) => s.displayed.first.title, 'title', 'Harimau'),
      ],
    );

    blocTest<CollectionBlocHandler, CollectionState>(
      'SearchArCards filters by title query',
      build: () {
        when(() => mockRepo.findAll()).thenAnswer((_) async => _allCards);
        when(() => mockRepo.getCategories()).thenAnswer((_) async => []);
        return CollectionBlocHandler(repository: mockRepo);
      },
      seed: () => CollectionLoaded(all: _allCards, displayed: _allCards),
      act: (bloc) => bloc.add(SearchArCards('sapi')),
      expect: () => [
        isA<CollectionLoaded>()
            .having((s) => s.displayed.length, 'count', 1)
            .having((s) => s.displayed.first.title, 'title', 'Sapi'),
      ],
    );

    blocTest<CollectionBlocHandler, CollectionState>(
      'SearchArCards with empty query shows all cards',
      build: () {
        when(() => mockRepo.findAll()).thenAnswer((_) async => _allCards);
        when(() => mockRepo.getCategories()).thenAnswer((_) async => []);
        return CollectionBlocHandler(repository: mockRepo);
      },
      seed: () => CollectionLoaded(
        all: _allCards,
        displayed: [_ternak],
        searchQuery: 'sapi',
      ),
      act: (bloc) => bloc.add(SearchArCards('')),
      expect: () => [
        isA<CollectionLoaded>().having(
          (s) => s.displayed.length,
          'shows all',
          3,
        ),
      ],
    );
  });

  group('AnimalResponse.fromJson', () {
    test('parses all fields correctly', () {
      final json = {
        'id': 'abc-123',
        'name': 'Rusa',
        'emoji': '🦌',
        'category': 'hutan',
        'image_url': 'https://example.com/rusa.png',
        'bg_color': '#E8F5E9',
        'fact': 'Tanduk rusa tumbuh cepat.',
        'is_unlocked': true,
      };
      final animal = AnimalResponse.fromJson(json);
      expect(animal.id, 'abc-123');
      expect(animal.name, 'Rusa');
      expect(animal.emoji, '🦌');
      expect(animal.category, 'hutan');
      expect(animal.isUnlocked, isTrue);
      expect(animal.bgColor.value, isNonZero);
    });

    test('uses default values for missing optional fields', () {
      final json = {'id': 'x', 'name': 'Test'};
      final animal = AnimalResponse.fromJson(json);
      expect(animal.emoji, '🐾');
      expect(animal.category, 'hutan');
      expect(animal.isUnlocked, isFalse);
    });
  });
}
