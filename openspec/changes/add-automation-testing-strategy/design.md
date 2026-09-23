# Design: Arunika automation testing architecture

## Context

Arunika is three repositories deployed as one product:

| Repo | Branch audited | Stack |
|---|---|---|
| `arunika_app` | `mvp` | Flutter 3.44.4 / Dart 3.8, `flutter_bloc` 8, `get_it`, `dio`, `go_router`, `in_app_purchase` + `in_app_purchase_android` |
| `arunika-backend` | `feature/education-module-v1-rebase` | Go 1.25 (toolchain 1.26.5), Gin, GORM, Postgres 15, Redis 7, Flyway |
| `arunika-backoffice` | `master-new` | React 19, TypeScript 6, Vite 8, Ant Design 6, TanStack Query 5, Zustand, Axios |

All three are GitHub repos under `hamimari`. This document records the assessment that produced the roadmap in `tasks.md` and the decisions behind it.

### A. Current architecture assessment

```text
Flutter app (arunika_app)                     Backoffice (arunika-backoffice)
  presentation/screens/*  (BLoC + Cubit)        pages/*  (React + antd + TanStack Query)
  data/repositories/*                           api/*    (axios client, admin/content/auth/analytics)
  data/api/*  (13 Dio clients)                  store/*  (zustand)
  core/{auth,feature_flags,media,storage}
  services/google_play_billing_service.dart
          │                                               │
          │  REST + Bearer JWT                            │  REST + Bearer admin JWT
          ▼                                               ▼
     ┌──────────────────────────────────────────────────────────┐
     │  Go backend (Gin)                                        │
     │    routes/router.go   — single flat route table          │
     │    middlewares/       — JWTAuth, OptionalAuth, AdminAuth, │
     │                          Subscription, RateLimit,         │
     │                          SecurityHeaders, Error           │
     │    handlers/  → services/  → models/ (GORM)              │
     └──────────────────────────────────────────────────────────┘
          │            │              │                │
          ▼            ▼              ▼                ▼
     PostgreSQL     Redis        Email (gomail)   Google Play
     54 Flyway      JWT revocation                Android Publisher API
     migrations     + rate limiting               + RTDN via Pub/Sub
     2 seed files
                                                  Midtrans (legacy web payment)
```

**Authentication.** Email/password signup with an OTP step, `golang-jwt/v5` access tokens plus DB-persisted refresh tokens with sliding expiry (`services/auth_service.go:82`), and Redis-backed JWT revocation on logout (`RevokeToken` stores the `jti` until `exp`). Admin auth is a separate token type behind `AdminAuthMiddleware`. `OptionalAuthMiddleware` is the interesting one: it lets anonymous users read content lists while still computing per-user unlock state when a token is present.

**Payments and entitlements.** Two providers coexist. Midtrans drives the legacy webview flow (`POST /payment/create` → `POST /payment/webhook`); Google Play Billing drives the app flow (`POST /payment/play/create` → `POST /payment/play/verify`, with `POST /payment/play/rtdn` receiving Real-time Developer Notifications). Both converge on the same model: an `orders` row is created PENDING, the provider confirms, and `EntitlementService.GrantForPaidOrder` grants either per-product `user_entitlements` rows (for a `content` package, fanned out over `premium_package_items`) or a `user_subscriptions` row (for a `subscription` package). `HasAccess` then resolves blanket subscription access first, falling back to a specific entitlement. Access is computed per request — `ar_cards.is_unlocked` as a stored flag was removed in migration `V39`.

**Domain boundaries that matter for testing.** The seam between *what was purchased* (orders/payments) and *what the user may see* (entitlements/subscriptions) is the single highest-value boundary in the system, and it is where a bug is most expensive: silently granting too much loses revenue, silently granting too little breaks a paying customer. Everything else in the product is content CRUD.

**How things start today.** `docker-compose.yml` in `arunika-backend` already orchestrates Postgres (healthchecked), Redis (healthchecked), Flyway migrate-to-completion, the backend, **and** the backoffice image built from `../arunika-backoffice`. Flutter runs from the developer's machine against whatever `app_config.dart` points at. There is no test-specific compose file and no seeded test database.

### B. Current testing assessment

Everything below currently passes (`go test ./...` green, `flutter test` 193/193 green) except the backoffice suite, which did not start until the Node pin landed in Phase 1.

| Suite | Location | Framework | Covers | Does not cover | Verdict |
|---|---|---|---|---|---|
| Go services | `services/*_test.go` (36 files, part of 417 test funcs) | `testify` + `DATA-DOG/go-sqlmock` + `miniredis` / `redismock` | Service-layer branching, auth lifecycle logic, Play verification branching (`payment_service_play_test.go` has 22 cases incl. token reuse, idempotent replay, RTDN revoke) | Real SQL, schema, constraints, transactions. Asserts exact GORM SQL strings via `regexp.QuoteMeta` | **Keep the logic tests; migrate the data-integrity ones to real Postgres** |
| Go handlers | `handlers/*_test.go` (8 files) | `httptest` + Gin `TestMode` + sqlmock | 28.8% of handlers | Most handlers have no test; no full-router path, so middleware chains are never exercised with handlers | **Improve** — supplement with real API tests rather than more sqlmock |
| Go middlewares | `middlewares/*_test.go` (3 files) | `testify` + miniredis | JWT, OptionalAuth, RateLimit — 45.1% | `SubscriptionMiddleware`, `AdminAuthMiddleware`, `SecurityHeadersMiddleware`, `ErrorMiddleware` untested | **Improve** |
| Go routes | `routes/router_test.go` | `httptest` | 99.5% — route table wiring | Behaviour behind the routes | **Keep** |
| Go utils | `utils/*_test.go` | `testify` | JWT + reset-token helpers, 92.3% | — | **Keep** |
| Go models | — | — | **nothing; 0% coverage** | `GrantEntitlement`, `HasEntitlement`, `FindPackageItems`, order/product helpers | **Gap — highest-value backend work** |
| Flutter | `test/**` (41 files, 193 tests) | `flutter_test`, `bloc_test`, `mocktail`, `fake_async` | BLoCs/Cubits for home, signin, signup, otp, dongeng, payment polling, premium packs, collection; repositories; several widget tests incl. parental gate and delete-account dialog | No `integration_test/`; no test touches a real backend; billing service untested | **Keep and build on** |
| Backoffice | `src/test/**` (11 files, 63 tests) | `vitest` 4, React Testing Library, `axios-mock-adapter` | 4 API modules, 7 pages — all 63 pass on Node 22 | 13 of 20 pages untested. No E2E. Vitest does not typecheck, which hid a failing `tsc -b` build | **Keep and extend** — Phase 1 verified the suite is sound, not rotted |
| CI | — | — | **nothing in any repo** | everything | **Gap — highest-value work overall** |

### C. Testing gaps, ranked by expected loss

1. **No CI.** 721 tests exist and none are enforced. Any of them could have been broken for weeks.
2. **Backoffice suite cannot run.** Silent rot; the Node pin is a ten-minute fix.
3. **No real-database testing.** Migrations, constraints and transactions are unverified. The `user_entitlements` uniqueness guarantee that makes duplicate purchases safe is tested only against a mock.
4. **`models/` at 0%.** The entitlement data layer is the least-tested and most business-critical code in the repo.
5. **No cross-system test.** The purchase→entitlement→unlock journey is verified by hand (tasks 16.1–16.6 of the active change).
6. **No contract check.** Two client methods already target routes that do not exist (`/animals`, `/fairy-tales/popular`).
7. **No Flutter integration layer.** Nothing between widget tests and a human with a phone.
8. **No security regression tests.** Authorization rules are asserted per-service, never as an end-to-end policy.

## Goals / Non-Goals

**Goals**
- A developer changing any repo gets a red/green signal in under 5 minutes on a PR, and full-system confidence before release.
- Entitlement correctness is enforced by tests running against the real Postgres constraints that enforce it in production.
- Backend↔client API drift becomes impossible to merge.
- Every test is runnable from a clean checkout with `docker` and nothing else — no hand-built databases, no developer-specific state.

**Non-Goals**
- Rewriting application code. The one exception is extracting a test seam around the Flutter billing service.
- A global coverage percentage target.
- Automating real Google Play production purchases, physical AR tracking, or visual/audio quality.
- Performance and load testing (deferred; noted in Phase 7 as a follow-up, not scoped here).
- Replacing the existing `sqlmock` service tests wholesale — only the data-integrity ones move.

## Decisions

### D1. Real Postgres via Testcontainers, not sqlmock, for anything about data

**Decision.** Add `testcontainers-go` and run `postgres:15-alpine` with the real `db/migrations` applied for repository, model and API tests. Keep `sqlmock` only where the database is incidental (e.g. "service returns error when repo errors"). Keep `miniredis` for Redis in Go tests — it is already a dependency and is behaviourally sufficient for revocation and rate limiting.

**Why.** The current pattern asserts GORM's SQL rendering, which is a restatement of the implementation rather than a test of behaviour. It cannot catch a missing migration, a wrong FK, or a broken `ON CONFLICT`. Worse, it gives false confidence exactly where it matters: `TestPaymentService_VerifyPlayPurchase_IdempotentReplay` currently passes because the mock was told to return one row, not because Postgres refused a duplicate insert.

**Alternatives considered.**
- *GitHub Actions `services:` containers + local docker-compose.* Cheaper (no new Go dependency) but splits local and CI setup, and a developer with no compose stack running gets a confusing failure. Rejected for `go test` ergonomics.
- *SQLite in-memory.* Fast, but Postgres-specific DDL in the Flyway migrations (and GORM's Postgres dialector, already wired in the test helpers) make it a different database. Rejected.
- *Keep sqlmock everywhere.* Rejected — it is the root cause of gap 3.

**Isolation.** One container per test *package*, started once in `TestMain`. Migrations run once into a template database; each test gets a fresh database cloned from the template (`CREATE DATABASE x TEMPLATE y`) for API tests, and a transaction rolled back at test end for pure repository tests. Both are parallel-safe.

**Trade-off.** Adds ~15s container startup per package and requires Docker locally. Mitigated by the template-database clone (milliseconds per test) and by keeping the unit tier free of containers so the fast loop stays fast.

### D2. OpenAPI 3.1 as the contract, not Pact

**Decision.** Maintain `openapi.yaml` in `arunika-backend` as the single source of truth. Backend API tests validate every response against it using `kin-openapi`. Flutter and backoffice each get a cheap conformance test asserting that every path their client layer calls exists in the spec.

**Why.** Consumer-driven contract testing (Pact) is designed for many independent consumer teams negotiating with a provider team. Arunika has one team, two consumers, and one provider. Pact would add a broker to run, a publishing step in three pipelines, and a second source of truth — for a problem (drift) that a schema plus two path-existence checks solves completely. The concrete drift found in the audit (`/animals`, `/fairy-tales/popular`) would be caught by the cheap check on day one.

**How the client check works without a build-time dependency on the backend.** `openapi.yaml` is published as a release artifact from `arunika-backend` and vendored into the other two repos under `test/contract/openapi.yaml`, refreshed by a scheduled job that opens a PR when it changes. A stale vendored spec therefore surfaces as a visible PR, not a silent pass. Flutter's check parses `lib/constants/api_paths.dart`'s emitted paths; the backoffice check walks the axios call sites in `src/api/*.ts`.

**Alternatives considered.** Pact (rejected above). Generating clients from the spec (larger change, touches production code, deferred). Snapshot-testing every JSON response (catches drift but produces noisy diffs on every additive change).

### D3. Mobile E2E — `integration_test` by default, Patrol at the native boundary, no Appium or Maestro

| | Flutter support | Native UI | Android CI | iOS | Debugging | Billing sheet | Maintenance |
|---|---|---|---|---|---|---|---|
| `integration_test` | first-party | **none** | good (emulator + KVM) | needs macOS runner | Dart stack traces | **cannot** | lowest |
| **Patrol** | wraps `integration_test` | **yes** (UIAutomator/XCUITest) | good | needs macOS runner | Dart + native logs | yes, on a license-tested build | moderate, small ecosystem |
| Maestro | black-box via a11y | yes | good | yes | YAML; no Dart-level hooks | yes | separate language, no reuse of `mocktail` doubles |
| Appium | via a11y | yes | heavy | yes | poor for Flutter | yes | highest |

**Decision.** Write the bulk of device-level flows with plain `integration_test`, running against a Dockerised backend with `GooglePlayBillingService` stubbed. Adopt **Patrol** only for the small set of flows that must touch native UI: camera/notification permission dialogs, and the Play Billing sheet on a license-tested build. Reject Appium (weight, poor Flutter debugging) and Maestro (a second language, and it cannot inject Dart test doubles, which is what makes the backend-backed flows deterministic).

**Why this split.** `integration_test` cannot dismiss a native dialog, which is fatal for billing — but that is the *only* thing it cannot do here, and paying Patrol's cost for every test to buy a capability three tests need is a bad trade. Tests written for `integration_test` run unchanged under Patrol later if that assumption breaks.

**iOS.** The audit found `ios/` present, but Google Play Billing is Android-only and no App Store release is in flight. iOS device automation is **out of scope**; Flutter unit and widget tests are platform-neutral and already cover the shared logic.

### D4. Google Play testing — three tiers, and the seam that makes tier 1 possible

`services/google_play_verifier.go:25` already reads `ANDROID_PUBLISHER_BASE_URL` from the environment specifically so tests can point verification at an `httptest` server, and `androidPackageName()` reads `ANDROID_PACKAGE_NAME`. This is the key enabler: the backend half of the purchase flow can be exercised against a **fake Android Publisher server** with no Google credentials anywhere.

| Scenario | Tier | How |
|---|---|---|
| Successful purchase → verify → order PAID → entitlement → content unlocked | **Fully automated** | Fake Publisher returns `purchaseState: 0`; real backend, real Postgres |
| Duplicate purchase token → no second entitlement | **Fully automated** | Relies on the real `user_entitlements` unique constraint |
| Invalid / unknown purchase token → rejected, no entitlement | **Fully automated** | Fake Publisher returns an error status |
| `productId` mismatch → rejected | **Fully automated** | Order references product A, token reports product B |
| Package-name mismatch → rejected | **Fully automated** | `ANDROID_PACKAGE_NAME` override |
| Bundle purchase grants every `premium_package_item` | **Fully automated** | Seeded package with 3 items |
| Reinstall → re-login → entitlements still present | **Fully automated** | New device/session, same user, assert `is_unlocked` |
| Subscription renewal / revoke via RTDN | **Fully automated** | POST a crafted RTDN payload to `/payment/play/rtdn` |
| Refund → voided-purchase reconciliation | **Fully automated** | Fake Publisher `voidedpurchases` list |
| Real Play Billing sheet, license-tested account | **Requires Google Play test environment** | Patrol test on an internal-testing track build; nightly/manual, never a PR gate |
| Real card, production purchase, real refund SLA | **Manual** | Release checklist |

**Credentials never enter the repository.** The fake server needs none; the license-tested tier reads a service account from a GitHub Actions secret at runtime only.

### D5. Cross-system E2E lives in `arunika-backend`, driven by docker-compose

`arunika-backend/docker-compose.yml` already builds Postgres, Redis, Flyway, the backend and the backoffice. A `docker-compose.test.yml` overlay adds the fake Android Publisher and points the backend at it. `arunika_app` and `arunika-backoffice` trigger the suite via `repository_dispatch` on merge to their main branches. This is the right home because the backend is the only component every flow passes through, and it already owns the orchestration.

**Docker Compose and Testcontainers, each where it fits.** Testcontainers for `go test` (a developer runs one command, gets a database). Compose for the multi-service E2E stack (the backend and backoffice must be *built and run as images*, which is compose's job, not a test-process concern).

### D6. Coverage ratchets, not a target

No global percentage. Instead, per-package floors that CI enforces, chosen so that critical code is held high and CRUD is not gold-plated:

| Package | Today | Floor |
|---|---|---|
| `arunika-backend/models` (entitlement, order, product, subscription) | **0%** | 80% |
| `arunika-backend/services` (entitlement, payment, order, auth, product) | 62.4% overall | 85% on those five files |
| `arunika-backend/services` (rest) | — | 65% |
| `arunika-backend/middlewares` | 45.1% | 90% |
| `arunika-backend/handlers` | 28.8% | 70% |
| `arunika-backend/utils` | 92.3% | hold 90% |
| `arunika_app` blocs + repositories | — | 80% |
| `arunika-backoffice/src/api` | — | 80% |
| Everything else | — | ratchet only: may not drop below the previous merge |

**What coverage cannot tell us.** That the assertions are meaningful (the current sqlmock tests have high coverage and low value); that the *right* scenarios exist; that two covered components work together; that the schema is correct; that a covered line is correct for inputs the test never supplied. Coverage is a floor against obvious neglect, never evidence of correctness.

### D7. Flaky tests — quarantine, don't retry

- **Detect.** CI records every run to JUnit XML. A nightly job re-runs the full suite on an unchanged commit; anything that changes result between identical commits is flaky by definition.
- **Quarantine.** A flaky test is tagged (`t.Skip` with a tracking issue in Go, `skip:` in Dart, `test.skip` in Vitest) within one working day and moved to a non-blocking job. It keeps running and reporting; it stops blocking merges.
- **Retries.** Permitted **only** in the E2E tier (`--retries 1` in Playwright, one rerun of a failed Patrol/integration_test case), and only because a real device/emulator has genuine nondeterminism. Never in unit, component, database or API tiers — a flaky test there is a real bug in the test or the code, and a retry hides it.
- **Track.** Quarantined tests get an owner and a two-week expiry; at expiry they are fixed or deleted. A permanently quarantined test is worse than no test, because it consumes CI time and trust.
- **Stabilise.** The main sources here will be: waiting on animations instead of state (use `pumpAndSettle` with explicit finders, never fixed sleeps), the backend not being ready (compose healthchecks already exist — use `service_healthy`, not `sleep`), and shared test data (solved by the per-test database isolation in D1).

## Recommended testing architecture

### F. Pyramid

```text
                    Cross-system E2E  ·  7 flows  ·  ~10 min  ·  merge + release
                  /                                        \
       Mobile UI (integration_test/Patrol)          Backoffice E2E (Playwright)
            ~10 flows · ~10 min · merge                ~12 flows · ~4 min · merge
                  \                                        /
                    Contract (OpenAPI)  ·  ~1 pass + 2 checks  ·  <1 min  ·  PR
                                        |
              API integration (real router + Postgres + Redis)
                          ~120 tests · ~5 min · PR
                                        |
                    Database / repository (Testcontainers)
                          ~80 tests · ~3 min · PR
                                        |
              Component (Flutter widget + React Testing Library)
                          ~120 tests · <2 min · PR
                                        |
                  Unit (Go services, Dart blocs/repos, TS api)
                        ~1000 tests (721 today) · <2 min · PR
```

Counts are targets, not quotas. The shape matters more than the numbers: **roughly 70% of tests below the API line, and never more than a dozen flows at the top.**

| Level | Purpose | Framework | What must NOT be tested here |
|---|---|---|---|
| Unit | Branching, calculations, state machines | `testify` + `sqlmock`/`miniredis`; `bloc_test` + `mocktail`; `vitest` | SQL correctness, HTTP wiring, cross-service behaviour |
| Component | One widget/page renders and reacts correctly | `flutter_test`; RTL + `axios-mock-adapter` | Business rules (push down), navigation across screens (push up) |
| Database | Schema, constraints, transactions, query shape | `testcontainers-go` + Flyway | HTTP status codes, auth |
| API | Route + middleware + handler + service + DB as one unit | `httptest` on the real `routes.SetupRouter` | UI concerns, third-party network calls (faked) |
| Contract | Backend and clients agree on paths and shapes | `kin-openapi` | Behaviour — the contract says *shape*, not *semantics* |
| Mobile UI | The app works against a real backend | `integration_test`, Patrol for native | Every screen; only journeys that cross screens |
| Backoffice UI | Admin can complete a publishing flow | Playwright | Field-level validation (push down to RTL) |
| Cross-system | A business outcome holds across all components | Go test driving compose | Anything a lower tier can prove |

### G. Test environments

```text
Local        unit + component            no Docker needed      seconds
             + database + API            Testcontainers        ~1 min extra
             + E2E (on demand)           docker compose up     ~3 min

CI / PR      lint, unit, component, database, API, contract    < 5 min target

CI / merge   everything above
             + backoffice E2E (Playwright, headless Chromium)
             + mobile integration_test (Android emulator, Linux + KVM)
             + cross-system E2E (docker compose + fake Publisher)

Staging      full cross-system E2E against deployed services
             + Play Billing on an internal-testing track (license-tested account)
             + RTDN delivered by real Pub/Sub

Production   smoke only: /health, anonymous content list, login with a
             dedicated canary account, GET /orders for that account.
             No writes, no purchases, no seeded data.
```

### H. Test data

Three mechanisms, each with a distinct job — and **no large static JSON fixtures**, which go stale silently:

1. **Migrations** are the schema source of truth. Tests run the real `db/migrations` via Flyway; a test that needs a column proves the migration adding it exists.
2. **Factories/builders** (`tests/fixtures` in Go, `test/helpers` in Dart) construct valid objects with sensible defaults and explicit overrides — `NewUser(t, db, WithEmail("a@b.c"))`, `NewPackage(t, db, WithItems(3))`. A test states only what it cares about, so adding a required column breaks one factory instead of 200 tests.
3. **The E2E seed set** (`db/seeds/test/`) is a small, versioned, deliberately-named corpus for the compose stack: 3 users (free / entitled-to-one-card / subscriber), 2 AR-card categories, 5 AR cards (3 free, 2 paid), 4 dongeng (2 free, 2 paid), 2 premium packages (one `content` with 3 items, one `subscription` with `duration_days: 30`), and one admin. Named constants, never magic UUIDs.

**Isolation.** Repository tests: per-test transaction, rolled back. API and E2E tests: per-test database cloned from a migrated template. Both allow `t.Parallel()`. No test depends on another test's leftovers, and no test depends on data a human created.

### I. CI pipeline

```text
Pull request  (all three repos, ~5 min budget)
  ├── backend:     golangci-lint · go test ./... (unit) · go test ./tests/db ./tests/api
  ├── app:         flutter analyze · flutter test --coverage
  ├── backoffice:  eslint · vitest run --coverage      [Node 22 via .nvmrc]
  └── all:         contract conformance check · coverage ratchet gate

Merge to main
  ├── everything above
  ├── backoffice: playwright (headless chromium) — 3 publishing flows
  ├── app:        integration_test on Android emulator (reactivecircus/android-emulator-runner)
  ├── backend:    build + push image
  └── dispatch →  arunika-backend: cross-system E2E on docker compose + fake Publisher

Release tag
  ├── deploy to staging
  ├── full cross-system E2E against staging
  ├── Patrol suite on an internal-testing build (license-tested Play account)
  ├── smoke tests
  └── promote to production → smoke tests again
```

**Optimisations.** Jobs are independent and parallel; Go module, pub and npm caches are keyed on lockfiles; the emulator job uses an AVD snapshot cache; `gotestsum --junitfile` / `vitest --reporter=junit` / `flutter test --machine` all emit JUnit XML consumed by `dorny/test-reporter`. On failure: Playwright traces and videos, Patrol/integration_test screenshots, `docker compose logs` for every service, and a dump of the seeded database — all uploaded as artifacts.

### J. Critical E2E scenarios

Of the seven flows, **five become permanent CI gates** and two stay out:

| # | Flow | Tier | CI gate? |
|---|---|---|---|
| 1 | Signup → OTP → login → create child → home → browse | Cross-system | **Yes** (merge) |
| 2 | Login → browse dongeng → open free dongeng → record play | Cross-system | **Yes** (merge) |
| 3 | Login → browse paid AR card → Play purchase → verify → entitlement → open card | Cross-system, fake Publisher | **Yes** (merge) — highest value in the suite |
| 4 | Buy `content` bundle → all `premium_package_items` granted → each card accessible | Cross-system, fake Publisher | **Yes** (merge) |
| 5 | Admin creates + publishes content → app sees it | Cross-system (backoffice + app API) | **Yes** (merge) |
| 6 | Access token expires → refresh → request continues | API tier, not E2E | **Yes** (PR) — cheaper one level down |
| 7 | Logout → protected API rejected (Redis revocation) | API tier, not E2E | **Yes** (PR) — cheaper one level down |

Flows 6 and 7 are deliberately demoted: they need no UI and no compose stack, so proving them at the API tier is faster and more reliable for identical confidence. That is the principle throughout — **prove it at the cheapest level that can actually prove it.**

### K. Folder structure

```text
arunika-backend/
  .github/workflows/{pr.yml,merge.yml,release.yml,nightly.yml}
  openapi.yaml                      # contract source of truth
  docker-compose.test.yml           # overlay: fake publisher + test seeds
  db/seeds/test/                    # deterministic E2E corpus
  services/*_test.go                # unit (sqlmock retained where DB is incidental)
  handlers/*_test.go                # unit
  tests/
    fixtures/                       # factories/builders + container bootstrap
    db/                             # Testcontainers: models, constraints, migrations
    api/                            # real router + Postgres + Redis
    contract/                       # response validation against openapi.yaml
    security/                       # authn/authz regression
    e2e/                            # docker-compose-driven cross-system flows
    fakes/androidpublisher/         # fake Play API server

arunika_app/
  .github/workflows/{pr.yml,merge.yml}
  test/                             # existing 41 files, unchanged layout
    helpers/                        # shared factories + mock registration
    contract/openapi.yaml           # vendored, auto-PR'd on change
  integration_test/
    flows/                          # app against a Dockerised backend
    patrol/                         # native-UI flows only

arunika-backoffice/
  .nvmrc                            # 22
  .github/workflows/{pr.yml,merge.yml}
  src/test/{api,pages,components}/  # existing layout, extended
  e2e/                              # Playwright publishing flows
```

**Naming.** Go: `Test<Unit>_<Scenario>_<Expectation>` — matches what is already there (`TestPaymentService_VerifyPlayPurchase_TokenReused`). Dart and TypeScript: `should_<expectation>_when_<condition>` as the test description — `should_reject_purchase_when_token_is_invalid`, `should_restore_entitlement_after_relogin`, `should_create_ar_card_when_request_is_valid`.

### L. What stays manual

| Area | Why automation would lie | How it is covered instead |
|---|---|---|
| AR surface detection, plane tracking, 3D placement | Emulators have no camera and no real ARCore; an emulator AR test passes or fails for reasons unrelated to the code | Device checklist per release on 2–3 reference phones. The **automatable part is split out**: QR payload → AR-card lookup, entitlement gate before AR launch, and asset-URL resolution are all pure logic and belong in unit + API tests |
| Real-world QR scanning (print quality, lighting, angle) | Physical variables | Printed-card checklist; `GET /ar/printable-pdf` content is asserted automatically |
| Google Play production purchase and refund | Cannot be done without real money and real Play accounts | Release checklist on the internal-testing track |
| Visual design, animation feel, child-friendly UX | Judgement, not assertion | Design review; the automated guard is the existing overflow/layout widget tests (e.g. `error_sheet_test.dart` asserting no overflow on a narrow phone) |
| Audio quality and mixing | Judgement | Automated check is limited to "audio URL resolves and playback state advances" |

The combination that works: automated tests prove the *system* is correct, and a short human checklist proves the *experience* is good. The checklist stays short precisely because automation covers everything it can.

### M. Representative examples

Sketches only — implementation happens after approval. Each uses patterns already present in the repos.

**Go unit (keep `sqlmock` where the DB is incidental)** — extends the existing `services/entitlement_service_test.go` style:

```go
func TestComputeSubscriptionExpiry_ActiveSub_ExtendsFromCurrentExpiry(t *testing.T) {
    now := time.Date(2026, 9, 23, 0, 0, 0, 0, time.UTC)
    current := now.AddDate(0, 0, 10)
    got := computeSubscriptionExpiry(now, &current, 30)
    assert.Equal(t, now.AddDate(0, 0, 40), got) // never loses the unused 10 days
}
```

**Go database test (new — real Postgres, proves the constraint)**:

```go
func TestGrantEntitlement_SameUserAndProductTwice_IsIdempotent(t *testing.T) {
    db := fixtures.FreshDB(t)                      // template clone, migrations applied
    user := fixtures.NewUser(t, db)
    product := fixtures.NewProduct(t, db)
    order := fixtures.NewPaidOrder(t, db, user, product)

    require.NoError(t, models.GrantEntitlement(db, user.ID, product.ID, &order.ID))
    require.NoError(t, models.GrantEntitlement(db, user.ID, product.ID, &order.ID))

    var count int64
    db.Model(&models.UserEntitlement{}).
        Where("user_id = ? AND product_id = ?", user.ID, product.ID).Count(&count)
    assert.Equal(t, int64(1), count) // enforced by the real UNIQUE index, not a mock
}
```

**Go API test (new — real router, real DB, fake Play)**:

```go
func TestVerifyPlayPurchase_ValidToken_GrantsEntitlementAndUnlocksCard(t *testing.T) {
    env := fixtures.NewAPIEnv(t)                   // router + Postgres + miniredis + fake publisher
    env.FakePlay.PurchaseStateFor("token-abc", services.PlayPurchaseStatePurchased)

    user := env.SeedUserWithToken(t)
    card := env.SeedPaidArCard(t)
    order := env.SeedPendingPlayOrder(t, user, card.ProductID)

    res := env.POST(t, "/payment/play/verify", user.Token, gin.H{
        "order_id": order.ID, "purchase_token": "token-abc",
    })
    require.Equal(t, http.StatusOK, res.Code)

    card = env.GET(t, "/ar/cards/"+card.ID.String(), user.Token).ArCard()
    assert.True(t, card.IsUnlocked)
}
```

**Flutter unit** — matches the existing `bloc_test` + `mocktail` style in `test/presentation/screens/**`:

```dart
blocTest<PremiumPackCubit, PremiumPackState>(
  'should_emit_error_when_repository_throws',
  setUp: () => when(() => repo.getPacks()).thenThrow(DioException(...)),
  build: () => PremiumPackCubit(repo),
  act: (cubit) => cubit.loadPacks(),
  expect: () => [isA<PremiumPackLoading>(), isA<PremiumPackError>()],
);
```

**Flutter widget** — extends the existing `collection_screen_test.dart` pattern:

```dart
testWidgets('should_show_lock_badge_when_card_is_not_entitled', (tester) async {
  await tester.pumpWidget(wrap(CollectionScreen(), bloc: stubbedWith(lockedCards)));
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('ar-card-lock-badge')), findsOneWidget);
});
```

**Flutter integration test (new — real backend, stubbed billing)**:

```dart
testWidgets('should_unlock_card_after_successful_purchase', (tester) async {
  await bootApp(tester, billing: FakeBilling.succeedsWith('token-abc'));
  await signIn(tester, TestUsers.free);
  await tester.tap(find.text('Harimau'));            // a paid card
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('buy-button')));
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('ar-launch-button')), findsOneWidget);
});
```

**Backoffice component test** — extends the existing `src/test/pages/*` + `axios-mock-adapter` pattern:

```tsx
it('should_disable_submit_when_title_is_empty', async () => {
  render(<ArCardsPage />, { wrapper: withQueryClient });
  await userEvent.click(screen.getByRole('button', { name: /tambah/i }));
  expect(screen.getByRole('button', { name: /simpan/i })).toBeDisabled();
});
```

**Cross-system E2E (new)**:

```go
func TestBundlePurchase_GrantsEveryPackageItem(t *testing.T) {
    stack := e2e.Up(t)                              // docker compose + test seeds
    user := stack.SignUpAndLogin(t)
    pkg := stack.Seed.ContentPackageWith3Items

    order := stack.CreatePlayOrder(t, user, pkg)
    stack.FakePlay.Purchased("token-bundle")
    stack.VerifyPlayPurchase(t, user, order, "token-bundle")

    for _, productID := range pkg.ProductIDs {
        assert.True(t, stack.HasAccess(t, user, productID),
            "product %s should be unlocked by the bundle", productID)
    }
}
```

## Risks / Trade-offs

- **Docker becomes a hard dependency for the full local suite.** → The unit and component tiers stay container-free, so the fast loop is unaffected; `make test-fast` vs `make test-all`.
- **Pinning Node 22 breaks the current machine's workflow.** → `.nvmrc` plus a one-line `nvm use`; the alternative (downgrading vitest) freezes the stack and was rejected.
- **Migrating entitlement tests off `sqlmock` is churn in already-passing tests.** → Done file-by-file in Phase 2, with the old test deleted only once the replacement proves the same scenario against real Postgres. Net test count should not drop.
- **Emulator jobs are slow and the most likely source of flakiness.** → Confined to the merge tier (never PR), AVD snapshot cached, and covered by the quarantine policy in D7.
- **The vendored `openapi.yaml` in the client repos can go stale.** → The refresh job opens a PR rather than committing silently, so staleness is visible.
- **The seven-phase roadmap is large and could stall halfway.** → Phases are ordered so each delivers standalone value: Phase 1 alone (CI + Node pin) already converts 721 unenforced tests into 721 enforced ones, which is the single largest confidence gain in the plan.

## Migration Plan

Phases run in the order given in `tasks.md`. Each phase is independently mergeable and leaves every suite green. No production behaviour changes at any point; the only non-test source edit is the Flutter billing seam in Phase 5. Rollback for any phase is deleting the added test directory and workflow file — nothing else depends on them.

## Open Questions

- Should the coverage ratchet **block** merges from the start, or report-only for the first two weeks while the floors are calibrated against real numbers? (Recommendation: report-only for Phase 1, blocking from Phase 2.)
- `arunika-backoffice`'s git remote currently points at `arunika-backend.git`. This must be corrected before its workflow runs in the right repo — is that remote wrong, or is the backoffice genuinely expected to live in the backend repo?
- The Midtrans webview flow still exists alongside Play Billing. Is it still a supported path for the Play Store build (and therefore owed E2E coverage), or is it legacy kept only for existing web users?
- Is there an existing staging environment, or does Phase 6's staging tier need one stood up first?
