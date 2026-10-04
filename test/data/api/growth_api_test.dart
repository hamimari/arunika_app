import 'dart:convert';
import 'dart:typed_data';

import 'package:arunika_app/core/growth/growth_engine.dart';
import 'package:arunika_app/data/api/growth_api.dart';
import 'package:arunika_app/data/repositories/growth_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records each request and answers with a canned status and body.
class _Adapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  int status = 200;
  Object body = {'data': _measurement};
  bool offline = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (offline) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      );
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const _measurement = {
  'id': 'm1',
  'client_id': 'k1',
  'measured_on': '2026-09-12',
  'height_cm': 94.8,
  'weight_kg': null,
  'position': 'standing',
  'age_days': 1158,
  'hfa': {'z': -0.68, 'category': 'normal'},
  'wfa': null,
  'flagged': false,
};

void main() {
  late _Adapter adapter;
  late GrowthRepository repo;
  final input = MeasurementInput(
    measuredOn: DateTime(2026, 9, 2),
    heightCm: 94.8,
    position: Position.recumbent,
  );

  setUp(() {
    adapter = _Adapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = adapter;
    repo = GrowthRepository(GrowthApi(dio: dio));
  });

  test('summary parses categories and never keeps z-scores', () async {
    adapter.body = {
      'data': {
        'profile_complete': true,
        'child': {
          'id': 'c1',
          'name': 'hamiz',
          'sex': 'male',
          'birth_date': '2023-07-12',
        },
        'measurements': [_measurement],
      },
    };
    final s = await repo.fetchSummary('c1');
    expect(adapter.requests.single.path, '/children/c1/growth');
    expect(s.child.sex, Sex.male);
    expect(s.measurements.single.hfaCategory, 'normal');
    expect(s.measurements.single.wfaCategory, isNull);
  });

  test('create sends snake_case values and the client id', () async {
    adapter.status = 201;
    final m = await repo.create('c1', input, clientId: 'k1');
    final req = adapter.requests.single;
    expect(req.method, 'POST');
    expect(req.path, '/children/c1/growth/measurements');
    expect(req.data, {
      'measured_on': '2026-09-02',
      'height_cm': 94.8,
      'weight_kg': null,
      'position': 'recumbent',
      'confirm_outlier': false,
      'client_id': 'k1',
    });
    expect(m.id, 'm1');
  });

  test('edit, delete and restore hit the measurement routes', () async {
    await repo.update('c1', 'm1', input, confirmOutlier: true);
    adapter.status = 204;
    adapter.body = '';
    await repo.delete('c1', 'm1');
    adapter.status = 200;
    await repo.restore('c1', 'm1');
    expect(adapter.requests.map((r) => '${r.method} ${r.path}'), [
      'PATCH /children/c1/growth/measurements/m1',
      'DELETE /children/c1/growth/measurements/m1',
      'POST /children/c1/growth/measurements/m1/restore',
    ]);
    expect((adapter.requests.first.data as Map)['confirm_outlier'], isTrue);
  });

  test('a 422 surfaces its code; no answer is a network error', () async {
    adapter
      ..status = 422
      ..body = {
        'error': 'invalid measurement',
        'code': 'OUTLIER_NEEDS_CONFIRM',
      };
    await expectLater(
      repo.create('c1', input, clientId: 'k1'),
      throwsA(
        isA<GrowthSaveException>().having(
          (e) => e.needsOutlierConfirm,
          'needsOutlierConfirm',
          isTrue,
        ),
      ),
    );

    adapter.offline = true;
    await expectLater(
      repo.delete('c1', 'm1'),
      throwsA(
        isA<GrowthSaveException>().having(
          (e) => e.isNetwork,
          'isNetwork',
          true,
        ),
      ),
    );
  });
}
