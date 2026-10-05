import 'dart:convert';
import 'dart:typed_data';

import 'package:arunika_app/constants/app_strings.dart';
import 'package:arunika_app/data/api/huruf_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records each request and answers with a canned status, body and ETag.
class _Adapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  int status = 200;
  Object? body = {'data': <String, dynamic>{}};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      body == null ? '' : jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        'etag': ['"abc"'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _Adapter adapter;
  late HurufApi api;

  setUp(() {
    adapter = _Adapter();
    api = HurufApi(
      dio: Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = adapter,
    );
  });

  test('manifest sends If-None-Match and treats 304 as unchanged', () async {
    adapter.body = {
      'data': {'premium': false, 'letters': []},
    };
    final first = await api.fetchManifest();
    expect(adapter.requests.single.path, '/learn/huruf/manifest');
    expect(adapter.requests.single.headers['If-None-Match'], isNull);
    expect(first.body, isNotNull);
    expect(first.etag, '"abc"');

    adapter
      ..status = 304
      ..body = null;
    final second = await api.fetchManifest(etag: '"abc"');
    expect(adapter.requests.last.headers['If-None-Match'], '"abc"');
    expect(second.body, isNull);
    expect(second.etag, '"abc"');
  });

  test('letter, progress and save hit the Huruf routes', () async {
    adapter.body = {
      'data': {'id': 'L'},
    };
    await api.fetchLetter('L');
    adapter.body = {'data': []};
    await api.fetchProgress('c1');
    adapter.body = {
      'data': {'letter_id': 'L'},
    };
    await api.saveProgress('c1', 'L', {'kenali_done': true});
    expect(adapter.requests.map((r) => '${r.method} ${r.path}'), [
      'GET /learn/huruf/letters/L',
      'GET /children/c1/huruf/progress',
      'PUT /children/c1/huruf/progress/L',
    ]);
    expect(adapter.requests.last.data, {'kenali_done': true});
  });

  test('a 402 surfaces as a DioException', () async {
    adapter
      ..status = 402
      ..body = {'code': 'PREMIUM_REQUIRED'};
    await expectLater(api.fetchLetter('B'), throwsA(isA<DioException>()));
  });

  test('Huruf copy', () {
    expect(AppStrings.hurufDoneCount(3, 26), '3 dari 26 selesai');
    expect(
      AppStrings.hurufReasonOffPath('A'),
      'Garisnya keluar dari jalur huruf A.',
    );
    expect(AppStrings.hurufNextLetter('B'), 'Lanjut ke huruf B');
    expect(AppStrings.hurufTraceTitle('a'), 'Tebalkan huruf a');
  });
}
