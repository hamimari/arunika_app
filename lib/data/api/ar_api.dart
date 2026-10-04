import 'package:arunika_app/constants/api_paths.dart';
import 'package:arunika_app/network/dio_client.dart';
import 'package:dio/dio.dart';

class ArApi {
  final Dio dio;

  ArApi() : dio = DioClient.dio;

  Future<Map<String, dynamic>> getById(String id) async {
    final res = await dio.get('${ApiPaths.arModelById}$id');
    return res.data;
  }

  Future<Map<String, dynamic>> findAll({
    String? categoryId,
    String? subCategoryId,
  }) async {
    final queryParams = <String, String>{};
    if (categoryId != null && categoryId.isNotEmpty) {
      queryParams['category_id'] = categoryId;
    }
    if (subCategoryId != null && subCategoryId.isNotEmpty) {
      queryParams['sub_category_id'] = subCategoryId;
    }
    final res = await dio.get(ApiPaths.arCards, queryParameters: queryParams);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getCategories() async {
    final res = await dio.get(ApiPaths.arCategories);
    return res.data as Map<String, dynamic>;
  }

  Future<List<int>> getPrintablePdf(String categoryId) async {
    final res = await dio.get<List<int>>(
      ApiPaths.arPrintablePdf,
      queryParameters: {'category_id': categoryId},
      options: Options(responseType: ResponseType.bytes),
    );
    return res.data ?? [];
  }
}
