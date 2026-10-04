import 'package:arunika_app/core/legal/legal_versions.dart';

/// The legal document versions a parent was shown when they gave consent.
/// Sent with signup, and on its own when an existing user consents again.
class ConsentRequest {
  final String termsVersion;
  final String privacyVersion;
  final String parentalVersion;

  const ConsentRequest({
    required this.termsVersion,
    required this.privacyVersion,
    required this.parentalVersion,
  });

  /// The versions this build of the app displays.
  const ConsentRequest.current()
    : termsVersion = LegalVersions.terms,
      privacyVersion = LegalVersions.privacy,
      parentalVersion = LegalVersions.parental;

  Map<String, dynamic> toJson() => {
    'terms_version': termsVersion,
    'privacy_version': privacyVersion,
    'parental_version': parentalVersion,
  };
}
