import 'package:arunika_app/constants/api_paths.dart';
import 'package:arunika_app/network/dio_client.dart';
import 'package:dio/dio.dart';

/// The manifest response: `body` is null when the server answered 304.
class ManifestResponse {
  final Map<String, dynamic>? body;
  final String? etag;

  const ManifestResponse(this.body, this.etag);
}

/// `/learn/huruf/*` and `/children/:childId/huruf/progress`.
class HurufApi {
  final Dio dio;

  HurufApi({Dio? dio}) : dio = dio ?? DioClient.dio;

  Future<ManifestResponse> fetchManifest({String? etag}) async {
    final res = await dio.get(
      ApiPaths.hurufManifest,
      options: Options(
        headers: {if (etag != null) 'If-None-Match': etag},
        validateStatus: (s) => s != null && (s >= 200 && s < 300 || s == 304),
      ),
    );
    final tag = res.headers.value('etag');
    if (res.statusCode == 304) return ManifestResponse(null, tag ?? etag);
    return ManifestResponse(res.data['data'] as Map<String, dynamic>, tag);
  }

  Future<Map<String, dynamic>> fetchLetter(String id) async {
    final res = await dio.get(ApiPaths.hurufLetter(id));
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<List<dynamic>> fetchProgress(String childId) async {
    final res = await dio.get(ApiPaths.hurufProgress(childId));
    return res.data['data'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> saveProgress(
    String childId,
    String letterId,
    Map<String, dynamic> body,
  ) async {
    final res = await dio.put(
      ApiPaths.hurufLetterProgress(childId, letterId),
      data: body,
    );
    return res.data['data'] as Map<String, dynamic>;
  }
}
