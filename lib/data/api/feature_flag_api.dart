import 'package:arunika_app/constants/api_paths.dart';
import 'package:arunika_app/network/dio_client.dart';
import 'package:dio/dio.dart';

class FeatureFlagApi {
  final Dio dio;

  FeatureFlagApi() : dio = DioClient.dio;

  /// GET /app/feature-flags → `{"data": {"qr_scan": true, ...}}`.
  Future<Map<String, dynamic>> fetchFlags() async {
    final res = await dio.get(ApiPaths.featureFlags);
    return res.data['data'] as Map<String, dynamic>;
  }
}
