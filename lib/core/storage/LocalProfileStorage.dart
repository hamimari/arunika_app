
import 'dart:convert';

import 'package:arunika_app/data/models/response/user_response.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalProfileStorage {
  static const _key = 'user_profile';

  static Future<void> save(UserResponse profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(profile.toJson()));
  }

  static Future<UserResponse?> get() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    return UserResponse.fromJson(jsonDecode(raw));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}