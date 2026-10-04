## ADDED Requirements

### Requirement: Home screen greeting header
The home screen SHALL display a personalised greeting (e.g., "Halo, Explorer! 👋") and a settings icon in the top-right corner.

#### Scenario: Greeting is visible on home
- **WHEN** the user navigates to the Beranda tab
- **THEN** a greeting text and settings icon are displayed at the top of the screen

### Requirement: Home quick-action buttons
The home screen SHALL display three quick-action buttons: Scan Mulai AR, Koleksiku (Lihat semua), and Dongeng (Cerita seru).

#### Scenario: Quick actions are tappable
- **WHEN** the user taps "Scan Mulai AR"
- **THEN** the app navigates to the Scan screen

#### Scenario: Koleksiku navigates to collection
- **WHEN** the user taps "Koleksiku"
- **THEN** the app navigates to the Koleksi tab

#### Scenario: Dongeng navigates to stories
- **WHEN** the user taps "Dongeng"
- **THEN** the app navigates to the Dongeng tab

### Requirement: Printable cards download banner
The home screen SHALL display an "Unduh Kartu Printable — Cetak, potong, dan main!" banner with a printable card preview image.

#### Scenario: Printable cards banner is visible
- **WHEN** the user views the home screen
- **THEN** the printable cards banner is shown below the quick-action buttons

### Requirement: Featured animal illustration
The home screen SHALL display a large featured animal illustration (e.g., Rusa/deer) as a hero visual element.

#### Scenario: Hero animal is displayed
- **WHEN** the home screen loads
- **THEN** a large animal illustration is visible as the central hero graphic
