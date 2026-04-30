import 'package:arunika_app/constants/api_paths.dart';
import 'package:arunika_app/network/dio_client.dart';
import 'package:dio/dio.dart';

class NotificationApi {
  final Dio dio;
  NotificationApi() : dio = DioClient.dio;

  Future<Map<String, dynamic>> getNotifications() async {
    final res = await dio.get(ApiPaths.notifications);
    return res.data as Map<String, dynamic>;
  }

  Future<void> markRead(String id) async {
    await dio.patch('${ApiPaths.notifications}/$id/read');
  }

  Future<void> registerToken(String token) async {
    await dio.post(ApiPaths.notificationsToken, data: {'token': token});
  }
}
