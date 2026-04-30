import 'package:arunika_app/data/api/user_api.dart';
import 'package:arunika_app/data/models/request/update_user_request.dart';
import 'package:arunika_app/data/models/response/user_response.dart';

class UserRepository {
  final UserApi api;

  UserRepository(this.api);

  Future<UserResponse> findById(String userId) async {
    final json = await api.findById(userId);
    // Backend returns { "data": {...}, "subscription_status": "free"|"premium" }
    final userData = Map<String, dynamic>.from(json['data'] as Map);
    userData['subscription_status'] = json['subscription_status'] ?? 'free';
    return UserResponse.fromJson(userData);
  }

  Future<UserResponse> update(UpdateUserRequest payload) async {
    final json = await api.update(payload.toJson());
    return UserResponse.fromJson(json["data"]);
  }
}
