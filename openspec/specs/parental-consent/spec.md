# parental-consent Specification

## Purpose
TBD - created by archiving change add-uu-pdp-parental-consent. Update Purpose after archive.
## Requirements
### Requirement: Signup requires explicit, separate parent/guardian consent
The child-data signup step SHALL show two separate checkboxes, both unticked by default and both required:
1. Agreement to the Syarat & Ketentuan and Kebijakan Privasi, each linked.
2. A declaration that the registrant is the child's parent or legal guardian, aged 18 or over, and consents to the processing of the child's personal data for the purposes stated in the Kebijakan Privasi.

The "Simpan" button SHALL be enabled only when both are ticked. The previous single "Dengan mendaftar, Kamu menyetujui …" checkbox SHALL be removed.

#### Scenario: Submit blocked until both boxes are ticked
- **WHEN** the registrant ticks only the T&C/Privacy checkbox
- **THEN** the "Simpan" button SHALL remain disabled

#### Scenario: Both boxes ticked enables submit
- **WHEN** the registrant ticks both checkboxes and the form is valid
- **THEN** the "Simpan" button SHALL be enabled

#### Scenario: Nothing pre-ticked
- **WHEN** the child-data step is first shown
- **THEN** both consent checkboxes SHALL be unticked

### Requirement: Consent is recorded as evidence on the backend
The backend SHALL have an append-only `user_consents` table (`id`, `user_id` FK → `users.id` ON DELETE CASCADE, `document` IN `TERMS`/`PRIVACY`/`PARENTAL`, `version`, `accepted_at`, `ip_address`, `user_agent`). `POST /auth/signup` SHALL accept an optional `consent` object (`terms_version`, `privacy_version`, `parental_version`). When the object is present, the backend SHALL insert one row per document in the same transaction as the user and child rows. A `consent` object missing any version SHALL be rejected with 400.

#### Scenario: Signup with consent records three rows
- **WHEN** a signup is submitted with all three consent versions
- **THEN** the user SHALL be created, and `user_consents` SHALL contain `TERMS`, `PRIVACY` and `PARENTAL` rows for that user with the submitted versions, the request IP and the user agent

#### Scenario: Incomplete consent rejected
- **WHEN** a signup is submitted with a `consent` object that lacks `parental_version`
- **THEN** the response SHALL be 400, and no user SHALL be created

#### Scenario: Legacy client without consent
- **WHEN** a signup is submitted with no `consent` object
- **THEN** the user SHALL be created with no consent rows, and their profile SHALL report `consent_required = true`

### Requirement: Outdated or missing consent triggers re-consent
The current version of each document SHALL be a single backend constant. The user profile response SHALL include `consent_required`, which is true when, for any document, the user's most recently accepted version is missing or differs from the current version. `POST /user/consent` (authenticated) SHALL accept the same shape as the signup `consent` object, append rows, and return the updated `consent_required`.

#### Scenario: Policy version bumped
- **WHEN** the current PRIVACY version changes from `2026-10-01` to `2027-01-15` and a user last accepted `2026-10-01`
- **THEN** that user's profile SHALL report `consent_required = true`

#### Scenario: Re-consent clears the flag
- **WHEN** that user calls `POST /user/consent` with all current versions
- **THEN** new rows SHALL be appended, previous rows SHALL be kept, and the response SHALL report `consent_required = false`

### Requirement: App blocks usage until re-consent
When a signed-in user's profile reports `consent_required = true`, the app SHALL route to a blocking consent screen before the main shell. The screen SHALL show the same two checkboxes and links as signup and SHALL have no back navigation. It SHALL offer "Keluar" (sign out) and "Hapus Akun" (the existing account-deletion flow) as alternatives to accepting.

#### Scenario: Existing user after a policy update
- **WHEN** a signed-in user whose consent is outdated opens the app
- **THEN** the consent screen SHALL be shown instead of the main shell

#### Scenario: Accepting continues to the app
- **WHEN** the user ticks both boxes and accepts, and `POST /user/consent` succeeds
- **THEN** the app SHALL navigate to the main shell

#### Scenario: Declining
- **WHEN** the user taps "Keluar" on the consent screen
- **THEN** the session SHALL be cleared and the user SHALL be returned to the landing screen

### Requirement: Legal documents cover UU PDP disclosures
The in-app Kebijakan Privasi SHALL, in Bahasa Indonesia, state:
- the controller identity and a privacy contact
- each category of parent and child data collected, with its purpose and legal basis
- that child data is processed only with parent/guardian consent and children cannot register themselves
- that data is not sold and children are not profiled for advertising
- the third-party processors used and any cross-border transfer
- the retention period and what happens on account deletion
- the data-subject rights under UU PDP (access, correction, deletion, withdrawal of consent, restriction, portability, objection) and how to exercise them
- breach notification within 3×24 hours
- how changes are notified

The Syarat & Ketentuan SHALL state that only a parent or legal guardian aged 18 or over may register. It SHALL describe in-app purchase and refund terms consistent with Google Play purchases, and it SHALL reference the Kebijakan Privasi. Each document SHALL display its version and effective date.

#### Scenario: Privacy policy lists data-subject rights
- **WHEN** a user opens Kebijakan Privasi from signup
- **THEN** the screen SHALL list the UU PDP data-subject rights, including withdrawal of consent and deletion, and how to exercise them

#### Scenario: Version is visible
- **WHEN** a user opens either legal document
- **THEN** the screen SHALL show the document's version and effective date, and they SHALL match the version the app sends when consent is given

