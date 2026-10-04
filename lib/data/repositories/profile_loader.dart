import 'package:arunika_app/core/auth/auth_notifier.dart';
import 'package:arunika_app/core/storage/LocalProfileStorage.dart';
import 'package:arunika_app/core/storage/SecureStorageToken.dart';
import 'package:arunika_app/data/models/response/subscription_info.dart';
import 'package:arunika_app/data/models/response/user_response.dart';
import 'package:arunika_app/data/repositories/user_repository.dart';

/// Loads the signed-in user's profile fresh from the backend (so
/// subscription state is current), falling back to the cached copy when the
/// network call fails. Returns null when logged out.
class ProfileLoader {
  final UserRepository _users;
  final AuthNotifier _auth;

  ProfileLoader(this._users, this._auth);

  Future<UserResponse?> load() async {
    if (!_auth.isLoggedIn) return null;
    final userId = await SecureTokenStorage.getUserId();
    var profile = await LocalProfileStorage.get();
    if (userId != null) {
      try {
        profile = await _users.findById(userId);
        await LocalProfileStorage.save(profile);
      } catch (_) {
        // keep the cached profile on failure
      }
    }
    return profile;
  }

  /// The user's active subscription, or null when they have none.
  Future<SubscriptionInfo?> activeSubscription() async {
    final profile = await load();
    if (profile == null || !profile.isSubscribed) return null;
    return profile.subscription ??
        const SubscriptionInfo(
          planName: 'Langganan Premium',
          status: 'premium',
        );
  }
}
