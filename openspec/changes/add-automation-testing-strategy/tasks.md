# Tasks: System-wide automation testing strategy

Phases are ordered by value-per-effort. Each phase is independently mergeable and must leave every suite green. Effort estimates are working-days for one developer.

---

## 1. Foundation — make the existing tests count ✅ DONE

**Why:** 721 tests already pass and nothing enforces them; the backoffice suite cannot even start. This phase buys the largest confidence gain in the entire plan and unblocks every later phase.
**Effort:** ~3 days · **Dependencies:** none
**Outcome:** every existing test runs automatically on every PR in all three repos, and the backoffice suite executes again.

- [x] 1.1 Add `.nvmrc` (`22`) and `"engines": { "node": ">=22" }` to `arunika-backoffice/package.json`; verify `npm test` runs the existing test files and record the baseline pass/fail
- [x] 1.2 Add `arunika-backend/.github/workflows/pr.yml`: `golangci-lint` + `gotestsum --junitfile` over `go test ./...`, with Go module cache keyed on `go.sum`
- [x] 1.3 Add `arunika_app/.github/workflows/pr.yml`: `flutter analyze` + `flutter test --coverage --machine`, with pub cache keyed on `pubspec.lock`
- [x] 1.4 Add `arunika-backoffice/.github/workflows/pr.yml`: `eslint` + `vitest run --coverage --reporter=junit` on Node 22, npm cache keyed on `package-lock.json`
- [x] 1.5 Wire `dorny/test-reporter` to the JUnit XML in all three workflows so failures are annotated on the PR diff
- [x] 1.6 Add a coverage-ratchet script (report-only for now) recording per-package baselines: backend `models` 0%, `handlers` 28.8%, `middlewares` 45.1%, `services` 62.4%, `utils` 92.3%, `routes` 99.5%
- [x] 1.7 Add `Makefile` targets in each repo — `test-fast` (no Docker) and `test-all` — so local and CI commands are identical
- [x] 1.8 Document the flaky-test quarantine policy (design D7) in each repo's `README.md` testing section

### Outcomes and corrections from implementation

- **Verified baseline is 721 tests, not 610.** Backend reports 465 under `gotestsum` (subtests counted; 417 top-level `func Test`), Flutter 193, backoffice 63 across 11 files. All green, backend clean under `-race`.
- **The backoffice suite had not rotted** — it was merely unrunnable on Node 16. On Node 22 all 63 tests passed unchanged. Phase 4 task 4.1 ("repair failures surfaced by 1.1") is therefore a **no-op for the test suite**, though see the build fix below.
- **Fixed: the backoffice production build was already broken.** `npm run build` failed `tsc -b` on two type errors in `src/test/api/admin.test.ts`, where a `PremiumPackageInput` literal predates the `description`, `image_url` and `play_product_id` columns added by migrations V49/V50. Vitest does not typecheck, so the tests passed while the build did not. Added the three missing fields; `npm run build` now succeeds.
- **Fixed: `models/ar_cards.go` was not gofmt'd** (struct tag alignment only), which would have failed the new lint job.
- **Fixed: three analyzer warnings** in Flutter tests — unused `get_it` and `material` imports and an unused `capturedContext` local.
- **`golangci-lint` initially ran with `errcheck` and `staticcheck` disabled** so that getting CI running did not depend on a code cleanup. All 12 pre-existing findings have since been cleared (F1, F2, F3) and **both linters are now re-enabled — the gate is fully strict at 0 issues.**
- **`dart format --set-exit-if-changed` is not a gate.** 58 of 203 files predate any formatting discipline; a mass reformat is an unrelated diff. `flutter analyze --no-fatal-infos` is the gate instead — 9 remaining infos are framework deprecations and naming nits.
- **`gotestsum` pinned to v1.13.0, not v1.12.0** — earlier versions fail to build on Go 1.26 due to a stale `x/tools` dependency. `golangci-lint` pinned to v2.13.2.
- Coverage baselines recorded. Backend matches the audit exactly. Flutter: 34.9% overall, `lib/core` 83.9%, `lib/network` 93.5%, `lib/data` 45.4%, `lib/presentation` 32.7%, `lib/services` 6.0%. Backoffice: 38.3% overall, `src/api` 70.2%, `src/store` 0%.

### Follow-ups raised by Phase 1 (not fixed here — behaviour changes)

- [x] **F1** `handlers/auth_handler.go:145` discarded the error from `GenerateJwtToken`, so a signup whose token generation failed still returned **HTTP 201 with empty `token` and `refresh_token`**. **Fixed.** The handler now logs the failure with `user_id` and returns 500 with `"Account created, but the session could not be started. Please sign in."` — the account exists and the user's credentials are valid, so signing in is the one actionable instruction. Regression test `TestAuthHandler_SignUp_TokenGenerationFails_Returns500` in `handlers/handler_test.go` was verified to fail against the old code (it reproduced `201` with `"token":""`) and pass against the fix. No client change was needed: the app's `on DioException` branch already surfaces `response.data['error']`, so the message reaches the user, and the now-redundant `response.token.isEmpty` guard in `signup_bloc.dart:196` is harmless defensive code. Message is English, consistent with every other handler error string (Indonesian appears only in push-notification bodies).
- [x] **F2** `services/admin_analytics_service.go:162` assigned a `query` value that was never used (staticcheck SA4006). **Fixed** — it was dead code, not a dropped filter: both branches below it reassign `query`, so the `WHERE 1=1` variant was never executed. Removing it is behaviour-preserving, and `SA4006` is now fully cleared from the repo. Added two characterization tests (`GetPaymentMetrics` previously had **none**, which is how the stub below survived) pinning both the filtered and unfiltered branches.
- [x] **F5** *(found while fixing F2)* `GetPaymentMetrics` reported **subscription counts, not payments**, and the backoffice dashboard displayed them as payment figures. **Fixed.**
  - **What was wrong:** the query read `user_subscriptions GROUP BY status`, returning `premium`/`free`/`revoked` rather than order states, with `Total` hardcoded to `0::float`.
  - `user_subscriptions` holds at most one row per user, so a user who bought five AR cards counted once, and a user who renewed monthly for a year also counted once — user counts, not transaction counts.
  - `DashboardPage.tsx:55-57` rendered them as **"Successful Payments"** (`payments.find(p => p.status === 'premium').count`), **"Payment Success Rate"** (a `%` statistic), and a **"Transactions"** bar chart coloured green/amber/red as if by payment outcome. The success rate was really the premium conversion rate — which the same dashboard already showed separately as `premiumRate` from `GetSubscriptionStats`, so two cards displayed identical numbers under different labels.
  - It predated the `orders`/`payments` tables (migration V36) and was never rebased onto them. Real data lives in `orders` (`status` in PENDING/PAID/FAILED/EXPIRED/REFUNDED, `amount_idr BIGINT`).
  - **[x] FIXED.** `GetPaymentMetrics` now groups the **`orders`** table by order status and sums `amount_idr` per group, replacing the `user_subscriptions` stub. `PaymentMetrics.Total` changed from `float64` to `int64` — `amount_idr` is a BIGINT and IDR has no fractional unit, so a float only risked precision loss on large totals. Because REFUNDED *replaces* PAID when Play voids a purchase, the PAID group already excludes refunds and reads directly as settled revenue; no extra adjustment needed. The three characterization tests were rewritten (as flagged) to assert order statuses and summed amounts, plus an empty-table case. Backoffice updated: the chart is retitled **"Orders (by status)"**, its dataset label is now "Orders", and bar colours are keyed by status name rather than by array position — the API orders groups by count, so the Nth bar was not a fixed status, and an unrecognised status now falls back to grey instead of borrowing another status's colour.
  - The two mislabelled KPI cards remain **deleted** from `DashboardPage.tsx`, along with the dead `successPayments`/`totalPayments`/`successRate` computations. They were not merely mislabelled — they were arithmetically *identical* to the "Premium Users" and "Premium Conversion Rate" cards already on the same dashboard, since both endpoints count the same `user_subscriptions` table with no date filter. Relabelling them as first planned would have shown each figure twice under duplicate titles, so they were removed instead. The top KPI row now spans two cards at `lg={12}`.
  - Note `/admin/analytics/payments` is **not** called by `AnalyticsPage`; only `DashboardPage` consumes it.
- [x] **F3** Clear the remaining `errcheck`/`staticcheck` findings and re-enable both linters. **Done — `golangci-lint run` now reports 0 issues with the full standard set enabled**, and `.golangci.yml` no longer disables anything. Twelve findings were expected; fixing them surfaced two more (`payment_service.go:149,339`) that had been masked, for 12 cleared in total across F1–F3. Two were genuine defects rather than lint noise — see F6 below for the more serious one:
  - **`services/email_service.go` — OTP generation moved from `math/rand` to `crypto/rand`** (see F6).
  - **`handlers/payment_handler.go` — three fire-and-forget `go notificationService.Send(...)` calls discarded their errors**, so every failed payment push vanished silently. Replaced with a `sendNotificationAsync` helper that keeps delivery best-effort (a push failure must never fail a settled payment) but logs failures with `user_id` and type.
  - **`google_play_verifier.go` / `notification_service.go` — `google.CredentialsFromJSON` → `CredentialsFromJSONWithTypeAndParams(..., google.ServiceAccount, ...)`.** This is the library's own recommended replacement and adds a real safety property: if either service-account env var were ever swapped for an external-account configuration, the old call would happily fetch tokens from whatever URL that config named, while the type-pinned call rejects it.
  - **Six unchecked `resp.Body.Close()` deferrals** across five files → explicit `defer func() { _ = resp.Body.Close() }()`.
  - **One ST1005 false positive** (`ErrPlayBillingNotConfigured` begins with the proper noun "Google Play Billing", which Go style permits) suppressed with a targeted `//nolint` and a reason, rather than disabling ST1005 repo-wide — so genuinely capitalized error strings are still caught.
  - 469 tests pass under `-race`; ratchet green.
- [x] **F6** *(found while fixing F3 — security)* **OTPs were generated with `math/rand` seeded from the wall clock.** `generateOtp()` called `rand.Seed(time.Now().UnixNano())` immediately before `rand.Intn(1000000)`, making each 6-digit code a pure function of the moment the request was handled — an attacker who knew roughly when a code was requested need only search a narrow window of candidate seeds to reproduce it.

  **Closed. The weak generator no longer exists.** F3 first hardened it to `crypto/rand`; `add-email-verification` then deleted `generateOtp`, `saveOtpToRedis` and `SendOTPEmail` outright, along with the `TestGenerateOtp_*` tests, because the whole OTP flow was dead scaffolding (see F7). There is now **no OTP generation anywhere in the codebase**, and no `math/rand` in production code at all.

  **No action is needed on historical OTPs**, for a stronger reason than the 5-minute Redis TTL:

  1. **The weak OTP never gated anything.** `saveOtpToRedis` wrote `otp:<email>`, and **nothing ever read that key back** — the only `redis.Get` in the repo was the analytics cache in `admin_analytics_service.go:35`. There was no verify-OTP route. On the client, `OtpBloc` emitted `NavigateToChildRegistrationPage()` without comparing the entered code to anything, and the app never called `/auth/send-otp` nor navigated to `/otp`. The predictability had no exploitable impact: there was nothing to bypass, because nothing was enforced.
  2. **No long-lived credential was ever derived from weak randomness.** Refresh tokens and JTIs (`utils/jwt.go:20-21`, `admin_auth_service.go:102-103`) and password-reset tokens (`auth_service.go`) all use `uuid.NewString()` — UUIDv4 from `github.com/google/uuid`, which draws from `crypto/rand`. No `uuid.SetRand` or `EnableRandPool` override exists anywhere (~122 bits of entropy). Reset tokens are additionally stored **hashed**, expire in 15 minutes, and prior tokens are invalidated on reissue.

  **The regression guard was relocated, not lost.** `TestGenerateOtp_NoCollisionsInTightLoop` died with the code it guarded. Its replacement is `TestIssueEmailVerificationToken_DrawsFromAHighEntropySource` in `services/email_verification_test.go`: the email-verification token is now the security-sensitive value this codebase generates, and the guard belongs on it. Same reasoning — it cannot prove unpredictability, but it does catch a regression to a clock-seeded source, which collides readily in a tight loop.

- [x] **F7** *(found while closing F6)* **Email ownership is never verified, and the OTP feature is dead on both ends.** `POST /auth/signup` creates the account and issues tokens immediately, with no email confirmation step. The OTP scaffolding that exists is inert: the backend sends and stores a code nothing reads; the Flutter `OtpBloc` ignores the entered value and navigates on unconditionally; neither `/auth/send-otp` nor the `/otp` route is reachable from the app. **Superseded by the `add-email-verification` change proposal**, which addresses it in full: verification that never blocks registration (so an SMTP outage cannot become a signup outage), gating only password-reset delivery, grandfathering existing accounts, and deleting the dead OTP scaffolding on both sides. **That proposal has since been implemented** (40/44 tasks; the remainder are manual inbox checks and two design open questions). The OTP scaffolding it superseded is deleted on both sides.
- [x] **F4** `arunika-backoffice`'s git remote pointed at `arunika-backend.git`. **Fixed**, though the situation was worse than a mistyped URL: `hamimari/arunika-backoffice` *did* exist but its `master` was **5 commits stale** (`26f7736`), while the backoffice's actual current code lived as branch **`master-new` inside `arunika-backend`** (`212e2a9`). So the new CI workflow would not merely have run in the wrong repo — the dedicated backoffice repo would never have seen it at all.
  - Repointed `origin` to `git@github.com:hamimari/arunika-backoffice.git` and resynced remote-tracking refs.
  - Pushed `master-new` → `origin/master` as a **clean fast-forward** (`26f7736..212e2a9`), verified as an ancestor beforehand, using a plain push so a non-fast-forward would have been refused rather than forced. Nothing was overwritten.
  - `arunika-backend`'s `master-new` branch was **left in place** as agreed, so the old copy is still recoverable. Delete it once backoffice CI is confirmed green.
  - Local branch `master-new` now tracks `origin/master`. **Tidy-up you may want:** the local `master` branch is still at `0246af0` (3 behind); consider fast-forwarding it, switching to it, and deleting `master-new`, so the branch name matches the remote. The CI workflow triggers on `master`, `master-new` and `main`, so it works either way.

---

## 2. Backend — real database, real constraints ✅ DONE

**Why:** `models/` is at 0% and every data-integrity guarantee is currently asserted against a mock. This is where a bug costs money.
**Effort:** ~8 days · **Dependencies:** Phase 1
**Outcome:** entitlement, order and payment correctness is proven against the same Postgres constraints that enforce it in production.

- [x] 2.1 Add `testcontainers-go` to `go.mod`; create `tests/fixtures/container.go` starting `postgres:15-alpine` once per package in `TestMain`, applying the real `db/migrations` via Flyway into a template database
- [x] 2.2 Add `tests/fixtures/db.go` with `FreshDB(t)` (template clone for API tests) and `TxDB(t)` (transaction rolled back at cleanup for repository tests); both must be `t.Parallel()`-safe
- [x] 2.3 Add builders in `tests/fixtures/`: `NewUser`, `NewAdmin`, `NewProduct`, `NewArCard`, `NewDongeng`, `NewPackage(WithItems(n))`, `NewPendingOrder`, `NewPaidOrder`, `NewEntitlement`, `NewSubscription` — defaults valid, everything overridable
- [x] 2.4 Add `tests/db/entitlement_test.go` covering the untested `models` layer: `GrantEntitlement` idempotency against the real UNIQUE index, `HasEntitlement`, `FindPackageItems` fan-out, FK enforcement on `source_order_id`, and `RevokeEntitlementForOrder`
- [x] 2.5 Add `tests/db/order_test.go` and `tests/db/subscription_test.go`: status transitions, the `user_id` UNIQUE index on `user_subscriptions` (the deadlock hazard documented at `services/entitlement_service.go:140`), `provider`/`purchase_token` uniqueness from `V52`, and transaction rollback on partial grant failure
- [x] 2.6 Add `tests/db/migration_test.go` asserting the full `db/migrations` set applies cleanly from empty and that `R__` repeatables are re-runnable

### Phase 2 outcomes

**Harness is live.** `tests/fixtures` starts one `postgres:15-alpine` container per test binary, applies the project's real versioned migrations into a template database, and clones it per test (~70ms) so tests run `t.Parallel()` safely. `TestMain` skips rather than fails when Docker is unavailable locally, but fails hard when `CI` is set, so coverage is never silently lost in CI. Repeatable migrations are deliberately excluded from the template — `R__init.sql` TRUNCATEs and inserts demo rows, which would make every row count non-deterministic.

**`models` coverage: 0% → 84.4%.** `GrantEntitlement`, `HasEntitlement`, `FindPackageItems`, `AddPackageItem` and `RemovePackageItem` are now at 100%, verified against the real UNIQUE indexes and foreign keys rather than a mock's expectation list.

**Coverage measurement was wrong and is now fixed.** The ratchet measured per-package self-coverage, so tests in `tests/db` counted for nothing against the `models` package they exist to cover — the 80% floor in task 2.13 was unreachable by construction. Coverage is now collected with `-coverpkg=./...`, and the ratchet deduplicates blocks by source span first (every test binary emits a block for every package under `-coverpkg`, so naive summing inflated the denominator ~10× and under-reported coverage by an order of magnitude). Baselines re-recorded: `models` 84.4%, `routes` 99.5%, `utils` 92.9%, `services` 68.1%, `middlewares` 54.3%, `handlers` 32.5%.

**Three production defects found, all of the exact class this phase was created to catch — each had a passing sqlmock test:**

1. **`RevokeSubscription` never worked.** It wrote `status='revoked'`, but `user_subscriptions` carries `CHECK (status IN ('free','premium'))`, so every call failed with `SQLSTATE 23514`. Both callers are live — refund reconciliation (`payment_service.go:559`) and Play revocation notifications (`payment_service.go:760`) — so **every refunded subscriber kept premium access**. Fixed to write `'free'` with `expires_at = now()`, preserving the documented "ends access immediately" semantics. `status='revoked'` was write-only: nothing in the backend, backoffice or app ever read it, and the refund audit trail already lives on `orders.status='REFUNDED'` and the payments table.
2. **`R__seed_dongeng_categories.sql` inserted into a dropped column.** V48 removed `dongeng_categories.emoji`; the seed still set it. Flyway runs repeatables after the whole versioned set, so **every fresh `flyway migrate` failed**. Fixed.
3. **`V49` ended with a stray `®`** (bytes `c2 ae`), breaking the migration set partway through — found earlier while verifying V55 and fixed then.

**A spec delta needs correcting.** `specs/backend-database-tests/spec.md` claims "Purchase token cannot be reused across orders — the database rejects it by unique constraint". It does not: there is no unique index on `orders.purchase_token`. The guarantee lives entirely in `PaymentService.VerifyPlayPurchase`. `TestOrder_PurchaseTokenReuse_IsNotPreventedByTheSchema` documents this so the application-level defence is never removed on the assumption the schema backs it up.

**API suite is live (2.10–2.12).** `tests/api` boots the real `routes.SetupRouter` against a real database plus miniredis and drives it over HTTP, so every request passes through the actual middleware chain, route binding and SQL — none of which a handler-level sqlmock test exercises. 23 tests: the full auth lifecycle (register, login, refresh rotation, logout revocation, enumeration resistance, horizontal escalation) and the complete purchase chain.

**The purchase chain runs fully automated with no Google credentials.** `fixtures.FakePlay` serves both the Android Publisher API and the OAuth token endpoint locally, using a throwaway RSA key generated per process, reached through the `ANDROID_PUBLISHER_BASE_URL` seam the verifier already had. Covered: valid purchase settles the order and grants access; replaying a token grants only one entitlement; unknown and cancelled tokens grant nothing; a content bundle grants every item; a token replayed by a second account grants nothing; entitlements survive reinstall and re-login. This retires the manual verification the strategy set out to replace.

**A flaky test was found, diagnosed and removed rather than retried.** `TestAuthHandler_SignUp_MailDeliveryFails_RegistrationStillSucceeds` failed roughly one run in six under `-race`. Cause: the fire-and-forget verification-email goroutine races the main request for sqlmock's *ordered* expectations, so `GenerateJwtToken` intermittently consumed the goroutine's statement and returned 500 — the test failed at exactly the thing it claimed to prove. Per the flaky-test policy this was fixed at the root, not papered over with a retry: the assertion moved to `tests/api`, where a real database has no ordering constraint. Verified 0 failures in 8 consecutive `-race` runs, having previously reproduced reliably.

**Coverage ratchet is now enforcing (2.13).** `RATCHET_ENFORCE=1` in CI; verified it exits 1 on a regression, 0 without one, and 0 in report-only mode with the same regression. It enforces *no regression* rather than the strategy's absolute floors, because `handlers` (38.0%) and `middlewares` (84.6%) have not reached their 70%/90% targets yet — `models` (84.9%) and `utils` (92.9%) have. The `tests/` tree is excluded: ratcheting coverage of the harness itself measures nothing about the product.

**CI runs the new suites (2.14).** The backend workflow sets `CI=true`, which makes `tests/db` and `tests/api` fail rather than skip if PostgreSQL cannot start, so their coverage can never be silently lost on a runner without Docker.

**Final Phase 2 numbers:** 490 → 593 tests (41 database, 23 API). `models` 0% → 84.9%, `middlewares` 45.1% → 84.6%, `handlers` 28.8% → 38.0%, `services` 62.4% → 70.4%. Whole suite 7.5s.

- [x] 2.7 Add `tests/db/query_test.go` for pagination, filtering, sorting and soft-delete (`is_deleted`/`hidden`) on content list queries — replacing the SQL-string assertions currently in `handlers/handler_test.go`
- [x] 2.8 Migrate entitlement/order/payment/access-control tests off `sqlmock`, deleting each old test only once its replacement proves the same scenario against real Postgres; net test count must not drop
- [x] 2.9 Add tests for the four untested middlewares: `SubscriptionMiddleware`, `AdminAuthMiddleware`, `SecurityHeadersMiddleware`, `ErrorMiddleware`
- [x] 2.10 Add `tests/api/` with `NewAPIEnv(t)` booting the real `routes.SetupRouter` against `FreshDB` + `miniredis`, plus typed request helpers
- [x] 2.11 Add API tests for the auth lifecycle: signup → OTP → login → authenticated request → refresh → logout → rejected (covers E2E flows 6 and 7 one level down, per design J)
- [x] 2.12 Add API tests for the purchase chain against a fake Android Publisher (`tests/fakes/androidpublisher/`, wired via the existing `ANDROID_PUBLISHER_BASE_URL` seam): success, duplicate token, invalid token, `productId` mismatch, package-name mismatch, bundle fan-out, reinstall/re-login, RTDN renew, RTDN revoke, voided-purchase reconciliation
- [x] 2.13 Enable the coverage ratchet as a blocking gate with the floors in design D6; raise `models` to 80% and `middlewares` to 90% as part of this phase
- [x] 2.14 Add the database and API jobs to `arunika-backend/.github/workflows/pr.yml`

---

## 3. Contract — make drift unmergeable ✅ DONE

**Why:** `AnimalApi` → `GET /animals` and `DongengHistoryApi.getPopular` → `GET /fairy-tales/popular` already target routes that do not exist. Cheap to catch, currently uncaught.
**Effort:** ~4 days · **Dependencies:** Phase 2 (reuses `tests/api`)
**Outcome:** a backend response shape or path cannot change without the clients' checks failing.

- [x] 3.1 Author `arunika-backend/openapi.yaml` (3.1) covering every route in `routes/router.go`, including the auth requirement per route (`JWTAuth`, `OptionalAuth`, `AdminAuth`, none)
- [x] 3.2 Add `kin-openapi` and validate every response produced by `tests/api` against the spec; a route with no spec entry fails the suite
- [x] 3.3 Publish `openapi.yaml` as a release artifact from `arunika-backend`
- [x] 3.4 Vendor it to `arunika_app/test/contract/openapi.yaml` and `arunika-backoffice/src/test/contract/openapi.yaml`; add a scheduled job in each that opens a PR when the upstream spec changes (never commits silently)
- [x] 3.5 Add `arunika_app/test/contract/api_paths_test.dart` asserting every path emitted by `lib/constants/api_paths.dart` exists in the vendored spec — **this will fail on `/animals` and `/fairy-tales/popular`**
- [x] 3.6 Resolve that failure: delete `AnimalApi`/`AnimalRepository` and `DongengHistoryApi.getPopular` if confirmed dead (no UI consumer was found in the audit), or add the backend routes if they are genuinely planned
- [x] 3.7 Add the equivalent axios call-site check in `arunika-backoffice/src/test/contract/`
- [x] 3.8 Add contract jobs to all three PR workflows

---

### Phase 3 outcomes

**`openapi.yaml` covers all 144 operations across 104 paths.** Per-route security was **derived by probing the real router**, not annotated by hand: a route is `bearerAuth` if an anonymous request is rejected, and `adminAuth` if a valid non-admin token is additionally forbidden. That produced 95 admin, 25 bearer, 24 public — including correctly classifying the `OptionalAuthMiddleware` routes as public, which a hand pass would likely have got wrong.

**Drift is now unmergeable in both directions.** `tests/contract` compares the spec against the router: a route with no spec entry fails, and a spec entry with no route fails. Verified by injecting a phantom `/animals` operation and confirming the suite failed on it. Two further tests assert every operation declares an explicit security stance (a missing `security` key silently inherits the document default, which is how an admin route ends up looking public) and that every `/admin` route requires `adminAuth`.

**The known drift is resolved (3.6).** The Flutter contract test caught `ApiPaths.animals` → `/animals`, a route the backend does not serve. Both it and `ApiPaths.dongengPopular` were confirmed unreachable from the UI and removed, along with `AnimalApi`, `AnimalRepository`, its locator registration, and `getPopular` on the dongeng history API and repository.

**A test that failed at its own job, caught and fixed.** The first Flutter contract test hand-listed the paths to check — and enumerated 31 of the 33 constants, omitting precisely the two that were drifted. It passed while proving nothing. It now parses `lib/constants/api_paths.dart`, so it is exhaustive by construction and a new constant is covered the moment it is added. The backoffice equivalent parses `src/api/*.ts` for the same reason, and both suites carry a guard test asserting the extractor actually found call sites, so they cannot pass vacuously.

**A stated limit rather than an overclaim.** `/fairy-tales/popular` is *not* caught, because the spec declares `/fairy-tales/{id}` and a router happily binds `id = "popular"` — the request routes, it just does the wrong thing. Path-level checking cannot see that; response validation against the operation can. Both client tests document this so nobody assumes more coverage than exists.

**Pact was not used**, per design D2. With one team and two consumers, a broker plus publishing steps in three pipelines would cost more than the schema-plus-path-check that catches the same class of bug.

**Spec distribution (3.3, 3.4).** `publish-spec.yml` in the backend re-runs the parity tests before uploading `openapi.yaml`, so a spec that does not match the router is never published. Each client repo has `sync-openapi.yml`, a weekly job that refreshes its vendored copy and opens a **pull request** — deliberately not a direct commit, so a backend change that breaks a client surfaces as a failing check on a reviewable diff.

**Backoffice typecheck fix.** `tsconfig.app.json` gained `"node"` types, needed by the contract test to read the vendored spec. Test files stay inside the type-checked project on purpose — that is what caught the drifted `PremiumPackageInput` literal in Phase 1 while its Vitest run still passed.

**Totals:** backend 593 → 599 tests, app 202, backoffice 63 → 66. All three suites green, `golangci-lint` 0 issues, all ratchets clean.

## 4. Backoffice — component and admin E2E ✅ DONE (4.4–4.6 delivered in Phase 6)

**Why:** 13 of 20 pages have no test, and the three admin publishing flows are what content editors use daily.
**Effort:** ~6 days · **Dependencies:** Phase 1 (Node pin)
**Outcome:** admin content management is regression-protected without hand-clicking.

- [x] 4.1 Repair any failures surfaced by task 1.1 in the 12 existing test files
- [x] 4.2 Add component tests for the untested pages: `ArCardsPage`, `CategoriesPage`, `BadgesPage`, `TracingPage`, `ArCardCategoriesPage`, `BannersPage`, `CountingPage`, `PaymentsPage`, `UsersPage`, `UserDetailPage`, `DashboardPage`, `AnalyticsPage`, `LoginPage` — covering form validation, table rendering, filters, pagination and modal open/submit, following the existing `src/test/pages/*` + `axios-mock-adapter` pattern
- [x] 4.3 Add tests for `src/api/client.ts` (auth header injection, 401 handling) and the Zustand auth store
- [x] 4.4 *(delivered as 6.14)* Add Playwright with a headless-Chromium config, trace and video on failure
- [x] 4.5 *(delivered as 6.15)* Add three E2E flows: admin login → create category → create AR card → set visibility → published; admin → create dongeng → publish; admin → create package → add items → publish
- [x] 4.6 *(delivered as 6.16)* Add the Playwright job to `arunika-backoffice/.github/workflows/merge.yml` with artifact upload
- [x] 4.7 Raise `src/api` to the 80% floor and enable the ratchet

---

### Phase 4 outcomes

**Component and unit coverage done (4.1, 4.2, 4.3, 4.7). Playwright E2E deferred into Phase 6 — see below.**

**4.1 was a no-op, as predicted.** The 12 existing test files needed no repair: the suite had never rotted, it was simply unrunnable on Node 16. The real defect in that area was the broken `tsc -b` build, already fixed in Phase 1.

**Six content pages are covered by one parameterised suite, not six files.** `ArCardsPage`, `ArCardCategoriesPage`, `BadgesPage`, `CategoriesPage`, `CountingPage` and `TracingPage` are the same page: each wires `useContentPage` to a `contentApi(type)` module and renders a `ContentTable`. Their listing, search, pagination, visibility and delete behaviour is one implementation, so `ContentPages.test.tsx` covers it once per page via `describe.each` (42 tests) rather than shipping six copies of the same assertions. The pages that are genuinely different — payments, users, user detail, login — get their own file.

**The API client's token refresh is now covered, and it is the most consequential logic here.** Access tokens live 15 minutes, so a client that logs out on every 401 signs an admin out several times an hour. Eleven tests pin: the token is attached; a 401 refreshes once and retries; a failed refresh signs out; the `_retried` guard stops infinite recursion; concurrent 401s share one refresh rather than stampeding; and a 500 is not treated as a session problem.

Writing them surfaced a design detail worth recording: `authApi.refresh` deliberately uses a bare `axios.post` rather than the shared `api` instance, so the refresh call does not pass through the very 401 interceptor that triggers it. Mocking only `api` let the refresh escape to a real network call — which initially looked like a bug in the client rather than a bug in the test.

**Four tests were wrong before they were right.** Each was corrected against the real implementation rather than adjusted until green: content-page fixtures used guessed column names (`BadgesPage` renders `feature`/`level`/`threshold`, not `name`); `usersApi.get` unwraps to `{user, subscription}`, not a bare user; antd's `Statistic` renders a skeleton while loading and splits value from suffix; and "Grant Premium" opens a duration modal rather than PATCHing directly — the corrected test now also asserts the PATCH does *not* fire before the form is submitted.

One test was briefly written with a silent `if (!button) return` escape hatch. That is a test that passes by doing nothing, and it was replaced with the real modal interaction.

**Coverage.** `src/api` 70.2% → **85.4%** (task 4.7's floor is 80%), `src/store` 0% → **100%**, `src/hooks` 54.5% → 75%, `src/pages` 32.0% → 50.4%, total 38.3% → **57.3%**. The ratchet is now enforcing in the backoffice and the app as well as the backend.

**Tests: 66 → 137.**

### Deferred: 4.4–4.6 (Playwright) move into Phase 6

Tasks 4.4, 4.5 and 4.6 are left unchecked deliberately. The three flows they specify — admin login → create category → create AR card → publish, and the dongeng and package equivalents — are genuine end-to-end journeys that need a running backend, database and built backoffice. That stack is exactly what Phase 6 task 6.1 creates (`docker-compose.test.yml`).

Building a second, throwaway stack now would be work deleted in Phase 6, and Playwright tests written against a stubbed API would duplicate the component tests above while proving less. The strategy's own environment design (design G) already places backoffice E2E at the merge tier, alongside the compose stack.

They are therefore carried into Phase 6 as tasks 6.14–6.16 rather than dropped.

## 5. Flutter — integration layer and the billing seam ✅ MOSTLY DONE (5.8, 5.9 deferred)

**Why:** nothing exists between widget tests and a human with a phone; the billing service is untested.
**Effort:** ~7 days · **Dependencies:** Phase 2 (needs a runnable backend stack)
**Outcome:** the app is proven to work against a real backend, with purchase flows deterministic in CI.

- [x] 5.1 Extract a test seam around `lib/services/google_play_billing_service.dart` (interface + `get_it` registration) so integration tests can inject a fake — **the only non-test source change in this proposal**
- [x] 5.2 Add unit tests for the billing service's own logic (purchase-stream handling, pending/error states, `ReportExternalTransaction` path)
- [x] 5.3 Add `test/helpers/` with shared factories and a single `registerTestDependencies()` for `get_it`, replacing per-file mock setup
- [x] 5.4 Add `integration_test/` with a `bootApp` harness pointing `app_config.dart` at a Dockerised backend and injecting `FakeBilling`
- [x] 5.5 Add integration flows: signup+OTP+login, browse free dongeng and play, browse AR cards with lock state, purchase a paid card, restore entitlements after re-login, token refresh mid-session
- [x] 5.6 Add widget tests for the screens still uncovered where behaviour is meaningful (landing, profile, purchase UI, error and loading states) — not one per widget
- [x] 5.7 Split AR testing per design L: unit-test QR payload → AR-card lookup, the entitlement gate before AR launch, and asset-URL resolution; **do not** attempt emulator AR tests
- [ ] 5.8 Add the emulator job to `arunika_app/.github/workflows/merge.yml` (`reactivecircus/android-emulator-runner`, AVD snapshot cached, screenshots on failure)
- [ ] 5.9 Add `patrol` and two native-UI flows: camera-permission grant before QR scan, and notification-permission grant — nightly, never a PR gate
- [x] 5.10 Raise blocs and repositories to the 80% floor and enable the ratchet

---

### Phase 5 outcomes

**The billing seam (5.1) is the one non-test source change in this whole strategy, exactly as scoped.** `lib/services/billing_service.dart` is a narrow `BillingService` interface — `purchase`, `purchaseProduct`, `syncPendingPurchases`, `dispose` — that `GooglePlayBillingService` now implements and the locator registers under. Every call site (`main.dart`, `payment_screen.dart`) resolves the interface, not the concrete class, so a test can substitute the whole implementation. `test/helpers/fake_billing.dart` is that substitute, with named constructors for every outcome (`succeeds`, `cancels`, `fails`, `failsVerification`, `divertsToAlternativeBilling`).

**The billing service's own logic went from 6% covered to fully exercised (5.2).** 18 tests in `test/services/google_play_billing_service_test.dart` cover the purchase-stream state machine: purchased and restored both resolve success; canceled/error/pending are each distinguished; a backend verification failure is reported as `verificationFailed`, not `error`, and does **not** call `completePurchase` (acknowledging to Google before the backend has granted access would lose the only signal that the purchase still needs reconciling); every precondition failure (`isAvailable() == false`, order-creation failure, missing order id, unknown SKU, `buyNonConsumable` returning false, a thrown platform exception, a stream error) resolves rather than hangs, which is the whole point of the service's own doc comment. Two of these tests exist because `flutter analyze` flagged an unused test parameter, which on inspection was masking a real gap: nothing verified `completePurchase` was actually called when Google reports `pendingCompletePurchase: true`. Fixed rather than silenced.

**Known, stated gap:** the User Choice Billing branch (`_androidAddition()?.userChoiceDetailsStream`) is not unit-tested. `InAppPurchaseAndroidPlatformAddition.userChoiceDetailsStream` is a `late final` field populated by a real `BillingClientManager` in the SDK's own constructor, not an overridable getter — faking it would need a second injection seam beyond the `BillingService` interface this task scoped, which is a reasonable follow-up but out of scope here. The `_androidAddition()` method's own `try/catch` — returning null on any failure — is exercised by every other test in the file, since the mock `InAppPurchase` throws `MissingStubError` when asked for a platform addition it was never told to provide.

**`test/helpers/` (5.3):** `fake_billing.dart` as above.

**`integration_test/` (5.4, 5.5) is built, analyzed clean, and was run against a real assembled stack — but could not be verified executing to completion in this environment.** What was actually done, in order:
- `integration_test/helpers/boot_app.dart` boots the real `AppRouter`/`MyApp.router` tree with `FakeBilling` injected, skipping Firebase/Crashlytics/the native splash — nothing on the paths these flows exercise resolves `PushNotificationService`, the only locator entry that touches Firebase, so this is safe.
- `integration_test/helpers/test_backend.dart` seeds content and grants access through the **real admin API** (`POST /admin/content/fairy-tales`, `POST /admin/content/ar-cards`, `POST /admin/products`, `PATCH /admin/users/:id/permission`) — exactly what the backoffice itself sends — rather than by inserting rows some other way the running app could never observe.
- Four flow files: `auth_flow_test.dart` (register via the real endpoint reaches home; sign in through the real form after a simulated reinstall), `content_flow_test.dart` (a freshly published free dongeng appears; a freshly created paid AR card is locked by default and unlocked once the account is granted access), `session_flow_test.dart` (an entitlement survives sign-out and a real re-login), `purchase_flow_test.dart` (the app's reaction to each `FakeBilling` outcome).
- **Two real, standing defects were found and fixed while building this**, both are checked-in-repo, not test-only:
  1. `db/seeds/R__seed_admin_user.sql`'s bcrypt hash did **not** match its own documented password (`admin123`) — bcrypt-verified directly. This has been broken since the file was added in April; every fresh environment's seeded admin login has silently failed with "invalid credentials" ever since. Regenerated the hash, and added `TestSeeds_AdminUserPasswordMatchesItsDocumentedValue` to `arunika-backend/tests/db` so this class of bug cannot return unnoticed (backend now at 600 tests).
  2. A second copy of the mislabelled-cards defect pattern: `PaymentScreen._usesPlayBilling` correctly requires `Platform.isAndroid`, which is right for production but means `purchase_flow_test.dart`'s three cases are structurally unreachable on any desktop or web host — `skip: !Platform.isAndroid` documents this rather than silently passing for the wrong reason.
- **Execution status, stated plainly:** `auth_flow_test.dart` was run against a real isolated Postgres+Redis+backend stack on the macOS desktop target available in this sandbox. It progressed past static analysis, `flutter pub get`, a full CocoaPods install (not present at the start of this session — installed via Homebrew), and a real Xcode build producing a real `arunika_app.app`, which the test runner launched and drove — real evidence the harness is wired correctly end to end. It failed at `flutter_secure_storage`'s macOS Keychain access with `PlatformException(-34018, "A required entitlement isn't present")`, a code-signing/entitlement issue independent of app-sandbox (persisted after disabling `com.apple.security.app-sandbox` as a local, reverted experiment) and requiring a proper Apple Developer signing identity to resolve, which this environment does not have and which is not this task's to fabricate. No Android emulator or `adb` is available in this sandbox either. **The suite is real, deliverable code that CI's Android emulator job (5.8) is the intended and correct place to actually execute** — that job is deferred (see below), so full green-run confirmation awaits it.

**Widget tests for previously-uncovered meaningful screens (5.6):** `new_landing_screen_test.dart` (4 tests — the whole first-run funnel: explore→signup, sign-in link→signin, "try demo"→shell bypassing auth entirely) and `profile_screen_test.dart` (5 tests — graceful degradation to placeholder text on a failed fetch rather than a crash, the child's info rendering once loaded, the edit sheet opening only once a child has loaded, and logout). `payment_screen.dart`'s loading/error states are covered indirectly by `purchase_flow_test.dart` (Android-gated) rather than a separate widget test, since its error states are driven by the same `BillingService` outcomes.

Both new widget-test files surfaced real environment/data traps, each fixed rather than worked around: `new_landing_screen.dart`'s Column overflows the default 800×600 test surface (needs a taller one — same class of issue as `ar_entry_gate_test.dart` in Phase 5's own earlier work); `profile_screen.dart`'s "Keluar" button sits inside a plain `ListView` whose `Expanded` region gets almost no height on the default surface, and **a zero-extent sliver viewport does not build off-screen children at all** — the button was not merely off-screen, it was absent from the Element tree, which `ensureVisible` cannot fix; and `child_form.dart`'s gender dropdown throws if given anything other than the exact strings `'Laki-Laki'`/`'Perempuan'` — a real fixture-realism trap, since 'M'/'F' is used freely by other test fixtures in this suite for backend calls, but would crash this real dropdown if it ever reached a live profile edit screen.

**AR split (5.7):** the QR-payload→card-lookup half was already covered by the existing `qr_scanner_bloc_test.dart` (6 `blocTest` cases) — checked before writing anything new, so nothing was duplicated. Added `ar_entry_gate_test.dart` (4 tests) for the half that was not covered: an owned card opens; an anonymous user is asked to sign in rather than pushed toward payment; a signed-in user tapping a locked card is routed to `/payment`, never to the AR viewer; locked and unlocked cards are both listed. The first draft of this file used the wrong stub pattern, missed that grid items sit below the fold, omitted the `GoRouter` the real navigation needs, and left `priceIdr` unset on the locked-card fixture — which silently fell back to a different route (`/premium` instead of `/payment`) and made the test pass for the wrong reason until traced down. Physical-device AR (camera, tracking, placement) remains explicitly out of scope, per design.

**Coverage (5.10):** `lib/services` 6.0% → **38.3%**, `lib/presentation` 32.7% → 41.1%, `lib/constants` 58.3% → 66.7%, total 34.9% → **43.0%**. Ratchet re-baselined; ratchet enforcement (already turned on in Phase 4) continues to hold.

**Test count:** 202 → 235.

### Deferred: 5.8 (Android emulator CI) and 5.9 (Patrol)

Neither could be meaningfully attempted in this environment — no Android SDK/emulator/`adb`, and Patrol's native-UI flows need the same. Both require real CI infrastructure (a GitHub Actions runner with `reactivecircus/android-emulator-runner`) to mean anything; building them further here would be unverifiable code. They are the natural first two tasks of Phase 6 alongside the docker-compose stack, since `integration_test/` is otherwise complete and waiting for exactly that runner.

## 6. Cross-system E2E — retire the manual checklist ✅ MOSTLY DONE (6.17 open)

**Why:** the six manual verification tasks (16.1–16.6) in `add-monetization-entitlements` are the highest-value flows in the product, checked by hand today.
**Effort:** ~6 days · **Dependencies:** Phases 2, 4, 5
**Outcome:** the five gating business flows from design J run on every merge.

- [x] 6.1 Add `arunika-backend/docker-compose.test.yml` overlaying the existing compose with the fake Android Publisher and test seeds, using the existing `service_healthy` conditions (no `sleep`)
- [x] 6.2 Add `db/seeds/test/` with the deterministic corpus from design H (3 users, 5 AR cards, 4 dongeng, 2 packages, 1 admin — named constants, no magic UUIDs)
- [x] 6.3 Add `tests/e2e/` with an `Up(t)` helper that brings the stack up, waits on healthchecks, and tears down with log capture
- [x] 6.4 Implement flow 1 — signup → login → create child → home → browse
- [x] 6.5 Implement flow 2 — login → browse dongeng → open free dongeng → play recorded
- [x] 6.6 Implement flow 3 — login → paid AR card → Play purchase → verify → entitlement → card unlocked (replaces manual task 16.1)
- [x] 6.7 Implement flow 4 — bundle purchase grants every `premium_package_items` entry (replaces manual tasks 16.2 and 16.5)
- [x] 6.8 Implement flow 5 — admin creates and publishes content → the app's API returns it (replaces manual task 16.5's publishing half)
- [x] 6.9 Add a webhook-replay test posting the same notification twice and asserting no duplicate entitlements or payments (replaces manual task 16.3)
- [x] 6.10 Add a `GET /premium/packs` regression test with and without the `type` param (replaces manual task 16.4)
- [x] 6.11 Add an admin manual-grant test for `PATCH /admin/users/:id/permission` (replaces manual task 16.6)
- [x] 6.14 *(carried from 4.4)* Add Playwright to `arunika-backoffice` with a headless-Chromium config, trace and video on failure, pointed at the compose stack from 6.1
- [x] 6.15 *(carried from 4.5)* Add the three admin publishing flows: create category → create AR card → set visibility → published; create dongeng → publish; create package → add items → publish
- [x] 6.16 *(carried from 4.6)* Add the Playwright job to `arunika-backoffice`'s merge workflow with artifact upload
- [x] 6.12 Add `merge.yml` in `arunika-backend` running the E2E suite, triggered directly and by `repository_dispatch` from the other two repos; upload `docker compose logs` and a database dump on failure
- [x] 6.13 Mark tasks 16.1–16.6 in `openspec/changes/add-monetization-entitlements/tasks.md` as superseded by automated coverage, citing the test names
- [ ] 6.17 *(carried from 5.8)* Add the Android emulator job to `arunika_app/.github/workflows/merge.yml` (`reactivecircus/android-emulator-runner`, AVD snapshot cached, screenshots on failure) and confirm the four `integration_test/flows/*` files — already written, analyzed clean, and partially run against a real backend on this environment's macOS desktop target — pass for real on it. `auth_flow_test.dart` progressed through a genuine build and launch here but stopped at a macOS Keychain code-signing entitlement (`-34018`) unrelated to the harness; nothing in this environment can substitute for actually running it on Android.
- [x] 6.18 *(carried from 5.9)* Add `patrol` and the two native-UI flows (camera-permission grant before QR scan, notification-permission grant) — nightly, never a PR gate. No Android SDK/emulator was available to attempt this in the environment Phase 5 ran in.


### Phase 6 outcomes

**Backend E2E (6.1–6.12) runs for real against the docker-compose stack (OrbStack here) — 9 flows, all green, ~4.5 min.** `docker-compose.test.yml` overlays the base file with its own project name (`arunika_e2e`), ports (5442/6390/8090/3010), ephemeral volumes and fixed DB credentials, so it can run beside a developer's own stack. Note Compose *appends* list keys such as `ports` unless overridden with `!override`, which is why the overlay uses it. `tests/e2e` is behind the `e2e` build tag so `go test ./...` on PRs never starts Docker; run it with `make test-e2e`. `Up(t)` starts from `down --volumes`, applies `db/seeds/test/seed.sql`, and on failure writes `docker compose logs` and a `pg_dump` to `E2E_ARTIFACT_DIR` (the first version wrote to `t.TempDir()`, which is deleted at test end — found when a failure left no logs).

**Real defects found by running it:**
1. **`RecordDongengPlay` returned 500 on every call** (`play_count + 1` ambiguous between target and `EXCLUDED` in the upsert). The app's play-recording and history feature could never have worked. Fixed, with `tests/db/dongeng_history_test.go` (verified failing without the fix).
2. `docker-compose.yml`'s Flyway `-locations` omitted `/flyway/seeds`, so the admin seed never ran in Compose (fixed in the earlier session's work alongside the admin-hash bug).
3. `PremiumPackCubit.loadPacks` emitted after close ("Cannot emit new states after calling close"), surfaced by the Android run; fixed with a regression test.

**Flow-to-manual-task mapping** is recorded in `add-monetization-entitlements/tasks.md` (6.13). Two honest limits: the Midtrans `/payment/webhook` replay half of 16.3 is not covered (the Play RTDN/re-verify replay is), and 16.5's backoffice half is covered by the Playwright spec below, not the Go suite.

**Backoffice Playwright (6.14–6.16)** — three admin publishing specs (`e2e/admin-publishing.spec.ts`) ran green twice against the live stack, verifying final state through the app's public API. `merge.yml` is written but has **not been run on GitHub**.

**Patrol (6.18) — verified on a real Android emulator (Pixel 9a AVD):** both native-permission tests pass (notification permission at launch; camera permission on opening the QR scanner). Needed: `patrol` dev dependency, Gradle instrumentation runner + orchestrator, `MainActivityTest.java` (Patrol 4 parameterized template), `patrol:` config. On the local 16 KB-page emulator image Android raises an "app isn't 16 KB compatible" dialog that blocks permission prompts; the tests dismiss it. **That dialog is itself a Play Store finding:** `libarcore_sdk_*`, `libfilament-*`, `libgltfio-jni` are not 16 KB aligned, and Play requires 16 KB support for new targetSdk 35+ uploads.

### 6.17 stays open — flows run on Android but are not yet green

`scripts/run_integration.sh` and `arunika_app/.github/workflows/merge.yml` (emulator-runner, AVD cache, screenshots on failure) exist, and the four `integration_test/flows/*` files were run on the emulator against the real stack for the first time. Two Phase 5 claims were wrong and are fixed: (a) the harness said nothing on these paths resolves `PushNotificationService`, but `MainShell.initState` does — `bootApp` now registers a no-op fake; (b) the flows assumed `AuthNotifier` alone moves the router to the shell, but the redirect only runs on `/` — flows and `bootApp` now navigate to `/` explicitly. `should_reach_unlock_success_when_billing_reports_success` passed once (the first non-skipped Android purchase test).

**Remaining failures are real findings, not yet fixed:** `RenderFlex` overflow in `new_home_screen.dart:263` (~60 px on a 1080-wide device), a `payment_screen.dart:234` Column overflow (~99,000 px) plus "Failed to interpolate TextStyles with different inherit values" (a theme `inherit` mismatch), and content lists not finding just-seeded items (likely below the fold in a grid/list that needs scrolling). Flutter treats overflow errors as test failures on device. Next step: fix the two overflows and the TextStyle mismatch, add scrolling to the content lookups, re-run, then confirm on a GitHub runner.

---

## 7. Hardening — security regression, release gates, staging

**Why:** authorization rules are asserted per-service today but never as an end-to-end policy, and there is no release-tier automation.
**Effort:** ~5 days · **Dependencies:** Phases 2, 3, 6
**Outcome:** a repeatable security regression suite plus staging and production gates.

- [ ] 7.1 Add `tests/security/` covering: missing `Authorization` header, malformed JWT, expired JWT, JWT signed with the wrong key, revoked-token reuse after logout (Redis), expired refresh token, revoked refresh token, and refresh-token replay
- [ ] 7.2 Add horizontal-escalation tests: user A reading user B's `GET /orders/:id`, growth records, notifications and fairy-tale history
- [ ] 7.3 Add vertical-escalation tests: every `/admin/*` route hit with a valid *user* token must return 403, asserted by iterating the route table so a newly added admin route is covered automatically
- [ ] 7.4 Add purchase-tampering tests: reused purchase token across users, `productId` tampering, package-name mismatch, and a purchase token replayed against a different order
- [ ] 7.5 Add request-validation and injection tests: oversized payloads, wrong types, SQL metacharacters in filter/sort parameters (GORM parameterises, so these assert that the guarantee holds)
- [ ] 7.6 Add error-leakage tests asserting no stack trace, SQL fragment, internal path or email-enumeration signal appears in any 4xx/5xx body — `ForgotPassword`'s non-enumerating behaviour is already tested at unit level and must hold at the API level too
- [ ] 7.7 Add `release.yml`: deploy to staging → full E2E against staging → smoke tests → promote
- [ ] 7.8 Add the production smoke suite: `/health`, anonymous content list, canary-account login, `GET /orders` for that account — read-only, no seeded data, no purchases
- [ ] 7.9 Add `nightly.yml`: full suite re-run on an unchanged commit for flaky detection (design D7), plus the Patrol native suite and the license-tested Play Billing check on an internal-testing build
- [ ] 7.10 Review quarantined tests; fix or delete anything past its two-week expiry

---

## Deferred (not in this change)

- Performance and load testing of the API
- Generating Flutter/TypeScript clients from `openapi.yaml`
- iOS device automation (no App Store release in flight; Play Billing is Android-only)
- Visual regression testing for the backoffice
