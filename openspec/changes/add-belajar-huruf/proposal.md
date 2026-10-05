## Why
Belajar Huruf teaches children aged 3–6 the letters A–Z through three activities per letter: Kenali (the letter, an example word and its picture), Dengar (the letter sound and the word) and Tebalkan (trace the letter with a finger). It is the first structured learning module behind Akses Premium. One letter is free as a sample, and every other letter needs the subscription, which gives parents a recurring reason to subscribe. The content team must be able to change letters, words, pictures, audio and tracing guides and publish them the same day, without an app release.

Sources: `PRD — Belajar Huruf (Premium).md`, `RFC — Belajar Huruf Implementation.md` and the Huruf screens of the `Kartu AR Redesign` design: Belajar Huruf (p.15), Huruf A / Tebalkan (p.16), the success and retry pop-ups (p.17–18), Backoffice — Belajar Huruf (p.19) and the letter editor (p.20).

## What Changes
**App (`arunika_app`)**
- New **Huruf** card on the Belajar hub. It is visible to everyone, carries a "Premium" badge for non-subscribers, and opens Belajar Huruf inside the Belajar tab. It is gated by a new `belajar_huruf` feature flag, seeded off and fail-closed.
- New **Belajar Huruf** screen:
  - a "Lanjutkan belajar" card for the latest unfinished letter, with Kenali and Tebalkan chips;
  - the "Semua Huruf" grid with not-started, in-progress and done states, a "Gratis" chip on the free letter and a lock on the others for non-subscribers;
  - an "x dari 26 selesai" counter.
- New **Huruf detail** screen:
  - a header with back and next-letter buttons;
  - the Kenali and Tebalkan segmented tabs. Dengar is folded into Kenali: the PRD's separate Dengar tab showed the same content, so it was merged after the first device review;
  - Kenali shows a large example picture, "A a" and the word with the letter highlighted, plus "Dengar bunyi" and tap-to-hear on the picture and word;
  - a tracing canvas with numbered start points, direction arrows and an orange stroke that paints as the finger moves, plus "Ulangi" and "Selesai".
- New **on-device tracing evaluator** using the RFC's coverage, accuracy and direction rules, an absolute SVG `M/L/Q/C` path parser, and the "Lihat contoh" stroke animation. Thresholds come from the server, so they can be tuned without a release.
- **Success and retry pop-ups**, matching the design ("Keren! Huruf A rapi!" / "Belum pas, ayo lagi!") and built as a shared component that Angka can reuse later.
- **Locked letters:** tapping one goes through the existing parental gate and then the existing Akses Premium paywall (`/premium`). The grid unlocks in place when the user returns as a subscriber. The free letter's success pop-up adds "Buka semua huruf" for non-subscribers.
- **Beranda "Lanjutkan belajar":** a row with the Huruf card in progress, shown only when the flag is on and a letter is in progress.

**Backend (`arunika-backend`)**
- New letter content tables:
  - `letters` holds the editable `draft` JSON, `sort_order`, `is_free` (at most one letter), the status (`draft`, `published` or `hidden`) and `published_version_id`;
  - `letter_versions` holds immutable published snapshots;
  - `letter_progress` stores progress per child.
- 26 letters are seeded as drafts.
- Public API, with access through the **existing** Akses Premium subscription (no new billing):
  - `GET /learn/huruf/manifest` (ETag);
  - `GET /learn/huruf/letters/:id`;
  - `GET /children/:childId/huruf/progress`;
  - `PUT /children/:childId/huruf/progress/:letterId`.
  - A locked letter responds `402 PREMIUM_REQUIRED`.
- Admin API:
  - list letters, and read and write a draft (with optimistic concurrency);
  - publish, with validation;
  - versions and rollback;
  - hide and unhide, set-free, reorder;
  - preview the draft content.
- **Media uploads:** `POST /admin/assets` (multipart).
  - The server sniffs the type, checks image size and squareness and audio size and duration, then computes a SHA-256.
  - Files are stored content-addressed in S3-compatible storage (Cloudflare R2), served from `MEDIA_PUBLIC_BASE_URL` (`media.haloarunika.com`), and recorded in a new `content_assets` table.
  - A local filesystem driver handles dev and e2e.
- **Admin roles and audit:**
  - `admin_users.role` is `editor` or `publisher`, and existing admins become `publisher`.
  - A role middleware guards the Huruf publish actions.
  - Any admin can list roles with `GET /admin/admins`; publishers change them with `PATCH /admin/admins/:id/role`.
  - A new `admin_audit_log` records every Huruf write, asset upload and role change, with before and after values.
- New `belajar_huruf` feature flag, seeded **off**. Account deletion removes `letter_progress`.

**Backoffice (`arunika-backoffice`)**
- New **Konten Belajar › Huruf** list page: order, letter, word and thumbnail, audio count (n/2), stroke count, status (Terbit / Draft / Ada perubahan / Disembunyikan), version and last edited. It has status filter tabs, search, "Ubah urutan" (drag to reorder) and a "Gratis" chip.
- New **letter editor** with these sections:
  - Identitas: order, Tampil di aplikasi, Gratis untuk semua;
  - Kenali: word, highlighted-letter picker, image upload;
  - Dengar: letter and word audio upload with playback;
  - Tebalkan: tabs for upper and lower case, a 300 × 300 grid canvas that draws lines, stroke list and order, "Unggah SVG", "Putar contoh", "Huruf kecil wajib";
  - Umpan balik.
- The editor autosaves the draft, has "Simpan draft" and "Terbitkan", shows a "Riwayat versi" drawer with versions, rollback and activity, and has a phone-sized **Pratinjau** of Kenali and Tebalkan.
- New **Pengaturan & peran** page, where publishers set each admin's role.
- Controls the current admin's role doesn't allow are disabled.

**Out of scope (later):**
- offline play and the 7-day entitlement cache (letters need a connection; progress writes retry and are merged on the server);
- App Store IAP and a new subscription model (Huruf reuses today's Akses Premium, which is Android-only);
- the "Perbarui pembayaran" grace banner;
- a nightly store price check;
- signed asset URLs (assets are public and content-addressed);
- WebP conversion on upload;
- a Flutter Web preview (the backoffice preview is React);
- the multi-child selector (the first child is used, as in Tumbuh);
- Belajar Angka, Stimulasi Bayi and the rest of the redesign;
- the legacy `tracing_items` / `tracing_progress` tables, which are left untouched.

## Impact
- Affected specs:
  - ADDED: `huruf-content-api`, `huruf-content-admin`, `media-assets`, `admin-roles-audit`, `huruf-tracing`, `belajar-huruf-screen`, `huruf-backoffice`.
  - ADDED to existing: `app-feature-flags` (the `belajar_huruf` flag), `account-deletion` (letter progress).
- Depends on `add-growth-tracking`, which provides the Belajar tab and hub. This change's branches (`belajar-huruf`) are cut from `growth-tracking-feature`. For media in production it depends on `launch-production-on-haloarunika` task 5 (the `media.haloarunika.com` R2 custom domain).
- Affected code:
  - `arunika-backend`:
    - new: migrations `V63`–`V65` (next free versions), `models/letter.go`, `models/content_asset.go`, `models/admin_audit_log.go`, `services/huruf_service.go`, `services/huruf_admin_service.go`, `services/asset_service.go`, `services/audit_service.go`, `storage/` (R2 and local drivers), `handlers/huruf_handler.go`, `handlers/admin_huruf_handler.go`, `handlers/admin_asset_handler.go`, `handlers/admin_role_handler.go`, `middlewares/admin_role_middleware.go`, `hurufpath/` (the shared stroke-path grammar);
    - changed: `models/admin_user.go`, `services/admin_auth_service.go` (role in the login response), `services/entitlement_service.go` (an exported `HasActiveSubscription`), `services/account_deletion_service.go`, `routes/router.go`, `registry/registry.go`, `config/config.go`, `.env.example`, `openapi.yaml`, `tests/security/authz_test.go`.
  - `arunika_app`:
    - new: `lib/core/tracing/`, `lib/data/api/huruf_api.dart`, `lib/data/repositories/huruf_repository.dart`, `lib/presentation/screens/huruf/`, `lib/presentation/screens/widgets/learning_feedback_dialog.dart`;
    - changed: `belajar/belajar_tab.dart`, `belajar/belajar_hub_screen.dart`, `home/new_home_screen.dart`, `core/feature_flags/feature_flags_notifier.dart`, `constants/api_paths.dart`, `constants/app_strings.dart`, `di/locator.dart`.
  - `arunika-backoffice`:
    - new: `src/api/huruf.ts`, `src/api/assets.ts`, `src/api/admins.ts`, `src/pages/huruf/` (list, editor, preview, stroke editor, history drawer), `src/pages/settings/RolesPage.tsx`;
    - changed: `src/App.tsx`, `src/components/AppLayout.tsx`, `src/store/authStore.ts` (role).
- Deviations from the RFC, explained in `design.md`:
  - The existing `user_subscriptions` / Play Billing entitlement is reused instead of new `subscriptions` and `subscription_events` tables, `/subscriptions/verify` and `/me/entitlements`.
  - Assets are public and content-addressed instead of signed URLs.
  - Uploads are not converted to WebP.
  - The backoffice preview is React instead of Flutter Web.
  - Tracing thresholds come in the manifest instead of a separate remote config.
  - JSON uses snake_case.
  - The audit log is generic (`entity_type`, `entity_id`) instead of letter-specific.
