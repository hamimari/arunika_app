All work happens on the `belajar-huruf` branch in each repo, cut from `growth-tracking-feature`. Dependencies between sections:
- Sections 1–3 (backend foundations) come first.
- Section 4 needs sections 1–2.
- Section 5 needs section 4.
- App section 6 (tracing engine) can run in parallel with all backend work.
- App sections 7–9 need section 4.
- Backoffice sections 10–12 need sections 2, 3 and 5.

## 1. Backend: roles and audit
- [x] 1.1 Migration: add `admin_users.role` (`editor`|`publisher`, default `publisher`) and create the `admin_audit_log` table and index.
- [x] 1.2 Changes to the `AdminUser` model, `AdminAuthService` and the auth handlers: return `role` on login and refresh.
- [x] 1.3 Add `middlewares.RequireAdminRole("publisher")`, which looks up the role in the DB on each request.
- [x] 1.4 Add `services.AuditService.Record(tx, …)`, coalescing consecutive `draft.save` entries by the same admin and entity within 10 minutes.
- [x] 1.5 Add `GET /admin/audit-log` (filter by entity, paginated).
- [x] 1.6 Add `GET /admin/admins` and `PATCH /admin/admins/:id/role` with the `LAST_PUBLISHER` guard and audit entries. *(Listing is open to any admin so editors see the roles page read-only; only the PATCH needs publisher.)*
- [x] 1.7 Tests:
  - middleware: an editor gets 403, and a demotion takes effect immediately;
  - the coalescing rule;
  - the last-publisher guard;
  - the migration keeps existing admins as publishers.

## 2. Backend: media assets
- [x] 2.1 Add a `storage` package with a `Store` interface and the `r2` driver (aws-sdk-go-v2 S3 against the R2 endpoint) and the `local` driver (directory plus the `/media/*` static route).
- [x] 2.2 Config (`config.go`, `.env.example`):
  - add `MEDIA_DRIVER`, `MEDIA_S3_ENDPOINT`, `MEDIA_S3_BUCKET`, `MEDIA_S3_ACCESS_KEY_ID`, `MEDIA_S3_SECRET_ACCESS_KEY`, `MEDIA_PUBLIC_BASE_URL` and `MEDIA_LOCAL_DIR`;
  - in production, fail at startup unless the driver is `r2` and the base URL is set and not on `r2.dev`.
- [x] 2.3 Migration: create the `content_assets` table with a unique `sha256`.
- [x] 2.4 Add `AssetService`:
  - byte sniffing (PNG, WebP, MP3, ADTS AAC);
  - image size, squareness and 256–2048 px checks;
  - audio size check, with duration taken from the MP3/ADTS frame walk (≤ 10 s);
  - the SHA-256 key and idempotent re-upload;
  - an audit entry.
- [x] 2.5 Add `POST /admin/assets` (multipart, any admin role) with the `INVALID_ASSET` reasons.
- [x] 2.6 Tests:
  - fixture files: a valid PNG and WebP, a renamed JPEG, a non-square image, a 600 KB image, MP3s of 2 s and 12 s, an AAC file and a corrupt file;
  - deduplication;
  - the production config guard.

## 3. Backend: letter content and admin API
- [x] 3.1 Migration: create `letters` (with the one-free partial unique index), `letter_versions` and `letter_progress`. Seed A–Z as drafts with default feedback, and make A free.
- [x] 3.2 Add `models.Letter`, `LetterVersion` and `LetterProgress`, and the typed `LetterContent` struct (snake_case JSON).
- [x] 3.3 Add the `hurufpath` package: an absolute M/L/Q/C single-subpath parser with 0–300 bounds, plus `testdata/svg_paths.json` (valid and invalid cases).
- [x] 3.4 Add `HurufAdminService`:
  - list with the derived status and counts;
  - get and save draft (the `draft_rev` check, `DRAFT_CONFLICT`);
  - publish validation (design D5) with field paths;
  - publish, versions and rollback;
  - hide and unhide;
  - set-free (one transaction);
  - reorder (full-set check);
  - preview resolution.
  Every write records an audit entry in the same transaction.
- [x] 3.5 Add the admin routes and handlers. Guard publish, hide, unhide, set-free, order and rollback with `RequireAdminRole("publisher")`.
- [x] 3.6 Tests:
  - every validation rule;
  - version numbering and rollback creating a new version;
  - set-free exclusivity;
  - the order 422;
  - the conflict 409;
  - audit entries per action;
  - editor 403s.

## 4. Backend: public Huruf API
- [x] 4.1 Export `EntitlementService.HasActiveSubscription`. Check access per letter: allow the free letter or premium, otherwise answer `402 PREMIUM_REQUIRED`. *(Done in `HurufService` rather than a middleware, so a progress write checks child ownership before access; see design D1.)*
- [x] 4.2 Add `HurufService.Manifest(userID)`:
  - published, non-hidden letters in order, with `locked` and `premium`;
  - `tracing_thresholds` from `HURUF_TRACING_*` env with defaults;
  - an ETag over the content plus the premium bit, with 304 handling.
- [x] 4.3 Add `GET /learn/huruf/letters/:id`: the published content with asset URLs, and 404 for draft-only, hidden or unknown letters.
- [x] 4.4 Progress:
  - `GET /children/:childId/huruf/progress`;
  - `PUT …/:letterId` with OR-merged flags, `GREATEST` best score and attempts += 1;
  - child ownership 404 and access 402.
- [x] 4.5 Add `belajar_huruf` feature flag migration (off). Make account deletion remove `letter_progress`.
- [x] 4.6 `openapi.yaml`: add every new public and admin route and schema. Run the API contract tests.
- [x] 4.7 Tests:
  - a table-driven router test proving every guarded route returns 402 for a non-free letter without premium and 200 for the free one;
  - expired subscriptions and content-pack-only owners are denied;
  - the manifest ETag changes on publish, set-free and subscription;
  - progress merge semantics;
  - `tests/security/authz_test.go` covering cross-parent progress read and write.
- [x] 4.8 Run `make test` and the coverage baseline check.

## 5. Backend: wrap-up
- [x] 5.1 Register services and handlers in `registry.go` and `router.go`. Make sure the media route is mounted only for the local driver. *(Served at `/media/huruf/:file`, an explicit route the API contract test can document.)*
- [x] 5.2 Update the e2e stack (`docker-compose.test.yml`): use the local media driver, and seed one published letter with fixture assets for the app and backoffice e2e tests.

## 6. App: tracing engine (no backend dependency)
- [x] 6.1 Add `lib/core/tracing/svg_path.dart`: an M/L/Q/C parser, and a copy of `svg_paths.json` into `test/fixtures/` with a parity test.
- [x] 6.2 Add `guide_sampler.dart`: 4-unit resampling with adaptive curve flattening.
- [x] 6.3 Add `stroke_evaluator.dart`: normalization, the 2-unit point drop, the start tolerance, live coverage, and the finger-up verdict (coverage, accuracy, direction) with the reasons `off_path`, `too_short` and `wrong_direction`.
- [x] 6.4 Add `letter_trace_session.dart`: stroke order, the upper-then-lower flow when `lower_required` is set, `max_failures`, score, reset, and the `TracingThresholds` defaults.
- [x] 6.5 Unit tests with synthetic traces for A, B, O and lowercase a (exact, noisy, partial, reversed, scribble, off-start) and the threshold boundaries.

## 7. App: data layer and gating
- [x] 7.1 Add `FeatureFlag.belajarHuruf` (fail-closed) and `belajarHurufEnabled`.
- [x] 7.2 Add `data/api/huruf_api.dart` and the models (manifest, letter content, progress), and `data/repositories/huruf_repository.dart`:
  - the ETag and 15-minute refetch rule;
  - letter content cached in memory by (id, version);
  - progress writes with retry and backoff;
  - 402 mapped to a `HurufLocked` result.
  Register both in `di/locator.dart`. Add the paths to `api_paths.dart`.
- [x] 7.3 Add `HurufCubit`: the first child, manifest plus progress, derived tile states, the done counter, the "Lanjutkan belajar" letter, refresh after returning from `/premium`, and the locked-tap flow (parental gate then paywall).

## 8. App: screens
- [x] 8.1 Add `BelajarDestination.huruf` and the Huruf card on `BelajarHubScreen` ("Premium" badge for non-subscribers, the guest login prompt, hidden when the flag is off).
- [x] 8.2 Add `HurufListScreen` to the design (p.15):
  - the header and the "Lanjutkan belajar" card with activity chips;
  - the "Semua Huruf" grid with pastel tiles and the not-started, in-progress (orange ring), done (check), locked and Gratis states;
  - the counter;
  - pull-to-refresh, and loading, error and incomplete-profile states.
- [x] 8.3 Add `HurufDetailScreen` to the design (p.16):
  - the header with next-letter navigation and lock handling;
  - the segmented tabs;
  - the "Aa" card, the "Dengar bunyi" and word buttons (`just_audio` through `MediaCache`, silent-mode respecting, an audio retry icon);
  - the progress writes.
- [x] 8.4 Add `TracingCanvas` (`CustomPainter`): the guide band and dotted centre line, numbered start markers, direction arrows, live orange coverage, the shake on a bad start, "Ulangi", "Selesai" and the "Lihat contoh" animation.
- [x] 8.5 Add `LearningFeedbackDialog`, with the success and retry variants to the design (p.17–18), and wire up the Huruf actions: "Lanjut ke huruf B", "Tebalkan lagi", "Coba lagi", "Lihat contoh", and "Buka semua huruf" for non-subscribers on the free letter.
- [x] 8.6 Add the Beranda "Lanjutkan belajar" row (the Huruf card in progress only), shown when the flag is on and a letter is in progress, and refreshed on pull-to-refresh.
- [x] 8.7 Add all copy to `app_strings.dart`.

## 9. App: tests and wrap-up
- [x] 9.1 Widget tests:
  - grid states for subscribers and non-subscribers;
  - a locked tap reaching the parental gate;
  - unlock after returning from the paywall;
  - the Dengar completion write;
  - an audio failure still allowing completion;
  - tracing success and retry pop-ups;
  - "Buka semua huruf" shown only for non-subscribers;
  - the hub card hidden when the flag is off;
  - the Beranda row shown and hidden.
- [x] 9.2 Repository tests: the ETag 304 path, the 402 mapping and the retry of progress writes.
- [ ] 9.3 Integration test against the e2e backend: open Huruf, play the free letter, trace it using the fixture trace and check that progress persists. Add a locked letter that opens the paywall. *(Written in `integration_test/flows/huruf_flow_test.dart` and analyzed; not run, because no Android emulator or device was available locally.)*
- [x] 9.4 Run `flutter analyze`, `flutter test` and the coverage baseline check. Do a manual pass on a 360 dp device with 140% text. *(The 360 dp / 140% pass is an automated widget test, which caught and fixed two overflows; no physical device was checked.)*

## 10. Backoffice: foundations
- [x] 10.1 `authStore`: store `role` from the login and refresh responses, and add a `useCanPublish()` hook.
- [x] 10.2 Add the API clients and types: `src/api/huruf.ts`, `src/api/assets.ts` (multipart upload with progress) and `src/api/admins.ts` (admins, roles and the audit log).
- [x] 10.3 Add `src/lib/svgPath.ts`: the same M/L/Q/C parser and sampler, with a parity test on `svg_paths.json` (copied from the backend).
- [x] 10.4 Menu (`AppLayout`) and routes (`App.tsx`): add the "Konten Belajar › Huruf" entries (`/huruf` and `/huruf/:id`) and "Pengaturan & peran" (`/settings/roles`).

## 11. Backoffice: Huruf pages
- [x] 11.1 Add `HurufListPage`: the status tabs with counts, search, the table columns to the design (p.19), pagination, and "Ubah urutan" drag-reorder (publisher only).
- [x] 11.2 Add `HurufEditorPage`:
  - the header (badge, version line, "Riwayat versi", "Simpan draft", "Terbitkan");
  - the Identitas, Kenali (highlight picker, image upload card), Dengar (audio upload rows with play) and Umpan balik sections;
  - the 2-second debounced autosave, the `DRAFT_CONFLICT` reload prompt, and field-level publish errors.
- [x] 11.3 Add `StrokeEditor`: the 300 × 300 SVG grid, the upper and lower tabs, "Gambar garis" (drag, 5-unit snap), "Unggah SVG" (path import with scaling), the stroke list (label, editable path with live parse errors, delete, drag order), "+ Tambah garis", "Putar contoh" and "Huruf kecil wajib".
- [x] 11.4 Add `PhonePreview`: the Kenali, Dengar and Tebalkan tabs rendering the unsaved draft through the preview endpoint, playing audio, and showing the guide markers and the stroke animation.
- [x] 11.5 Add `HistoryDrawer`: the Versi tab (rollback for publishers, with confirmation) and the Aktivitas tab (the audit log).
- [x] 11.6 Add `RolesPage`: the admin list, the role switch for publishers, the `LAST_PUBLISHER` message, and read-only mode for editors.

## 12. Backoffice: tests
- [x] 12.1 Unit tests:
  - API clients;
  - the path parser parity;
  - the list filters;
  - autosave debounce and the conflict prompt;
  - upload error messages;
  - publish errors highlighting fields;
  - publisher-only controls disabled for editors;
  - the roles page.
- [ ] 12.2 Playwright e2e: *(Written in `e2e/belajar-huruf.spec.ts`; not run, because the e2e stack's base compose file needs a backend `.env`.)*
  - an editor uploads an image and audio, draws a stroke and saves the draft;
  - a publisher publishes and the version shows v1;
  - a rollback creates v2;
  - "Belajar Huruf" appears on App Features and can be toggled.
- [x] 12.3 Run `npm run lint`, `npm test`, and the bundle and coverage baseline checks. *(Bundle grew 4.6%, within the 20% budget. `nginx-security-headers.conf` gained `media-src` so the editor can play uploaded audio.)*

## 13. Rollout
- [ ] 13.1 Set up R2: the `media.haloarunika.com` custom domain (from `launch-production-on-haloarunika` task 5), an API token scoped to the bucket, and `MEDIA_*` in the VPS `.env`.
- [ ] 13.2 Deploy the backend and backoffice with the flag off. Assign editor and publisher roles to the content team.
- [ ] 13.3 The content team uploads assets and publishes the 26 letters. Check that a publish reaches a test device within 15 minutes.
- [ ] 13.4 Run a usability session with 5–10 children (recording traces as new evaluator fixtures). Tune `HURUF_TRACING_*` if needed.
- [ ] 13.5 Release the app with the flag off. Enable `belajar_huruf` for internal testing, then in production. Watch the 402 rate, progress write errors and paywall conversion.

## 14. Follow-up from the first backoffice review
- [x] 14.1 Backend: add `POST /admin/huruf/letters/:id/unset-free` (publisher, audited as `unset_free`), allowing zero free letters.
- [x] 14.2 Backend: add the external media URL slots (`image_url`, `letter_audio_url`, `word_audio_url`). Trim them and drop them when overridden on save; validate https-only on publish (`INVALID_URL`); resolve them in the manifest, letter, preview and admin list; count them in the audio count. Update `openapi.yaml` and the client contract copies. Add API tests.
- [x] 14.3 Backoffice: make the "Gratis untuk semua" toggle work both ways, add the "Unggah file / Pakai URL" switch with https and r2.dev warnings, and change the menu: Fairy Tales and AR Cards move under Konten Belajar, and Tracing Items, Counting Questions and Badges are hidden. Add tests.
