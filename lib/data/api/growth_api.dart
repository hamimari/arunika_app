import 'package:arunika_app/constants/api_paths.dart';
import 'package:arunika_app/network/dio_client.dart';
import 'package:dio/dio.dart';

/// `/children/:childId/growth` — Tumbuh Kembang measurements.
class GrowthApi {
  final Dio dio;

  GrowthApi({Dio? dio}) : dio = dio ?? DioClient.dio;

  Future<Map<String, dynamic>> fetchSummary(String childId) async {
    final res = await dio.get(ApiPaths.childGrowth(childId));
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> create(
    String childId,
    Map<String, dynamic> body,
  ) async {
    final res = await dio.post(
      ApiPaths.growthMeasurements(childId),
      data: body,
    );
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> update(
    String childId,
    String id,
    Map<String, dynamic> body,
  ) async {
    final res = await dio.patch(
      ApiPaths.growthMeasurement(childId, id),
      data: body,
    );
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<void> delete(String childId, String id) async {
    await dio.delete(ApiPaths.growthMeasurement(childId, id));
  }

  Future<void> restore(String childId, String id) async {
    await dio.post(ApiPaths.growthMeasurementRestore(childId, id));
  }
}
