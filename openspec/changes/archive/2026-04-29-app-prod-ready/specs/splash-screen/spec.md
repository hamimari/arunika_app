## ADDED Requirements

### Requirement: Branded native splash screen
The app SHALL display a native splash screen (rendered before Flutter engine initialises) using `assets/splash.png` centred on a white (`#FFFFFF`) background that blends seamlessly with the white portions of the image.

#### Scenario: Splash screen appears on cold launch
- **WHEN** the user cold-launches the app
- **THEN** the native splash screen is shown immediately with `splash.png` centred on a white background before any Flutter widget renders

#### Scenario: Background colour matches image white
- **WHEN** the splash screen is visible
- **THEN** the background colour is `#FFFFFF` so that the white edges of `splash.png` are indistinguishable from the background

#### Scenario: Splash dismisses when Flutter is ready
- **WHEN** the Flutter engine and first widget tree have initialised
- **THEN** the splash screen is dismissed and the app's first route is displayed
