## ADDED Requirements

### Requirement: Personal data stored only in secure storage
The app SHALL store authentication tokens and any cached personal data (parent name, phone, email, address, and child records) only via `flutter_secure_storage`, and SHALL NOT write such data to `SharedPreferences`. Non-personal data such as feature flags MAY remain in `SharedPreferences`.

#### Scenario: Profile is cached securely
- **WHEN** the user profile is fetched and cached
- **THEN** it is written to secure storage and no `SharedPreferences` key contains it

#### Scenario: Legacy plaintext cache is migrated once
- **WHEN** a user upgrades from a version that cached the profile in `SharedPreferences` and the profile is next read
- **THEN** the profile is copied into secure storage and the legacy `SharedPreferences` key is deleted

#### Scenario: Logout clears both locations
- **WHEN** the user logs out
- **THEN** the cached profile is removed from secure storage and any legacy `SharedPreferences` copy is also removed
