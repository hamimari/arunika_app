## Why
Arunika is about to ship its first public release. It handles children's PII and real payments (Midtrans and Google Play Billing), and no single pass has yet run SAST, dependency CVE scanning, secret scanning, DAST and performance checks across all four repos. A generic pre-release script was drafted outside the repo (`~/Downloads/prerelease_check.sh`). It assumes a `./backend ./web ./mobile` monorepo, and when a tool is missing it skips the check and still exits 0. On this machine gitleaks, gosec, govulncheck, golangci-lint and k6 are all missing, so that script would report a green release having checked nothing. A first look during this proposal also found real gaps:

- **Flutter:** the full parent profile (name, phone, email, address, children) is cached in plaintext `SharedPreferences` (`lib/core/storage/LocalProfileStorage.dart`). Tokens already use `flutter_secure_storage`, but this PII does not.
- **Backoffice:** `nginx.conf` sends no `Content-Security-Policy`. Its static-asset `location` block also sets its own `add_header`, so by nginx's inheritance rule every JS/CSS/image response loses `X-Frame-Options`, `X-Content-Type-Options` and `Referrer-Policy`.
- **Flutter:** there is no certificate pinning. This is a deliberate decision to record, not an automatic blocker (see design.md).

## What Changes
- Add a **per-repo pre-release gate**: a `scripts/prerelease_check.sh` plus a `make prerelease` target in `arunika_app`, `arunika-backend` and `arunika-backoffice`, and a script only in `arunika-landing`, which is static HTML with no Makefile. Each gate runs only the checks that apply to that repo's stack and writes reports to a git-ignored `prerelease-reports/`.
- The gate **fails when a required security tool is missing** unless `--allow-missing` is passed, so a missing tool can never look like a pass.
- Adopt the **severity policy** from the drafted checklist as the triage rule. Blockers are secrets, reachable high/critical CVEs, and injection findings.
- Record **baselines** for Go benchmarks, the backoffice bundle size and the landing Lighthouse score, so later releases can detect regressions (>20% for performance, >10 points for Lighthouse).
- **Run the gate on all four repos, triage every finding** into `docs/prerelease-triage.md`, and **fix every blocker** before release.
- **Fix known gaps:** move the cached profile to secure storage, migrating it once and deleting the plaintext copy; add a CSP to the backoffice and send its security headers on every response.
- **Record the certificate-pinning decision** and the manual mobile attack-surface review (Midtrans WebView, `url_launcher`, Android intent filters) in the triage report.

Out of scope: cert pinning implementation, semgrep (gosec covers the Go injection patterns), CI wiring of the gate, and load testing against production infrastructure. The checklist itself notes that local DAST and load results must be re-run once a real deployment exists.

## Impact
- Affected specs: `prerelease-gate` (new), `flutter-prod-hardening` (ADDED requirement), `backoffice-prod-hardening` (new)
- Affected code:
  - `arunika_app`: `scripts/prerelease_check.sh`, `Makefile`, `.gitignore`, `lib/core/storage/LocalProfileStorage.dart`, `docs/prerelease-triage.md`
  - `arunika-backend`: `scripts/prerelease_check.sh`, `Makefile`, `.gitignore`, `bench-baseline.txt`, plus fixes for any blocker findings
  - `arunika-backoffice`: `scripts/prerelease_check.sh`, `Makefile`, `nginx.conf`, `eslint.config.js` (+ `eslint-plugin-security`), `.gitignore`, `bundle-baseline.json`
  - `arunika-landing`: `scripts/prerelease_check.sh`, `.gitignore`, `lighthouse-baseline.json`
- Developer tooling to install: gitleaks, gosec, govulncheck, golangci-lint, k6, and Docker for ZAP (already installed)
