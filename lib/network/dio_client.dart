import 'package:arunika_app/constants/api_paths.dart';
import 'package:arunika_app/core/storage/SecureStorageToken.dart';
import 'package:arunika_app/presentation/navigation/app_router.dart';
import 'package:dio/dio.dart';
import '../config/app_config.dart';

class DioClient {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      headers: {'Content-Type': 'application/json'},
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      validateStatus: (status) => status != null && status < 400,
    ),
  )..interceptors.add(AuthInterceptor());
}

class RefreshDio {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      headers: {'Content-Type': 'application/json'},
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      validateStatus: (status) => status != null && status < 400,
    ),
  );
}

class AuthInterceptor extends InterceptorsWrapper {
  static bool _isRefreshing = false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await SecureTokenStorage.getToken();
    if (token?.isNotEmpty == true) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
      DioException err,
      ErrorInterceptorHandler handler,
      ) async {
    if (err.requestOptions.extra['isRefresh'] == true) {
      return handler.next(err);
    }

    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;

      final success = await _refreshToken();
      _isRefreshing = false;

      if (success) {
        final token = await SecureTokenStorage.getToken();

        final response = await DioClient.dio.request(
          err.requestOptions.path,
          data: err.requestOptions.data,
          queryParameters: err.requestOptions.queryParameters,
          options: Options(
            method: err.requestOptions.method,
            headers: {
              ...err.requestOptions.headers,
              'Authorization': 'Bearer $token',
            },
          ),
        );

        return handler.resolve(response);
      }
    }

    handler.next(err);
  }

  Future<bool> _refreshToken() async {
    final refreshToken = await SecureTokenStorage.getRefreshToken();
    if (refreshToken == null) return false;

    try {
      final res = await RefreshDio.dio.post(
        ApiPaths.refreshToken,
        data: {'refresh_token': refreshToken},
        options: Options(extra: {'isRefresh': true}),
      );

      final newToken = res.data['token'];
      final newRefreshToken = res.data['refresh_token'];

      await SecureTokenStorage.saveToken(newToken);
      await SecureTokenStorage.saveRefreshToken(newRefreshToken);
      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await authNotifier.logout();
      }
      return false;
    } catch (e) {
      await SecureTokenStorage.clear();
      return false;
    }
  }

}
