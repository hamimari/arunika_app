
import 'package:arunika_app/config/app_config.dart';
import 'package:arunika_app/constants/api_paths.dart';
import 'package:arunika_app/core/storage/SecureStorageToken.dart';
import 'package:dio/dio.dart';

class FairyTalesApi {
  final Dio dio;

  FairyTalesApi() : dio = Dio(BaseOptions(baseUrl: AppConfig.baseUrl));

  Future<Map<String, dynamic>> findAll() async {
    String? token = await SecureTokenStorage.getToken();
    final options = Options(headers: {'Authorization': 'Bearer $token'});
    final res = await dio.get(ApiPaths.fairyTales, options: options);

    return res.data;
  }
}