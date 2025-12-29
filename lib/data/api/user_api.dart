import 'package:arunika_app/config/app_config.dart';
import 'package:arunika_app/constants/api_paths.dart';
import 'package:arunika_app/core/storage/SecureStorageToken.dart';
import 'package:dio/dio.dart';

class UserApi {
  final Dio dio;

  UserApi() : dio = Dio(BaseOptions(baseUrl: AppConfig.baseUrl));

  Future<Map<String, dynamic>> findById(String id) async {
    String? token = await SecureTokenStorage.getToken();
    final options = Options(headers: {'Authorization': 'Bearer $token'});
    final res = await dio.get('${ApiPaths.findUserById}$id', options: options);

    return res.data;
  }

  Future<Map<String, dynamic>> update(Map<String, dynamic> payload) async {
    String? token = await SecureTokenStorage.getToken();
    final options = Options(headers: {'Authorization': 'Bearer $token'});
    print('Payload: $payload');
    final res = await dio.put(ApiPaths.updateUser, options: options, data: payload);
    print('Res: $res');
    return res.data;
  }
}