import 'package:arunika_app/network/api_errors.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

DioException _error(int status, Object? data) {
  final options = RequestOptions(path: '/payment/create');
  return DioException(
    requestOptions: options,
    response: Response(requestOptions: options, statusCode: status, data: data),
  );
}

void main() {
  test('recognises the backend refusal for an active subscriber', () {
    expect(isSubscriptionActiveError(_error(409, {'code': 'SUBSCRIPTION_ACTIVE'})), isTrue);
  });

  test('ignores any other failure', () {
    expect(isSubscriptionActiveError(_error(409, {'code': 'OTHER'})), isFalse);
    expect(isSubscriptionActiveError(_error(500, {'code': 'SUBSCRIPTION_ACTIVE'})), isFalse);
    expect(isSubscriptionActiveError(_error(409, 'not json')), isFalse);
    expect(isSubscriptionActiveError(Exception('offline')), isFalse);
  });
}
