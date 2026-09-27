## ADDED Requirements

### Requirement: Browser-driven coverage of admin publishing flows
The backoffice SHALL have a browser-automation suite covering the administrative flows that content editors depend on, driving a real browser against the running backoffice and backend rather than mocked HTTP.

#### Scenario: Administrator publishes an AR card
- **WHEN** an administrator logs in, creates a category, creates an AR card in it, configures its assets and makes it visible
- **THEN** each step succeeds in the browser and the created content is persisted in the backend

#### Scenario: Administrator publishes a dongeng
- **WHEN** an administrator creates a dongeng and makes it visible
- **THEN** the dongeng is persisted and appears in the administrative listing

#### Scenario: Administrator assembles a package
- **WHEN** an administrator creates a premium package, adds items to it and makes it visible
- **THEN** the package and its items are persisted and appear in the administrative listing

#### Scenario: Suite runs outside the pull-request gate
- **WHEN** a pull request is opened
- **THEN** the browser suite does not run; it runs on merge and on release

### Requirement: Browser test failures produce diagnostic artifacts
The browser suite SHALL capture artifacts on failure so a failure can be diagnosed without reproducing it locally.

#### Scenario: Failure uploads a trace
- **WHEN** a browser test fails in CI
- **THEN** a screenshot and a trace or video are uploaded as build artifacts

#### Scenario: Retries are bounded and visible
- **WHEN** a browser test is retried
- **THEN** at most one retry occurs and the retry is reported, so intermittency is visible rather than hidden

### Requirement: Component-level coverage of every administrative page
Every page in the backoffice SHALL have component-level tests covering its meaningful behaviour — form validation, table rendering, filtering, pagination, and modal submission — using the existing component-testing setup with mocked HTTP.

#### Scenario: Page renders its data
- **WHEN** a page is rendered with a mocked successful API response
- **THEN** the returned records are displayed

#### Scenario: Invalid form submission is prevented
- **WHEN** a required field is left empty in a create or edit form
- **THEN** submission is prevented and the validation message is shown

#### Scenario: API failure surfaces an error state
- **WHEN** a page's API request fails
- **THEN** the page shows an error state rather than an empty success state

#### Scenario: Filtering and pagination are exercised
- **WHEN** a listing page's filter or pagination controls are used
- **THEN** the corresponding request is issued with the expected parameters

### Requirement: API client and session handling coverage
The backoffice HTTP client and authentication store SHALL have tests covering credential attachment and unauthorised-response handling.

#### Scenario: Requests carry the admin credential
- **WHEN** an authenticated request is issued through the shared client
- **THEN** the admin credential is attached

#### Scenario: Unauthorised response ends the session
- **WHEN** the backend responds that the admin credential is no longer valid
- **THEN** the client clears the session and the user is returned to the login screen
