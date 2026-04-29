// ignore_for_file: inference_failure_on_function_invocation

import 'package:arunika_app/data/api/fairy_tales_api.dart';
import 'package:arunika_app/data/repositories/fairy_tales_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFairyTalesApi extends Mock implements FairyTalesApi {}

Map<String, dynamic> _listJson(int count) => {
  'data': List.generate(
    count,
    (i) => {
      'id': 'story-$i',
      'title': 'Story $i',
      'age_start': 3,
      'age_end': 6,
      'is_free': true,
      'image_url': 'https://img/$i.png',
      'audio_url': '',
      'duration': '5 min',
      'pages': <dynamic>[],
      'created_at': '2024-01-01T00:00:00.000Z',
      'updated_at': '2024-01-01T00:00:00.000Z',
      'is_deleted': false,
    },
  ),
  'total': count,
  'page': 1,
};

Map<String, dynamic> _detailJson(String id) => {
  'data': {
    'id': id,
    'title': 'Story $id',
    'age_start': 3,
    'age_end': 6,
    'is_free': true,
    'image_url': 'https://img/$id.png',
    'audio_url': '',
    'duration': '5 min',
    'pages': <dynamic>[],
    'created_at': '2024-01-01T00:00:00.000Z',
    'updated_at': '2024-01-01T00:00:00.000Z',
    'is_deleted': false,
  },
};

void main() {
  late MockFairyTalesApi mockApi;
  late FairyTalesRepository repo;

  setUp(() {
    mockApi = MockFairyTalesApi();
    repo = FairyTalesRepository(mockApi);
  });

  group('FairyTalesRepository', () {
    test('findAll returns mapped DongengListResult on success', () async {
      when(() => mockApi.findAll()).thenAnswer((_) async => _listJson(3));

      final result = await repo.findAll();

      expect(result.items.length, 3);
      expect(result.total, 3);
      expect(result.page, 1);
    });

    test('findAll returns empty list', () async {
      when(() => mockApi.findAll()).thenAnswer((_) async => _listJson(0));

      final result = await repo.findAll();

      expect(result.items, isEmpty);
    });

    test('findAll propagates exception on failure', () async {
      when(() => mockApi.findAll()).thenThrow(Exception('network error'));

      expect(() => repo.findAll(), throwsException);
    });

    test('findById returns mapped DongengResponse on success', () async {
      when(
        () => mockApi.findById('story-1'),
      ).thenAnswer((_) async => _detailJson('story-1'));

      final result = await repo.findById('story-1');

      expect(result.id, 'story-1');
    });

    test('findById propagates exception on failure', () async {
      when(() => mockApi.findById(any())).thenThrow(Exception('not found'));

      expect(() => repo.findById('bad-id'), throwsException);
    });
  });
}
