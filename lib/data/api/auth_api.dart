import 'package:dio/dio.dart';
import '../../config/app_config.dart';
import '../../constants/api_paths.dart';

class AuthApi {
  final Dio dio;

  AuthApi() : dio = Dio(BaseOptions(baseUrl: AppConfig.baseUrl));

  Future<Map<String, dynamic>> signup(Map<String, dynamic> body) async {
    final res = await dio.post(ApiPaths.signup, data: body);
    return res.data;
  }

  Future<Map<String, dynamic>> signin(Map<String, dynamic> body) async {
    final res = await dio.post(ApiPaths.signin, data: body);
    return res.data;
  }
}
