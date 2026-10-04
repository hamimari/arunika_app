## 1. Backend (`arunika-backend`)
- [x] 1.1 Add migration `V60__create_user_consents.sql` (table, CHECK on `document`, index on `(user_id, document, accepted_at DESC)`, FK to `parents`)
- [x] 1.2 Add `models.UserConsent` and a `ConsentService` with the `CurrentConsentVersions` constant, `Record(userID, versions, ip, ua)` and `IsRequired(userID)`
- [x] 1.3 Extend `SignUpRequest` with an optional `consent`. Insert consent rows in the signup transaction. Return 400 when `consent` is present but incomplete
- [x] 1.4 Add `POST /user/consent` (JWT) handler and route
- [x] 1.5 Add `consent_required` to the user profile response
- [x] 1.6 Make sure `DELETE /user/me` removes consent rows (deleted explicitly, since the parent row is anonymised rather than removed), and add a test
- [x] 1.7 Update `openapi.yaml` and the app's `test/contract/openapi.yaml`
- [x] 1.8 Unit tests: signup with, without and with incomplete consent; `IsRequired` with an outdated version; the consent endpoint

## 2. Legal text
- [x] 2.1 Draft new Kebijakan Privasi and Syarat & Ketentuan (Bahasa Indonesia) covering the design.md checklist, with version `2026-10-01`
- [ ] 2.2 Confirm the controller identity and privacy contact with the owner
- [ ] 2.3 Legal review sign-off (gate before release)

## 3. Flutter app
- [x] 3.1 Add a `LegalVersions` constant. Update `terms_and_condition_screen.dart` and `privacy_policy_screen.dart` with the new text and a version/effective-date line
- [x] 3.2 Replace the single T&C checkbox in `child_signup_screen.dart` with two required, unticked checkboxes (T&C + Privacy; parent/guardian declaration). "Simpan" is enabled only when both are ticked
- [x] 3.3 Update the signup bloc/event/state and the signup request model to send `consent`
- [x] 3.4 Add `consent_required` to the profile model. Add a `/consent` route and a blocking `ConsentScreen` (accept, sign out, delete account) plus the redirect from `/` and the shell
- [x] 3.5 Widget/bloc tests: button disabled until both boxes are ticked; the payload contains the versions; re-consent redirect and accept flow
- [x] 3.6 Update the integration test signup helper (`integration_test/helpers/signed_in_session.dart`) to tick both boxes

## 4. Landing (`arunika-landing`)
- [x] 4.1 Replace `privacy-policy.html` content with the same text and version as the app
- [x] 4.2 Add `terms.html` and link it from the footer and privacy page
- [x] 4.3 Check that the app and landing text match (same version string, section-by-section diff)

## 5. Validation
- [x] 5.1 `openspec validate add-uu-pdp-parental-consent --strict`
- [x] 5.2 Backend `go test ./...` (including real-Postgres tests) and app `flutter test`
- [ ] 5.3 Manual signup + re-consent run on a device
