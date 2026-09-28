import 'package:arunika_app/network/dio_client.dart';
import 'package:dio/dio.dart';
import '../../config/app_config.dart';
import '../../constants/api_paths.dart';

class AuthApi {
  /// For the calls made before there is a session (sign-up, sign-in, ...):
  /// plain, and never sends a token.
  final Dio dio;

  /// For the calls that act as the signed-in user: it attaches their token
  /// and refreshes it when it has expired. Using [dio] for these sends no
  /// token, so the backend answers 401.
  final Dio authenticatedDio;

  AuthApi({Dio? dio, Dio? authenticatedDio})
    : dio = dio ?? Dio(BaseOptions(baseUrl: AppConfig.baseUrl)),
      authenticatedDio = authenticatedDio ?? DioClient.dio;

  Future<Map<String, dynamic>> signup(Map<String, dynamic> body) async {
    final res = await dio.post(ApiPaths.signup, data: body);
    return res.data;
  }

  Future<Map<String, dynamic>> checkAvailability({
    required String email,
    required String phone,
  }) async {
    final res = await dio.get(
      ApiPaths.checkAvailability,
      queryParameters: {'email': email, 'phone': phone},
    );
    return res.data;
  }

  Future<Map<String, dynamic>> signin(Map<String, dynamic> body) async {
    final res = await dio.post(ApiPaths.signin, data: body);
    return res.data;
  }

  Future<Map<String, dynamic>> forgotPassword(Map<String, dynamic> body) async {
    final res = await dio.post(ApiPaths.forgotPassword, data: body);
    return res.data;
  }

  /// Requests a fresh verification email for the signed-in user.
  /// The backend rate-limits this; a 429 surfaces as a DioException the
  /// caller distinguishes so the user is told to wait rather than shown a
  /// generic failure.
  Future<Map<String, dynamic>> resendVerification() async {
    final res = await authenticatedDio.post(ApiPaths.resendVerification);
    return res.data as Map<String, dynamic>;
  }
}
