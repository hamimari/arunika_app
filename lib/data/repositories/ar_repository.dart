import 'package:arunika_app/data/api/ar_api.dart';
import 'package:arunika_app/data/models/response/ar_card_category.dart';
import 'package:arunika_app/data/models/response/ar_card_response.dart';

class ArRepository {
  final ArApi api;

  ArRepository(this.api);

  Future<ArCardResponse> findById(String id) async {
    final json = await api.getById(id);
    return ArCardResponse.fromJson(json);
  }

  Future<List<ArCardResponse>> findAll({
    String? categoryId,
    String? subCategoryId,
  }) async {
    final json = await api.findAll(
      categoryId: categoryId,
      subCategoryId: subCategoryId,
    );
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => ArCardResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ArCardCategory>> getCategories() async {
    final json = await api.getCategories();
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => ArCardCategory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<int>> getPrintablePdf(String categoryId) async {
    return api.getPrintablePdf(categoryId);
  }
}
