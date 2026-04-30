## ADDED Requirements

### Requirement: Congratulations modal on successful registration
The system SHALL display a congratulations modal dialog immediately after a user successfully completes registration, before navigating to the next screen.

#### Scenario: Modal shown on registration success
- **WHEN** the user submits the registration form and the backend returns a success response
- **THEN** a modal dialog SHALL appear with a congratulations icon, a success title, a brief message, and a primary action button

#### Scenario: Modal action navigates to next step
- **WHEN** the user taps the primary action button in the congratulations modal
- **THEN** the modal SHALL dismiss and the app SHALL navigate to the child setup or home screen

#### Scenario: Modal cannot be dismissed by tapping outside
- **WHEN** the congratulations modal is visible
- **THEN** tapping outside the modal SHALL NOT dismiss it; only the action button SHALL dismiss it
