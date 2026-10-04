## ADDED Requirements

### Requirement: Per-repository pre-release gate
Each of `arunika_app`, `arunika-backend`, `arunika-backoffice` and `arunika-landing` SHALL provide a `scripts/prerelease_check.sh` that runs the security, correctness and performance checks applicable to that repository's stack and writes every report to a git-ignored `prerelease-reports/` directory. The repositories with a Makefile (`arunika_app`, `arunika-backend`, `arunika-backoffice`) SHALL also expose it as `make prerelease`. The gate SHALL exit non-zero when any check fails.

#### Scenario: Clean run passes
- **WHEN** every check in the repository's gate succeeds
- **THEN** the gate prints a summary with zero failures and exits 0

#### Scenario: Failing check fails the gate
- **WHEN** any check reports a finding or a test failure
- **THEN** the summary names the failing check and its report path, and the gate exits non-zero

#### Scenario: Secret scanning covers history
- **WHEN** the gate runs in any repository
- **THEN** gitleaks scans both the git history and the working tree

### Requirement: Missing tools are never silent passes
The gate SHALL treat a missing required tool as a failure and print its install command. An explicit `--allow-missing` flag SHALL change these to warnings, and the summary SHALL still list every skipped check.

#### Scenario: Missing tool fails by default
- **WHEN** a required tool such as gosec is not on PATH
- **THEN** the gate reports a failure naming the tool and its install command, and exits non-zero

#### Scenario: Allowed missing tool is still reported
- **WHEN** the gate runs with `--allow-missing` and a required tool is not on PATH
- **THEN** that check is listed as skipped in the summary and does not by itself fail the gate

### Requirement: Stack-specific check coverage
The gates SHALL run, at minimum: gosec, govulncheck, golangci-lint and `go test -race` for the backend; `npm audit --omit=dev --audit-level=high` (runtime dependencies block; the full audit including dev tooling is written out for triage), ESLint with `eslint-plugin-security`, the unit test suite and an OWASP ZAP baseline scan against the production Docker image for the backoffice; `flutter analyze`, `flutter test --coverage` with the coverage ratchet and `dart pub outdated` for the app; and a ZAP baseline scan and Lighthouse run for the landing page.

#### Scenario: Backoffice DAST scans what ships
- **WHEN** the backoffice gate runs its ZAP baseline scan
- **THEN** the scan targets a container built from the backoffice production Dockerfile, not the Vite dev or preview server

#### Scenario: Unreachable target is skipped explicitly
- **WHEN** a load test or DAST target is not reachable, or `--skip-load` / `--skip-dast` is passed
- **THEN** the check is listed as skipped with the reason, and not reported as passed

### Requirement: Performance baselines and regression flags
The gate SHALL record baselines for backend benchmarks, the backoffice production bundle size and the landing Lighthouse performance score on first run, SHALL compare later runs against them, and SHALL re-record them only when `--write-baselines` is passed.

#### Scenario: First run records the baseline
- **WHEN** the gate runs and no baseline file exists
- **THEN** the current measurement is written as the baseline and the check passes

#### Scenario: Regression is flagged
- **WHEN** a benchmark or the bundle size regresses by more than 20%, or the Lighthouse performance score drops by more than 10 points, against the baseline
- **THEN** the gate reports the regression with the baseline and current values

### Requirement: Severity-based release triage
Every gate finding for a release SHALL be recorded in `arunika_app/docs/prerelease-triage.md` with its repository, tool, severity, decision and rationale. Hardcoded secrets, reachable high or critical CVEs, and SQL or command injection findings SHALL be blockers. Low-severity or unreachable CVEs and lint findings SHALL be tracked, not blocking. The release SHALL NOT proceed while any blocker is open.

#### Scenario: Secret found is a blocker
- **WHEN** gitleaks reports a real credential
- **THEN** the finding is triaged as a blocker, the credential is rotated, and then it is removed before release

#### Scenario: Unreachable CVE is tracked
- **WHEN** govulncheck or npm audit reports a vulnerability in code the application never reaches, or of low severity
- **THEN** the finding is recorded as tracked, with its rationale, and does not block release

#### Scenario: Manual reviews are recorded
- **WHEN** the triage record is completed for a release
- **THEN** it includes the certificate-pinning decision, the review of the payment WebView, external URL launches and Android exported components, the result of a profile-mode run on a real device, and the list of checks to re-run against a real deployment
