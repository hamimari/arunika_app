import 'package:arunika_app/constants/api_paths.dart';
import 'package:arunika_app/network/dio_client.dart';
import 'package:dio/dio.dart';

class TracingApi {
  final Dio dio;
  TracingApi() : dio = DioClient.dio;

  Future<Map<String, dynamic>> getItems({String? type}) async {
    final res = await dio.get(
      ApiPaths.tracingItems,
      queryParameters: {if (type != null && type.isNotEmpty) 'type': type},
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> saveProgress(Map<String, dynamic> body) async {
    final res = await dio.post(ApiPaths.tracingProgress, data: body);
    return res.data as Map<String, dynamic>;
  }
}
