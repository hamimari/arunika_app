import 'package:arunika_app/constants/api_paths.dart';
import 'package:arunika_app/network/dio_client.dart';
import 'package:dio/dio.dart';

class GrowthApi {
  final Dio dio;
  GrowthApi() : dio = DioClient.dio;

  Future<Map<String, dynamic>> saveRecord(Map<String, dynamic> body) async {
    final res = await dio.post(ApiPaths.growth, data: body);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateRecord(
    String id,
    Map<String, dynamic> body,
  ) async {
    final res = await dio.put('${ApiPaths.growthUpdate}$id', data: body);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getHistory(String childId) async {
    final res = await dio.get(
      ApiPaths.growth,
      queryParameters: {'child_id': childId},
    );
    return res.data as Map<String, dynamic>;
  }
}
