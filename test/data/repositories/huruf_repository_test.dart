import 'package:arunika_app/data/repositories/huruf_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_huruf_api.dart';

void main() {
  late FakeHurufApi api;
  late HurufRepository repo;
  late DateTime now;
  late List<Duration> slept;

  setUp(() {
    api = FakeHurufApi();
    now = DateTime(2026, 10, 5, 9);
    slept = [];
    repo = HurufRepository(
      api,
      now: () => now,
      sleep: (d) async => slept.add(d),
    );
  });

  test(
    'manifest is cached for 15 minutes, then revalidated with the ETag',
    () async {
      final first = await repo.manifest();
      expect(first.letters.map((l) => l.upper), ['A', 'B', 'C']);
      expect(first.letters.first.locked, isFalse);
      expect(first.letters[1].locked, isTrue);
      expect(first.thresholds.radius, 22);

      now = now.add(const Duration(minutes: 10));
      await repo.manifest();
      expect(api.calls, ['manifest -'], reason: 'still fresh');

      now = now.add(const Duration(minutes: 6));
      final again = await repo.manifest();
      expect(
        api.calls.last,
        'manifest "v1"-false',
        reason: 'sends If-None-Match',
      );
      expect(again, same(first), reason: '304 keeps the cached manifest');
    },
  );

  test('force refetches; a changed manifest replaces the cache', () async {
    await repo.manifest();
    api.premium = true;
    final m = await repo.manifest(force: true);
    expect(m.premium, isTrue);
    expect(m.letters.every((l) => !l.locked), isTrue);
  });

  test('a locked letter maps 402 to HurufLockedException', () async {
    await expectLater(
      repo.letter('id-B', version: 1),
      throwsA(isA<HurufLockedException>()),
    );
    final a = await repo.letter('id-A', version: 1);
    expect(a.upperStrokes.single.path, 'M40 150 L260 150');
    await repo.letter('id-A', version: 1);
    expect(
      api.calls.where((c) => c == 'letter id-A'),
      hasLength(1),
      reason: 'cached by (id, version)',
    );
  });

  test(
    'progress writes retry network and server errors with backoff',
    () async {
      api
        ..failProgressWrites = 2
        ..failStatus = null;
      final p = await repo.saveProgress('c1', 'id-A', dengar: true);
      expect(p.dengarDone, isTrue);
      expect(slept, [const Duration(seconds: 1), const Duration(seconds: 2)]);

      api
        ..failProgressWrites = 10
        ..failStatus = 503;
      await expectLater(
        repo.saveProgress('c1', 'id-A', kenali: true),
        throwsA(isA<HurufException>()),
      );
      expect(api.calls.where((c) => c == 'save id-A'), hasLength(3 + 4));
    },
  );

  test('a 402 on a progress write is not retried', () async {
    await expectLater(
      repo.saveProgress('c1', 'id-B', kenali: true),
      throwsA(isA<HurufLockedException>()),
    );
    expect(api.calls.where((c) => c == 'save id-B'), hasLength(1));
    expect(slept, isEmpty);
  });

  test('only set flags are sent', () async {
    await repo.saveProgress(
      'c1',
      'id-A',
      tebalkan: true,
      score: 0.9,
      attempt: true,
    );
    expect(api.progressBodies.single, {
      'tebalkan_done': true,
      'score': 0.9,
      'attempt': true,
    });
  });
}
