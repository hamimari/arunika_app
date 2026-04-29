import 'package:arunika_app/constants/api_paths.dart';
import 'package:arunika_app/network/dio_client.dart';
import 'package:dio/dio.dart';

class FairyTalesApi {
  final Dio dio;

  FairyTalesApi() : dio = DioClient.dio;

  /// Returns a paginated, optionally-filtered list of fairy tales (no pages).
  Future<Map<String, dynamic>> findAll({
    String search = '',
    int page = 1,
    int perPage = 10,
  }) async {
    final res = await dio.get(
      ApiPaths.fairyTales,
      queryParameters: {
        if (search.isNotEmpty) 'search': search,
        'page': page,
        'per_page': perPage,
      },
    );
    return res.data as Map<String, dynamic>;
  }

  /// Returns a single fairy tale with its pages ordered by page_number.
  Future<Map<String, dynamic>> findById(String id) async {
    final res = await dio.get('${ApiPaths.fairyTaleById}$id');
    return res.data as Map<String, dynamic>;
  }
}
