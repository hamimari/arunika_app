## MODIFIED Requirements

### Requirement: Branded native splash screen
The app SHALL display a native splash screen (rendered before Flutter engine initialises) using `assets/splash.png` centred on a cream/warm-white (`#FFF8F0`) background that blends with the warm illustration style of the welcome screen.

#### Scenario: Splash screen appears on cold launch
- **WHEN** the user cold-launches the app
- **THEN** the native splash screen is shown immediately with `splash.png` centred on a cream background before any Flutter widget renders

#### Scenario: Background colour matches warm theme
- **WHEN** the splash screen is visible
- **THEN** the background colour is `#FFF8F0` (warm cream) matching the app's colour palette

#### Scenario: Splash dismisses to welcome screen
- **WHEN** the Flutter engine and first widget tree have initialised
- **THEN** the splash dismisses and the "Bring Animals to Life!" welcome screen is displayed with "Let's Explore!" and "Try Demo AR" buttons
