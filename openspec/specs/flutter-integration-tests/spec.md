# flutter-integration-tests Specification

## Purpose
TBD - created by archiving change add-automation-testing-strategy. Update Purpose after archive.
## Requirements
### Requirement: Flutter integration tests run the real app against a real backend
The Flutter app SHALL have an `integration_test` suite that drives the assembled application against a backend running from the project's container stack with a deterministic seed set, rather than against mocked HTTP responses.

#### Scenario: App boots against the container stack
- **WHEN** an integration test starts
- **THEN** the app is configured to reach the containerised backend and its seeded database, and no test depends on a developer-specific environment

#### Scenario: Journey crosses screens
- **WHEN** an integration test signs in and navigates to content
- **THEN** real HTTP requests reach the backend and the resulting screens reflect the seeded data

#### Scenario: Mocked HTTP stays at the unit and widget levels
- **WHEN** a test only needs to verify how a bloc or widget reacts to a response
- **THEN** it remains a unit or widget test with a mocked dependency, and is not promoted to the integration suite

### Requirement: Billing is injectable so purchase flows are deterministic in CI
The Google Play billing dependency SHALL be reachable through an injectable interface so integration tests can supply a fake implementation. Integration tests SHALL NOT require a real Play Store transaction.

#### Scenario: Fake billing completes a purchase
- **WHEN** an integration test injects a fake billing implementation that reports a successful purchase
- **THEN** the app submits the resulting purchase token to the backend and the content becomes unlocked

#### Scenario: Fake billing reports failure
- **WHEN** the injected billing implementation reports a cancelled or failed purchase
- **THEN** the app shows the failure state and no content is unlocked

#### Scenario: Billing service logic is unit tested
- **WHEN** the billing service handles purchase-stream events, pending purchases and errors
- **THEN** that logic has unit tests independent of the integration suite

### Requirement: Core user journeys have integration coverage
The integration suite SHALL cover the journeys that cross screens and depend on backend state, without attempting to cover every screen.

#### Scenario: New user journey
- **WHEN** the suite runs the signup, OTP and login journey
- **THEN** the user reaches the home screen with content loaded from the backend

#### Scenario: Free content journey
- **WHEN** a signed-in user opens a free dongeng
- **THEN** the content opens and the play is recorded against the backend

#### Scenario: Paid content journey
- **WHEN** a signed-in user purchases a paid AR card through the injected fake billing
- **THEN** the backend grants the entitlement and the card is presented as unlocked

#### Scenario: Entitlements survive re-login
- **WHEN** a user who owns content signs out and signs back in
- **THEN** the owned content is still presented as unlocked

#### Scenario: Session continues across token refresh
- **WHEN** the access token expires during a session
- **THEN** the app refreshes it and the interrupted request completes without the user being signed out

### Requirement: Native UI interaction is confined to a separate device suite
Flows that require interacting with operating-system UI — permission dialogs and the store billing sheet — SHALL live in a separate suite using a framework capable of native automation, and SHALL NOT gate pull requests.

#### Scenario: Permission dialog is handled
- **WHEN** the native suite runs the QR-scanner flow and the camera permission dialog appears
- **THEN** the suite grants the permission and the flow continues

#### Scenario: Native suite runs outside the pull-request gate
- **WHEN** a pull request is opened
- **THEN** the native suite does not run; it runs on a scheduled or release basis

#### Scenario: Real store billing is not a pull-request gate
- **WHEN** the real store billing sheet is exercised
- **THEN** it runs against a test-account build outside the pull-request gate, and never with production payment credentials

### Requirement: Augmented reality testing is split by what can be proven
AR-related testing SHALL separate deterministic logic from hardware-dependent behaviour. Logic SHALL be automated; camera, surface detection and object placement SHALL NOT be automated on emulators.

#### Scenario: Scan payload resolution is automated
- **WHEN** a scanned code payload is mapped to an AR card
- **THEN** that mapping is covered by automated tests with no camera involved

#### Scenario: Access gate before AR launch is automated
- **WHEN** a user without an entitlement attempts to open a paid AR card
- **THEN** an automated test asserts that the AR experience is not launched and the purchase path is offered instead

#### Scenario: Asset resolution is automated
- **WHEN** an AR card's model and sound assets are resolved
- **THEN** automated tests assert the resolved references without rendering anything

#### Scenario: Hardware behaviour stays manual
- **WHEN** surface detection, tracking stability or object placement needs verifying
- **THEN** it is covered by a physical-device checklist, and no emulator-based test claims to verify it

