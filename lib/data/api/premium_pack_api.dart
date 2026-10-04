import 'package:arunika_app/constants/api_paths.dart';
import 'package:arunika_app/network/dio_client.dart';
import 'package:dio/dio.dart';

class PremiumPackApi {
  final Dio dio;

  PremiumPackApi() : dio = DioClient.dio;

  /// Fetches active premium packages from GET /premium/packs.
  /// Pass [type] = 'content' or 'subscription' to filter.
  Future<List<dynamic>> fetchPacks({String? type}) async {
    final res = await dio.get(
      ApiPaths.premiumPacks,
      queryParameters: {if (type != null && type.isNotEmpty) 'type': type},
    );
    final data = res.data as Map<String, dynamic>;
    return data['data'] as List<dynamic>;
  }
}
