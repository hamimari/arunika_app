import 'package:arunika_app/data/api/ar_api.dart';
import 'package:arunika_app/data/repositories/ar_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockArApi extends Mock implements ArApi {}

void main() {
  late MockArApi mockApi;
  late ArRepository repo;

  setUp(() {
    mockApi = MockArApi();
    repo = ArRepository(mockApi);
  });

  group('ArRepository', () {
    test('findById returns ArCardResponse on success', () async {
      when(() => mockApi.getById('card-1')).thenAnswer(
        (_) async => {
          'id': 'card-1',
          'type': 'model',
          'title': 'Card 1',
          'file_url': 'https://example.com/model.glb',
          'short_code': 'c1',
          'audio_url': 'https://example.com/audio.mp3',
        },
      );

      final result = await repo.findById('card-1');

      expect(result.id, 'card-1');
      expect(result.fileUrl, 'https://example.com/model.glb');
    });

    test('findById propagates exception on failure', () async {
      when(() => mockApi.getById(any())).thenThrow(Exception('not found'));

      expect(() => repo.findById('bad'), throwsException);
    });
    test('getPrintablePdf calls correct endpoint and returns bytes', () async {
      final fakeBytes = [37, 80, 68, 70]; // %PDF
      when(
        () => mockApi.getPrintablePdf('cat-ternak'),
      ).thenAnswer((_) async => fakeBytes);

      final result = await repo.getPrintablePdf('cat-ternak');

      verify(() => mockApi.getPrintablePdf('cat-ternak')).called(1);
      expect(result, fakeBytes);
    });

    test('getPrintablePdf propagates exception on non-200 status', () async {
      when(
        () => mockApi.getPrintablePdf(any()),
      ).thenThrow(Exception('404 Not Found'));

      expect(() => repo.getPrintablePdf('unknown'), throwsException);
    });
  });
}
