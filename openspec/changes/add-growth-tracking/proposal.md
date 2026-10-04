## Why
Parents track their child's height and weight on the paper KMS card (Buku KIA), which is easy to lose, hard to read and updated monthly at best. The app already has parents' attention through Kartu AR and Dongeng but offers nothing for their own goals for the child. "Tumbuh Kembang" lets a parent log height and weight and see, against the WHO Child Growth Standards and the Permenkes No. 2/2020 categories, whether growth is normal. It is the first parent-facing tab and gives parents a reason to open the app between learning sessions.

Sources: `PRD — Tumbuh Kembang (Growth Tracking, WHO Standard).md`, `RFC — Tumbuh Kembang Growth Tracking Implementation.md` and the growth screens of the `Kartu AR Redesign` design (Beranda, Belajar, Tumbuh Kembang, Edit Pengukuran, Hapus data pengukuran).

## What Changes
**App (`arunika_app`)**
- **BREAKING (navigation):** the bottom nav changes from Beranda · Scan · Koleksi · Dongeng · Orang Tua to **Beranda · Belajar · Tumbuh · Profil**.
- New **Belajar** tab: a hub with a Kartu AR card and a Dongeng card. Both open the existing Koleksi and Dongeng screens inside the tab, so the nav bar stays visible and a back button returns to the hub. The Stimulasi Bayi, Angka and Huruf cards in the design are out of scope.
- QR scan leaves the nav bar. A scan icon sits in the Kartu AR header, next to search, and is still gated by `qr_scan`.
- Every shortcut that used to switch to the Koleksi, Dongeng or Scan tabs (Beranda tiles, unlock-success, push notifications, "Lihat Semua") now opens the matching screen inside Belajar.
- New **Tumbuh** tab, built to the design: a child header, height and weight tiles with status chips and the change since the last measurement, a "Tambah Pengukuran" button, a TB/U and BB/U chart with WHO zones and a dashed median, a status sentence, the disclaimer, and a "Riwayat Pengukuran" list with edit and delete.
- New **Tambah / Edit Pengukuran** form with date, height, weight and position, the read-only age, and a live "Hasil menurut standar WHO" preview computed on the device.
- New delete confirmation sheet, and an "Urungkan" toast for 5 seconds after a delete.
- New **Beranda card** "Tumbuh kembang {nama}", with the latest values, or the empty state "Catat pengukuran pertama".
- A Dart WHO LMS engine and the bundled WHO 2006 LMS file, used for the live preview and for drawing the chart.
- "Orang Tua" is renamed "Profil".

**Backend (`arunika-backend`)**
- **BREAKING (unused API):** the old `growth_records` table and the `POST/GET/PUT /growth` routes are replaced. No client calls them and production holds no rows.
- New `growth_measurements` table, a Go WHO LMS engine (`growth` package with the embedded LMS file), and child-scoped endpoints under `/children/:childId/growth`: summary and list, create, edit, soft delete and restore.
- The server recomputes age, z-scores and categories on every write, and again for all of a child's measurements when the child's birth date or sex changes through `PUT /user`.
- Idempotent create by `client_id`. Outliers must be confirmed with `confirm_outlier`.
- A purge job hard-deletes soft-deleted rows after 30 days. Account deletion removes all measurements.
- A new `growth_tracking` feature flag, seeded **off**.
- New aggregate endpoint `GET /admin/analytics/growth`.

**Backoffice (`arunika-backoffice`)**
- The `growth_tracking` switch appears on the existing App Features page with no code change. It is the rollout control.
- New "Tumbuh Kembang" card on the Analytics page with aggregate PRD metrics only: activation, habit, correction health and outlier share. No screen shows an individual child's measurements.

**Out of scope (later phases):** offline save queue and the "Belum tersinkron" state (the API is idempotent now, so the queue can come later without API changes), the multiple-children selector (FR-9), CSV/PDF export, monthly reminders, head circumference, BMI and weight-for-height, ages above 5, premature age correction, percentage rollout, and the rest of the redesign (Kartu AR, Dongeng, Stimulasi, Angka and Huruf visual changes, and the cart).

## Impact
- Affected specs:
  - ADDED: `growth-classification`, `growth-tracking-api`, `growth-tracking-screen`, `belajar-hub`, `growth-analytics-backoffice`
  - MODIFIED: `bottom-navigation`, `app-feature-flags`, `collection-screen`, `animal-categories-dynamic`
  - ADDED to existing: `home-screen` (Beranda growth card)
- Affected code:
  - `arunika_app`: `lib/presentation/navigation/main_shell.dart`, `app_router.dart`, `home/new_home_screen.dart`, `vocab/collection_screen.dart`, `unlock_success/unlock_success_screen.dart`, `services/push_notification_service.dart`, `core/feature_flags/feature_flags_notifier.dart`, `constants/app_strings.dart`; new `core/growth/`, `data/api/growth_api.dart`, `data/repositories/growth_repository.dart`, `presentation/screens/belajar/`, `presentation/screens/growth/`, `assets/growth/`
  - `arunika-backend`: new `growth/` package, `db/migrations/V62__create_growth_measurements.sql` (or the next free version), `models/growth_measurement.go`, `services/growth_service.go`, `handlers/growth_handler.go`, `routes/router.go`, `services/user_service.go` (recompute), `services/account_deletion_service.go`, `services/admin_analytics_service.go`, `main.go` (purge job), `openapi.yaml`, `tests/security/authz_test.go`
  - `arunika-backoffice`: `src/api/analytics.ts`, `src/pages/analytics/AnalyticsPage.tsx`, tests
- Deviations from the RFC, explained in `design.md`: the existing `children.gender` and `date_of_birth` columns are reused instead of adding `sex` and `birth_date`; profile edits keep going through `PUT /user` instead of a new `PATCH /children/{id}`; JSON uses snake_case like the rest of the API; the LMS data lives in an embedded file instead of a `who_lms` table; restore uses the measurement id instead of a `restoreToken`.
