import 'package:arunika_app/config/app_config.dart';
import 'package:arunika_app/constants/api_paths.dart';
import 'package:dio/dio.dart';

class ArApi {
  final Dio dio;

  ArApi() : dio = Dio(BaseOptions(baseUrl: AppConfig.baseUrl));

  Future<Map<String, dynamic>> getById(String id) async {
    final res = await dio.get('${ApiPaths.arModelById}$id');
    return res.data;
  }
}