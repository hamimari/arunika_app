# Change: System-wide automation testing strategy for Arunika

## Why

Arunika already has **721 passing automated tests** (465 Go incl. subtests, 193 Flutter, 63 backoffice) — but **nothing runs them automatically**. There is no CI configuration in any of the three repositories (`arunika_app`, `arunika-backend`, `arunika-backoffice`). Every test is a test a developer must remember to run, and the backoffice suite **cannot run at all** on the current toolchain (`vitest` 4 / `rolldown` require Node ≥ 20.19; the machine has Node 16.20.2) — which also hid a broken production build, since Vitest does not typecheck and `npm run build` was failing `tsc -b`.

Underneath that, the tests that do exist verify the wrong things at the wrong level:

- **Every backend "integration" test is `sqlmock` with hand-written SQL regexes** (36 of 46 test files). `regexp.QuoteMeta("SELECT * FROM \"dongengs\" WHERE is_deleted = $1 AND hidden = $2 LIMIT $3")` asserts that GORM emits one exact string — it does not verify the schema, a single migration, a UNIQUE index, a foreign key, or a transaction boundary. The crown-jewel guarantee of the product ("the same purchase token must never grant two entitlements") is currently asserted against a mock's expectation list, not against the real Postgres constraint that actually enforces it.
- **`models/` has 0% coverage.** `GrantEntitlement`, `HasEntitlement`, and `FindPackageItems` — the entire entitlement data layer — have no tests at all. `handlers/` sits at 28.8% and `middlewares/` at 45.1% (only 3 of 7 middlewares are tested; `subscription_middleware`, `admin_auth_middleware`, `security_headers_middleware` and `error_middleware` are not).
- **Nothing checks that Flutter and the backend still agree.** Drift already exists: `AnimalApi` calls `GET /animals` and `DongengHistoryApi.getPopular` calls `GET /fairy-tales/popular`, and **neither route exists in `routes/router.go`**. Both are currently unreachable from the UI, so the drift is latent rather than live — but nothing would have caught it if they were reachable, and nothing will catch the next one.
- **No cross-system test exists.** The active `add-monetization-entitlements` change has 7 unfinished tasks and 6 of them (16.1–16.6) are *manual* verification steps: "purchase a content package in the app → webhook settles → entitlements granted → collection screen shows unlocked". The highest-value business flow in the product is verified by hand, every time.
- **No `integration_test/` directory exists in the Flutter app**, so there is no level above widget tests at all.

The enabling insight from the audit: `services/google_play_verifier.go` already exposes `ANDROID_PUBLISHER_BASE_URL` as an overridable seam, and `docker-compose.yml` in `arunika-backend` already builds Postgres, Redis, Flyway, the backend **and** the backoffice image. The infrastructure for real, fully-automated purchase-to-entitlement testing is largely already in place and unused.

This change defines the testing architecture, picks the frameworks, and lays out a seven-phase roadmap to close those gaps — deliberately buying the cheapest reliable coverage first (CI + real Postgres) before spending anything on E2E.

## What Changes

- **CI/CD (new)**: GitHub Actions workflows in all three repos. PR-time lint + unit + component tests under 5 minutes; merge-time database, API, contract and backoffice-E2E jobs; release-time full cross-system E2E and smoke tests. JUnit XML reporting and failure artifacts (screenshots, container logs, seeded data) everywhere.
- **Toolchain pinning**: `.nvmrc` + `package.json` `engines` pinning Node 22 in `arunika-backoffice` so the existing `vitest` 4 suite runs again locally and in CI. **BREAKING for local dev**: contributors on Node 16 must upgrade.
- **Real-database testing (new)**: introduce `testcontainers-go` for repository and API tests, running `postgres:15-alpine` with the real `db/migrations` Flyway set applied. `sqlmock` is retained only where the database is genuinely incidental to the logic under test; it is **removed** from entitlement, order, payment and access-control tests, which move to real Postgres.
- **Backend API integration tests (new)**: a `tests/api` suite booting the real Gin router against containerised Postgres + Redis and exercising actual routes end-to-end (status, body, validation, authorization, persisted DB state).
- **Deterministic test data (new)**: Go factories/builders in `tests/fixtures` plus a versioned E2E seed set, replacing reliance on ad-hoc rows per test. Isolation by per-test transaction rollback for DB tests and template-database reset for API tests.
- **Contract testing (new)**: an OpenAPI 3.1 document in `arunika-backend` as the single source of truth. Backend API tests validate every response against it; Flutter (`lib/constants/api_paths.dart`) and backoffice (`src/api/*.ts`) gain a conformance check that every path they call exists in the spec. **Pact is explicitly rejected** — see `design.md`.
- **Security regression suite (new)**: repeatable automated tests for missing/invalid/expired JWTs, revoked-refresh-token reuse, horizontal privilege escalation (user A reading user B's orders), admin endpoints hit by normal users, purchase-token reuse, product-ID and package-name tampering, and error-message leakage.
- **Flutter integration tests (new)**: an `integration_test/` harness running the real app against a Dockerised backend with the billing layer stubbed at `GooglePlayBillingService`. **Patrol** is adopted only for the handful of flows needing native UI (permissions, Play Billing sheet); `integration_test` alone covers the rest. Appium and Maestro are rejected — see `design.md`.
- **Backoffice component + E2E tests**: extend the existing Vitest + React Testing Library suite to the 13 of 20 pages that currently have no test, and add **Playwright** for the three admin publishing flows.
- **Cross-system E2E (new)**: a `tests/e2e` suite in `arunika-backend` driving the existing `docker-compose.yml` stack, covering seven business flows. The Play purchase flow runs **fully automated in CI** by pointing the backend's verifier at a fake Android Publisher server via the existing `ANDROID_PUBLISHER_BASE_URL` seam. This retires manual tasks 16.1–16.6 of `add-monetization-entitlements`.
- **Coverage policy**: ratchet-based per-package floors (no global percentage target), with hard floors on entitlement, payment, auth and authorization code.
- **Flaky-test policy**: quarantine-and-track rather than blanket retries; retries permitted only in the E2E tier and only with a recorded reason.

## Capabilities

### New Capabilities
- `test-ci-pipelines`: GitHub Actions pipelines, toolchain pinning, test reporting, failure artifacts, coverage ratchets and the flaky-test policy across all three repos
- `test-data-fixtures`: deterministic factories, builders, seed sets and test isolation strategy
- `backend-database-tests`: Testcontainers-backed Postgres tests covering migrations, constraints, unique indexes, foreign keys, transactions, pagination/filtering/sorting, and the untested `models/` package
- `backend-api-tests`: full-router HTTP integration tests against real Postgres + Redis, including the auth lifecycle and the purchase→entitlement chain
- `api-contract-tests`: OpenAPI 3.1 source of truth, backend response validation, and Flutter/backoffice client path conformance
- `security-regression-tests`: repeatable automated authn/authz and input-tampering regression tests
- `flutter-integration-tests`: `integration_test/` harness against a Dockerised backend, the Patrol boundary for native UI, and the automatable/manual split for AR
- `backoffice-e2e-tests`: Playwright admin publishing flows plus component coverage for every administrative page
- `cross-system-e2e-tests`: seven docker-compose-driven business flows spanning Flutter, backend, Postgres, Redis and the backoffice

### Unchanged Capabilities
`backend-unit-tests`, `flutter-unit-tests` and the in-flight `backoffice-unit-tests` keep their current requirements. This change is deliberately orthogonal to them: it adds the levels *above* unit testing plus the infrastructure to run everything, so both changes can be archived independently.

## Impact

- **New in `arunika-backend`**: `.github/workflows/`, `tests/` (`fixtures/`, `db/`, `api/`, `security/`, `e2e/`, `contract/`), `openapi.yaml`, `docker-compose.test.yml`, a fake Android Publisher test server, and `testcontainers-go` + `kin-openapi` + `gotestsum` in `go.mod`. Existing entitlement/order/payment/access-control tests migrate off `sqlmock`.
- **New in `arunika_app`**: `.github/workflows/`, `integration_test/`, `test/helpers/` (shared factories and mock registration), a stubbable seam around `GooglePlayBillingService`, and `patrol` + `integration_test` dev dependencies.
- **New in `arunika-backoffice`**: `.github/workflows/`, `.nvmrc`, `package.json` `engines`, `e2e/` (Playwright), and component tests for `ArCardsPage`, `CategoriesPage`, `BadgesPage`, `TracingPage`, `ArCardCategoriesPage`, `BannersPage`, `CountingPage`, `PaymentsPage`, `UsersPage`, `UserDetailPage`, `DashboardPage`, `AnalyticsPage`, `LoginPage`.
- **Retires**: manual verification tasks 16.1–16.6 in `openspec/changes/add-monetization-entitlements/tasks.md`.
- **No application behaviour changes.** No production code is rewritten; the only non-test source change is extracting a test seam around the Flutter billing service.
- **Note for follow-up (not addressed here)**: `arunika-backoffice`'s git remote points at `git@github.com:hamimari/arunika-backend.git`, which will need correcting before its workflow can run in the right repo.
