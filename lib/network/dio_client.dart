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
  // Shared by all concurrent 401s so simultaneous requests await the same
  // refresh attempt instead of only the first one retrying while the rest
  // are dropped unhandled (the old `!_isRefreshing` guard silently let
  // concurrent 401s fall through to the caller with no recovery attempt).
  static Future<bool>? _refreshFuture;

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

    if (err.response?.statusCode == 401) {
      _refreshFuture ??= _refreshToken();
      final success = await _refreshFuture!;
      _refreshFuture = null;

      if (success) {
        try {
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
        } catch (_) {
          // fall through to handler.next(err) below
        }
      }
    }

    handler.next(err);
  }

  Future<bool> _refreshToken() async {
    final refreshToken = await SecureTokenStorage.getRefreshToken();
    if (refreshToken == null) {
      // No refresh token to work with — the session is genuinely gone.
      await authNotifier.logout();
      AppRouter.router.go('/landing');
      return false;
    }

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
        // Refresh token itself is invalid/expired — session is truly over.
        await authNotifier.logout();
        AppRouter.router.go('/landing');
      }
      // Any other error (network blip, server down) is treated as transient:
      // don't nuke the session, just let this request fail and retry later.
      return false;
    } catch (e) {
      return false;
    }
  }
}
