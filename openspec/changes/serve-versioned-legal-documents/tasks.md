## 1. Landing (arunika-landing)
- [ ] 1.1 Add `legal/terms/2026-10-01.html`, `legal/privacy/2026-10-01.html` and `legal/parental/2026-10-01.html`. The first two are exact copies of the current `terms.html` and `privacy-policy.html` bodies. The third holds the declaration sentence now in `consent_checkboxes.dart`. Before copying, diff the app text against the web text and resolve any differences.
- [ ] 1.2 `scripts/legal_publish.sh <document> <version>`: copies the current page to its version file, adds its sha256 to `legal/manifest.json`, and prints the `INSERT INTO legal_documents` line for the backend migration
- [ ] 1.3 `scripts/legal_check.sh`: every manifest entry's file hash matches, and `terms.html` and `privacy-policy.html` match the latest version file of their document. Wire it into `scripts/prerelease_check.sh` and the landing CI.
- [ ] 1.4 Deploy, and confirm that the three version URLs are served publicly

## 2. Backend (arunika-backend)
- [ ] 2.1 Migration `V62__create_legal_documents.sql`: create the table, seed the three `2026-10-01` rows (URL and sha256 from 1.2), and add the FK from `user_consents (document, version)`
- [ ] 2.2 `models/legal_document.go`, plus a `LegalService.Current()` that returns the latest effective row per document
- [ ] 2.3 `ConsentService`: replace `CurrentConsentVersions` with `LegalService.Current()` in `IsRequired`; validate input versions: unknown → 400 `LEGAL_VERSION_UNKNOWN`, not current → 409 `LEGAL_VERSION_OUTDATED`. Apply this to both signup and `POST /user/consent`.
- [ ] 2.4 `GET /legal/current` (public, rate-limited like other public routes) returns `{documents: [{document, version, url, sha256, effective_at}]}`
- [ ] 2.5 Tests:
  - DB: a future `effective_at` is not current; the FK rejects an unknown version
  - Service: 409 and 400 paths; a version bump makes `consent_required` true
  - Handler and contract: `/legal/current` shape
  - e2e: signup with the current versions still passes
- [ ] 2.6 `go test ./...` and `make prerelease` are green

## 3. App (arunika_app)
- [ ] 3.1 `LegalRepository` + `LegalDocuments` model for `GET /legal/current`, cached in memory for the session
- [ ] 3.2 `LegalDocumentScreen(document)`: a WebView on the fetched URL with JS disabled, same-host navigation only (other links go to `url_launcher`), and the full-page error view with retry. Point the `/terms` and `/privacy` routes at it.
- [ ] 3.3 `ConsentCheckboxes`: the declaration label comes from the fetched PARENTAL text. Both checkboxes and the submit button stay disabled until the documents have loaded.
- [ ] 3.4 Signup and `ConsentScreen` send the fetched versions. On 409 `LEGAL_VERSION_OUTDATED`, refetch, untick the boxes, and show "Dokumen telah diperbarui, silakan baca kembali".
- [ ] 3.5 Delete `lib/core/legal/legal_versions.dart` and the hardcoded text in `terms_and_condition_screen.dart` and `privacy_policy_screen.dart`
- [ ] 3.6 Tests:
  - Unit: the repository, and 409 handling in the signup and consent blocs
  - Widget: the checkboxes stay disabled while loading, and the declaration label is the fetched text
  - Integration: signup against the e2e stack records the fetched versions
- [ ] 3.7 `flutter analyze`, `flutter test` and `make prerelease` are green

## 4. Rollout check
- [ ] 4.1 On the e2e stack: add a `2099-01-01` TERMS row. Confirm that an existing user gets the consent screen, sees the new text, accepts once, and reaches home with no loop. Then remove the row.
- [ ] 4.2 Update `docs/prerelease-triage.md` (evidence gap closed)
