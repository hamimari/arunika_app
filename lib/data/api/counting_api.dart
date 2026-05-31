import 'package:arunika_app/constants/api_paths.dart';
import 'package:arunika_app/network/dio_client.dart';
import 'package:dio/dio.dart';

class CountingApi {
  final Dio dio;
  CountingApi() : dio = DioClient.dio;

  Future<Map<String, dynamic>> getQuestions({String? level}) async {
    final res = await dio.get(
      ApiPaths.countingQuestions,
      queryParameters: {if (level != null && level.isNotEmpty) 'level': level},
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> saveProgress(Map<String, dynamic> body) async {
    final res = await dio.post(ApiPaths.countingProgress, data: body);
    return res.data as Map<String, dynamic>;
  }
}
