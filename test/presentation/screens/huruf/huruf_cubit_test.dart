import 'package:arunika_app/data/repositories/huruf_repository.dart';
import 'package:arunika_app/presentation/screens/huruf/huruf_cubit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_huruf_api.dart';

void main() {
  late FakeHurufApi api;
  late ValueNotifier<bool> enabled;

  HurufCubit build({String? child = 'c1'}) => HurufCubit(
    repository: HurufRepository(api, sleep: (_) async {}),
    enabled: () => enabled.value,
    childId: () async => child,
    trigger: enabled,
  );

  setUp(() {
    api = FakeHurufApi();
    enabled = ValueNotifier(true);
  });

  test('loads the manifest and derives tile states', () async {
    api.progressRows['id-A'] = {
      'letter_id': 'id-A',
      'kenali_done': true,
      'dengar_done': false,
      'tebalkan_done': false,
      'updated_at': '2026-10-05T08:00:00Z',
    };
    final cubit = build();
    await cubit.load();
    final s = cubit.state;
    expect(s.status, HurufStatus.loaded);
    expect(s.tileState(s.letters[0]), LetterTileState.inProgress);
    expect(s.tileState(s.letters[1]), LetterTileState.locked);
    expect(s.continueLetter?.upper, 'A');
    expect(s.nextActivity('id-A'), HurufActivity.tebalkan);
    expect(s.nextLetter('id-A')?.upper, 'B');
    expect(s.nextLetter('id-C'), isNull);
    expect(s.doneCount, 0);
    await cubit.close();
  });

  test('hidden when disabled, and again when the flag turns off', () async {
    enabled.value = false;
    final cubit = build();
    expect(cubit.state.status, HurufStatus.hidden);
    enabled.value = true;
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.status, HurufStatus.loaded);
    enabled.value = false;
    expect(cubit.state.status, HurufStatus.hidden);
    await cubit.close();
  });

  test('no child', () async {
    final cubit = build(child: null);
    await cubit.load();
    expect(cubit.state.status, HurufStatus.noChild);
    await cubit.close();
  });

  test('record shows progress at once and keeps the server row', () async {
    final cubit = build();
    await cubit.load();
    final pending = cubit.record('id-A', kenali: true);
    expect(
      cubit.state.progress['id-A']!.kenaliDone,
      isTrue,
      reason: 'optimistic',
    );
    await pending;
    await cubit.record('id-A', dengar: true);
    await cubit.record('id-A', tebalkan: true, score: 0.93, attempt: true);
    final p = cubit.state.progress['id-A']!;
    expect(p.done, isTrue);
    expect(p.bestScore, 0.93);
    expect(cubit.state.doneCount, 1);
    expect(cubit.state.tileState(cubit.state.letters[0]), LetterTileState.done);
    expect(cubit.state.continueLetter, isNull, reason: 'done letters drop out');
    await cubit.close();
  });

  test('a 402 on a write is dropped and the manifest refreshed', () async {
    api.premium = true;
    final cubit = build();
    await cubit.load();
    expect(
      cubit.state.tileState(cubit.state.letters[2]),
      LetterTileState.notStarted,
    );

    // The subscription lapses while C is open.
    api.premium = false;
    await cubit.record('id-C', kenali: true);
    expect(
      api.calls,
      contains('manifest "v1"-true'),
      reason: 'refetched past the 15-minute cache',
    );
    expect(cubit.state.premium, isFalse);
    expect(
      cubit.state.tileState(cubit.state.letters[2]),
      LetterTileState.locked,
    );
    expect(cubit.state.status, HurufStatus.loaded);
    await cubit.close();
  });

  test('a load failure without cached data is an error state', () async {
    final cubit = HurufCubit(
      repository: HurufRepository(_Failing()),
      enabled: () => true,
      childId: () async => 'c1',
    );
    await cubit.load();
    expect(cubit.state.status, HurufStatus.error);
    await cubit.close();
  });
}

class _Failing extends FakeHurufApi {
  @override
  Future<List<dynamic>> fetchProgress(String childId) async =>
      throw StateError('offline');
}
