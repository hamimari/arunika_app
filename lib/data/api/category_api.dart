import 'package:arunika_app/constants/api_paths.dart';
import 'package:arunika_app/network/dio_client.dart';
import 'package:dio/dio.dart';

class CategoryApi {
  final Dio dio;

  CategoryApi() : dio = DioClient.dio;

  Future<List<dynamic>> getCategories() async {
    final res = await dio.get(ApiPaths.categories);
    final data = res.data as Map<String, dynamic>;
    return data['data'] as List<dynamic>;
  }
}
