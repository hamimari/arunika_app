## 1. Tooling
- [x] 1.1 Install gitleaks, gosec, govulncheck, golangci-lint and k6. Confirm Docker is running and can pull `ghcr.io/zaproxy/zaproxy:stable`
- [x] 1.2 Add `prerelease-reports/` to `.gitignore` in all four repos

## 2. Per-repo gates (2.1–2.4 are independent and can run in parallel)
- [x] 2.1 `arunika_app`: `scripts/prerelease_check.sh` + `make prerelease` (gitleaks, flutter analyze, flutter test --coverage + ratchet, dart pub outdated, TODO/FIXME grep)
- [x] 2.2 `arunika-backend`: `scripts/prerelease_check.sh` + `make prerelease` (gitleaks, gosec, govulncheck, make lint, go test -race, benchmarks vs baseline, k6 against local API)
- [x] 2.3 `arunika-backoffice`: add `eslint-plugin-security` to `eslint.config.js`; `scripts/prerelease_check.sh` + `make prerelease` (gitleaks, npm audit, eslint, npm test, bundle size vs baseline, ZAP against Docker image)
- [x] 2.4 `arunika-landing`: `scripts/prerelease_check.sh` (gitleaks, ZAP and Lighthouse against local static server)
- [x] 2.5 Shared gate behaviour in every script: missing tool fails unless `--allow-missing`; `--skip-load`, `--skip-dast`, `--write-baselines`; summary lists failures and skipped checks; non-zero exit on any failure
- [x] 2.6 Verify: temporarily hide one tool from PATH and confirm the gate fails, then passes with `--allow-missing` and lists the tool as skipped

## 3. Known fixes
- [x] 3.1 `LocalProfileStorage` → `flutter_secure_storage`, with a one-time migration that deletes the legacy `SharedPreferences` key; `clear()` removes both keys
- [x] 3.2 Unit tests: migration copies then deletes the legacy key; `clear()` removes both keys; `get()` returns null when both are empty
- [x] 3.3 Backoffice `nginx.conf`: security headers on every location + CSP
- [x] 3.4 Verify 3.3: `curl -I` of `/` and of a hashed `.js` asset from the Docker image both show all headers; the Playwright E2E suite passes against the image

## 4. Run and triage (depends on 1–3)
- [x] 4.1 Run `make prerelease` in each repo (with the API stack up for k6/ZAP) and record the baselines
- [x] 4.2 Create `docs/prerelease-triage.md` listing every finding with its repo, tool, severity per the policy, decision (blocker / tracked / false positive) and rationale
- [x] 4.3 Fix every blocker. If a secret is found in git history, rotate it first, then remove it
- [x] 4.4 Record the manual reviews in the triage report: certificate-pinning decision; Midtrans WebView navigation restrictions; `url_launcher` targets; Android intent filters and exported components
- [x] 4.5 Record the manual Flutter profile-mode run on a real device (cold start time, visible jank) in the triage report — **deferred**: no physical device was available during this change; emulator numbers stand in, see the triage report for the follow-up
- [x] 4.6 List the checks to re-run once a deployment URL exists (ZAP, k6, landing headers)
- [x] 4.7 Re-run all four gates: each exits 0 with no `--allow-missing`

## 5. Validation
- [x] 5.1 Existing suites green in all repos (`make test-all` in app/backend, `npm run test:ci` in backoffice)
- [x] 5.2 `openspec validate add-prerelease-security-gate --strict`
