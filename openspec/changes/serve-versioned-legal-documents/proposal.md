## Why
The Syarat & Ketentuan and Kebijakan Privasi text exists in two hand-synced copies: Dart string constants in the app (`terms_and_condition_screen.dart`, `privacy_policy_screen.dart`) and the landing pages (`terms.html`, `privacy-policy.html`). The version exists in two more places (`legal_versions.dart` and the backend's `CurrentConsentVersions` map). `user_consents` records which version a parent accepted, but nothing stored alongside it proves what that version said. As a result:

- **Evidence gap (UU PDP Art. 24):** "accepted 2026-10-01" can only be resolved to text through git history of two repos, not from a record the backend owns.
- **Drift:** the app and web copies can silently differ, even though the `landing-page` spec requires them to match.
- **Re-consent loop on old builds:** changing the text requires an app release. A build still in users' hands keeps showing its bundled text and sending its bundled version. The backend stores that version, and still reports `consent_required = true` because it differs from the current one. The user is sent back to the consent screen after every accept, with no way out except updating the app. There is no force-update mechanism.

## What Changes
- **Versioned, immutable files as the source of truth.** Each legal document version is published once on the landing site at `legal/<document>/<version>.html` and is never edited afterwards. `terms.html` and `privacy-policy.html` remain the current, human-facing pages (the Play Console privacy URL does not change), and a check script verifies they match the latest version file.
- **Backend `legal_documents` table** (`document`, `version`, `url`, `sha256`, `effective_at`). Rows are added by a Flyway migration per published version. The current version of a document is its latest row with `effective_at <= now()`. This replaces the `CurrentConsentVersions` map. `user_consents (document, version)` gets a foreign key to it, so a consent can only reference a version whose text and hash are on record.
- **New public endpoint `GET /legal/current`** returns the current version, URL, sha256 and effective date of each document. It needs no auth, because signup uses it.
- **App shows fetched documents.** The Terms and Privacy screens load the URL from `/legal/current` in a locked-down WebView. The parental declaration label is fetched the same way, and the app sends the versions it received. `legal_versions.dart` and the hardcoded document text are removed.
- **Stale-version handling:** `POST /user/consent` and signup reject a version that is not current with `409 LEGAL_VERSION_OUTDATED`. The app then refetches `/legal/current` and shows the new text instead of looping. Builds that predate this change get a 409 with a readable "perbarui aplikasi" message rather than a silent loop.
- **BREAKING (API):** consent versions not present in `legal_documents` are rejected with 400, and outdated ones with 409. No build has been released yet, so no deployed client is affected.

## Timing
If this ships **before the first public release**, no released build ever carries hardcoded legal text. If it ships later, every build released until then keeps the old behaviour. Those users then need the 409 message to reach them when the T&C first change. Recommended: ship with, or immediately after, the first release, and in any case before the first text change.

## Impact
- Affected specs: `parental-consent` (MODIFIED, ADDED), `landing-page` (MODIFIED)
- Affected code:
  - `arunika-backend`: new migration `V62__create_legal_documents.sql` (table, the `2026-10-01` rows, FK on `user_consents`); `models/legal_document.go`; `services/consent_service.go` (current versions from DB, 409 for outdated); new `handlers/legal_handler.go` plus a route in `routes/router.go`; tests in `tests/db`, `services`, `handlers`, and the API contract tests
  - `arunika-landing`: `legal/terms/2026-10-01.html`, `legal/privacy/2026-10-01.html`, `legal/parental/2026-10-01.html`; `scripts/legal_publish.sh` (copy the current page to its version file, print sha256 and a migration stub); `scripts/legal_check.sh` (current pages match their latest version files; version files are unchanged since publish)
  - `arunika_app`: remove `lib/core/legal/legal_versions.dart` and the text in `terms_and_condition_screen.dart` and `privacy_policy_screen.dart`; add `LegalRepository` (`GET /legal/current`), a `LegalDocumentScreen` (WebView), and changes to `consent_checkboxes.dart`, `signup_bloc.dart`, `consent_screen.dart`, `consent_request.dart` and `app_router.dart`; update tests
- Out of scope: backoffice UI for publishing versions (migrations are reviewed in git, which suits a legal change), English translations, and a general force-update mechanism.
