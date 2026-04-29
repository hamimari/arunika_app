import 'package:arunika_app/constants/api_paths.dart';
import 'package:arunika_app/network/dio_client.dart';
import 'package:dio/dio.dart';

class ArApi {
  final Dio dio;

  ArApi() : dio = DioClient.dio;

  Future<Map<String, dynamic>> getById(String id) async {
    final res = await dio.get('${ApiPaths.arModelById}$id');
    return res.data;
  }
}
