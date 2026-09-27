# Automation testing — what exists and how to run it

Covers all three repos. The rationale lives in
`openspec/changes/add-automation-testing-strategy/` (`design.md`, `tasks.md`);
this page is the operating manual.

Repos are expected side by side (the E2E stack builds the backoffice from a
sibling directory):

```
Projects/
├── arunika_app          Flutter app        (this repo)
├── arunika-backend      Go API
└── arunika-backoffice   React admin
```

## The tiers

| Tier | Where | Needs | Runs in CI |
|---|---|---|---|
| Unit / widget / component | all three repos | nothing | every pull request |
| API + DB (real Postgres via Testcontainers, miniredis) | `arunika-backend/tests/{api,db,contract}` | Docker | every pull request |
| **Security regression** | `arunika-backend/tests/security` | Docker | every pull request (part of `go test ./...`) |
| Cross-system E2E (real docker-compose stack) | `arunika-backend/tests/e2e` | Docker | on merge (`merge.yml`) |
| Admin E2E (Playwright, headless Chromium) | `arunika-backoffice/e2e` | the E2E stack | on merge (`merge.yml`) |
| App integration on an Android emulator | `arunika_app/integration_test` | the E2E stack + emulator | on merge (`merge.yml`) |
| Native permission dialogs (Patrol) | `arunika_app/patrol_test` | emulator | nightly (`nightly.yml`) |
| Flaky-test detection | `arunika-backend/scripts/flaky_detect.py` | Docker | nightly (`nightly.yml`) |
| Deployed-environment smoke | `arunika-backend/tests/smoke` | a URL + canary account | manual / release |

## Running it locally

Docker must be running for anything marked Docker. Nothing needs a real Google
credential — `fixtures.FakePlay` stands in for the Play Developer API.

### Every-day loop

```bash
# app
cd arunika_app && make test-fast          # flutter test
# backend
cd arunika-backend && make test-fast      # go test ./...   (includes tests/security)
# backoffice
cd arunika-backoffice && npm test         # vitest
```

### Exactly what a pull request runs

```bash
cd arunika_app         && make test-all   # needs: dart pub global activate junitreport
cd arunika-backend     && make test-all   # needs gotestsum v1.13.0 + golangci-lint v2.13.2
cd arunika-backoffice  && make test-all   # Node 22 (see .nvmrc)
```

`test-all` also runs the coverage ratchet. After an intentional coverage change:
`make coverage-baseline` in the affected repo.

### Just the security suite

```bash
cd arunika-backend
go test ./tests/security/ -count=1 -v
go test ./tests/security/ -count=1 -run 'EveryAdminRoute' -v    # one test
```

What it proves (34 tests): forged/expired/wrong-key/`alg:none` tokens are
rejected; logout kills the access and refresh token; refresh replay fails;
user A cannot read or change user B's orders, notifications, history or
child's growth records; every `/admin/*` route (found by reading the live route
table, so new routes are covered automatically) returns 403 to a user token;
purchase tokens cannot be swapped, replayed or reused across accounts; SQL
metacharacters are inert; no route answers hostile input with a 500 or leaks
SQL, paths or stack traces; login and forgot-password do not reveal which
accounts exist.

### Cross-system E2E, admin Playwright, app on an emulator

The E2E stack (Postgres, Redis, Flyway, backend, backoffice) is started by a Go
test. Run all flows once, or hold the stack up for the other suites:

```bash
cd arunika-backend
make test-e2e                # run the flows and tear down
make e2e-hold                # keep it up: API :8090, backoffice :3010 (Ctrl-C to stop)
```

While `e2e-hold` prints `E2E STACK READY`, in another terminal:

```bash
# Admin Playwright flows (first time: npx playwright install chromium)
cd arunika-backoffice && npm run e2e

# App flows on a running Android emulator (10.0.2.2 = the host, from the emulator)
cd arunika_app && scripts/run_integration.sh emulator-5554 http://10.0.2.2:8090 artifacts
```

> The stack builds several images. On a memory-constrained machine give Docker
> at least 6 GB and close other heavy apps first — running it alongside an
> Android emulator and an IDE has crashed a 16 GB laptop before.

### Patrol (native permission dialogs)

```bash
dart pub global activate patrol_cli
cd arunika_app && patrol test --target patrol_test/native_permissions_test.dart
```

### Smoke suite against a deployed environment

Read-only: no seeding, no purchases. Uses a dedicated canary account.

```bash
cd arunika-backend
SMOKE_BASE_URL=https://api.example.com \
SMOKE_CANARY_EMAIL=canary@example.com SMOKE_CANARY_PASSWORD=... \
go test -tags smoke ./tests/smoke/ -count=1 -v
```

Without the canary variables only the anonymous checks run.

### Flaky detection

```bash
cd arunika-backend
for i in 1 2 3; do gotestsum --junitfile reports/nightly-$i.xml -- -race -count=1 ./... ; done
python3 scripts/flaky_detect.py reports/nightly-*.xml
```

Exit 1 lists tests that passed *and* failed on the same commit (flaky) and
tests that failed every run (broken) separately. Quarantine policy: see each
repo's README "Flaky tests" section.

## CI workflows

| Repo | File | Trigger | What |
|---|---|---|---|
| all three | `.github/workflows/pr.yml` | pull request | lint/analyze + tests + coverage ratchet |
| backend | `merge.yml` | push to master, `app-merged` / `backoffice-merged` dispatch | cross-system E2E |
| backoffice | `merge.yml` | push, `backoffice-merged` dispatch | Playwright against the stack |
| app | `merge.yml` | push, `app-merged` dispatch | integration flows on an emulator |
| backend | `nightly.yml` | 02:00 WIB, manual | 3× full suite + flaky comparison |
| app | `nightly.yml` | 03:00 WIB, manual | Patrol on an emulator |

Cross-repo checkouts use the `CROSS_REPO_TOKEN` secret, falling back to the
workflow token (which only works if all three repos are public or the token has
access). **None of the merge or nightly workflows has run on GitHub yet** —
trigger each once with *Run workflow* and fix what the first real run shows.

## Adding to the suite

- **A new backend route** needs nothing for admin-escalation and leakage
  coverage; both walk the route table. Add a horizontal-escalation test in
  `tests/security/authz_test.go` if the route returns per-user data.
- **A defect you can't fix immediately:** write the test for the *correct*
  behaviour, then `t.Skip("KNOWN VULNERABILITY: … ")` with the location. Never
  weaken the assertion. Delete the skip in the fix.
- **Test helpers:** `tests/fixtures` (builders, `FreshDB`, `FakePlay`) for Go;
  `test/helpers` (`registerTestDependencies`, `FakeBilling`) for Flutter.

## Known gaps

- **App emulator flows are not green yet** (`tasks.md` 6.17): real overflows in
  `new_home_screen.dart` and `payment_screen.dart`, a `TextStyle` `inherit`
  mismatch, and content lookups that need scrolling.
- **Play Billing with a licence-tested account** needs a real internal-testing
  build on a device; it is a manual release step.
- **No staging deploy pipeline** (`tasks.md` 7.7): the repos contain no deploy
  mechanism, so `release.yml` was descoped. The smoke suite is ready to be
  pointed at staging and production once that exists.
- `refresh_tokens.expires_at` is a zoneless `TIMESTAMP`; expiry is only correct
  when the server runs in UTC.
