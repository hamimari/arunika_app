## ADDED Requirements

### Requirement: Featured premium story card
The dongeng list screen SHALL display a featured story card at the top (e.g., "Petualangan Rusa") with a "Premium" badge, cover image, description, and "Baca Sekarang" button.

#### Scenario: Featured card is visible
- **WHEN** the user opens the Dongeng screen
- **THEN** a large featured story card with premium badge is displayed at the top

### Requirement: Popular stories list
The dongeng list screen SHALL display a "Cerita Populer — Lihat Semua" section with story rows showing cover thumbnail, title, description, and a lock/unlock icon.

#### Scenario: Locked stories show lock icon
- **WHEN** a story requires premium access
- **THEN** a lock icon is displayed on the story row

#### Scenario: Unlocked stories are accessible
- **WHEN** the user taps an unlocked story row
- **THEN** the app navigates to the dongeng player screen for that story

### Requirement: Existing dongeng player preserved
The dongeng player screen (story reading/narration UI) SHALL remain visually unchanged.

#### Scenario: Player screen is not modified
- **WHEN** the user opens a story to read
- **THEN** the player screen renders identically to its pre-change state
