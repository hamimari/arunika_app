# Change: Add UU PDP-compliant parental consent to registration

## Why
Signup collects personal data about a parent (name, phone, email, city, full address) and a child (name, birth date, gender). Under UU No. 27/2022 on Pelindungan Data Pribadi (UU PDP), a child's personal data needs **consent from the parent or guardian** (Art. 25). Consent must also be **explicit, informed and specific to its purpose** (Art. 20–22), and the controller must be able to **prove that it was given** (Art. 24).

Today the app falls short in three ways:
- It shows one combined line, "Dengan mendaftar, Kamu menyetujui …", with a single checkbox.
- The backend keeps no record of consent.
- The T&C and Privacy Policy text leave out the disclosures UU PDP requires: legal basis, retention, data-subject rights, cross-border transfer, breach notification and a contact point.

## What Changes
- **Legal text:** rewrite the in-app Syarat & Ketentuan and Kebijakan Privasi to cover the UU PDP disclosures, each with a version identifier. Mirror the same text on the public landing site (`arunika-landing`), which is the privacy policy URL registered in Google Play.
- **Explicit consent at signup:** replace the single combined checkbox on the child-data step with two required checkboxes. Neither is pre-ticked.
  1. Agreement to the T&C and Privacy Policy.
  2. A parent/guardian declaration: the person registering is the child's parent or legal guardian, aged 18 or over, and consents to the processing of the child's data for the stated purposes.
- **Consent record (backend):** `POST /auth/signup` accepts a `consent` object. The backend stores one row per accepted document in a new `user_consents` table, holding the document, version, acceptance time, IP and user agent. The current document versions are a single backend constant.
- **Re-consent for existing users:** the user profile reports `consent_required` when the user's latest accepted versions are older than the current ones. The app then shows a blocking re-consent screen after launch, backed by a new `POST /user/consent` endpoint. Declining offers sign-out or account deletion, since withdrawing consent means data can no longer be processed.
- **Account deletion:** consent rows are deleted with the account, which extends the existing `DELETE /user/me`.

Data minimisation (dropping the full address, making gender optional, reducing the birth date to month and year) is **out of scope** for this change and can follow separately.

## Impact
- Affected specs:
  - `parental-consent`: new capability.
  - `landing-page`: the privacy policy requirement is modified, and a Terms page is added.
- Affected code:
  - App: `lib/presentation/screens/signup/{child_signup_screen,terms_and_condition_screen,privacy_policy_screen,signup_bloc,signup_event,signup_state}.dart`, the signup repository/model, `app_router.dart` (re-consent redirect), and a new re-consent screen.
  - Backend (`arunika-backend`): new migration `V60__create_user_consents.sql`, `handlers/auth_handler.go` (`SignUpRequest.Consent`), `services/user_service.go` (profile `consent_required`, account deletion), a new `POST /user/consent` route and handler, and `openapi.yaml`.
  - Landing (`arunika-landing`): `privacy-policy.html` and a new `terms.html`.
- Not a breaking change for older app builds: a signup without `consent` still succeeds, but the account is flagged `consent_required` (see design.md).
- The legal wording should be reviewed by a qualified Indonesian legal advisor before release. This proposal defines the required *coverage*, not final legal language.
