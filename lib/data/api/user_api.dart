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
}
