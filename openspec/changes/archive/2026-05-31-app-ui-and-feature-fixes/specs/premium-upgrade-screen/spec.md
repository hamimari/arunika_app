## ADDED Requirements

### Requirement: Auth guard before premium upsell
When an unauthenticated user taps any premium-locked feature, the app SHALL show a dialog prompting the user to log in or register before proceeding. After successful authentication, the app SHALL navigate to the Paket Konten tab of the premium upgrade screen.

#### Scenario: Unauthenticated user taps premium content
- **WHEN** a user who is not logged in taps a locked premium feature
- **THEN** a dialog appears with the options "Login" and "Daftar Akun" (and a dismiss option)

#### Scenario: User chooses Login from dialog
- **WHEN** the user taps "Login" in the auth-guard dialog
- **THEN** the app navigates to the login screen; after successful login, the app navigates to the Paket Konten tab of the premium upgrade screen

#### Scenario: User chooses Daftar from dialog
- **WHEN** the user taps "Daftar Akun" in the auth-guard dialog
- **THEN** the app navigates to the register screen; after successful registration, the app navigates to the Paket Konten tab of the premium upgrade screen

#### Scenario: User dismisses dialog
- **WHEN** the user dismisses the auth-guard dialog without choosing an action
- **THEN** the dialog closes and the user remains on the current screen
