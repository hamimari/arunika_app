## ADDED Requirements

### Requirement: Alternative billing is off unless explicitly enabled
The backend SHALL seed an `alternative_billing` feature flag with `is_enabled = false`. The app SHALL treat `alternative_billing` as off whenever its value is unknown: missing from the response, not yet fetched, or the backend unreachable. This is the opposite of the fail-open rule for other flags, because failing open would re-open a payment path that Google Play and App Store rules restrict.

#### Scenario: Flag missing on first launch
- **WHEN** the app has no cached flags and `GET /app/feature-flags` fails
- **THEN** `alternative_billing` SHALL be treated as off, while other flags remain enabled

#### Scenario: Admin enables alternative billing
- **WHEN** an admin turns on "Midtrans (alternative billing)" on the App Features page
- **THEN** `GET /app/feature-flags` SHALL return `alternative_billing: true`
