import 'package:arunika_app/constants/api_paths.dart';
import 'package:arunika_app/network/dio_client.dart';
import 'package:dio/dio.dart';

class BadgeApi {
  final Dio dio;
  BadgeApi() : dio = DioClient.dio;

  Future<Map<String, dynamic>> getBadges() async {
    final res = await dio.get(ApiPaths.badges);
    return res.data as Map<String, dynamic>;
  }
}
