import 'package:arunika_app/constants/api_paths.dart';
import 'package:arunika_app/data/api/huruf_api.dart';
import 'package:arunika_app/network/dio_client.dart';
import 'package:dio/dio.dart';

/// `/learn/angka/*` and `/children/:childId/angka/*`.
class AngkaApi {
  final Dio dio;

  AngkaApi({Dio? dio}) : dio = dio ?? DioClient.dio;

  Future<ManifestResponse> fetchManifest({String? etag}) async {
    final res = await dio.get(
      ApiPaths.angkaManifest,
      options: Options(
        headers: {if (etag != null) 'If-None-Match': etag},
        validateStatus: (s) => s != null && (s >= 200 && s < 300 || s == 304),
      ),
    );
    final tag = res.headers.value('etag');
    if (res.statusCode == 304) return ManifestResponse(null, tag ?? etag);
    return ManifestResponse(res.data['data'] as Map<String, dynamic>, tag);
  }

  Future<Map<String, dynamic>> fetchNumber(int value) async {
    final res = await dio.get(ApiPaths.angkaNumber(value));
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<List<dynamic>> fetchProgress(String childId) async {
    final res = await dio.get(ApiPaths.angkaProgress(childId));
    return res.data['data'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> startSession(
    String childId,
    String levelId, {
    bool restart = false,
  }) async {
    final res = await dio.post(
      ApiPaths.angkaSessions(childId),
      data: {'level_id': levelId, if (restart) 'restart': true},
    );
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> recordTry(
    String childId,
    String sessionId, {
    required int q,
    required int attempt,
    required int answer,
  }) async {
    final res = await dio.patch(
      ApiPaths.angkaSession(childId, sessionId),
      data: {'q': q, 'try': attempt, 'answer': answer},
    );
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> complete(
    String childId,
    String sessionId,
  ) async {
    final res = await dio.post(
      ApiPaths.angkaSessionComplete(childId, sessionId),
    );
    return res.data['data'] as Map<String, dynamic>;
  }
}
