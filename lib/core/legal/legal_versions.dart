/// Versions of the legal documents shown in the app. They must match the
/// backend's `CurrentConsentVersions` (services/consent_service.go) and the
/// landing site pages: the app sends these when a parent gives consent, and
/// the backend asks for consent again whenever its current version differs.
class LegalVersions {
  LegalVersions._();

  static const String terms = '2026-10-01';
  static const String privacy = '2026-10-01';
  static const String parental = '2026-10-01';

  /// Effective date shown on the documents, in Indonesian.
  static const String effectiveDate = '1 Oktober 2026';
}
