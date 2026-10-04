## ADDED Requirements
### Requirement: Legal document versions are immutable files registered with a hash
Each version of the TERMS, PRIVACY and PARENTAL documents SHALL be published once as a static file on the landing site at `legal/<document>/<version>.html`, and SHALL NOT be edited afterwards. The backend SHALL have a `legal_documents` table (`document`, `version`, `url`, `sha256`, `effective_at`, primary key `(document, version)`), with rows added by migration. A document's current version SHALL be its highest version whose `effective_at` is not in the future. `user_consents (document, version)` SHALL reference `legal_documents`.

#### Scenario: Future version is not yet current
- **WHEN** a TERMS row `2027-01-15` with `effective_at` tomorrow exists next to `2026-10-01`
- **THEN** the current TERMS version SHALL be `2026-10-01` until that time, and `2027-01-15` afterwards, without a deploy

#### Scenario: Published file edited
- **WHEN** a version file's bytes no longer match the sha256 recorded when it was published
- **THEN** the landing `legal_check.sh` SHALL fail

### Requirement: Current legal documents are available from a public endpoint
`GET /legal/current` SHALL require no authentication and SHALL return, for each document, its current `version`, `url`, `sha256` and `effective_at`.

#### Scenario: Signup screen loads documents
- **WHEN** an unauthenticated client calls `GET /legal/current`
- **THEN** the response SHALL be 200 with one entry each for TERMS, PRIVACY and PARENTAL

### Requirement: App shows the fetched legal documents
The app SHALL NOT bundle legal document text or versions. The Syarat & Ketentuan and Kebijakan Privasi screens SHALL load the URL returned by `GET /legal/current` in a WebView with JavaScript disabled, and links to another host SHALL open in the external browser. The parental declaration checkbox label SHALL be the fetched PARENTAL text. The consent checkboxes and submit button SHALL stay disabled until the documents have loaded. On failure, the app SHALL show an error with retry.

#### Scenario: Text changed without an app release
- **WHEN** a new TERMS version becomes current
- **THEN** an installed app SHALL show the new text and send the new version, without an update

#### Scenario: Documents fail to load
- **WHEN** `GET /legal/current` fails on the signup child-data step
- **THEN** both checkboxes and "Simpan" SHALL be disabled, and a retry SHALL be offered

## MODIFIED Requirements
### Requirement: Consent is recorded as evidence on the backend
The backend SHALL have an append-only `user_consents` table:
- `id`
- `user_id`, FK → `parents.id`. Not cascading: account deletion removes the rows explicitly.
- `document`, one of `TERMS`/`PRIVACY`/`PARENTAL`
- `version`, where `(document, version)` is an FK → `legal_documents`
- `accepted_at`, `ip_address`, `user_agent`

`POST /auth/signup` SHALL accept an optional `consent` object (`terms_version`, `privacy_version`, `parental_version`). When the object is present, the backend SHALL insert one row per document in the same transaction as the user and child rows. The backend SHALL reject:
- a `consent` object missing any version, with 400
- a version not in `legal_documents`, with 400 `LEGAL_VERSION_UNKNOWN`
- a version that exists but is not current, with 409 `LEGAL_VERSION_OUTDATED`, whose message asks the user to reread or update the app

#### Scenario: Signup with consent records three rows
- **WHEN** a signup is submitted with all three current consent versions
- **THEN** the user SHALL be created, and `user_consents` SHALL contain `TERMS`, `PRIVACY` and `PARENTAL` rows for that user with the submitted versions, the request IP and the user agent

#### Scenario: Incomplete consent rejected
- **WHEN** a signup is submitted with a `consent` object that lacks `parental_version`
- **THEN** the response SHALL be 400, and no user SHALL be created

#### Scenario: Outdated version rejected
- **WHEN** a signup or `POST /user/consent` submits `terms_version = 2026-10-01` while the current TERMS version is `2027-01-15`
- **THEN** the response SHALL be 409 `LEGAL_VERSION_OUTDATED`, and no rows SHALL be written

#### Scenario: Unknown version rejected
- **WHEN** a consent payload contains a version that is not in `legal_documents`
- **THEN** the response SHALL be 400 `LEGAL_VERSION_UNKNOWN`

#### Scenario: Legacy client without consent
- **WHEN** a signup is submitted with no `consent` object
- **THEN** the user SHALL be created with no consent rows, and their profile SHALL report `consent_required = true`

### Requirement: Outdated or missing consent triggers re-consent
The current version of each document SHALL come from `legal_documents`, as defined in "Legal document versions are immutable files registered with a hash". The user profile response SHALL include `consent_required`, which is true when, for any document, the user's most recently accepted version is missing or differs from the current version. `POST /user/consent` (authenticated) SHALL accept the same shape as the signup `consent` object, apply the same version checks, append rows, and return the updated `consent_required`. When the app receives 409 `LEGAL_VERSION_OUTDATED`, it SHALL refetch the current documents, untick both checkboxes, and ask the user to read them again.

#### Scenario: Policy version bumped
- **WHEN** a PRIVACY row `2027-01-15` becomes effective and a user last accepted `2026-10-01`
- **THEN** that user's profile SHALL report `consent_required = true`

#### Scenario: Re-consent clears the flag
- **WHEN** that user calls `POST /user/consent` with all current versions
- **THEN** new rows SHALL be appended, previous rows SHALL be kept, and the response SHALL report `consent_required = false`

#### Scenario: Version becomes current while the consent screen is open
- **WHEN** the app submits versions that became outdated after it fetched them
- **THEN** the backend SHALL return 409, and the app SHALL show the new documents, with no loop back to the same screen

### Requirement: Legal documents cover UU PDP disclosures
The Kebijakan Privasi SHALL, in Bahasa Indonesia, state:
- the controller identity and a privacy contact
- each category of parent and child data collected, with its purpose and legal basis
- that child data is processed only with parent/guardian consent and children cannot register themselves
- that data is not sold and children are not profiled for advertising
- the third-party processors used and any cross-border transfer
- the retention period and what happens on account deletion
- the data-subject rights under UU PDP (access, correction, deletion, withdrawal of consent, restriction, portability, objection) and how to exercise them
- breach notification within 3×24 hours
- how changes are notified

The Syarat & Ketentuan SHALL state that only a parent or legal guardian aged 18 or over may register. It SHALL describe in-app purchase and refund terms consistent with Google Play purchases, and it SHALL reference the Kebijakan Privasi. Each document file SHALL display its version and effective date.

#### Scenario: Privacy policy lists data-subject rights
- **WHEN** a user opens Kebijakan Privasi from signup
- **THEN** the screen SHALL list the UU PDP data-subject rights, including withdrawal of consent and deletion, and how to exercise them

#### Scenario: Version is visible
- **WHEN** a user opens either legal document
- **THEN** the screen SHALL show the document's version and effective date, and they SHALL match the version returned by `GET /legal/current`, which is the version the app sends when consent is given

#### Scenario: No buy button on product cards
- **WHEN** the product section renders
- **THEN** no card SHALL contain a control that initiates a purchase or payment flow

#### Scenario: Get-the-app CTA remains the only action
- **WHEN** a visitor wants to obtain a package
- **THEN** the only actionable control available to them SHALL be the existing CTA directing them to install/open the app
