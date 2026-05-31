import 'package:arunika_app/constants/api_paths.dart';
import 'package:arunika_app/network/dio_client.dart';
import 'package:dio/dio.dart';

class DongengHistoryApi {
  final Dio dio;

  DongengHistoryApi() : dio = DioClient.dio;

  Future<void> recordPlay(String dongengId) async {
    await dio.post(ApiPaths.dongengPlay(dongengId));
  }

  Future<void> updateProgress(String dongengId, int progressSeconds) async {
    await dio.put(
      ApiPaths.dongengPlay(dongengId),
      data: {'progress_seconds': progressSeconds},
    );
  }

  Future<List<dynamic>> getHistory() async {
    final res = await dio.get(ApiPaths.dongengHistory);
    final data = res.data as Map<String, dynamic>;
    return data['data'] as List<dynamic>;
  }

  Future<List<dynamic>> getPopular({String? category}) async {
    final res = await dio.get(
      ApiPaths.dongengPopular,
      queryParameters: {
        if (category != null && category.isNotEmpty) 'category': category,
      },
    );
    final data = res.data as Map<String, dynamic>;
    return data['data'] as List<dynamic>;
  }
}
