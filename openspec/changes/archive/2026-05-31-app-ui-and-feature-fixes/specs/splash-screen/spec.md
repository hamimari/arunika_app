## MODIFIED Requirements

### Requirement: Branded native splash screen
The app SHALL display a native splash screen (rendered before Flutter engine initialises) using `assets/splash.png` centred on a background colour that has low contrast with the app's main background (`#F7F8FC`), avoiding a harsh colour transition. The background colour SHALL be `#F7F8FC` (same as the app background) or a very close neutral tone.

#### Scenario: Splash screen appears on cold launch
- **WHEN** the user cold-launches the app
- **THEN** the native splash screen is shown immediately with `splash.png` centred on a low-contrast background before any Flutter widget renders

#### Scenario: Background colour does not clash with app background
- **WHEN** the splash screen transitions to the welcome screen
- **THEN** there is no harsh colour contrast jump between the splash background and the app background

#### Scenario: Splash dismisses to welcome screen
- **WHEN** the Flutter engine and first widget tree have initialised
- **THEN** the splash dismisses and the "Bring Animals to Life!" welcome screen is displayed with "Let's Explore!" and "Try Demo AR" buttons
