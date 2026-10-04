// ignore_for_file: inference_failure_on_function_invocation

import 'dart:convert';

import 'package:arunika_app/constants/api_paths.dart';
import 'package:arunika_app/core/auth/auth_notifier.dart';
import 'package:arunika_app/core/storage/SecureStorageToken.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/network/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A canned [HttpClientAdapter] response: matched against a request by
/// [matches] and returned in order via [FakeAdapter].
class CannedResponse {
  final bool Function(RequestOptions options) matches;
  final int statusCode;
  final Map<String, dynamic> body;

  CannedResponse({
    required this.matches,
    required this.statusCode,
    required this.body,
  });
}

/// Replaces real network I/O with canned responses so the [AuthInterceptor]
/// retry/refresh flow can be exercised without a server.
class FakeAdapter implements HttpClientAdapter {
  final List<CannedResponse> responses;
  final List<RequestOptions> requests = [];

  FakeAdapter(this.responses);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    for (final canned in responses) {
      if (canned.matches(options)) {
        return ResponseBody.fromString(
          jsonEncode(canned.body),
          canned.statusCode,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      }
    }
    throw StateError('FakeAdapter: no canned response for ${options.path}');
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock flutter_secure_storage's platform channel with an in-memory map, so
  // SecureTokenStorage reads/writes work without a real platform.
  const secureStorageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final storageValues = <String, String>{};

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (call) async {
          switch (call.method) {
            case 'write':
              final args = Map<String, dynamic>.from(call.arguments as Map);
              storageValues[args['key'] as String] = args['value'] as String;
              return null;
            case 'read':
              final args = Map<String, dynamic>.from(call.arguments as Map);
              return storageValues[args['key'] as String];
            case 'delete':
              final args = Map<String, dynamic>.from(call.arguments as Map);
              storageValues.remove(args['key'] as String);
              return null;
            case 'deleteAll':
              storageValues.clear();
              return null;
            default:
              return null;
          }
        });
  });

  setUp(() async {
    storageValues.clear();
    await SecureTokenStorage.saveToken('expired-access-token');
    await SecureTokenStorage.saveRefreshToken('valid-refresh-token');

    // The interceptor calls the top-level `authNotifier` (a locator lookup)
    // on a dead session, and AuthNotifier.logout() reads/writes prefs.
    SharedPreferences.setMockInitialValues({});
    if (locator.isRegistered<AuthNotifier>()) {
      locator.unregister<AuthNotifier>();
    }
    locator.registerSingleton<AuthNotifier>(AuthNotifier());
  });

  tearDown(() {
    // Restore real adapters so no fake leaks into another test file's run.
    DioClient.dio.httpClientAdapter = IOHttpClientAdapter();
    RefreshDio.dio.httpClientAdapter = IOHttpClientAdapter();
  });

  test(
    '401 on a request triggers a body-only refresh (no Authorization header) '
    'and retries with the new access token',
    () async {
      final fake = FakeAdapter([
        CannedResponse(
          matches: (o) => o.path == '/protected' && o.headers['Authorization'] == 'Bearer expired-access-token',
          statusCode: 401,
          body: {'error': 'token expired'},
        ),
        CannedResponse(
          matches: (o) => o.path == ApiPaths.refreshToken,
          statusCode: 200,
          body: {'access_token': 'fresh-access-token', 'refresh_token': 'fresh-refresh-token'},
        ),
        CannedResponse(
          matches: (o) => o.path == '/protected' && o.headers['Authorization'] == 'Bearer fresh-access-token',
          statusCode: 200,
          body: {'ok': true},
        ),
      ]);
      DioClient.dio.httpClientAdapter = fake;
      RefreshDio.dio.httpClientAdapter = fake;

      final response = await DioClient.dio.get('/protected');

      expect(response.statusCode, 200);
      expect(response.data['ok'], true);
      expect(await SecureTokenStorage.getToken(), 'fresh-access-token');
      expect(await SecureTokenStorage.getRefreshToken(), 'fresh-refresh-token');

      // The refresh request must never carry an Authorization header — the
      // backend endpoint takes no JWT middleware, since an expired access
      // token is exactly when a refresh is needed.
      final refreshRequest = fake.requests.firstWhere(
        (o) => o.path == ApiPaths.refreshToken,
      );
      expect(refreshRequest.headers.containsKey('Authorization'), isFalse);
      expect(
        (refreshRequest.data as Map)['refresh_token'],
        'valid-refresh-token',
      );
    },
  );

  test(
    'a 401 on the refresh call itself (dead session) logs out without '
    'crashing on the response body',
    () async {
      final fake = FakeAdapter([
        CannedResponse(
          matches: (o) => o.path == '/protected',
          statusCode: 401,
          body: {'error': 'token expired'},
        ),
        CannedResponse(
          matches: (o) => o.path == ApiPaths.refreshToken,
          statusCode: 401,
          body: {'error': 'Invalid or expired refresh token'},
        ),
      ]);
      DioClient.dio.httpClientAdapter = fake;
      RefreshDio.dio.httpClientAdapter = fake;

      await expectLater(DioClient.dio.get('/protected'), throwsA(isA<DioException>()));

      // The interceptor's generic catch on a malformed/absent token must not
      // have written garbage into storage.
      expect(await SecureTokenStorage.getToken(), isNull);
    },
  );
}
