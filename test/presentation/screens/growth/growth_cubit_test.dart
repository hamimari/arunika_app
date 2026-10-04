import 'dart:io';

import 'package:arunika_app/core/growth/growth_engine.dart';
import 'package:arunika_app/data/models/response/growth_response.dart';
import 'package:arunika_app/data/repositories/growth_repository.dart';
import 'package:arunika_app/presentation/screens/growth/growth_cubit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGrowthRepository extends Mock implements GrowthRepository {}

GrowthMeasurement m(
  String id,
  DateTime on, {
  double? h,
  double? w,
  String? hfa = 'normal',
  String? wfa = 'normal',
}) => GrowthMeasurement(
  id: id,
  measuredOn: on,
  heightCm: h,
  weightKg: w,
  position: Position.standing,
  ageDays: on.difference(DateTime(2023, 7, 12)).inDays,
  hfaCategory: h == null ? null : hfa,
  wfaCategory: w == null ? null : wfa,
);

GrowthSummary summary(List<GrowthMeasurement> ms) => GrowthSummary(
  profileComplete: true,
  child: GrowthChild(
    id: 'c1',
    name: 'hamiz',
    sex: Sex.male,
    birthDate: DateTime(2023, 7, 12),
  ),
  measurements: ms,
);

void main() {
  late MockGrowthRepository repo;
  late WhoGrowthStandard who;
  late ValueNotifier<bool> enabled;

  setUpAll(() {
    who = WhoGrowthStandard.parse(
      File(WhoGrowthStandard.assetPath).readAsStringSync(),
    );
    registerFallbackValue(
      MeasurementInput(measuredOn: DateTime(2026), position: Position.standing),
    );
  });

  setUp(() {
    repo = MockGrowthRepository();
    enabled = ValueNotifier(true);
  });

  GrowthCubit build() => GrowthCubit(
    repository: repo,
    enabled: () => enabled.value,
    childId: () async => 'c1',
    loadStandard: () async => who,
    trigger: enabled,
  );

  final full = summary([
    m('m2', DateTime(2026, 9, 12), h: 94.8, w: null),
    m('m1', DateTime(2026, 6, 12), h: 92.6, w: 13.3),
  ]);

  test('loads on creation and derives latest values and deltas', () async {
    when(() => repo.fetchSummary('c1')).thenAnswer((_) async => full);
    final cubit = build();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    final s = cubit.state;
    expect(s.status, GrowthStatus.loaded);
    expect(s.latestHeight!.value, 94.8);
    expect(s.latestHeight!.delta, 2.2);
    // The newest has no weight: the latest weight is the older one, with no
    // earlier weight to compare against.
    expect(s.latestWeight!.value, 13.3);
    expect(s.latestWeight!.delta, isNull);
    expect(s.newest!.id, 'm2');
    await cubit.close();
  });

  test('stays hidden while disabled and clears when switched off', () async {
    when(() => repo.fetchSummary('c1')).thenAnswer((_) async => full);
    enabled.value = false;
    final cubit = build();
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.status, GrowthStatus.hidden);
    verifyNever(() => repo.fetchSummary(any()));

    enabled.value = true;
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.status, GrowthStatus.loaded);

    enabled.value = false;
    expect(cubit.state.status, GrowthStatus.hidden);
    expect(cubit.state.summary, isNull);
    await cubit.close();
  });

  test('delete hides the row at once and restores it on failure', () async {
    when(() => repo.fetchSummary('c1')).thenAnswer((_) async => full);
    when(
      () => repo.delete('c1', 'm2'),
    ).thenAnswer((_) async => throw const GrowthSaveException(null));
    final cubit = build();
    await cubit.load();

    final future = cubit.delete('m2');
    expect(cubit.state.measurements.map((e) => e.id), ['m1']);
    expect(cubit.state.latestHeight!.value, 92.6);

    expect(await future, isFalse);
    expect(cubit.state.measurements.map((e) => e.id), ['m2', 'm1']);
    await cubit.close();
  });

  test('delete then restore reloads from the server', () async {
    when(() => repo.fetchSummary('c1')).thenAnswer((_) async => full);
    when(() => repo.delete('c1', 'm2')).thenAnswer((_) async {});
    when(() => repo.restore('c1', 'm2')).thenAnswer((_) async {});
    final cubit = build();
    await cubit.load();

    expect(await cubit.delete('m2'), isTrue);
    await cubit.restore('m2');

    verify(() => repo.restore('c1', 'm2')).called(1);
    verify(() => repo.fetchSummary('c1')).called(greaterThanOrEqualTo(3));
    await cubit.close();
  });

  test('create passes the client id and reloads', () async {
    when(() => repo.fetchSummary('c1')).thenAnswer((_) async => full);
    when(
      () =>
          repo.create('c1', any(), clientId: 'client-1', confirmOutlier: false),
    ).thenAnswer((_) async => full.measurements.first);
    final cubit = build();
    await cubit.load();

    await cubit.create(
      MeasurementInput(
        measuredOn: DateTime(2026, 9, 12),
        heightCm: 94.8,
        position: Position.standing,
      ),
      clientId: 'client-1',
    );

    verify(
      () =>
          repo.create('c1', any(), clientId: 'client-1', confirmOutlier: false),
    ).called(1);
    await cubit.close();
  });

  test('keeps the current data when a refresh fails', () async {
    when(() => repo.fetchSummary('c1')).thenAnswer((_) async => full);
    final cubit = build();
    await cubit.load();
    when(() => repo.fetchSummary('c1')).thenThrow(Exception('offline'));

    await cubit.load();

    expect(cubit.state.status, GrowthStatus.error);
    expect(cubit.state.summary, full);
    await cubit.close();
  });

  test('client ids are v4 UUIDs and unique', () {
    final a = newClientId(), b = newClientId();
    expect(
      RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      ).hasMatch(a),
      isTrue,
    );
    expect(a, isNot(b));
  });
}
