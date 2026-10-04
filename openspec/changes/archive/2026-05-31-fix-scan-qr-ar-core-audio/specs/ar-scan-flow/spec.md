## MODIFIED Requirements

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
