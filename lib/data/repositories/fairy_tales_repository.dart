import 'package:arunika_app/data/api/fairy_tales_api.dart';
import 'package:arunika_app/data/models/response/dongeng_response.dart';

class DongengListResult {
  final List<DongengResponse> items;
  final int total;
  final int page;

  const DongengListResult({
    required this.items,
    required this.total,
    required this.page,
  });
}

class FairyTalesRepository {
  final FairyTalesApi api;

  FairyTalesRepository(this.api);

  Future<DongengListResult> findAll({
    String search = '',
    int page = 1,
    int perPage = 10,
  }) async {
    final json = await api.findAll(search: search, page: page, perPage: perPage);
    final items = DongengResponse.fromJsonList(json['data'] as List<dynamic>);
    final total = (json['total'] as num?)?.toInt() ?? items.length;
    final currentPage = (json['page'] as num?)?.toInt() ?? page;
    return DongengListResult(items: items, total: total, page: currentPage);
  }

  Future<DongengResponse> findById(String id) async {
    final json = await api.findById(id);
    return DongengResponse.fromJson(json['data'] as Map<String, dynamic>);
  }
}
