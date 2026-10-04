## ADDED Requirements

### Requirement: Backoffice-controlled feature flags
The backend SHALL store app feature flags in `app_feature_flags` keyed by a stable string, seeded with `printable_cards` and `qr_scan` enabled. `GET /app/feature-flags` SHALL be public and return `{"data": {"<key>": <bool>}}`. Admins SHALL list flags via `GET /admin/feature-flags` and change one via `PATCH /admin/feature-flags/:key` with `{"is_enabled": <bool>}`; an unknown key SHALL return 404 and a missing `is_enabled` SHALL return 400.

#### Scenario: Admin hides QR scanning
- **WHEN** an admin turns off the "Scan QR Kartu AR" switch on the App Features page
- **THEN** `PATCH /admin/feature-flags/qr_scan` is sent with `is_enabled: false` and `GET /app/feature-flags` returns `qr_scan: false`

#### Scenario: Unknown flag
- **WHEN** an admin calls `PATCH /admin/feature-flags/does_not_exist`
- **THEN** the server responds 404

### Requirement: App applies feature flags without flicker
The app SHALL apply the last cached flags before the first frame, refresh them from the backend on launch, on returning to the foreground, and on home pull-to-refresh, and SHALL treat unknown flags or an unreachable backend as enabled.

#### Scenario: Backend unreachable on first launch
- **WHEN** the app has no cached flags and `GET /app/feature-flags` fails
- **THEN** the Scan tab and printable-cards section are shown

#### Scenario: Flag changed while app in background
- **WHEN** QR scanning is disabled while the app is backgrounded and the user returns to it
- **THEN** the flags are refreshed and the Scan tab disappears without restarting the app

### Requirement: Hidden QR scan keeps navigation proportional
When `qr_scan` is disabled the app SHALL remove the Scan tab from the bottom navigation, evenly spacing the remaining tabs, keep every remaining tab opening its own screen, return to Home if Scan was the open tab, redirect `/ar-scan` to the shell, stop the fallback hero banner from linking to Scan, and hide the animal-detail "Scan di AR" button.

#### Scenario: Scan tab was open
- **WHEN** the user is on the Scan tab and `qr_scan` becomes disabled
- **THEN** the camera screen is removed, Home is shown, and tapping "Kartu AR" opens the collection

### Requirement: Hidden printable cards
When `printable_cards` is disabled the home screen SHALL omit the "Kartu Printable" section with no leftover gap.

#### Scenario: Printable cards hidden
- **WHEN** `printable_cards` is disabled
- **THEN** the home screen shows no "Kartu Printable" card and the list ends with the standard bottom spacing
