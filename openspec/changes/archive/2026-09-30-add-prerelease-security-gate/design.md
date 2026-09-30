## Context
Arunika spans four sibling repositories: `arunika_app` (Flutter), `arunika-backend` (Go/Gin), `arunika-backoffice` (React/Vite, served by nginx) and `arunika-landing` (static HTML). Each repo already has a CI test pipeline and a coverage ratchet (`test-ci-pipelines`). None has security scanning, DAST or performance baselines. The drafted checklist and script assume a monorepo and a single React app, so they do not map onto these repos as written.

## Goals / Non-Goals
- Goals: one command per repo that runs every applicable check; missing tools are visible failures; a single triage record for the release; all blockers fixed before shipping.
- Non-Goals: running the gate in CI (it needs Docker, a running stack and long scans; revisit later), certificate pinning, testing against production infrastructure, replacing a human pentest.

## Decisions

### Per-repo scripts, with the triage record in `arunika_app`
Each repo owns `scripts/prerelease_check.sh` and a `make prerelease` target. `arunika-landing` has no Makefile and gets only the script. Each script checks only its own stack. The combined triage record lives in `arunika_app/docs/prerelease-triage.md`, next to the openspec specs that already cover all four repos.

### Check matrix
| Repo | Security | Correctness / performance |
|---|---|---|
| all | `gitleaks detect` (history + working tree); TODO/FIXME grep on auth/payment/entitlement paths | — |
| app | `flutter analyze`; `dart pub outdated` (manual advisory review) | `flutter test --coverage` + existing `coverage_ratchet.py` |
| backend | `gosec`, `govulncheck`, `make lint` (gofmt + golangci-lint) | `go test -race`; benchmarks vs `bench-baseline.txt`; k6 against a locally running API |
| backoffice | `npm audit --omit=dev --audit-level=high` (full audit saved for triage); ESLint with `eslint-plugin-security`; ZAP baseline | `npm test`; `npm run build` bundle size vs `bundle-baseline.json` |
| landing | ZAP baseline | Lighthouse vs `lighthouse-baseline.json` |

### Missing tools fail the gate
The drafted script marks a missing tool as "skipped" and still exits 0. The gate treats a missing required tool as a failure and prints the install command. Passing `--allow-missing` changes these to warnings, and the summary lists every skipped check, so a partial run cannot be mistaken for a clean one. Stack-dependent checks (k6, ZAP, Lighthouse) are skipped with a printed notice when their target is unreachable. Pass `--skip-load` / `--skip-dast` to skip them explicitly.

### Runtime dependencies gate the backoffice audit
The backoffice ships as a static bundle, so only runtime dependencies reach users. The gate blocks on `npm audit --omit=dev --audit-level=high` and writes the full audit, including dev tooling, to the report for triage. This applies the severity policy's "unreachable → track" rule mechanically.

### Scanner suppressions are the owner's call
The gate never suppresses its own findings: no `#nosec`, no `.gitleaksignore` and no excluded directories are added as part of this change. False positives are listed in the triage record with the exact suppression line, and the owner adds it after review. Until then the gate stays red, which is the intended behaviour.

### ZAP targets the image that ships
Use `ghcr.io/zaproxy/zaproxy:stable`. The `owasp/zap2docker-stable` image in the drafted script is deprecated and no longer updated. For the backoffice, ZAP scans the production Docker image, not `vite preview`: the security headers come from `nginx.conf`, so a Vite dev server would report findings that don't match what ships. The landing page is scanned from a local static server. Its real headers depend on the hosting provider, so header findings there are recorded as "verify on host", not as blockers.

### Load test targets real read endpoints
k6 hits `/health` plus the public catalog/dongeng list endpoints at 20 VUs for 30s, and records p95 latency and error rate. Results are informational until the API runs on production-like infrastructure. An error rate above 1% is investigated.

### Baselines are recorded on first run
No benchmark, bundle size or Lighthouse history exists yet. The first gate run writes the baseline files. Later runs compare against them and flag a regression above 20% (benchmarks, bundle) or a drop above 10 points (Lighthouse). A `--write-baselines` flag re-records them after an intentional change, like `make coverage-baseline`.

### Profile cache moves to secure storage
`LocalProfileStorage` keeps its API (`save`/`get`/`clear`), so its four callers don't change. Its storage moves to `flutter_secure_storage`. On the first `get()` after upgrade, if the secure store is empty and the legacy `SharedPreferences` key exists, the value is copied into secure storage and the legacy key is deleted. `clear()` also removes the legacy key. Feature-flag caching stays in `SharedPreferences` because it holds no PII.

### Backoffice CSP
nginx drops every `add_header` inherited from the parent block as soon as a `location` declares one of its own. The fix moves the security headers into a shared include (or repeats them) so they appear in every location. It adds `Content-Security-Policy` with `default-src 'self'`, `script-src 'self'`, `connect-src` limited to the API origin (substituted at image build time from `VITE_API_BASE_URL`), `frame-ancestors 'none'`, `object-src 'none'` and `base-uri 'self'`. `style-src` needs `'unsafe-inline'` because Ant Design injects CSS-in-JS at runtime, and `img-src` allows `https:` because banner images are admin-entered URLs. A Playwright auto-fixture fails any E2E test that logs a CSP violation, so the policy is re-verified on every E2E run.

### Certificate pinning: not now
This decision is recorded in the triage report, not implemented. If the pinned certificate rotates (e.g. Let's Encrypt every 90 days) and the app has no remote pin-update path, every installed copy loses network access until users update. The API already runs over TLS, and tokens are short-lived and revocable (`security-regression-tests`). Revisit once hosting is settled, using SPKI pinning of the intermediate CA with a backup pin.

## Risks / Trade-offs
- First-run scans may surface many findings → the severity policy decides what blocks release. Non-blockers are tracked in the triage record, not fixed now.
- Local DAST and load results don't reflect production TLS, CDN or network conditions → the triage record lists the checks to re-run once a deployment URL exists.
- Secure-storage migration runs on the first read after upgrade → if it fails, the profile is refetched from the API (`profile_loader` already falls back to the network), so the failure is a cache miss, not data loss.

## Open Questions
- Hosting provider for the landing page and API (this affects header verification and the future pinning decision). This doesn't block the change.
