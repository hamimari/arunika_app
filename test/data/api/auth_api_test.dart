import 'dart:convert';

import 'package:arunika_app/constants/api_paths.dart';
import 'package:arunika_app/data/api/auth_api.dart';
import 'package:arunika_app/network/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records every request and answers 200, so a test can read the headers the
/// call really went out with.
class _RecordingAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode({'message': 'ok'}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureStorageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (call) async {
          if (call.method == 'read') {
            final key = (call.arguments as Map)['key'];
            return key == 'auth_token' ? 'access-123' : null;
          }
          return null;
        });
  });

  // Regression: resend-verification went out with no Authorization header
  // (AuthApi used a bare Dio), so the backend answered 401 and the banner
  // said "Gagal mengirim email" every time.
  test(
    'should_send_the_signed_in_users_token_when_resending_verification',
    () async {
      final adapter = _RecordingAdapter();
      final authed = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = adapter
        ..interceptors.add(AuthInterceptor());
      final api = AuthApi(authenticatedDio: authed);

      await api.resendVerification();

      expect(adapter.requests, hasLength(1));
      expect(adapter.requests.single.path, ApiPaths.resendVerification);
      expect(
        adapter.requests.single.headers['Authorization'],
        'Bearer access-123',
      );
    },
  );

  test('should_use_the_apps_authenticated_client_for_resend_by_default', () {
    expect(identical(AuthApi().authenticatedDio, DioClient.dio), isTrue);
  });

  test('should_not_send_a_token_on_the_calls_made_before_signing_in', () async {
    final adapter = _RecordingAdapter();
    final plain = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = adapter;
    final api = AuthApi(dio: plain);

    await api.signin({'email': 'a@b.c', 'password': 'x'});

    expect(
      adapter.requests.single.headers.containsKey('Authorization'),
      isFalse,
    );
  });
}
