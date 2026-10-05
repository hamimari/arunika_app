import 'package:arunika_app/data/repositories/angka_repository.dart';
import 'package:arunika_app/presentation/screens/angka/angka_cubit.dart';
import 'package:arunika_app/presentation/screens/angka/angka_play_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_angka_api.dart';

void main() {
  late FakeAngkaApi api;
  late AngkaRepository repo;

  setUp(() {
    api = FakeAngkaApi();
    repo = AngkaRepository(api, sleep: (_) async {});
  });

  AngkaCubit cubit({bool enabled = true, String? child = 'c1'}) => AngkaCubit(
    repository: repo,
    enabled: () => enabled,
    childId: () async => child,
  );

  group('AngkaCubit', () {
    test('level states follow premium, prerequisites and progress', () async {
      api.premium = true;
      api.progressRows['l1'] = {
        'level_id': 'l1',
        'best_stars': 3,
        'completed': true,
        'current_session_id': null,
      };
      final c = cubit();
      await c.load();
      final s = c.state;
      expect(s.status, AngkaStatus.loaded);
      expect(s.levelState(s.levels[0]), AngkaLevelState.done);
      expect(s.levelState(s.levels[1]), AngkaLevelState.notStarted);
      expect(s.levelState(s.levels[2]), AngkaLevelState.prerequisiteLocked);
      expect(s.levelNumber('l2'), 2);
      expect(s.nextOpenLevel('l1')?.id, 'l2');
      expect(s.nextOpenLevel('l2'), isNull);
      await c.close();
    });

    test('premium locks win, and nothing is continued while locked', () async {
      await repo.startSession('c1', 'l1');
      final c = cubit();
      await c.load();
      final s = c.state;
      expect(s.levelState(s.levels[0]), AngkaLevelState.inProgress);
      expect(s.levelState(s.levels[1]), AngkaLevelState.premiumLocked);
      expect(s.continueLevel?.id, 'l1');
      await c.close();
    });

    test('no child and disabled states', () async {
      final none = cubit(child: null);
      await none.load();
      expect(none.state.status, AngkaStatus.noChild);
      await none.close();

      final off = cubit(enabled: false);
      expect(off.state.status, AngkaStatus.hidden);
      await off.close();
    });

    test('load retries a pending complete first', () async {
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
      await expectLater(repo.complete('c1', s.id), throwsA(anything));

      final c = cubit();
      await c.load();
      expect(c.state.progress['l1']!.completed, isTrue);
      expect(c.state.progress['l1']!.bestStars, 3);
      await c.close();
    });
  });

  group('AngkaPlayCubit', () {
    late AngkaPlayCubit play;

    setUp(() async {
      play = AngkaPlayCubit(repository: repo, childId: 'c1', levelId: 'l1');
      await play.start();
    });

    tearDown(() => play.close());

    void answer(int n) {
      for (final ch in '$n'.split('')) {
        play.type(int.parse(ch));
      }
      play.check();
    }

    test('starts at the first question with an empty box', () {
      expect(play.state.phase, AngkaPlayPhase.answering);
      expect(play.state.questions, hasLength(10));
      expect(play.state.input, '');
      expect(play.state.benda, isIn(['apel', 'bola']));
    });

    test('the box holds two digits and reads leading zeros', () {
      play.type(0);
      play.type(7);
      play.type(9);
      expect(play.state.input, '07');
      play.backspace();
      expect(play.state.input, '0');
      play.check();
      expect(play.state.lastAnswer, 0);
      expect(
        play.state.phase,
        AngkaPlayPhase.retry,
        reason: '0 is always wrong',
      );
    });

    test('right first time counts a star', () {
      answer(play.state.question!.count);
      expect(play.state.phase, AngkaPlayPhase.success);
      expect(play.state.firstTry, isTrue);
      expect(play.state.firstCorrect, 1);
    });

    test('keeps asking until the answer is right', () async {
      final n = play.state.question!.count;
      for (var wrong = 1; wrong <= 4; wrong++) {
        answer(n + wrong);
        expect(play.state.phase, AngkaPlayPhase.retry);
        await play.next();
        expect(play.state.index, 0, reason: 'no moving on while wrong');
        play.tryAgain();
        expect(play.state.input, '');
      }
      answer(n);
      expect(play.state.phase, AngkaPlayPhase.success);
      expect(play.state.tries, hasLength(5));
      expect(play.state.firstCorrect, 0);
      await play.next();
      expect(play.state.index, 1);
      expect(play.state.tries, isEmpty);
    });

    test('right on the second try is not a first-try star', () {
      final n = play.state.question!.count;
      answer(n + 1);
      play.tryAgain();
      answer(n);
      expect(play.state.phase, AngkaPlayPhase.success);
      expect(play.state.firstTry, isFalse);
      expect(play.state.firstCorrect, 0);
    });

    test('marks number the tapped pictures once', () {
      expect(play.mark(2), 1);
      expect(play.mark(0), 2);
      expect(play.mark(2), isNull);
      expect(play.state.marks, [2, 0]);
    });

    test('finishing completes on the server, tries sent in order', () async {
      for (var i = 0; i < 10; i++) {
        answer(play.state.question!.count);
        await play.next();
      }
      expect(play.state.phase, AngkaPlayPhase.done);
      expect(play.state.result!.stars, 3);
      expect(play.state.provisional, isFalse);
      final tries = api.calls.where((c) => c.startsWith('try'));
      expect(tries, hasLength(10));
      expect(api.calls.last, 'complete s1');
    });

    test('a failed complete shows provisional stars', () async {
      for (var i = 0; i < 9; i++) {
        answer(play.state.question!.count);
        await play.next();
      }
      api.failCompletes = 4;
      answer(play.state.question!.count + 1);
      play.tryAgain();
      answer(play.state.question!.count);
      await play.next();
      expect(play.state.phase, AngkaPlayPhase.done);
      expect(play.state.provisional, isTrue);
      expect(play.state.result!.stars, 3, reason: '9 of 10 first try');
    });

    test('resumes at the first unfinished question', () async {
      for (var i = 0; i < 3; i++) {
        answer(play.state.question!.count);
        await play.next();
      }
      final again = AngkaPlayCubit(
        repository: repo,
        childId: 'c1',
        levelId: 'l1',
      );
      await again.start();
      expect(again.state.index, 3);
      expect(again.state.firstCorrect, 3);
      await again.close();
    });

    test('locked levels report why', () async {
      final locked = AngkaPlayCubit(
        repository: repo,
        childId: 'c1',
        levelId: 'l2',
      );
      await locked.start();
      expect(locked.state.phase, AngkaPlayPhase.premiumLocked);
      api.premium = true;
      await locked.start();
      expect(locked.state.phase, AngkaPlayPhase.prerequisiteLocked);
      await locked.close();
    });
  });
}
