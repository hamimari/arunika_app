All work happens on branch `growth-tracking-feature` in each repo. Sections 1–4 (backend) and 5 (app engine and navigation) can run in parallel. App sections 6–8 need the API from section 3. Section 9 (backoffice) needs task 4.2.

## 1. Shared WHO engine (backend first; the app copies the file)
- [x] 1.1 Download the WHO expanded daily tables (`lhfa_boys_z_exp`, `lhfa_girls_z_exp`, `wfa_boys_z_exp`, `wfa_girls_z_exp`). Build `growth/data/who2006_lms.csv` (`indicator,sex,age_days,l,m,s`, days 0–1856) with a script in `scripts/`, and commit the script.
- [x] 1.2 Build `growth/testdata/golden.csv`: SD lines −3…+3 at monthly ages 0–60 for both sexes and indicators (from the WHO z-score tables), plus the boundary cases (−3, −2, +1, +3), tail-rule cases and the 730/731-day cases.
- [x] 1.3 Implement the Go package `growth`: embedded LMS lookup, `Classify`, gender normalization, age label, the 0.7 cm adjustment, the WFA tail rule, categories, flag limits and `out_of_range`.
- [x] 1.4 Go tests: golden fixture within ±0.01, boundaries, the LMS SHA-256 checksum, and gender normalization.

## 2. Backend data model
- [ ] 2.1 Before writing the migration, confirm on the VPS that `growth_records` has 0 rows. *(Not done: needs VPS access. Do this before deploying V62.)*
- [x] 2.2 Write migration `V62__create_growth_measurements.sql` (or the next free version): drop `growth_records`, create `growth_measurements` with its checks and partial index, and insert the `growth_tracking` flag (off).
- [x] 2.3 Add `models.GrowthMeasurement`. Remove `models.GrowthRecord` and its references, including `account_deletion_service.go`, which now deletes measurements.

## 3. Backend growth API
- [x] 3.1 Rewrite `services/growth_service.go`:
  - ownership check (`parent_id` and `is_deleted = false`);
  - summary with latest values and deltas;
  - create with validation (Asia/Jakarta date), the outlier rule and `client_id` idempotency;
  - PATCH with explicit-null semantics;
  - soft delete and restore;
  - `RecomputeChild(tx, child)`.
- [x] 3.2 Rewrite `handlers/growth_handler.go`, using 422 error codes, 404 for not found or not owned, and the `{"data": …}` envelope. Register the `/children/:childId/growth…` routes in `routes/router.go` and remove the `/growth` group.
- [x] 3.3 Call `RecomputeChild` from `UserService.UpdateUser` when a child's `date_of_birth` or `gender` changes, in the same transaction.
- [x] 3.4 Add a purge job in `main.go`: a ticker every 24 h that hard-deletes rows soft-deleted more than 30 days ago, logging only counts.
- [x] 3.5 Update `openapi.yaml`: remove `/growth*` and add the new paths and schemas. Run the API contract tests.
- [x] 3.6 Unit tests: service (validation, idempotency, delta, restore, recompute, purge) and handler (status codes).
- [x] 3.7 Security tests: rewrite the `tests/security/authz_test.go` growth cases for cross-parent read, create, patch, delete and restore.
- [x] 3.8 Run `make test` and the coverage baseline check.

## 4. Backend admin analytics
- [x] 4.1 Add `AdminAnalyticsService.GetGrowthMetrics(days)`, with the aggregates from design D8 and a 10-minute Redis cache.
- [x] 4.2 Add `GET /admin/analytics/growth`, with a handler test and an `openapi.yaml` entry.

## 5. App: engine, flag and navigation
- [x] 5.1 Copy `who2006_lms.csv` to `assets/growth/` and register it in `pubspec.yaml`. Copy the golden fixture to `test/fixtures/growth_golden.csv`.
- [x] 5.2 Implement `lib/core/growth/` (LMS loader, `classify`, age label and formatters for comma decimals and dates). Add tests for the golden fixture, boundaries and the checksum.
- [x] 5.3 In `FeatureFlagsNotifier`: add `FeatureFlag.growthTracking`, add it to `failClosed`, and expose `growthTrackingEnabled`.
- [x] 5.4 In `MainShell`: change the tab ids to home, belajar, tumbuh and profil, apply the visibility rules, restyle the nav to the design (icons, peach pill), rename "Orang Tua" to "Profil", and update `app_strings.dart`.
- [x] 5.5 Add `presentation/screens/belajar/`: the Belajar hub screen and a nested Navigator (hub, kartu-ar, dongeng). Add back handling and the tap-active-tab-pops-to-hub behaviour.
- [x] 5.6 Add a leading back button to `CollectionScreen` and `NewDongengListScreen` when they are hosted in Belajar. Add the `qr_scan`-gated scan icon to the Kartu AR header.
- [x] 5.7 Replace every `switchTab(collection|dongeng|scan)` caller (`new_home_screen.dart`, `unlock_success_screen.dart`, `push_notification_service.dart`) with `openBelajar(...)` or a push to `/ar-scan`. Delete `DongengTabController` if nothing else uses it.
- [x] 5.8 Widget tests: tab visibility (guest, logged in, flag off), back behaviour in Belajar, each shortcut caller landing on the right destination, and the scan icon gated by `qr_scan`.

## 6. App: data layer
- [x] 6.1 Add `data/api/growth_api.dart` and the request and response models (snake_case), and `data/repositories/growth_repository.dart`. Register them in `di/locator.dart`.
- [x] 6.2 Add `GrowthCubit`, provided at the shell: load the first child, reload after writes, apply optimistic delete and undo, and keep `client_id` across retries.

## 7. App: Tumbuh screens
- [x] 7.1 Build the Tumbuh screen: header, summary tiles, "Tambah Pengukuran", history list, the incomplete-profile and empty states, and pull-to-refresh.
- [x] 7.2 Build the growth chart `CustomPainter`: zones, dashed median, child series, latest label, axes and legend, the TB/U and BB/U switch, the status box, the disclaimer, the over-60-months note and the semantics label.
- [x] 7.3 Build the add and edit form: date picker limits, read-only age, comma and dot decimal parsing, position default and helper text, the debounced local preview, the outlier warning with "Tetap simpan", the network error state, and "Hapus data ini".
- [x] 7.4 Build the delete confirmation sheet and the 5-second "Urungkan" toast.
- [x] 7.5 Widget tests: tiles and deltas, the single-measurement case, chip copy for every category, no rendered z-score, the form validation and preview, delete and undo, and the incomplete profile.

## 8. App: Beranda card and wrap-up
- [x] 8.1 Add the Beranda growth card (with-data and empty states, hidden for guests or when the flag is off, refreshed on pull-to-refresh) below the "Mau belajar apa hari ini?" section.
- [ ] 8.2 Integration test against the e2e backend: add a measurement, see it on Tumbuh and Beranda, edit it, delete it and undo. *(Written in `integration_test/flows/growth_flow_test.dart` and analyzed; not run, because no Android emulator was available locally. It runs in the merge workflow once the backend change is on master.)*
- [x] 8.3 Run `flutter analyze`, `flutter test` and the coverage baseline check. Do a manual pass on a 360 dp device with 140% text. *(The 360 dp / 140% pass is an automated widget test; no physical device was checked.)*

## 9. Backoffice
- [x] 9.1 Add `analyticsApi.getGrowth(days)` and its types in `src/api/analytics.ts`.
- [x] 9.2 Add a "Tumbuh Kembang" card with statistics, the category distribution and the not-tracked-yet note. *(It is on the Dashboard for the last 30 days, because `AnalyticsPage.tsx` is not routed.)*
- [x] 9.3 Unit and contract tests for the API client and card. Add an e2e check that "Tumbuh Kembang" appears on App Features and can be toggled. *(The Playwright spec `e2e/growth-tracking.spec.ts` is written but was not run: the e2e stack needs a backend `.env`.)*
- [x] 9.4 Run `npm run lint`, `npm test` and the bundle and coverage baseline checks.

## 10. Rollout
- [ ] 10.1 Deploy the backend with the flag off, then smoke-test `/children/:id/growth` with a test account.
- [ ] 10.2 Release the app with the 4-tab nav. Enable `growth_tracking` in staging and test internally.
- [ ] 10.3 Enable `growth_tracking` in production. Watch the `/children/*/growth` error rate and the backoffice growth card.
