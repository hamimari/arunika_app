## ADDED Requirements

### Requirement: Belajar Huruf flag
The backend SHALL seed an `app_feature_flags` row `belajar_huruf`, named "Belajar Huruf", described "Huruf card on Belajar and Beranda.", with `is_enabled = false`.

The app SHALL treat `belajar_huruf` as fail-closed: it is off when the flag is missing, unknown or not yet fetched. When the flag is off, the app SHALL hide the Huruf card on the Belajar hub and the Huruf entry in the Beranda "Lanjutkan belajar" row.

#### Scenario: Fresh database
- **WHEN** migrations run on an empty database
- **THEN** `GET /app/feature-flags` includes `belajar_huruf: false`

#### Scenario: Flags not yet fetched
- **WHEN** the app starts offline with no cached flags
- **THEN** the Belajar hub shows no Huruf card

#### Scenario: Flag turned on
- **WHEN** an admin enables "Belajar Huruf" on App Features and the app refreshes its flags
- **THEN** the Huruf card appears on the Belajar hub
