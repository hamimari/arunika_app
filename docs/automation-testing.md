# Automation testing — arunika_app

How the Flutter app is tested and how to run each suite again. The other repos
have their own page: [backend](../../arunika-backend/docs/automation-testing.md),
[backoffice](../../arunika-backoffice/docs/automation-testing.md). Rationale and
history: `openspec/changes/add-automation-testing-strategy/`.

The three repos are expected side by side — the E2E stack builds the backoffice
from a sibling directory:

```
Projects/
├── arunika_app          this repo
├── arunika-backend      Go API (owns the docker-compose E2E stack)
└── arunika-backoffice   React admin
```

## Suites

| Suite | Where | Needs | CI |
|---|---|---|---|
| Unit / bloc / widget | `test/` | nothing | every pull request (`pr.yml`) |
| API-path contract | `test/contract/` | nothing | every pull request |
| **Integration flows** — real backend, real Android | `integration_test/flows/` | E2E stack + Android emulator | on merge (`merge.yml`) |
| **Native permission dialogs** (Patrol) | `patrol_test/` | Android emulator | nightly (`nightly.yml`) |

## Everyday loop

```bash
make test-fast     # flutter test
make test-all      # everything a PR runs: analyze + tests + JUnit + coverage ratchet
```

`test-all` needs the JUnit converter once: `dart pub global activate junitreport`.
After an intentional coverage change: `make coverage-baseline`.

Shared test code: `test/helpers/` — `fake_billing.dart` (a `BillingService` that
succeeds, cancels or fails verification) and the `registerTestDependencies()`
get_it setup. The billing seam is `lib/services/billing_service.dart`; real
Google Play is never touched by any test.

## Integration flows on an Android emulator

Four files, 9 tests: signup + sign-in, free dongeng and locked/unlocked AR cards,
purchase outcomes (success / cancel / verification failure), and re-login
restoring entitlements. They run the real app against the real backend stack and
seed data through the same admin API the backoffice uses.

**1. Start the stack** (from `arunika-backend`) and leave it running:

```bash
make e2e-hold          # prints "E2E STACK READY: api http://localhost:8090 ..."; Ctrl-C to stop
```

**2. Start an emulator** with a data partition big enough for the ~175 MB debug
APK (the default 6 GB one filled up and failed installs with
`Requested internal only, but not enough space`):

```bash
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools
emulator -avd Pixel_9a -no-window -no-audio -memory 4096 -partition-size 8192 \
  -gpu swiftshader_indirect -no-snapshot-save &        # add -wipe-data to reset it
adb wait-for-device shell 'while [ "$(getprop sys.boot_completed)" != 1 ]; do sleep 2; done'
```

**3. Run the flows** — `10.0.2.2` is how the emulator reaches the host:

```bash
scripts/run_integration.sh emulator-5554 http://10.0.2.2:8090 artifacts
```

A failing file leaves a screenshot in `artifacts/screenshots/`. Run one file with
`flutter test integration_test/flows/content_flow_test.dart --dart-define=API_BASE_URL=http://10.0.2.2:8090 -d emulator-5554`.

> **Memory.** The stack (Postgres, Redis, backend, backoffice) plus an emulator
> plus an IDE is heavy; an earlier run of all three at once exhausted memory and
> crashed the machine. Cap the emulator (`-memory 4096`), run it headless
> (`-no-window`), and close other heavy apps. Stop the stack with Ctrl-C when done.

### Writing flows — three traps already hit

- **Never mount a second `MaterialApp` without the app theme.** Doing so on top
  of `bootApp`'s app made a button's text style animate from the app theme to
  Material's default and throw *"Failed to interpolate TextStyles with different
  inherit values"*; the error widget then laid out ~99,000 px tall, which looked
  like a `PaymentScreen` overflow but wasn't. Pass `theme: AppTheme.lightTheme`
  and pump `SizedBox.shrink()` first (see `purchase_flow_test.dart`).
- **Scroll before asserting on seeded content.** The collection tab is a lazy
  `GridView.builder` and the shared backend accumulates cards, so a card seeded a
  moment ago is usually past the last built row. Use `scrollToText` from
  `integration_test/helpers/scroll.dart`.
- **`AppRouter.router` is a process-wide singleton.** `bootApp` resets it to `/`;
  don't bypass it.

## Patrol — native permission dialogs

Camera before QR scan and notifications at launch: dialogs `integration_test`
cannot see. Nightly only — never a PR gate.

```bash
dart pub global activate patrol_cli          # once
patrol test --target patrol_test/native_permissions_test.dart --device emulator-5554
```

Needs no backend. Red ❌ lines for individual native taps in the output are
optional steps (dismissing an "app isn't 16 KB compatible" dialog that only some
images show); the per-test ✅/❌ and the final `Test summary` are what count.

## CI

| File | Trigger | What |
|---|---|---|
| `.github/workflows/pr.yml` | pull request | analyze, tests, coverage ratchet |
| `.github/workflows/merge.yml` | push to master/main, `app-merged` dispatch, manual | checks out backend + backoffice, starts the stack, runs the flows on an emulator, uploads screenshots and stack log on failure |
| `.github/workflows/nightly.yml` | 03:00 WIB, manual | Patrol on an emulator |

Cross-repo checkouts use the `CROSS_REPO_TOKEN` secret, falling back to the
workflow token (enough only if the repos are public or the token has access).
**Neither `merge.yml` nor `nightly.yml` has run on GitHub yet.** The flows and
Patrol pass locally on an API 37 emulator (Pixel_9a); CI uses API 34 on x86_64, so run each
workflow once with *Run workflow* and expect to tune emulator settings.

## Known gaps

- Play Billing with a licence-tested account needs a real internal-testing build
  on a device signed in as a licence tester — a manual release step.
- No deploy pipeline exists, so there is no `release.yml`.
