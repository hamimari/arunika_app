import 'package:arunika_app/constants/api_paths.dart';
import 'package:arunika_app/network/dio_client.dart';
import 'package:dio/dio.dart';

class NotificationApi {
  final Dio dio;

  NotificationApi() : dio = DioClient.dio;

  /// Links this device's FCM token to the logged-in user (POST /notifications/token).
  Future<void> registerToken(String token) async {
    await dio.post(ApiPaths.notificationToken, data: {'token': token});
  }
}
