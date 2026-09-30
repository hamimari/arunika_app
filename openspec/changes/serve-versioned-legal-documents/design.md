## Context
Consent evidence (`user_consents`) is already append-only and per document. What is missing is an authoritative, immutable record of each version's text, and a single place that decides the current version. The work spans three repos: landing (where the files live), backend (the registry and endpoint) and app (display and submit).

## Goals / Non-Goals
- Goals: one source for each version's text; a hash on record for every version a user can accept; T&C changes that need no app release; no re-consent loop.
- Non-Goals: a CMS for legal text; storing the HTML body in Postgres; multi-language documents.

## Decisions

### Files on the landing site, with URL and hash in the DB
The text lives as static HTML at `legal/<document>/<version>.html` on the landing site. The DB stores the URL and the SHA-256 of the file's bytes.
- Why not the text in a DB column: the landing site must serve the page publicly anyway (the Play Console privacy URL), so a DB copy would be a third copy to keep in sync. Legal edits also belong in a reviewed git diff, not a backoffice form.
- Why a hash: the URL alone proves nothing if the file is later edited. With the hash, anyone can show that the archived file is the one that was accepted. `legal_check.sh` fails if a published version file no longer matches its recorded hash. It reads the hashes from a `legal/manifest.json` that `legal_publish.sh` writes.
- Why not R2: the landing repo already deploys the legal pages, and git history is a second archive. R2 remains an option if the landing host changes.

### The version registry is a table, and versions are added by migration
`legal_documents(document, version, url, sha256, effective_at, created_at)` has primary key `(document, version)`.
- The current version of a document is `MAX(version) WHERE effective_at <= now()`. Versions are ISO dates, so string order is chronological. A new version can be merged ahead of time with a future `effective_at` and takes effect without a deploy on the day.
- A migration rather than an admin endpoint: publishing is rare, legal and reviewed. `legal_publish.sh` prints the `INSERT` for the migration.
- `user_consents` gains `FOREIGN KEY (document, version) REFERENCES legal_documents`. Production has no consent rows yet. The migration seeds `2026-10-01` for all three documents before adding the FK, so existing test and e2e rows remain valid.

### Parental declaration is a document too
The PARENTAL declaration is a single sentence shown as the checkbox label, but consent is recorded against it, so it gets its own version file (`legal/parental/<version>.html`, a single `<p>`). The app shows the fetched text as the label, converting the HTML to plain text, so what is ticked and what is recorded cannot differ.

### App display: WebView restricted to the document URL
`webview_flutter` is already a dependency. The screen loads the `url` from `/legal/current` with JavaScript disabled. Links to the same host are allowed, and any other link opens in the external browser through `url_launcher`. The WebView does not verify the hash itself: the backend is trusted to serve the right URL, and the hash exists for later audit, not for client verification.
- Alternative considered: fetching the HTML and rendering it natively (`flutter_html`). Rejected because it adds a package and a second renderer for the same markup.

### Outdated versions are rejected, not recorded
Signup and `POST /user/consent` accept only a document's current version:
- An unknown version returns 400 (`LEGAL_VERSION_UNKNOWN`).
- A known but not current version returns 409 (`LEGAL_VERSION_OUTDATED`) with a message in Indonesian.
The existing comment that the backend "stores what the client sent" still holds, because the only versions accepted are ones the client was actually served. The 409 turns the old-build loop into a visible prompt to update. On a 409, a new build refetches `/legal/current` and asks the user to read the new text.

### Offline / fetch failure
Signup and consent already need the network. If `/legal/current` or the page fails to load, the screen shows the existing full-page error view with a retry, and the accept button stays disabled until the documents have loaded.

## Risks / Trade-offs
- **Landing host outage blocks signup:** accepted, because the backend being down blocks it too. Mitigation: host the landing site on a static CDN (it already is static).
- **Someone edits a published version file:** `legal_check.sh` fails in the landing CI and in the pre-release gate.
- **`effective_at` in the future but the migration is deployed early:** intended, and covered by a test.
- **Landing domain:** URLs are absolute in the DB. If the domain changes, a migration rewrites the URLs, while hashes and versions stay the same.

## Migration Plan
1. Landing: publish the `2026-10-01` version files and the manifest, and deploy.
2. Backend: deploy V62 (table, seed, FK) with the endpoint, the DB-driven current version, and the 409/400 checks. Old clients keep working, because they send `2026-10-01`, which is current.
3. App: release the build that uses `/legal/current`.
4. First real text change: publish the version files, merge a migration with the future `effective_at`, and deploy. No app release is needed.
Rollback: revert the app and backend code. The table and FK are harmless to keep.

## Open Questions
- The landing site's production domain is needed for the seeded URLs. It is not in any repo yet.
