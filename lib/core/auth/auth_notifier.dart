import 'package:arunika_app/core/storage/LocalProfileStorage.dart';
import 'package:arunika_app/core/storage/SecureStorageToken.dart';
import 'package:flutter/cupertino.dart';

class AuthNotifier extends ChangeNotifier {
  bool _loggedIn = false;

  bool get isLoggedIn => _loggedIn;

  Future<void> checkAuth() async {
    final token = await SecureTokenStorage.getToken();
    _loggedIn = token != null && token.isNotEmpty;
    notifyListeners();
  }

  Future<void> logout() async {
    await SecureTokenStorage.clear();
    await LocalProfileStorage.clear(); // clear cached profile so UI resets immediately
    _loggedIn = false;
    notifyListeners();
  }
}
