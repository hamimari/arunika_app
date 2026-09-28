# Design: UU PDP parental consent

## Context
The change spans three repos: the Flutter app (`arunika_app`), the Go backend (`arunika-backend`) and the static landing site (`arunika-landing`). The legal text is hardcoded in two Flutter screens and one HTML page. There is no consent persistence.

## Goals / Non-Goals
- Goals:
  - Consent that is explicit, specific and provable (UU PDP Art. 20–25).
  - Legal text that covers the Art. 21 disclosures.
  - Existing users re-accept when the text changes.
- Non-Goals:
  - Data minimisation of signup fields.
  - A CMS for legal text.
  - Per-purpose granular consent toggles, such as marketing push. Promo push notifications keep using the OS notification permission.
  - Guaranteeing legal sufficiency. The final wording needs legal review.

## Decisions

### Consent storage: append-only `user_consents` table
```
user_consents (
  id UUID PK,
  user_id UUID NOT NULL REFERENCES parents(id),
  document VARCHAR NOT NULL CHECK (document IN ('TERMS','PRIVACY','PARENTAL')),
  version VARCHAR NOT NULL,          -- e.g. '2026-10-01'
  accepted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  ip_address VARCHAR NULL,
  user_agent VARCHAR NULL
)
INDEX (user_id, document, accepted_at DESC)
```
- The table is append-only, so the full history of what was accepted and when is kept as evidence (Art. 24). A column on `users` would be overwritten.
- The parent table is `parents`, and account deletion **anonymises** that row instead of removing it, so an `ON DELETE CASCADE` would never fire. `AccountDeletionService` deletes the user's consent rows explicitly. They hold the IP and user agent, so they are personal data and go with the account.
- `PARENTAL` is recorded as its own document. The parent/guardian declaration is the Art. 25 basis for processing child data, and it is distinct from agreeing to the T&C.
- Alternative considered: a JSON column on `users`. Rejected because it loses history and is harder to query.

### Current versions are a backend constant
`services.CurrentConsentVersions = {TERMS: "2026-10-01", PRIVACY: "2026-10-01", PARENTAL: "2026-10-01"}`. The app hardcodes the version shown on each legal screen (`LegalVersions`) and sends it back on acceptance. If the backend still reports `consent_required` after the app sends its versions (the app is older than the backend), the consent screen tells the user to update the app instead of looping. The backend stores the version the client sent. If the sent version is older than the current one, `consent_required` stays true and the app prompts again immediately. This keeps the evidence truthful: we record what was actually shown.

### Consent rows are inserted with the parent
`models.Parent` has a `Consents` association (`json:"-"`), so GORM inserts the rows in the same transaction as the parent and children, with no separate service call and no half-recorded account. The rows are built before the parent has an id and GORM fills `user_id` in; a real-Postgres test covers this.

### Signup contract (backward compatible)
`POST /auth/signup` gains an optional field:
```json
"consent": { "terms_version": "2026-10-01", "privacy_version": "2026-10-01", "parental_version": "2026-10-01" }
```
- Present and complete: insert three `user_consents` rows in the same transaction as the user and child rows.
- Absent: the signup still succeeds, so released app builds don't break. The user has no consent rows, which makes `consent_required = true`. Updated app builds will then prompt on next launch.
- Present but incomplete: `400`.

Trade-off: older builds can create unconsented accounts until users update. This is acceptable because the new build blocks usage until consent is given. A later change can enforce a minimum app version.

### Re-consent flow
- The profile response gains `"consent_required": bool`. It is true when any document's latest accepted version is missing or differs from the current constant.
- `POST /user/consent` (JWT) takes the same body shape as the signup `consent` field and returns the updated `consent_required`.
- App: a redirect on the `/shell` route (`ConsentGate`) checks `consent_required` on the profile. Sign-in goes straight to `/shell`, so a check only on `/` would have skipped users who sign in. When it is true, the app routes to `/consent`, a blocking screen with the same two checkboxes and links. The gate fails open if the profile can't be loaded within 3 seconds (offline), so a user is not locked out of paid content, and remembers a pass per user for the session so the profile isn't reloaded on every navigation. The screen has no back navigation. Its secondary actions are "Keluar" (sign out) and "Hapus Akun" (the existing deletion flow).

### Where the legal text lives
The legal text stays hardcoded in the Flutter screens and the landing HTML, which is the minimal option. Each document shows "Versi: 2026-10-01 · Berlaku sejak 1 Oktober 2026". A shared Dart constant `LegalVersions` holds the versions the app sends.

### Required legal content (coverage checklist)
Privacy Policy (UU PDP Art. 21, 25, 46, 56; rights in Art. 5–13):
- Controller identity and contact, with a privacy contact email.
- Data collected: the parent fields, the child fields, device and usage data, and purchase data.
- The purpose of each field and its legal basis. Consent is the basis for child data, and performance of the contract is the basis for account and purchases.
- A statement that child data is processed only with parent/guardian consent and that children cannot register themselves.
- No sale of data, no advertising profiling of children, and no automated decisions with legal effect.
- Processors and recipients: Google (Firebase, Crashlytics, Cloud Messaging, Play Billing) and Midtrans. Disclose cross-border transfer and the safeguards used.
- Retention period while the account is active, and deletion or anonymisation after account deletion. Accounting records are retained anonymised, as in the `account-deletion` spec.
- Data-subject rights: information, access and copy, correction, deletion, withdrawal of consent, restriction of processing, portability, objection, and complaint to the authority. Explain how to exercise them (in-app "Hapus Akun", the landing deletion page, email) and the response time.
- Breach notification to users and the authority within 3×24 hours.
- Security measures, how changes are notified (re-consent), and the version and effective date.

T&C:
- Registration only by a parent or legal guardian aged 18 or over.
- Accountability for the child's use.
- Purchases through Google Play follow Google Play's refund policy, plus the admin refund path. This replaces the physical-flashcard clause.
- A reference to the Privacy Policy, the version and effective date, and governing law.

## Risks / Trade-offs
- Legal wording risk: the checklist reduces omissions but does not replace legal review. Tasks include a review gate.
- Hardcoded text drifts between the app and landing: mitigated by a single version string and a task to diff the two.
- The blocking re-consent screen interrupts existing users once. This is acceptable and expected by the regulation.

## Migration Plan
1. Deploy the backend migration and endpoints. They are backward compatible.
2. Publish the landing pages.
3. Release the app build. Existing users see re-consent on their next launch.
Rollback: the app can be rolled back independently. The backend fields are additive.

## Open Questions
- The controller's legal entity name and address, and the privacy contact (currently `arunika.helpdesk@gmail.com`), need confirmation before release.
