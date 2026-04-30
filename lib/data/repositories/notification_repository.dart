import 'package:arunika_app/data/api/notification_api.dart';
import 'package:arunika_app/data/models/response/app_notification.dart';

class NotificationRepository {
  final NotificationApi api;
  NotificationRepository(this.api);

  Future<List<AppNotification>> getNotifications() async {
    final json = await api.getNotifications();
    return AppNotification.fromJsonList(json['data'] as List<dynamic>);
  }

  Future<void> markRead(String id) => api.markRead(id);

  Future<void> registerToken(String token) => api.registerToken(token);
}
