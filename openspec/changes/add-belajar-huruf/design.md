## Context
The RFC describes a greenfield setup: "the app has no subscription handling today", with a new entitlement service, a new staff role model and a new asset pipeline. The code says otherwise, and in a few places it is missing what the RFC assumes:

- **Akses Premium already exists.**
  - `user_subscriptions` (status `free`/`premium` plus `expires_at`, one row per user) is fed by Midtrans and Google Play Billing (`/payment/play/verify`, the RTDN webhook `/payment/play/rtdn`, reconciliation and renewal).
  - `EntitlementService.HasAccess` / `hasActiveSubscription` decide access, and `SubscriptionMiddleware` returns 403 for non-subscribers.
  - The app has the `/premium` paywall (`PremiumUpgradeScreen`) behind `ParentalGateGuard`.
  - Billing is Android-only (`in_app_purchase_android`), and there is no App Store integration.
- **Admin auth is a single role.**
  - `admin_users` (email, password) issue a JWT with `role: "admin"`, and `AdminAuthMiddleware` accepts any admin.
  - There are no editor/publisher roles and no audit log.
- **There is no upload pipeline.** Every backoffice content form takes a pasted URL (`image_url`, `audio_url`). Existing media live on `pub-….r2.dev`, which Internet Positif blocks in Indonesia. `launch-production-on-haloarunika` task 5 moves media to `media.haloarunika.com`, an R2 custom domain.
- **Content today is edited live.** There are no drafts or versions.
- **There is no app remote config** other than the boolean `app_feature_flags`.
- **The Belajar tab** (`BelajarTab`, a nested Navigator with `BelajarDestination`) comes from `add-growth-tracking`. This change adds a `huruf` destination to it.
- **Legacy `tracing_items` / `tracing_progress`** (V17, V22, `/tracing/*`, the backoffice "Tracing Items" page) exist, but the app does not use them. They are generic (`alphabet|number|shape`, unversioned, no audio) and do not fit Huruf. They are left untouched, and removing them is a separate cleanup.

The decisions taken with the product owner:
- reuse the existing subscription;
- build versions **and** roles and an audit log;
- build **real uploads** to storage;
- **defer offline** play.

## Goals / Non-Goals
- **Goals:**
  - PRD FR-1 to FR-7 for the first child;
  - BO-1 to BO-6;
  - one free letter;
  - access decided only by the server;
  - publishing reaches devices within 15 minutes;
  - a tracing evaluator that is deterministic and unit-testable.
- **Non-Goals:**
  - offline play;
  - iOS purchases;
  - a new subscription model;
  - signed URLs;
  - WebP conversion;
  - a Flutter Web preview;
  - multi-child;
  - Angka and Stimulasi;
  - roles on non-Huruf admin pages.

## Decisions

### D1. Entitlement: reuse Akses Premium
- `premium(user)` uses today's `hasActiveSubscription` rule: `status = 'premium' AND (expires_at IS NULL OR expires_at > now())`. It is exported as `EntitlementService.HasActiveSubscription(userID)`.
- Play's grace period is already reflected, because RTDN `SyncSubscriptionExpiry` moves `expires_at`. Content-only purchases (`user_entitlements`) do **not** unlock Huruf. Only the subscription does.
- `HurufService` checks access for each letter it serves or records progress for. It lets a request through when the letter's published `is_free` is true or the user is premium. Otherwise it answers **`402 {"error":"premium required","code":"PREMIUM_REQUIRED"}`**.
  - The check lives in the service rather than in a middleware, so a progress write checks child ownership (404) before access (402), and the letter is loaded once.
  - The new routes use 402, not the old middleware's 403, so the app can tell "locked" from "forbidden".
  - `SubscriptionMiddleware` is unchanged.
- **The free letter** is `letters.is_free`, enforced by a partial unique index (`WHERE is_free`). `set-free` clears the old free letter and sets the new one in one transaction. Seeded default: A.
- **Expiry mid-activity:** the app has the letter content in memory, so the child finishes the current letter. Progress writes for a locked letter return 402. The app keeps them in memory, does not show an error, and drops them. The next grid load shows locks.
- **Alternative considered:** the RFC's `subscriptions` and `subscription_events` tables plus `/subscriptions/verify`. They duplicate a working Play integration and would mean migrating live subscribers. Revisit when iOS billing is added.

### D2. Content model, versions and publish
- **Tables:**
  - `letters`: `id uuid`, `upper char(1) UNIQUE` (A–Z), `sort_order smallint`, `is_free bool`, `status text CHECK (draft|published|hidden)`, `draft jsonb`, `draft_rev integer`, `published_version_id uuid NULL`, `updated_by uuid → admin_users`, `updated_at`;
  - `letter_versions`: `id`, `letter_id`, `version int`, `content jsonb`, `published_by`, `published_at`, `UNIQUE(letter_id, version)`.
  - The seed migration inserts 26 letters as `draft` with `{upper, lower, feedback defaults}` and A as `is_free`.
- **Content JSON** follows the RFC shape in snake_case:

```json
{ "upper":"A","lower":"a",
  "kenali":{"word":"Apel","highlight":[0],"image_asset_id":"…"},
  "dengar":{"letter_audio_id":"…","word_audio_id":"…"},
  "tebalkan":{"grid":300,"lower_required":false,
    "upper":[{"order":1,"label":"Garis miring kiri","path":"M150 30 L70 260"}],
    "lower":[]},
  "feedback":{"success":"Keren! Huruf {huruf} rapi!","retry":"Belum pas, ayo lagi!","hint":"Mulai dari angka 1, lalu ikuti titik-titik sampai ujung."} }
```

- **Status:**
  - `hidden` hides a letter from the manifest, but `published_version_id` is kept, so unhiding restores it.
  - "Ada perubahan belum terbit" is derived: the canonical JSON of `draft` differs from the published `content`.
  - The list shows **Draft** when no version exists yet, **Terbit** when published and unchanged, and **Ada perubahan** when published with a differing draft.
- **Draft writes** use optimistic concurrency.
  - `PUT /admin/huruf/letters/:id/draft` takes `{draft, draft_rev}`.
  - If `draft_rev` is stale, the server answers `409 DRAFT_CONFLICT`, so two editors don't silently overwrite each other.
  - Autosave in the backoffice is debounced (2 s).
- **Publish**, in one transaction:
  1. validate the draft (D5);
  2. insert `letter_versions` with `max(version)+1`;
  3. point `published_version_id` at it;
  4. set `status = 'published'`;
  5. write an audit entry.
- **Rollback** copies an old version's content into a **new** version and into the draft, so history only grows.
- **Reorder** takes the full array of letter ids and rewrites `sort_order` 1..n in one transaction.

### D3. Delivery: manifest, ETag, 15-minute freshness
- **`GET /learn/huruf/manifest`** (auth only) returns:
  - the published, non-hidden letters in order, each with `{id, upper, lower, word, is_free, locked, version, image_url}`;
  - `tracing_thresholds` (D6).
- The **ETag** is a SHA-256 over the manifest body *without* `locked`, plus the caller's premium bit, so subscribing changes it. `If-None-Match` answers 304.
- **`GET /learn/huruf/letters/:id`** (guarded by D1) returns the published `content` with resolved asset URLs (`image_url`, `letter_audio_url`, `word_audio_url`) and the `version`.
- **App caching.** The app refetches the manifest when Belajar Huruf opens and the last fetch is older than 15 minutes, on pull-to-refresh, and when it returns from `/premium`. Letter JSON is cached in memory by `(id, version)`, and media go through the existing `MediaCache`. This meets "published changes reach the app within 15 minutes" without push.

### D4. Media assets
- **Endpoint:** `POST /admin/assets`, multipart with `file` and `kind` (`image` or `audio`). It requires the editor role or higher.
- **Validation runs on the bytes:**
  - Image: sniff PNG or WebP (magic bytes, not the filename), ≤ 500 KB, decoded dimensions square, between 256 and 2048 px. Uses `image/png` and `golang.org/x/image/webp` decode only.
  - Audio: sniff MP3 (ID3 or frame sync) or AAC (ADTS), ≤ 300 KB. Duration is computed by walking the MP3 or ADTS frames, must be ≤ 10 s, and is stored in ms.
  - Anything else answers `422 INVALID_ASSET` with a reason code: `UNSUPPORTED_TYPE`, `TOO_LARGE`, `NOT_SQUARE`, `TOO_LONG` or `UNREADABLE`.
- **Storage:**
  - The key is `huruf/<sha256>.<ext>`. Upload is idempotent: if a `content_assets` row with that `sha256` already exists, it is returned.
  - The `storage.Store` interface has two drivers:
    - `r2`, an S3-compatible client (`aws-sdk-go-v2/service/s3`), configured by `MEDIA_S3_ENDPOINT`, `MEDIA_S3_BUCKET`, `MEDIA_S3_ACCESS_KEY_ID`, `MEDIA_S3_SECRET_ACCESS_KEY`;
    - `local`, which writes to `MEDIA_LOCAL_DIR` and serves it at `/media/huruf/:file`, for dev and e2e.
  - The public URL is `MEDIA_PUBLIC_BASE_URL + key`.
- **`content_assets` columns:** `id`, `kind`, `storage_key`, `sha256 UNIQUE`, `bytes`, `mime`, `width`, `height`, `duration_ms`, `original_name`, `created_by`, `created_at`.
- **Public, not signed (deviation from the RFC):**
  - The keys are unguessable hashes, and only premium letter JSON reveals them.
  - Signed URLs would also defeat device and CDN caching.
  - The risk is someone sharing a direct image or audio link, which is low value. Signed URLs can be added behind the same `storage.Store` later.
- **No WebP conversion (deviation from the RFC).** Go has no pure WebP encoder, and cgo (libwebp) complicates the Docker build. Admins upload WebP or PNG within 500 KB.

### D5. Publish validation
Publish is blocked with `422 {"code":"VALIDATION_FAILED","fields":[{"path":"kenali.word","code":"REQUIRED"},…]}`, and the backoffice maps each `path` to its field. The rules:
- `kenali.word` is 1–20 letters and starts with, or contains at the highlighted indexes, the letter (case-insensitive). `highlight` is non-empty and within the word.
- `kenali.image_asset_id` exists and is of kind `image`. `dengar.letter_audio_id` and `dengar.word_audio_id` exist and are of kind `audio`.
- `tebalkan.upper` has ≥ 1 stroke. When `lower_required` is true, `lower` has ≥ 1 stroke too.
- Every stroke has a unique, contiguous `order` starting at 1. Its `path` parses with the shared grammar (absolute `M`, `L`, `Q`, `C` only, a single subpath starting with `M`, coordinates within 0–300).
- Feedback texts are non-empty and ≤ 80 characters (hint ≤ 160).

The Go path parser and the Dart path parser share a fixture file of valid and invalid paths (`testdata/svg_paths.json`, copied into the app).

### D6. Tracing evaluator (app)
- Implemented exactly as the RFC describes, as pure Dart under `lib/core/tracing/`:
  - `SvgPathParser` turns a path into segments.
  - `GuideSampler` resamples every 4 units, flattening `Q` and `C` by adaptive subdivision.
  - `StrokeEvaluator` normalizes touches to the 300 grid, drops points closer than 2 units, rejects a touch that starts more than 30 units from the start point, marks coverage within radius r, and on finger up computes coverage, accuracy (within 2r) and direction (≥ 70% forward projection steps). It returns `pass` / `fail(reason)`.
  - `LetterTraceSession` handles stroke order, the 3-failures-per-stroke rule and the score (mean of coverage × accuracy).
- **Thresholds** are `{radius: 22, coverage: 0.80, accuracy: 0.85, direction: 0.70, start_tolerance: 30, max_failures: 3}`. They arrive in the manifest's `tracing_thresholds`, sourced from backend env (`HURUF_TRACING_*`) with these defaults, so they can be tuned without an app release (deviation: no separate remote config). The app falls back to compiled defaults when they are missing.
- **Retry reasons** map to the retry pop-up's subtitle:
  - off path → "Garisnya keluar dari jalur huruf {X}.";
  - too short → "Garisnya belum sampai ujung.";
  - wrong direction → "Arah garisnya terbalik.".
- **"Lihat contoh"** moves a dot along each stroke in order, 600 ms per stroke, from the same samples. Rendering is a `CustomPainter` with three layers: the guide (light band plus dotted centre line), the covered samples in brand orange, and markers (numbered start points and direction arrows at 60% of each stroke).
- **Fixtures:** synthetic traces (exact, noisy within r, a 50% partial, reversed, a scribble, off-start) for A, B, O (curves) and lowercase a. Until recorded child traces exist, the evaluator must pass the good traces and fail the rest.

### D7. Progress
- **Table:** `letter_progress(child_id → children ON DELETE CASCADE, letter_id → letters, kenali_done, dengar_done, tebalkan_done, best_score numeric(3,2), attempts int, updated_at, PRIMARY KEY(child_id, letter_id))`.
- **`PUT /children/:childId/huruf/progress/:letterId`** takes `{kenali_done?, dengar_done?, tebalkan_done?, score?, attempt?: bool}`:
  - flags are OR-merged, so a stale write never clears a completion;
  - `best_score = GREATEST`;
  - `attempts += 1` when `attempt` is true.
  - It is guarded by child ownership (404, as in growth) and by D1.
- The **app** marks Kenali and Dengar done when a letter opens (Dengar's sounds live on the Kenali tab), and Tebalkan after the required cases pass. A letter is done when Kenali and Tebalkan are done; the server keeps `dengar_done` so a separate Dengar activity can return without a migration. A write that fails is retried with backoff while the screen is open (no persistent queue, because offline is deferred).
- **Letter done** = all three flags. "x dari 26 selesai" counts done letters among the published letters in the manifest. **"Lanjutkan belajar"** is the most recently updated letter with progress that is not done.
- **Stars:** the "+1 bintang" and the three stars in the pop-up are celebratory UI only. The PRD defines no star economy for Huruf, so nothing is stored.

### D8. Roles and audit
- **Roles:**
  - Migration: `admin_users.role text NOT NULL DEFAULT 'publisher' CHECK (role IN ('editor','publisher'))`. Existing admins become publishers, so nobody loses access.
  - Login and refresh responses include `role`. The JWT keeps `role: "admin"` for `AdminAuthMiddleware`, which is unchanged.
- **`RequireAdminRole("publisher")`:**
  - It reads the role from the DB on each request, so a demotion takes effect immediately without waiting for the 15-minute token expiry.
  - It is applied to: Huruf publish, hide/unhide, set-free, reorder, rollback, and changing a role.
  - Draft read and write, preview, version listing and asset upload stay open to any admin role.
  - Every other existing admin route is untouched.
- **Role management:**
  - `GET /admin/admins` lists `{id, email, role}` for any admin (editors see the page read-only). `PATCH /admin/admins/:id/role` changes a role and requires publisher.
  - Demoting the last publisher answers `409 LAST_PUBLISHER`.
  - Creating admin accounts stays out of scope (it happens via the seed or SQL today).
- **Audit:**
  - Table: `admin_audit_log(id bigserial, admin_id, action text, entity_type text, entity_id text, before jsonb, after jsonb, created_at)`, indexed on `(entity_type, entity_id, created_at DESC)`.
  - It is written **in the same transaction** as each Huruf admin write (`draft.save`, `publish`, `rollback`, `hide`, `unhide`, `set_free`, `reorder`), each asset upload, and each role change.
  - Autosave draft entries are coalesced: consecutive `draft.save` entries by the same admin within 10 minutes update the last row's `after` instead of inserting a new one, so the log stays readable.
  - `GET /admin/audit-log?entity_type=letter&entity_id=…` feeds the history drawer.

### D9. Backoffice editor and preview
- **Stack:** the existing React + antd + react-query backoffice. The pages are new, under `src/pages/huruf/`. The menu gets a "Konten Belajar" group with "Huruf", plus "Pengaturan & peran". Existing English labels are kept, and the new pages use the design's Indonesian copy.
- **Stroke editor:**
  - an SVG 300 × 300 grid;
  - "Gambar garis" adds a straight stroke by click-drag (`M x y L x y`, snapped to 5 units);
  - "Unggah SVG" imports the `path` `d` attributes of an uploaded SVG (one stroke per path, in document order, scaled to the viewBox, then validated);
  - each stroke has a label, its raw path (editable as text, validated live by the TS parser) and a delete button;
  - drag reorders the strokes.
  - Curves come in via SVG import or by editing the text.
- **Preview:** React and SVG components that mirror the app's layout for Kenali and Tebalkan, fed the current draft, including "Putar contoh" (the same 600 ms per stroke animation) and audio playback. It does not evaluate tracing. **Deviation from the RFC:** it is not Flutter Web. Shipping a Flutter Web build inside the Vite app adds a second toolchain and several MB to the bundle. Path parsing parity across Go, Dart and TS is covered by the shared fixture (D5).

### D10. App placement and gating
- **Flag:** `FeatureFlag.belajarHuruf = 'belajar_huruf'`, added to `failClosed`. When it is off, the Huruf card on the hub and the Beranda "Lanjutkan belajar" row are hidden.
- **Guests:** they see the hub card. Tapping it uses the existing `auth_guard` login prompt, because progress needs a child.
- **The first child** is used, as in `GrowthCubit.firstChildId`. A user without a child sees the incomplete-profile state that links to Profil.
- **`BelajarDestination.huruf`** opens `HurufListScreen` in the Belajar navigator. The letter detail is pushed inside the same navigator. Locked taps push the root `/premium` route, which already sits behind the parental gate.
- **The feedback dialog** `LearningFeedbackDialog` (variants `success` and `retry`) is generic and takes the title, subtitle, hint and actions, so Angka can reuse it.
- **Sound:**
  - `just_audio` with the default (ambient-respecting) audio session, which never overrides silent mode.
  - When the media volume is 0, the speaker buttons show a muted icon. This needs `volume_controller` or a platform channel; if neither is acceptable, the indicator is dropped (P1).
  - An audio load failure shows a retry icon, and activities still complete.

## Risks / Trade-offs
- **Public media URLs** can be shared. *Mitigation:* the hashed keys are unguessable, and signed URLs can be added behind `storage.Store`.
- **Synthetic tracing fixtures** may not reflect real children's input. *Mitigation:* thresholds are server-tunable, and the usability test before rollout records traces into fixtures.
- **Roles read from the DB** add one indexed query on publisher routes. This is negligible at backoffice volume.
- **Android-only purchase.** iOS users can't subscribe until App Store billing exists. Huruf access follows the account, so an Android subscription unlocks iOS.
- **R2 credentials** are new secrets on the VPS (`.env`), and the local driver must never be enabled in prod (`MEDIA_DRIVER=r2` is required when `APP_ENV=production`; startup fails otherwise).

## Migration Plan
1. Backend migrations (next free versions; V63 if growth's V62 is merged first):
   - **V63** `content_assets` and `admin_audit_log`, plus `admin_users.role`;
   - **V64** `letters`, `letter_versions` and `letter_progress`, plus the 26 draft letters with A free;
   - **V65** the `belajar_huruf` flag (off).
   All of them are additive, so rollback is the down path of dropping the new tables and column. Nothing existing changes.
2. Configure R2 (`MEDIA_*`) once the `media.haloarunika.com` custom domain exists.
3. Deploy the backend and the backoffice. The content team uploads assets and publishes the 26 letters.
4. Release the app with the flag off. Enable it for internal testing, then for everyone (the flags are boolean today, so there is no 10% stage. See open questions).

## Open Questions
- The PRD's 10% rollout stage needs percentage flags, which `app_feature_flags` doesn't support. Is it enough to go internal → 100%? (Assumed yes.)
- Should "Lanjutkan belajar" on Beranda appear for non-subscribers whose only progress is the free letter? (Assumed yes.)
