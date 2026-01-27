
import 'package:arunika_app/config/app_config.dart';
import 'package:arunika_app/constants/api_paths.dart';
import 'package:arunika_app/core/storage/SecureStorageToken.dart';
import 'package:arunika_app/network/dio_client.dart';
import 'package:dio/dio.dart';

class FairyTalesApi {
  final Dio dio;

  FairyTalesApi() : dio = DioClient.dio;

  Future<Map<String, dynamic>> findAll() async {
    final res = await dio.get(ApiPaths.fairyTales);
    return res.data;
  }
}