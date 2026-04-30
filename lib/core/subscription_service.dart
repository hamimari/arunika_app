import 'package:arunika_app/core/storage/LocalProfileStorage.dart';

/// Lightweight helper to check subscription status from local cache.
/// Always prefer reading from cached profile so there's no extra network call.
class SubscriptionService {
  SubscriptionService._();

  /// Returns true if the locally-cached user has `subscriptionStatus == 'premium'`.
  static Future<bool> isPremium() async {
    final user = await LocalProfileStorage.get();
    return user?.isPremium ?? false;
  }
}
