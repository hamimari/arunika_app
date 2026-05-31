## ADDED Requirements

### Requirement: Scan screen camera viewfinder
The scan screen SHALL display a full-screen camera viewfinder with an animated card-shaped scan guide overlay and a help (?) and flashlight icon.

#### Scenario: Camera viewfinder is active
- **WHEN** the user opens the Scan screen
- **THEN** the camera feed is displayed with an animated scan frame overlay

### Requirement: AR experience screen
After a successful QR scan confirmation, the app SHALL fetch the AR card data (3D model URL and optional sound URL) and navigate to the AR experience screen (`ArCoreSurfacePlaceScreen`). Navigation MUST occur automatically once the bloc emits `ModelLoaded` — no further user action required after tapping "Lihat AR".

#### Scenario: AR model appears after scan
- **WHEN** a valid AR card QR code is scanned
- **AND** the user taps "Lihat AR" on the confirmation card
- **THEN** the app fetches the AR card record by ID
- **AND** navigates to `ArCoreSurfacePlaceScreen` with the resolved `modelUrl` and `soundUrl`

#### Scenario: Navigation does not require second tap
- **WHEN** `QRScannerBloc` emits `ModelLoaded` in the bottom nav scan tab
- **THEN** the app pushes `ArCoreSurfacePlaceScreen` without requiring any additional user interaction

### Requirement: Fun fact overlay after interaction
After the user interacts with the AR animal, the app SHALL display a "Tahukah kamu?" fun fact overlay card with educational text and a sound button.

#### Scenario: Fun fact card displayed
- **WHEN** the user taps the AR animal
- **THEN** a fun fact overlay appears with an educational fact about the animal

### Requirement: Reward screen after AR session
After completing an AR interaction, the app SHALL display a reward screen showing "+10 ⭐" stars earned and a "Lihat Koleksiku" button.

#### Scenario: Reward screen shown
- **WHEN** the AR session ends (animal successfully interacted with)
- **THEN** a celebration reward screen shows stars earned and a button to view the collection
