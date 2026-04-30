import 'package:arunika_app/data/api/growth_api.dart';
import 'package:arunika_app/data/models/response/growth_record.dart';

class GrowthRepository {
  final GrowthApi api;
  GrowthRepository(this.api);

  Future<GrowthRecord> saveRecord({
    required String childId,
    required double weightKg,
    required double heightCm,
    DateTime? recordedAt,
  }) async {
    final json = await api.saveRecord({
      'child_id': childId,
      'weight_kg': weightKg,
      'height_cm': heightCm,
      if (recordedAt != null)
        'recorded_at': recordedAt.toUtc().toIso8601String(),
    });
    return GrowthRecord.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<GrowthRecord> updateRecord({
    required String id,
    required double weightKg,
    required double heightCm,
    DateTime? recordedAt,
  }) async {
    final json = await api.updateRecord(id, {
      'weight_kg': weightKg,
      'height_cm': heightCm,
      if (recordedAt != null)
        'recorded_at': recordedAt.toUtc().toIso8601String(),
    });
    return GrowthRecord.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<List<GrowthRecord>> getHistory(String childId) async {
    final json = await api.getHistory(childId);
    return GrowthRecord.fromJsonList(json['data'] as List<dynamic>);
  }
}
