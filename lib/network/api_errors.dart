import 'package:dio/dio.dart';

/// True when the backend refused to start a purchase because the user's
/// active subscription already covers everything (409 SUBSCRIPTION_ACTIVE).
bool isSubscriptionActiveError(Object error) {
  if (error is! DioException) return false;
  final response = error.response;
  if (response?.statusCode != 409) return false;
  final data = response?.data;
  return data is Map && data['code'] == 'SUBSCRIPTION_ACTIVE';
}
