## ADDED Requirements

### Requirement: Automated test execution on every pull request
Each of the three repositories (`arunika_app`, `arunika-backend`, `arunika-backoffice`) SHALL have a GitHub Actions workflow that runs lint and the full unit and component test suites on every pull request. A pull request whose tests fail SHALL NOT be mergeable.

#### Scenario: Passing pull request
- **WHEN** a pull request is opened and every lint and test job succeeds
- **THEN** the workflow reports success and the pull request is mergeable

#### Scenario: Failing test blocks merge
- **WHEN** a pull request introduces a change that breaks any existing test
- **THEN** the workflow reports failure and the pull request is not mergeable

#### Scenario: Pull-request feedback stays fast
- **WHEN** the pull-request workflow runs
- **THEN** it completes within 5 minutes, with lint, unit, component, database, API and contract jobs running in parallel

### Requirement: Pinned Node toolchain for the backoffice
`arunika-backoffice` SHALL pin its Node version to 22 via `.nvmrc` and a `engines` field in `package.json`, and its CI workflow SHALL use that version, so the existing `vitest` 4 suite executes both locally and in CI.

#### Scenario: Backoffice suite executes
- **WHEN** `npm test` is run on the pinned Node version
- **THEN** the Vitest suite starts and reports per-test results instead of failing at module load

#### Scenario: Unsupported Node version is rejected
- **WHEN** a contributor runs `npm install` on a Node version below the `engines` floor
- **THEN** npm warns or errors rather than installing a toolchain that cannot run the tests

### Requirement: Staged pipeline across pull request, merge and release
CI SHALL run progressively wider test tiers: pull requests run lint, unit, component, database, API and contract tests; merges to the main branch additionally run backoffice E2E, mobile integration tests and the cross-system E2E suite; release tags additionally run staging E2E, the native-UI suite and smoke tests.

#### Scenario: Merge triggers the wider tier
- **WHEN** a pull request is merged to the main branch
- **THEN** the merge workflow runs the backoffice Playwright suite, the Flutter emulator integration suite and the cross-system E2E suite

#### Scenario: Release triggers deployment gates
- **WHEN** a release tag is pushed
- **THEN** the pipeline deploys to staging, runs the full E2E suite against staging, runs smoke tests, and only then promotes to production

#### Scenario: Slow tiers never gate a pull request
- **WHEN** a pull request is opened
- **THEN** no emulator, Playwright or docker-compose E2E job runs in that workflow

### Requirement: Machine-readable test reporting and failure artifacts
Every test job SHALL emit JUnit XML that CI renders as annotations on the pull-request diff, reporting passed, failed and skipped counts with per-test duration. Jobs in the UI and E2E tiers SHALL upload failure artifacts.

#### Scenario: Failure is annotated in the diff
- **WHEN** a test fails in CI
- **THEN** the failing test name, message and duration are annotated against the relevant file in the pull-request diff

#### Scenario: UI failure uploads diagnostic artifacts
- **WHEN** a Playwright, Patrol or `integration_test` case fails
- **THEN** the job uploads screenshots, a trace or video where the framework produces one, and the relevant logs

#### Scenario: Cross-system failure uploads stack state
- **WHEN** a cross-system E2E test fails
- **THEN** the job uploads `docker compose logs` for every service and a dump of the seeded test database

### Requirement: Per-package coverage ratchets
CI SHALL enforce per-package coverage floors rather than a single global target. Coverage SHALL NOT drop below the previous merge for any package, and the packages holding authentication, authorization, entitlement and payment logic SHALL meet explicit higher floors.

#### Scenario: Coverage regression is blocked
- **WHEN** a pull request lowers coverage for a package below its recorded baseline
- **THEN** the coverage gate fails

#### Scenario: Critical package floor is enforced
- **WHEN** coverage of the backend `models` package is below 80%, `middlewares` below 90%, `handlers` below 70%, or the entitlement, payment, order, auth and product service files below 85%
- **THEN** the coverage gate fails

#### Scenario: New code does not need a global percentage
- **WHEN** a pull request adds a package with modest coverage but no package regresses and every floor is met
- **THEN** the coverage gate passes

### Requirement: Flaky-test quarantine policy
Flaky tests SHALL be quarantined and tracked rather than masked by retries. Automatic retries SHALL be permitted only in the E2E tier. A quarantined test SHALL have an owner and SHALL be fixed or deleted within two weeks.

#### Scenario: Flakiness is detected
- **WHEN** the nightly job re-runs the full suite on an unchanged commit and a test's result differs from the previous run
- **THEN** that test is identified as flaky and reported

#### Scenario: Quarantined test stops blocking merges
- **WHEN** a test is quarantined
- **THEN** it is moved to a non-blocking job where it still runs and reports, and it no longer fails the pull-request gate

#### Scenario: Retries are refused below the E2E tier
- **WHEN** a retry is configured for a unit, component, database, API or contract test
- **THEN** the configuration is rejected in review, because a non-deterministic test at those tiers indicates a real defect

#### Scenario: Expired quarantine is resolved
- **WHEN** a quarantined test passes its two-week expiry
- **THEN** it is either fixed and returned to the blocking suite or deleted
