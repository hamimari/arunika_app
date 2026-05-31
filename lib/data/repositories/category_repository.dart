import 'package:arunika_app/data/api/category_api.dart';
import 'package:arunika_app/data/models/response/category_item.dart';

class CategoryRepository {
  final CategoryApi api;
  List<CategoryItem>? _cache;

  CategoryRepository(this.api);

  Future<List<CategoryItem>> getCategories() async {
    if (_cache != null) return _cache!;
    try {
      final list = await api.getCategories();
      _cache = CategoryItem.fromJsonList(list);
      return _cache!;
    } catch (_) {
      return [];
    }
  }

  void clearCache() => _cache = null;
}
