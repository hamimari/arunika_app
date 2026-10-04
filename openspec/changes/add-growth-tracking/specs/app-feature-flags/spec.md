## MODIFIED Requirements

### Requirement: App applies feature flags without flicker
The app SHALL apply the last cached flags before the first frame, refresh them from the backend on launch, on returning to the foreground, and on home pull-to-refresh, and SHALL treat unknown flags or an unreachable backend as enabled, except the fail-closed flags `alternative_billing` and `growth_tracking`.

#### Scenario: Backend unreachable on first launch
- **WHEN** the app has no cached flags and `GET /app/feature-flags` fails
- **THEN** the Kartu AR scan icon and printable-cards section are shown, and the Tumbuh tab is hidden

#### Scenario: Flag changed while app in background
- **WHEN** QR scanning is disabled while the app is backgrounded and the user returns to it
- **THEN** the flags are refreshed and the Kartu AR scan icon disappears without restarting the app

### Requirement: Hidden QR scan keeps navigation proportional
When `qr_scan` is disabled, the app SHALL:
- hide the scan icon in the Kartu AR header;
- close the scanner and return to the previous screen if the scanner is open;
- redirect `/ar-scan` to the shell;
- stop the fallback hero banner from linking to scan;
- hide the animal-detail "Scan di AR" button.

The bottom navigation is unaffected because scan is no longer a tab.

#### Scenario: Scan tab was open
- **WHEN** the user is on the QR scanner and `qr_scan` becomes disabled
- **THEN** the camera screen is removed, and tapping "Kartu AR" on Beranda opens the collection inside Belajar with no scan icon

## ADDED Requirements

### Requirement: Growth tracking flag
The app SHALL read the `growth_tracking` flag and treat it as off whenever its value is unknown. While it is off, the app SHALL hide the Tumbuh tab and the Beranda growth card. If Tumbuh is the open tab when the flag turns off, the app SHALL return to Beranda. The flag SHALL be listed on the backoffice App Features page as "Tumbuh Kembang", like the other flags.

#### Scenario: Admin turns on Tumbuh Kembang
- **WHEN** an admin enables "Tumbuh Kembang" on the App Features page and a logged-in user brings the app to the foreground
- **THEN** the Tumbuh tab and the Beranda growth card appear

#### Scenario: Old backend without the flag
- **WHEN** `GET /app/feature-flags` has no `growth_tracking` key
- **THEN** the Tumbuh tab stays hidden
