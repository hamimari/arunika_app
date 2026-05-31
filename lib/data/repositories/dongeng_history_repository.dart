import 'package:arunika_app/data/api/dongeng_history_api.dart';
import 'package:arunika_app/data/models/response/dongeng_history_item.dart';

class DongengHistoryRepository {
  final DongengHistoryApi api;

  DongengHistoryRepository(this.api);

  Future<void> recordPlay(String dongengId) async {
    try {
      await api.recordPlay(dongengId);
    } catch (_) {}
  }

  Future<void> updateProgress(String dongengId, int progressSeconds) async {
    try {
      await api.updateProgress(dongengId, progressSeconds);
    } catch (_) {}
  }

  Future<List<DongengHistoryItem>> getHistory() async {
    try {
      final list = await api.getHistory();
      return DongengHistoryItem.fromJsonList(list);
    } catch (_) {
      return [];
    }
  }

  Future<List<dynamic>> getPopular({String? category}) async {
    try {
      return await api.getPopular(category: category);
    } catch (_) {
      return [];
    }
  }
}
