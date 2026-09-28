import 'package:arunika_app/constants/api_paths.dart';
import 'package:arunika_app/network/dio_client.dart';
import 'package:dio/dio.dart';

class UserApi {
  final Dio dio;

  UserApi() : dio = DioClient.dio;

  Future<Map<String, dynamic>> findById(String id) async {
    final res = await dio.get('${ApiPaths.findUserById}$id');

    return res.data;
  }

  Future<Map<String, dynamic>> update(Map<String, dynamic> payload) async {
    final res = await dio.put(ApiPaths.updateUser, data: payload);
    return res.data;
  }

  /// POST /user/consent — records acceptance of the legal documents.
  /// Returns whether consent is still required afterwards.
  Future<bool> recordConsent(Map<String, dynamic> payload) async {
    final res = await dio.post(ApiPaths.recordConsent, data: payload);
    return (res.data as Map<String, dynamic>)['consent_required'] as bool? ??
        false;
  }

  /// DELETE /user/me — deletes/anonymizes the authenticated user's account
  /// and data (see AccountDeletionService on the backend).
  Future<void> deleteAccount() async {
    await dio.delete(ApiPaths.deleteAccount);
  }
}
