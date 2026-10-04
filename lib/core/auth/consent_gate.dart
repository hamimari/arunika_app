import 'package:arunika_app/core/storage/SecureStorageToken.dart';
import 'package:arunika_app/data/repositories/profile_loader.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:flutter/foundation.dart';

/// Decides whether a signed-in user has to see the consent screen before the
/// app: true when the backend reports `consent_required` on their profile
/// (a new legal document version, or an account made before consent existed).
///
/// It fails open. If the profile can't be loaded in time (offline, slow
/// network) the user is let through and asked next launch, rather than locked
/// out of content they may have paid for.
class ConsentGate {
  ConsentGate._();

  static const _timeout = Duration(seconds: 3);

  /// The user id that last passed the check, so navigating to the shell
  /// several times in one session loads the profile once. Keyed by user, so
  /// signing in as someone else is checked again.
  static String? _clearedFor;

  /// The route to send the user to, or null to carry on.
  static Future<String?> redirect() async {
    final userId = await SecureTokenStorage.getUserId();
    if (userId == null || userId == _clearedFor) return null;

    final profile = await locator<ProfileLoader>().load().timeout(
      _timeout,
      onTimeout: () => null,
    );
    if (profile == null) return null;
    if (profile.consentRequired) return '/consent';

    _clearedFor = userId;
    return null;
  }

  @visibleForTesting
  static void reset() => _clearedFor = null;

  /// Call once the user has consented, so the shell isn't redirected back.
  static Future<void> markAccepted() async {
    _clearedFor = await SecureTokenStorage.getUserId();
  }
}
