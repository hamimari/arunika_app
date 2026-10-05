## Why
Belajar Angka teaches children aged 3–6 to recognise numbers and count objects, in two parts:
- **Kenal Angka:** tap a number to see it and that many objects, and tap the speaker to hear it and hear them counted aloud.
- **Hitung Benda:** count the pictures and type the answer, in levels of about 10 questions that earn 1–3 stars and unlock the next level.

It is the second learning module behind Akses Premium, after Belajar Huruf. One sample level and the numbers 1–5 are free. The content team must be able to add objects and levels from the backoffice and publish them the same day, without an app release.

Sources:
- `PRD — Belajar Angka (Premium).md`;
- `RFC — Belajar Angka Implementation.md`;
- the Angka screens of the `Kartu AR Redesign` design: the Belajar hub card (p.6), Belajar Angka (p.10), the question screen (p.11), the success and retry pop-ups (p.12–14), Backoffice — Belajar Angka (p.21) and the level editor (p.22).

## What Changes
**App (`arunika_app`)**
- New **Angka** card on the Belajar hub ("Angka", "Kenal angka, hitung benda, jawab soal", "Mulai"). It is visible to everyone, carries a "Premium" badge for non-subscribers, and opens Belajar Angka inside the Belajar tab. It is gated by a new `belajar_angka` feature flag, seeded off and fail-closed.
- New **Belajar Angka** screen:
  - the **Kenal Angka** card: a grid of number tiles. Tapping one opens a number card with the numeral and that many objects. Its speaker plays the number, then lights the objects one by one as they are counted aloud. Nothing plays until the child taps it;
  - the **Hitung Benda** list of levels. Each level card shows its range badge, name, stars, and one state: Mulai, Lanjut with "x/10 soal", Main lagi, locked behind the previous level ("Selesaikan Level 2 untuk membuka"), or locked behind Premium.
- New **question screen**:
  - "Level 2 · Soal 3 dari 10" with a progress bar, a close button and a star counter;
  - the question text with a speaker button. The question audio plays only when the child taps it;
  - the pictures, which number themselves when tapped to help counting;
  - a "Jawabanmu" box, and a number pad (1–9, 0, delete, Periksa) with keys of at least 56 px.
- **Answer flow:**
  - a right answer shows "Hebat! Benar!";
  - every wrong answer shows "Hampir benar!" with the hint, "Coba lagi" and "Dengar soal lagi". The child keeps trying until the answer is right; the answer is never given away.
  - The level ends with a stars pop-up. For non-subscribers, the free level's pop-up adds "Buka semua level".
- New on-device **question generator**: the RFC's seeded mulberry32 generator, written in Dart and identical to the Go version, so questions are made on the device with no network round trip per question.
- **Sessions:** start, record each try, complete, and resume a level mid-way. Stars come from the server's re-scoring.
- **Beranda "Lanjutkan belajar"** also shows the level in progress ("ANGKA", "Hitung 1–10", "3/10 soal").
- **Locked items** go through the existing parental gate and Akses Premium paywall (`/premium`), as in Huruf.

**Backend (`arunika-backend`)**
- New tables:
  - `angka_objects` (the object library) and `angka_numbers` (1–20, seeded with their names, 1–5 free), each with a draft and a published copy;
  - `angka_levels` with immutable `angka_level_versions`, a single free level, and an optional prerequisite;
  - `angka_sessions` (seed, object snapshot, tries, stars) and `angka_level_progress` (best stars, completed, current session) per child.
- New `angkagen` package, the seeded question generator, with a golden fixture shared with the app.
- Public API, with access through the **existing** Akses Premium subscription:
  - `GET /learn/angka/manifest` (ETag);
  - `GET /learn/angka/numbers/:value`;
  - `GET /learn/angka/levels/:id`;
  - `POST /children/:childId/angka/sessions`, `PATCH …/sessions/:id` and `POST …/sessions/:id/complete`;
  - `GET /children/:childId/angka/progress`.
  - A locked item responds `402 PREMIUM_REQUIRED`, and a level whose prerequisite isn't completed responds `409 LEVEL_LOCKED`.
- Admin API for objects, numbers and levels:
  - drafts with optimistic concurrency, and publish with validation;
  - level versions and rollback;
  - hide and unhide, set-free and unset-free, level reorder;
  - a preview that generates sample questions for a seed.
  - Huruf's roles (editor and publisher) and audit log apply unchanged.
- Uploads keep using `POST /admin/assets`. Assets gain a `has_alpha` flag so object pictures can be checked for a transparent background. Every image and audio slot also accepts an external https URL, as Huruf does.
- New `belajar_angka` feature flag, seeded **off**. Account deletion removes Angka sessions and progress.

**Backoffice (`arunika-backoffice`)**
- New **Konten Belajar › Angka** menu entry, placed above Huruf as in the design. It opens "Belajar Angka" with three tabs:
  - **Level Hitung Benda:** order, name with the "Gratis" chip and prerequisite, range, questions, objects, star thresholds, status, version and actions. It has drag reorder, "Tambah level", and a "Pustaka benda" summary card;
  - **Pustaka benda:** object cards (picture, name, "Dipakai di n level", status) with an add and edit drawer;
  - **Kenal Angka:** one row per number 1–20 (numeral, name, audio, object, Gratis, Tampil di aplikasi, status).
- New **level editor**:
  - Identitas: name, order, "Terbuka setelah", Tampil di aplikasi, Gratis untuk semua;
  - Soal: minimum and maximum, questions per level, objects, Tersebar or Baris layout;
  - Penilaian: thresholds for 3 and 2 stars;
  - Umpan balik.
  - It has autosave, "Simpan draft", "Terbitkan" and "Riwayat versi", and a **Pratinjau soal** phone panel with "Acak ulang".
- The Huruf upload-or-URL field, status tag and history drawer are shared with the Angka pages.

**Out of scope (later):**
- offline play and the 7-day entitlement cache, as in Huruf. Tries are retried while the screen is open, and an unfinished complete is retried on the next open;
- App Store IAP;
- percentage rollout;
- numbers above 20;
- addition, subtraction, comparing and number tracing;
- the parent-facing stars report (US-7, P1);
- the Beranda "Mau belajar apa hari ini?" grid;
- the legacy `counting_questions` and `counting_progress` tables and the `/counting` routes, which are left untouched.

## Impact
- Affected specs:
  - ADDED: `angka-question-generator`, `angka-content-api`, `angka-sessions`, `angka-content-admin`, `belajar-angka-screen`, `angka-backoffice`.
  - ADDED to existing: `app-feature-flags` (the `belajar_angka` flag) and `account-deletion` (Angka progress).
- Depends on `add-belajar-huruf`, which provides the entitlement check, assets, roles, audit log, `LearningFeedbackDialog` and the backoffice upload field. This change's branches (`belajar-angka`) are cut from `belajar-huruf`.
- Affected code:
  - `arunika-backend`:
    - new: migrations `V66` (Angka tables, number seed, `content_assets.has_alpha`) and `V67` (flag); `angkagen/` with `testdata/generator_golden.json`; `models/angka.go`; `services/angka_service.go`, `services/angka_session_service.go` and `services/angka_admin_service.go`; `handlers/angka_handler.go` and `handlers/admin_angka_handler.go`;
    - changed: `services/asset_inspect.go` and `asset_service.go` (`has_alpha`), `services/audit_service.go` (Angka actions), `services/account_deletion_service.go`, `routes/router.go`, `registry/registry.go`, `openapi.yaml`, `tests/security/authz_test.go`.
  - `arunika_app`:
    - new: `lib/core/angka/` (PRNG and generator), `lib/data/api/angka_api.dart`, `lib/data/repositories/angka_repository.dart`, `lib/presentation/screens/angka/`, and `test/fixtures/angka_generator_golden.json`;
    - also new: `lib/data/models/response/angka_response.dart`;
    - changed: `belajar/belajar_tab.dart`, `belajar/belajar_hub_screen.dart`, `home/home_continue_learning.dart`, `navigation/app_router.dart` (the `AngkaCubit` provider), `navigation/main_shell.dart`, `widgets/learning_feedback_dialog.dart` (star options, scrolling), `core/feature_flags/feature_flags_notifier.dart`, `constants/api_paths.dart`, `constants/app_strings.dart` and `di/locator.dart`.
  - `arunika-backoffice`:
    - new: `src/api/angka.ts` and `src/pages/angka/` (the tabbed page, level editor, object drawer, number drawer and question preview);
    - moved to shared `src/components/content/`: `AssetField`, `StatusTag` and `HistoryDrawer` from `src/pages/huruf/`;
    - changed: `src/App.tsx` and `src/components/AppLayout.tsx`.
- Deviations from the RFC, explained in `design.md`:
  - The existing subscription and per-service access check are reused, as in Huruf.
  - Asset URLs are public, not signed.
  - Objects and numbers have a draft and a published copy but no version history.
  - A session snapshots its object list, so hiding an object never changes a session in progress.
  - Access is checked when a session starts, so a child whose subscription expires mid-level can finish it.
  - The backoffice preview renders server-generated questions in React instead of Flutter Web.
  - JSON uses snake_case.
