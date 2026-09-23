import 'package:dio/dio.dart';
import '../../config/app_config.dart';
import '../../constants/api_paths.dart';

class AuthApi {
  final Dio dio;

  AuthApi() : dio = Dio(BaseOptions(baseUrl: AppConfig.baseUrl));

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
    final res = await dio.post(ApiPaths.resendVerification);
    return res.data as Map<String, dynamic>;
  }
}
