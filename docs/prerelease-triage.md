# Pre-release triage — first public release

Gate runs: 2026-09-29, local only (no deployment URL yet). Run it with `make prerelease` in `arunika_app`, `arunika-backend` and `arunika-backoffice`, and with `scripts/prerelease_check.sh` in `arunika-landing`. Severity policy: `openspec/changes/add-prerelease-security-gate`.

Decisions: **blocker** (release waits), **fixed**, **tracked** (not blocking; revisit), **false positive**.

## Blockers — all resolved

| # | Repo | Finding | What's needed |
|---|---|---|---|
| B1 | backend | ~~gitleaks: `.env` committed in `e07e45b`, removed in `9622c4d`.~~ **Resolved 2026-09-30:** the owner confirmed the values were local development credentials only, so nothing to rotate. Both fingerprints are recorded in `arunika-backend/.gitleaksignore`. To prevent a repeat, a gitleaks `Secret scan` job now runs on every PR and push in all four repos, and `arunika_app` now ignores `.env` files (the backend already did). | — |
| B2 | backend | ~~gosec false positives fail the gate.~~ **Resolved 2026-09-30:** the owner reviewed and approved all the false positives below. They are annotated with `#nosec` and a reason, the gate excludes `tests/` from gosec, and the app's findings are in `arunika_app/.gitleaksignore`. | — |
| B3 | backend | ~~govulncheck GO-2026-6354/6355 (`x/crypto/ssh`).~~ **Resolved 2026-09-30:** backend moved to Go 1.26 (`go.mod`, Dockerfile, all CI workflows; CI golangci-lint pinned to v2.14.0 to match), and `x/crypto` upgraded to v0.57.0. govulncheck: 0 reachable. `make test-all`, lint and the Docker build pass. | — |
| B4 | app | ~~Google Play 16 KB page size: `libfilament-jni.so`, `libfilament-utils-jni.so` and `libgltfio-jni.so` had 4 KB-aligned LOAD segments (`0x1000`), from Filament 1.52.0 via `io.github.sceneview:arsceneview:2.2.1` in `packages/ar_flutter_plugin_2`.~~ **Resolved 2026-09-30:** upgraded to `arsceneview:2.3.0` (Filament 1.56.0, ARCore 1.48). The release APK builds without code changes, every native library in arm64-v8a and x86_64 is aligned at ≥ `0x4000`, and `zipalign -c -P 16` passes. | **AR check on a real phone** before release (scan a card, place the model, move and rotate it, sound). If AR regresses, the fix still has to come from a newer Filament. |

## Fixed in this change

| Repo | Finding | Fix |
|---|---|---|
| backend | **GO-2025-3553**: `golang-jwt/jwt/v5` v5.0.0 excessive memory allocation in header parsing, reachable from `AdminAuthMiddleware` → `jwt.Parse`. | Upgraded to v5.2.2. All suites pass, including `tests/security`. |
| backend | GO-2026-6253: `moby/go-archive` path traversal (test fixtures). | Upgraded to v0.3.0. |
| app | Full parent/child profile (name, phone, email, address, children) cached in plaintext `SharedPreferences`. | `LocalProfileStorage` now uses `flutter_secure_storage`. The legacy copy is migrated once and deleted, and `clear()` removes both. 4 new tests. |
| app | Midtrans `snap.js` was hardcoded to the **sandbox**, while the backend URL is env-driven. It would break checkout if `alternative_billing` were enabled in production. | Now `--dart-define=MIDTRANS_SNAP_JS_URL`. The production build command is in the README. |
| backoffice | No CSP. The static-asset `location` dropped every security header (nginx `add_header` inheritance). | Shared `nginx-security-headers.conf` is included in every location. Added CSP, `X-Frame-Options: DENY`, `Permissions-Policy` and `server_tokens off`. Verified with `curl -I` on `/`, a hashed JS asset and a deep link. All 8 Playwright E2E tests pass against the image, and a new auto-fixture fails any test that logs a CSP violation (checked against a deliberate violation). |
| backoffice | npm audit, runtime deps: `axios` ≤1.17 (prototype-pollution gadgets, ReDoS), `form-data` CRLF injection, `react-router` ≤7.18.1 (includes an open redirect via `<Link>`/`useNavigate`). | Upgraded within semver: axios 1.20.0, form-data 4.0.6, react-router-dom 7.18.4. Runtime audit: 0 vulnerabilities. Tests, typecheck and build are green. |

## False positives (reviewed and suppressed by the owner, 2026-09-30)

| Repo | Finding | Why it's false | Suppression applied |
|---|---|---|---|
| backend | gosec G101 `services/payment_method.go:8` "hardcoded credentials" | A map of Midtrans payment-type display labels. | `var paymentTypeLabels = map[string]string{ // #nosec G101 -- display labels, not credentials` |
| backend | gosec G703 + G304 `services/notification_service.go:185` path traversal / file inclusion | The path comes from the operator's `FIREBASE_SERVICE_ACCOUNT_JSON` / `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` env var, never from a request. | `content, err := os.ReadFile(value) // #nosec G304 G703 -- trusted env config` |
| backend | gosec G304 `tests/fixtures/container.go:226`, G112 `tests/fixtures/playfake.go:101` | Test-only code. | The gate runs gosec with `-exclude-dir=tests` |
| app | gitleaks `generic-api-key` in `.github/workflows/{merge,nightly}.yml` (4 hits) | `key: avd-api-34-…` is a GitHub Actions cache key. | `arunika_app/.gitleaksignore` |
| app | gitleaks `gcp-api-key` in `google-services.json`, `lib/firebase_options.dart` | Firebase client API keys ship in every app binary by design. | `arunika_app/.gitleaksignore`. **Also** make sure the key is restricted in Google Cloud Console (Android app restriction with package `com.arunika` + SHA-1, and an API allow-list), because an unrestricted key can be abused for quota. |
| backoffice | eslint `security/detect-unsafe-regex` ×3 (Premium packages / Products) | `/\B(?=(\d{3})+(?!\d))/g` is the standard thousands separator, run on short admin number input. | None needed (they're warnings). |
| backoffice | eslint `security/detect-object-injection` ×9, `detect-non-literal-fs-filename` ×3 | Index lookups keyed by typed enums or table rows; the fs calls are in a contract test that reads the repo's own files. | None needed (they're warnings). |

## Tracked (not blocking this release)

| Repo | Finding | Note |
|---|---|---|
| backend | gosec G706 log injection ×10 (LOW) | slog's JSON handler escapes values, so a newline in user input can't forge a log line. |
| backend | No Go benchmarks exist | The gate reports this as skipped. Add benchmarks for hot paths (entitlement check, catalog list) to get a regression baseline. |
| backoffice | npm audit dev deps: `brace-expansion`, `browserslist` (high), `vitest`/`@vitest/*`, `baseline-browser-mapping` (moderate), `@babel/core` (low) | Build and test tooling only; nothing ships in the static bundle. `npm update` currently crashes on an npm-arborist bug (`edgesOut` of null) while resolving vitest peers. Retry after an npm upgrade. The gate blocks on runtime deps and writes the full audit to `npm-audit-all.txt`. |
| backoffice | ZAP: CSP wildcard directive | Deliberate `img-src https:`: banner/campaign images are admin-entered URLs. Can be narrowed once images live on a known CDN. |
| backoffice | ZAP: COEP missing, storable/cacheable content, "modern web app", suspicious comment / Unix timestamp in the bundle | COEP is only needed for cross-origin isolation, which the app doesn't use. Caching of fingerprinted assets is intended. The other two are informational and come from minified library code. |
| backoffice | Bundle: 1.63 MB JS+CSS (baseline recorded), Vite chunk-size warning | Admin-only tool; code splitting would help but isn't a release concern. |
| app | `flutter analyze`: 9 infos (6 `deprecated_member_use`, 3 lint) | Pre-existing, no warnings or errors. |
| app | `pub outdated`: no security advisories. Discontinued transitives `flutter_secure_storage_macos`, `js` | Neither ships in the Android build. Several major upgrades are available (go_router 12→18, flutter_bloc 8→9, firebase 3→4, …); do them after release, not before. |
| app | Android `allowBackup` is unset (defaults to **true**) | Auto Backup copies app data. The secure-storage file is encrypted with a Keystore key that isn't backed up, so a restore on a new device yields undecryptable entries. **Recommend** `android:allowBackup="false"` (or excluding `FlutterSecureStorage` in backup rules) in a follow-up. |
| app | Payment WebView: JS unrestricted, no `NavigationDelegate`, and the `Flutter` JS channel is callable by any page the flow navigates to (bank 3DS, e-wallet redirects) | Acceptable for now: Snap needs JS and cross-domain redirects, and a forged `success:` message isn't trusted, because `PaymentPollingCubit` confirms the order status with the backend. Revisit if the success path ever skips polling. |
| landing | ZAP: no CSP / X-Frame-Options / X-Content-Type-Options / Permissions-Policy, server version, COEP | Served locally from stock nginx; production headers come from the host. **Verify on host** after deploy. |
| landing | ZAP: SRI missing | The only external resources are Google Fonts CSS, which is generated per user agent, so SRI can't be used for it. |
| content | Dongeng page images that are the wrong shape for the reader (from `add-dongeng-page-curl-and-image-check`) | The backoffice now blocks new ones. Existing ones remain: (1) upload `kancil-1-16x9.jpeg` (2400×1350, already cropped) and replace the kancil page's Image URL; (2) run `node scripts/audit_page_images.ts` in arunika-backoffice against the real backend; (3) re-crop and replace every page it lists. |
| landing | Lighthouse performance 72 (baseline recorded) | Local nginx, no CDN or compression tuning. The large PNGs in `assets/` are the obvious lever. |

## Manual reviews

- **Certificate pinning: not implemented, by decision.** If the server certificate rotates (e.g. Let's Encrypt, every 90 days) and the app has no remote pin-update path, every installed copy loses network access until users update. Mitigations already in place: TLS only (targetSdk ≥ 28 blocks cleartext by default, and no `usesCleartextTraffic` is set in the main manifest), short-lived revocable tokens (`security-regression-tests`), and payments verified server-side. Revisit once hosting is chosen, using SPKI pinning of the intermediate CA with a backup pin.
- **Payment WebView:** see "Tracked". The sandbox URL issue was fixed.
- **`url_launcher`:** one call site (`active_subscription_view.dart`), which opens Google Play's subscription page for the app's own package, built from constants. There's no user-controlled URL.
- **Android exported components / intent filters:** only `MainActivity` is exported, with the `MAIN`/`LAUNCHER` filter. `PROCESS_TEXT` sits in `<queries>` (Flutter's default text-processing query), not an intent filter. There are no deep links or custom schemes.
- **Profile-mode run on a real device (start time, jank):** ☐ **deferred, no physical device available during this change.** Emulator numbers are below and stand in for now. Before shipping, repeat them on a phone with the same command, and check the AR scan by hand — also worth checking there since the AR placement and Google Play cancel-purchase fixes (see below) were validated on the e2e stack and by unit test, not on a real device. The same goes for the dongeng page curl: it was checked by widget test and in the emulator profile run below, so also swipe through a story on the phone.

## Performance (emulator, profile mode, 2026-09-30)

API 36 emulator (16 KB pages) against the E2E stack seeded by `scripts/perf_seed.py` (30 dongeng × 10 pages, 30 AR cards, real R2 images). Run: `flutter drive --profile --no-dds -d DEVICE --driver=test_driver/perf_driver.dart --target=integration_test/perf/app_perf_test.dart --dart-define=API_BASE_URL=http://10.0.2.2:8090`. Summaries land in `build/perf/`. An emulator's GPU isn't a phone's, so treat these as indicative only.

| Flow | UI thread | Raster | Frames over 16.7 ms |
|---|---|---|---|
| Cold start | Android `TotalTime` 878–907 ms (5 runs); first Flutter frame 609 ms | | |
| Home scroll | ≤ 3.3 ms | avg 16.5, p90 18.6, max 27.1 ms | **50 / 83** |
| Dongeng list scroll | ≤ 3.5 ms | avg 2.4 ms | 0 |
| Dongeng page flip | ≤ 2.5 ms | avg 3.2 ms | 0 |
| Dongeng page curl (8 arrow turns + 4 swipes, re-run after `add-dongeng-page-curl-and-image-check`) | build avg 0.7, max 2.2 ms | avg 2.4, p90 3.1, p99 4.4, max 12.0 ms | 0 / 184 |
| AR collection scroll | ≤ 1.9 ms | avg 3.6 ms | 0 |

Memory (RSS): 379 MB when home loads, 486 MB after all flows, 475 MB after three rounds of tab switching. It plateaus, so there's no sign of a leak.

**Home scroll jank (tracked, cause unconfirmed):** it's raster-bound, not build-bound. The likely cause is that images are decoded at full size (the covers are 1408×768 and 1254×1254 PNGs of about 2 MB), because nothing sets `cacheWidth`/`memCacheWidth` and `MediaCache.image` has no size cap. Confirm on a phone before changing code, e.g. by passing a decode width through `MediaCache.image` for card-sized images.

## Load test (local)

k6, 20 VUs for 30 s against the E2E stack (`/health`, `/ar/cards`, `/ar/categories`, `/fairy-tales`, `/dongeng-categories`, `/premium/packs`, `/banners`, `/app/feature-flags`): 4,688 requests, 0% errors, p95 15 ms. Local only; this says nothing about production capacity.

## Re-run once a deployment URL exists

1. ZAP baseline against the production backoffice and landing URLs. Confirm the landing host sends CSP, `X-Frame-Options`, `X-Content-Type-Options` and HSTS.
2. `curl -I` on the production API to confirm HSTS and the security headers from `SecurityHeadersMiddleware` behind the real load balancer and TLS termination.
3. k6 (`TARGET_URL=https://… k6 run scripts/load-test.js` in arunika-backend) against production-like infrastructure.
4. Lighthouse against the hosted landing page, to get the real CDN/compression score.
5. A release build with the production `--dart-define`s (README). Check that one Midtrans checkout opens (if `alternative_billing` will be on) and that Play Billing works end to end.
