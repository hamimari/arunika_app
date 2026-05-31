import 'package:arunika_app/constants/api_paths.dart';
import 'package:arunika_app/network/dio_client.dart';
import 'package:dio/dio.dart';

class AnimalApi {
  final Dio dio;

  AnimalApi() : dio = DioClient.dio;

  Future<List<dynamic>> findAll({String category = ''}) async {
    final res = await dio.get(
      ApiPaths.animals,
      queryParameters: {
        if (category.isNotEmpty && category != 'all') 'category': category,
      },
    );
    final data = res.data as Map<String, dynamic>;
    return data['data'] as List<dynamic>;
  }
}
