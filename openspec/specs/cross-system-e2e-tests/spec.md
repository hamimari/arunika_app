# cross-system-e2e-tests Specification

## Purpose
TBD - created by archiving change add-automation-testing-strategy. Update Purpose after archive.
## Requirements
### Requirement: Reproducible multi-service test stack
Cross-system end-to-end tests SHALL run against a container stack that provisions PostgreSQL, Redis, database migrations, the backend and the backoffice, plus a fake store verification service, started from configuration checked into the repository. The suite SHALL wait on service health checks rather than fixed delays.

#### Scenario: Stack starts from a clean checkout
- **WHEN** the end-to-end suite is invoked on a machine with only Docker available
- **THEN** every service is built and started from repository configuration, migrations and the test seed are applied, and the suite runs without manual setup

#### Scenario: Readiness is determined by health checks
- **WHEN** the suite waits for the backend to become available
- **THEN** it waits on the service health check rather than sleeping for a fixed duration

#### Scenario: Teardown captures diagnostics on failure
- **WHEN** an end-to-end test fails
- **THEN** logs for every service and the state of the test database are captured before teardown

### Requirement: No external credentials are required to run the suite
The end-to-end suite SHALL exercise store purchase verification against a fake store service, requiring no production credentials and no store service-account key in any repository.

#### Scenario: Purchase verification uses the fake service
- **WHEN** the backend verifies a purchase during the end-to-end suite
- **THEN** it calls the fake store service configured through the existing base-URL override

#### Scenario: No credentials in version control
- **WHEN** the repository is inspected
- **THEN** it contains no store service-account key, and the suite passes without one

### Requirement: Gating business flows have end-to-end coverage
The following cross-system flows SHALL be covered by automated end-to-end tests that gate merges: new-user onboarding, free content consumption, paid content purchase, bundle purchase, and admin content publishing.

#### Scenario: New user onboarding
- **WHEN** a new user signs up, logs in, creates a child profile and opens the home screen
- **THEN** each step succeeds and the home screen is populated from seeded backend content

#### Scenario: Free content consumption
- **WHEN** a signed-in user opens a free dongeng
- **THEN** the content is served and the play is recorded in the backend

#### Scenario: Paid content purchase unlocks access
- **WHEN** a user purchases a paid AR card and the fake store reports the purchase as valid
- **THEN** the backend records the order as paid, grants the entitlement, and the card is subsequently reported as unlocked for that user

#### Scenario: Bundle purchase grants every item
- **WHEN** a user purchases a content package containing several products
- **THEN** an entitlement is granted for every product in the package and each is reported as unlocked

#### Scenario: Admin publishing reaches the app
- **WHEN** an administrator creates a content item and makes it visible
- **THEN** the app-facing endpoints return that item

### Requirement: Settlement is idempotent under replay
End-to-end tests SHALL verify that replaying a payment settlement notification does not duplicate payments or entitlements.

#### Scenario: Replayed notification changes nothing
- **WHEN** the same settlement notification is delivered twice
- **THEN** the order remains paid exactly once, and no duplicate payment or entitlement row is created

### Requirement: Flows provable at a cheaper level are not duplicated end to end
Behaviour that can be proven at the API level SHALL be tested there rather than in the end-to-end suite. The token-refresh and logout-revocation flows specifically SHALL be covered by API tests.

#### Scenario: Token refresh is covered at the API level
- **WHEN** the token refresh flow is verified
- **THEN** it is covered by an API test and has no separate end-to-end test

#### Scenario: Logout revocation is covered at the API level
- **WHEN** the logout revocation flow is verified
- **THEN** it is covered by an API test and has no separate end-to-end test

#### Scenario: End-to-end suite stays small
- **WHEN** a new end-to-end test is proposed
- **THEN** it is accepted only if no cheaper level can prove the same behaviour

### Requirement: Automated coverage replaces manual purchase verification
The manual verification steps currently required to confirm purchase, bundle, replay, package-listing and administrative grant behaviour SHALL be superseded by the automated end-to-end and API coverage defined here, and the manual checklist SHALL record which automated test replaces each step.

#### Scenario: Manual step is retired with a named replacement
- **WHEN** an automated test covers a previously manual verification step
- **THEN** the manual step is marked superseded and names the test that replaces it

#### Scenario: Release requires no manual purchase check
- **WHEN** a release candidate is prepared
- **THEN** purchase, bundle and entitlement correctness are confirmed by the automated suite rather than by hand

