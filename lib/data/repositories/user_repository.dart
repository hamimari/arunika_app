import 'package:arunika_app/data/api/user_api.dart';
import 'package:arunika_app/data/models/request/consent_request.dart';
import 'package:arunika_app/data/models/request/update_user_request.dart';
import 'package:arunika_app/data/models/response/user_response.dart';

class UserRepository {
  final UserApi api;

  UserRepository(this.api);

  Future<UserResponse> findById(String userId) async {
    final json = await api.findById(userId);
    return UserResponse.fromJson(json["data"]);
  }

  Future<UserResponse> update(UpdateUserRequest payload) async {
    final json = await api.update(payload.toJson());
    return UserResponse.fromJson(json["data"]);
  }

  /// Returns true if the backend still wants consent (e.g. a newer document
  /// version than the one this build sent).
  Future<bool> recordConsent(ConsentRequest consent) =>
      api.recordConsent(consent.toJson());

  Future<void> deleteAccount() => api.deleteAccount();
}