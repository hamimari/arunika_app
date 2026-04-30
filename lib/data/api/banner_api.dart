import 'package:arunika_app/constants/api_paths.dart';
import 'package:arunika_app/network/dio_client.dart';
import 'package:dio/dio.dart';

class BannerApi {
  final Dio dio;
  BannerApi() : dio = DioClient.dio;

  Future<List<dynamic>> getActiveBanners() async {
    final res = await dio.get(ApiPaths.banners);
    final data = res.data;
    if (data is Map && data['data'] != null) {
      return data['data'] as List<dynamic>;
    }
    if (data is List) return data;
    return [];
  }
}
