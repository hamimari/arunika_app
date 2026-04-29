## ADDED Requirements

### Requirement: Navigation buttons respect safe-area insets
The Previous and Next navigation buttons on the dongeng detail screen SHALL be fully visible and tappable on all supported device sizes, including devices with notches, rounded corners, or narrow aspect ratios.

#### Scenario: Buttons visible on narrow device
- **WHEN** the dongeng detail screen is displayed on a device with a narrow screen or large corner radius
- **THEN** both the Previous and Next circular buttons are fully within the visible screen area and not clipped

#### Scenario: Buttons respect device safe-area padding
- **WHEN** the device reports non-zero horizontal safe-area padding (e.g. notch or system UI insets)
- **THEN** the buttons are offset inward by at least the safe-area padding value so they do not overlap system UI

#### Scenario: Button tap area remains accessible
- **WHEN** the buttons are positioned with the corrected insets
- **THEN** the full 44×44 dp tap target of each button is within the touchable area of the screen
