import 'dart:async';

import 'package:arunika_app/data/repositories/premium_pack_repository.dart';
import 'package:arunika_app/data/static/premium_packs.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/presentation/screens/premium/premium_pack_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// ─── Mocks ────────────────────────────────────────────────────────────────────

class MockPremiumPackRepository extends Mock implements PremiumPackRepository {}

// ─── Helpers ──────────────────────────────────────────────────────────────────

PremiumPack _pack(String id) => PremiumPack(
  id: id,
  name: 'Pack $id',
  subtitle: 'Great pack',
  priceIdr: 29000,
);

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockPremiumPackRepository mockRepo;

  setUp(() async {
    if (locator.isRegistered<PremiumPackRepository>()) {
      await locator.unregister<PremiumPackRepository>();
    }
    mockRepo = MockPremiumPackRepository();
    locator.registerSingleton<PremiumPackRepository>(mockRepo);
  });

  tearDown(() async {
    if (locator.isRegistered<PremiumPackRepository>()) {
      await locator.unregister<PremiumPackRepository>();
    }
  });

  group('PremiumPackCubit', () {
    test(
      'does not emit (or throw) when closed before the fetch completes',
      () async {
        final completer = Completer<List<PremiumPack>>();
        when(
          () => mockRepo.fetchPacks(type: any(named: 'type')),
        ).thenAnswer((_) => completer.future);

        final cubit = PremiumPackCubit('content');
        final load = cubit.loadPacks();
        await cubit.close();
        completer.complete([_pack('1')]);

        await expectLater(load, completes);
      },
    );

    blocTest<PremiumPackCubit, PremiumPackState>(
      'emits [PremiumPackLoading, PremiumPackLoaded] when fetchPacks succeeds',
      build: () {
        when(
          () => mockRepo.fetchPacks(type: any(named: 'type')),
        ).thenAnswer((_) async => [_pack('1'), _pack('2')]);
        return PremiumPackCubit('content');
      },
      act: (c) => c.loadPacks(),
      expect: () => [
        isA<PremiumPackLoading>(),
        isA<PremiumPackLoaded>().having((s) => s.packs.length, 'pack count', 2),
      ],
    );

    blocTest<PremiumPackCubit, PremiumPackState>(
      'emits [PremiumPackLoading, PremiumPackLoaded] with empty list',
      build: () {
        when(
          () => mockRepo.fetchPacks(type: any(named: 'type')),
        ).thenAnswer((_) async => []);
        return PremiumPackCubit('content');
      },
      act: (c) => c.loadPacks(),
      expect: () => [
        isA<PremiumPackLoading>(),
        isA<PremiumPackLoaded>().having((s) => s.packs.isEmpty, 'empty', true),
      ],
    );

    blocTest<PremiumPackCubit, PremiumPackState>(
      'emits [PremiumPackLoading, PremiumPackError] when fetchPacks throws',
      build: () {
        when(
          () => mockRepo.fetchPacks(type: any(named: 'type')),
        ).thenThrow(Exception('network error'));
        return PremiumPackCubit('content');
      },
      act: (c) => c.loadPacks(),
      expect: () => [isA<PremiumPackLoading>(), isA<PremiumPackError>()],
    );
  });
}
