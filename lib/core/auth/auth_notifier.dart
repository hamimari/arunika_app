import 'package:arunika_app/core/storage/SecureStorageToken.dart';
import 'package:flutter/cupertino.dart';

class AuthNotifier extends ChangeNotifier {
  bool _loggedIn = false;
  bool _initialized = false;

  bool get isLoggedIn => _loggedIn;
  bool get initialized => _initialized;

  Future<void> checkAuth() async {
    final token = await SecureTokenStorage.getToken();
    _loggedIn = token != null && token.isNotEmpty;
    _initialized = true;
    notifyListeners();
  }

  Future<void> logout() async {
    await SecureTokenStorage.clear();
    _loggedIn = false;
    _initialized = true;
    notifyListeners();
  }
}
