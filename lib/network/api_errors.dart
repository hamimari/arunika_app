import 'package:dio/dio.dart';

bool _hasCode(Object error, int status, String code) {
  if (error is! DioException) return false;
  final response = error.response;
  if (response?.statusCode != status) return false;
  final data = response?.data;
  return data is Map && data['code'] == code;
}

/// True when the backend refused to start a purchase because the user's
/// active subscription already covers everything (409 SUBSCRIPTION_ACTIVE).
bool isSubscriptionActiveError(Object error) =>
    _hasCode(error, 409, 'SUBSCRIPTION_ACTIVE');

/// True when the backend refused the Midtrans checkout because alternative
/// billing is switched off (403 ALTERNATIVE_BILLING_DISABLED).
bool isAlternativeBillingDisabledError(Object error) =>
    _hasCode(error, 403, 'ALTERNATIVE_BILLING_DISABLED');
