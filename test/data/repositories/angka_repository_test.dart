import 'package:arunika_app/data/repositories/angka_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_angka_api.dart';

void main() {
  late FakeAngkaApi api;
  late AngkaRepository repo;
  late DateTime now;
  late List<Duration> slept;

  setUp(() {
    api = FakeAngkaApi();
    now = DateTime(2026, 10, 5, 9);
    slept = [];
    repo = AngkaRepository(
      api,
      now: () => now,
      sleep: (d) async => slept.add(d),
    );
  });

  test(
    'manifest is cached for 15 minutes, then revalidated with the ETag',
    () async {
      final first = await repo.manifest();
      expect(first.numbers, hasLength(10));
      expect(first.numbers[4].locked, isFalse);
      expect(first.numbers[5].locked, isTrue);
      expect(first.levels.map((l) => l.rangeLabel), ['1–5', '1–10', '11–20']);
      expect(first.levels[1].prerequisiteId, 'l1');

      now = now.add(const Duration(minutes: 10));
      await repo.manifest();
      expect(api.calls, ['manifest -'], reason: 'still fresh');

      now = now.add(const Duration(minutes: 6));
      final again = await repo.manifest();
      expect(api.calls.last, 'manifest "v1"-false', reason: 'revalidated');
      expect(again, first, reason: 'a 304 keeps the cached manifest');
    },
  );

  test('402 means locked, 409 LEVEL_LOCKED means the prerequisite', () async {
    await expectLater(repo.number(7), throwsA(isA<AngkaLockedException>()));
    await expectLater(
      repo.startSession('c1', 'l2'),
      throwsA(isA<AngkaLockedException>()),
    );
    api.premium = true;
    await expectLater(
      repo.startSession('c1', 'l2'),
      throwsA(isA<AngkaLevelLockedException>()),
    );
  });

  test('numbers are cached until the manifest changes', () async {
    await repo.manifest();
    final n = await repo.number(3);
    expect(n.countAudio.keys, [1, 2, 3]);
    await repo.number(3);
    expect(api.calls.where((c) => c == 'number 3'), hasLength(1));
    api.etag = '"v2"';
    await repo.manifest(force: true);
    await repo.number(3);
    expect(api.calls.where((c) => c == 'number 3'), hasLength(2));
  });

  test('a try is retried with backoff on network errors', () async {
    final s = await repo.startSession('c1', 'l1');
    api.failWrites = 2;
    await repo.recordTry('c1', s.id, q: 1, attempt: 1, answer: 3);
    expect(slept, const [Duration(seconds: 1), Duration(seconds: 2)]);
    expect(api.sessions[s.id]!['answers'], hasLength(1));
  });

  test('a failed complete is remembered and retried later', () async {
    final s = await repo.startSession('c1', 'l1');
    final qs = api.questionsOf(s.id);
    for (var i = 0; i < qs.length; i++) {
      await repo.recordTry(
        'c1',
        s.id,
        q: i + 1,
        attempt: 1,
        answer: qs[i].count,
      );
    }
    api.failCompletes = 4;
    await expectLater(
      repo.complete('c1', s.id),
      throwsA(isA<AngkaException>()),
    );
    expect(repo.pendingCompletes, {('c1', s.id)});

    await repo.retryPendingCompletes('c1');
    expect(repo.pendingCompletes, isEmpty);
    expect(api.progressRows['l1']!['best_stars'], 3);
  });

  test('a pending complete the server sees as unfinished is dropped', () async {
    // A try was lost, so the server can't finish the session.
    final s = await repo.startSession('c1', 'l1');
    api.failCompletes = 4;
    await expectLater(
      repo.complete('c1', s.id),
      throwsA(isA<AngkaException>()),
    );
    expect(repo.pendingCompletes, hasLength(1), reason: 'network: retry later');

    await repo.retryPendingCompletes('c1');
    expect(repo.pendingCompletes, isEmpty, reason: '422: Lanjut resumes it');
    expect(api.progressRows['l1']!['completed'], isFalse);
  });

  test('the session regenerates the same questions as the server', () async {
    final s = await repo.startSession('c1', 'l1');
    expect(s.questions(), api.questionsOf(s.id));
    expect(s.content.hint, contains('{benda}'));
    expect(s.objects.keys, ['apel', 'bola']);
  });
}
