import 'package:arunika_app/constants/api_paths.dart';
import 'package:arunika_app/core/storage/SecureStorageToken.dart';
import 'package:dio/dio.dart';
import '../config/app_config.dart';

class DioClient {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      headers: {'Content-Type': 'application/json'},
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  )..interceptors.add(AuthInterceptor());
}

class AuthInterceptor extends InterceptorsWrapper {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await SecureTokenStorage.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final success = await _refreshToken();
      if (success) {
        final req = err.requestOptions;
        final newToken = await SecureTokenStorage.getToken();

        req.headers['Authorization'] = 'Bearer $newToken';

        final response = await DioClient.dio.fetch(req);
        return handler.resolve(response);
      }
    }

    super.onError(err, handler);
  }

  Future<bool> _refreshToken() async {
    final refreshToken = await SecureTokenStorage.getRefreshToken();
    if (refreshToken == null) return false;

    try {
      final res = await Dio().post(
        AppConfig.baseUrl + ApiPaths.refreshToken,
        data: {'refresh_token': refreshToken},
      );

      final newToken = res.data['token'];
      final newRefreshToken = res.data['refresh_token'];

      await SecureTokenStorage.saveToken(newToken);
      await SecureTokenStorage.saveRefreshToken(newRefreshToken);
      return true;
    } catch (_) {
      await SecureTokenStorage.clear();
      return false;
    }
  }
}
