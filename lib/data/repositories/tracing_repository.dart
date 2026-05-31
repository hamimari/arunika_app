import 'package:arunika_app/data/api/tracing_api.dart';
import 'package:arunika_app/data/models/response/tracing_item.dart';

class TracingRepository {
  final TracingApi api;
  TracingRepository(this.api);

  Future<List<TracingItem>> getItems({String? type}) async {
    final json = await api.getItems(type: type);
    return TracingItem.fromJsonList(json['data'] as List<dynamic>);
  }

  Future<void> saveProgress({
    required String childId,
    required String itemId,
    required int score,
    required bool passed,
  }) async {
    await api.saveProgress({
      'child_id': childId,
      'item_id': itemId,
      'score': score,
      'passed': passed,
    });
  }
}
