## ADDED Requirements

### Requirement: Belajar Angka flag
The backend SHALL seed an `app_feature_flags` row `belajar_angka`, named "Belajar Angka", described "Angka card on Belajar and Beranda.", with `is_enabled = false`.

The app SHALL treat `belajar_angka` as fail-closed. When it is off, the app SHALL hide the Angka card on the Belajar hub and the Angka card in the Beranda "Lanjutkan belajar" row.

#### Scenario: Fresh database
- **WHEN** migrations run on an empty database
- **THEN** `GET /app/feature-flags` includes `belajar_angka: false`

#### Scenario: Flags not yet fetched
- **WHEN** the app starts offline with no cached flags
- **THEN** the Belajar hub shows no Angka card
