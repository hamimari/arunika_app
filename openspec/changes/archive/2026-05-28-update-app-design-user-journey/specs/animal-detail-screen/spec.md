## ADDED Requirements

### Requirement: Animal detail page layout
The animal detail screen SHALL display a large animal image on a coloured background, the animal's name, a "Fakta Seru" (fun fact) section, and action buttons.

#### Scenario: Animal image displayed prominently
- **WHEN** the user opens an animal detail page
- **THEN** a large animal image is shown at the top with a styled background

#### Scenario: Fun fact section shown
- **WHEN** the animal detail screen loads
- **THEN** a "Fakta Seru 🐾" card with educational text and a sound icon is displayed

### Requirement: Scan di AR button
The animal detail screen SHALL display a "Scan di AR" button that navigates to the AR scan screen.

#### Scenario: Navigates to scan
- **WHEN** the user taps "Scan di AR"
- **THEN** the app navigates to the AR scan screen with this animal pre-selected

### Requirement: Sound, share, and favorite actions
The animal detail screen SHALL display a "Suara" (sound) button, a "Bagikan" (share) button, and a heart/favorite toggle.

#### Scenario: Sound button plays audio
- **WHEN** the user taps "Suara"
- **THEN** the animal's sound or name pronunciation plays

#### Scenario: Share button triggers share sheet
- **WHEN** the user taps "Bagikan"
- **THEN** the system share sheet is opened
