## ADDED Requirements

### Requirement: Dongeng list screen has correct background color
The system SHALL use `AppColors.pageBackground` (warm page background) as the background color of the dongeng list screen, consistent with the home screen.

#### Scenario: Dongeng list background matches home screen
- **WHEN** the user navigates to the Dongeng tab
- **THEN** the background color SHALL visually match the home screen's warm background

### Requirement: Dongeng list screen shows subtitle
The system SHALL display a subtitle below the "Dongeng" heading on the list screen, providing context to the user.

#### Scenario: Subtitle visible on load
- **WHEN** the dongeng list screen is loaded
- **THEN** a subtitle text SHALL appear below the main heading
