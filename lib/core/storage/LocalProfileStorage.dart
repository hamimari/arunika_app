// ignore_for_file: file_names

import 'dart:convert';

import 'package:arunika_app/data/models/response/user_response.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Caches the signed-in user's profile. It holds personal data (name, phone,
/// email, address, children), so it lives in secure storage, not
/// SharedPreferences.
class LocalProfileStorage {
  static const _key = 'user_profile';

  static const _storage = FlutterSecureStorage();

  static Future<void> save(UserResponse profile) async {
    await _storage.write(key: _key, value: jsonEncode(profile.toJson()));
  }

  static Future<UserResponse?> get() async {
    final raw = await _storage.read(key: _key) ?? await _migrateLegacy();
    if (raw == null) return null;
    return UserResponse.fromJson(jsonDecode(raw));
  }

  static Future<void> clear() async {
    await _storage.delete(key: _key);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  /// Versions before secure storage cached the profile in plaintext
  /// SharedPreferences. Moves that copy across once and deletes it.
  static Future<String?> _migrateLegacy() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    await _storage.write(key: _key, value: raw);
    await prefs.remove(_key);
    return raw;
  }
}
