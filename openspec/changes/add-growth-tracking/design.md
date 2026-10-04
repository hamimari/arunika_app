## Context
The PRD and RFC assume the backend has no reliable child birth date or sex, and no growth storage. The code says otherwise:

- `children.gender VARCHAR(20) NOT NULL` and `children.date_of_birth DATE NOT NULL` already exist (V1). Signup (`child_signup_screen.dart`) and the Profil edit sheet (`child_form.dart`) both capture them. Gender is stored as the Indonesian label `Laki-Laki` / `Perempuan`. The "0 Tahun" the PRD mentions comes from `calculateAge` rounding a child under 1 year down to whole years; the birth date itself is present.
- `growth_records` (V12) and `POST/GET/PUT /growth` exist: non-null weight and height, no position, no classification, no delete. The app never calls them, and production has no data (the app has not launched; see `launch-production-on-haloarunika`).
- The backend is Go + Gin + GORM, Postgres, with Flyway migrations in `db/migrations`. A background job is a `time.Ticker` goroutine started from `main.go` (`startPlayPurchaseReconciliation`).
- Feature flags are boolean rows in `app_feature_flags`. The backoffice App Features page lists them from the API, so a new row appears there with no backoffice change.
- The app shell (`MainShell`) is an `IndexedStack` of tab ids. Other screens jump between tabs with `MainShell.shellKey.currentState?.switchTab(MainShellTab.x)`.

The change spans all three repos. The spec lives here in `arunika_app/openspec`, as earlier cross-repo changes do.

## Goals / Non-Goals
- Goals: PRD Phase 1 (FR-1 to FR-8) for the first child; one WHO engine with identical results in Dart and Go; the 4-tab navigation with Kartu AR and Dongeng moved into Belajar; a backoffice flag for rollout and aggregate metrics.
- Non-Goals: offline queue, the multi-child selector, export, reminders, other indicators, ages above 5, premature correction, any admin view of an individual child's data, and the non-growth parts of the redesign.

## Decisions

### D1. One WHO engine, two runtimes, one data file
- **Data:** a single canonical file, `who2006_lms.csv`, with columns `indicator,sex,age_days,l,m,s`. It holds `lhfa` and `wfa` for `male` and `female`, days 0–1856, built by `scripts/build_who_lms.py` (backend) from WHO's official expanded daily tables (`lhfa-boys/girls-zscore-expanded-tables.xlsx`, `wfa-boys/girls-zscore-expanded-tables.xlsx` on cdn.who.int). That is about 7,400 rows and under 300 KB. The backend owns the file (`growth/data/who2006_lms.csv`, `go:embed`), and the app keeps a byte-identical copy at `assets/growth/who2006_lms.csv`. A test in each repo checks the file's SHA-256 against a constant, so drift fails CI.
- **No `who_lms` table** (unlike the RFC). The values never change, the engine only needs an in-memory lookup, and a table would add a seed step and a DB round trip to every classification. If analytics ever needs SQL access to LMS values, a table can be seeded from the same file.
- **Engine API:** a pure function `Classify(sex, birthDate, measuredOn, heightCm?, weightKg?, position) → {ageDays, ageLabel, hfa{z, category, flagged}?, wfa{z, category, flagged}?, adjustedHeightCm?}`. Go: package `arunika_backend/growth`. Dart: `lib/core/growth/`. A plain library, because the repo's `packages/` folder holds only a vendored plugin and a separate package adds no value yet.
- **Math (from the RFC):**
  - z = ((X/M)^L − 1)/(L·S).
  - Weight-for-age tail rule beyond ±3 using SD₃/SD₂ (and SD₋₃/SD₋₂), where SD_k = M(1 + L·S·k)^(1/L).
  - Length/height: ±0.7 cm adjustment at the 731-day boundary.
  - Round z to 2 decimals.
  - Flag limits: HFA outside [−6, +6], WFA outside [−6, +5].
  - Age above 1856 days: no z, category `out_of_range`.
- **Category boundaries (Permenkes 2/2020):**
  - HFA: z < −3 → `severely_stunted`; −3 ≤ z < −2 → `stunted`; −2 ≤ z ≤ +3 → `normal`; z > +3 → `tall`.
  - WFA: z < −3 → `severely_underweight`; −3 ≤ z < −2 → `underweight`; −2 ≤ z ≤ +1 → `normal`; z > +1 → `risk_overweight`.
  - Boundaries are tested on the rounded z.
- **Golden fixture:** `growth/testdata/golden.csv`, also copied to the app's `test/fixtures/growth_golden.csv`. It has one row per WHO SD column (SD4neg…SD4) of the same tables, both sexes, both indicators, monthly 0–60 (2,196 rows). WHO extends the weight SD3/SD4 lines linearly, so they also exercise the tail rule. Both engines must match it within ±0.01. Boundary, tail-rule and 730/731-day cases are unit tests in each engine.

### D2. Reuse `children.gender` / `date_of_birth`
- No schema change to `children`. The engine normalizes gender case-insensitively: `laki-laki`, `male` and `l` become `male`; `perempuan`, `female` and `p` become `female`. Anything else means the profile is incomplete.
- Profile edits keep going through the existing `PUT /user`, so there is no new `PATCH /children/{id}`. When `UserService.UpdateUser` changes a child's `date_of_birth` or `gender`, it recomputes all of that child's measurements in the same transaction.
- **Alternative considered:** a `sex` enum column with a backfill. It is cleaner, but it touches signup, the profile and the backoffice user view for no user-visible gain in Phase 1.

### D3. Replace `growth_records`
- Migration V62 (or the next free number when applied): `DROP TABLE growth_records`, then `CREATE TABLE growth_measurements` as in the RFC, without the `who_lms` table (see D1).
  - It keeps `hfa_z`, `wfa_z`, the categories, `flagged`, `who_version`, `client_id UNIQUE`, `deleted_at` and the `height OR weight` check.
  - It adds `CHECK (height_cm IS NULL OR height_cm > 0)` and the same for weight.
  - It indexes `(child_id, measured_on DESC) WHERE deleted_at IS NULL`.
- The FK uses `ON DELETE CASCADE` on `children(id)`.
- Remove the `/growth` routes, the handler and service code, `models.GrowthRecord`, and their tests. Rewrite the authz security tests against the new routes.
- It is safe because no client calls these routes and production has no rows. Before applying, check the VPS: `SELECT count(*) FROM growth_records` must be 0.

### D4. API shape
- The JSON uses snake_case, like every other endpoint (`date_of_birth`, `is_enabled`). Responses are wrapped in `{"data": …}`, as existing handlers do.
- Routes, under `JWTAuthMiddleware`:
  - `GET /children/:childId/growth`
  - `POST /children/:childId/growth/measurements`
  - `PATCH /children/:childId/growth/measurements/:id`
  - `DELETE /children/:childId/growth/measurements/:id`
  - `POST /children/:childId/growth/measurements/:id/restore`
- **Ownership:** the child must have `parent_id = caller` and `is_deleted = false`, and the measurement must belong to that child. Failures return 404 `CHILD_NOT_FOUND` / `MEASUREMENT_NOT_FOUND`. A foreign id and an unknown id get the same answer, keeping the existing no-oracle rule.
- **Errors:** 422 with the API's existing flat envelope `{"error": "…", "code": "…"}` for `PROFILE_INCOMPLETE`, `DATE_OUT_OF_RANGE`, `VALUE_REQUIRED`, `INVALID_VALUE` (≤ 0 or ≥ 1000, the `numeric(4,1)` limit), `INVALID_POSITION` and `OUTLIER_NEEDS_CONFIRM` (which adds `"indicators": ["hfa"|"wfa"]`).
- **Duplicate `client_id`** returns **200** with the existing row, not a 409. That is simpler for the future offline queue, which treats both as success. The RFC's 409 adds a branch with no benefit. A `client_id` already used for a *different* child returns 409 `CLIENT_ID_CONFLICT`.
- **Restore** uses the measurement id. A `restoreToken` adds nothing, because ownership is already checked and the purge window bounds it.
- **"Today"** for date validation is the current date in `Asia/Jakarta`.
- **GET summary:**
  - `profile_complete`, the child's `name`, `sex`, `birth_date`, `age_label` and `over_60_months`.
  - `latest_height` and `latest_weight`: the newest measurement with that value, with `{value, category, measured_on, delta_from_previous?}`.
  - `measurements`: newest first, each with raw values, position, `age_days`, `age_label`, categories, `flagged`, `created_at` and `updated_at`.
  - Z-scores are included for analytics and debugging. The app never renders them.

### D5. App navigation: Belajar hosts Kartu AR and Dongeng in a nested Navigator
- Tab ids become `home`, `belajar`, `tumbuh`, `profil`.
  - `belajar` is always visible.
  - `tumbuh` is visible when logged in and `growth_tracking` is on.
  - `profil` is visible when logged in.
- The Belajar tab owns a `Navigator` with routes for the hub, `kartu-ar` (the existing `CollectionScreen`, with an optional `categoryId`) and `dongeng` (the existing `NewDongengListScreen` and its bloc, with an optional highlight id).
  - The shell's nav bar stays visible, as in the design.
  - Android back pops the nested navigator first.
  - Tapping Belajar while on it pops to the hub.
  - `CollectionScreen` and `NewDongengListScreen` gain a leading back button when shown inside Belajar. Their content and visuals are unchanged.
- `MainShellState.openBelajar(BelajarDestination dest, {String? categoryId, String? highlightProductId})` replaces every `switchTab(collection|dongeng)` call. `switchTab(scan)` callers push `/ar-scan` instead.
- The scan icon in the Kartu AR header pushes `/ar-scan`, and it is hidden when `qr_scan` is off.
- **Alternative considered:** go_router `StatefulShellRoute`. It is the idiomatic choice, but it means rewriting the whole shell and router. That is a larger, riskier change than a nested navigator in one tab.

### D6. Growth UI implementation
- **State:** `GrowthCubit`, in the shell and shared by the Tumbuh tab and the Beranda card, so one fetch feeds both. It loads `GET …/growth` for the first child, reloads after every write, and keeps a pending-delete set for undo.
- **Chart:** a `CustomPainter`, with no new dependency. Band fills between two LMS curves are straightforward paths, which is the awkward case for `fl_chart`.
  - Sample every 7 days over the window: x from the first measurement minus 3 months to the latest plus 3 months, clamped to 0–60.
  - y fits the −3 and +3 SD curves plus 2 cm or 0.5 kg.
  - Zone cut-offs: HFA −3/−2/+3, WFA −3/−2/+1.
  - Points are plotted at `(age_days, adjusted value)`. The latest point is larger and labelled with its comma-decimal value.
  - The axis labels and legend follow the design: "2 th / 2,5 / 3 th", legend "{nama} · Median WHO · zone names".
  - A `Semantics` label carries the status sentence.
- **Form:** decimal input accepts `,` and `.` (numeric keypad). The preview recomputes on a 250 ms debounce. The position default follows the age from the chosen date. After a save, the server's categories replace the preview.
- **Outlier:** the warning and any save error sit in the fixed bottom bar above the save button, so they are never scrolled out of view. On `OUTLIER_NEEDS_CONFIRM` the form shows "Angka ini tidak biasa. Periksa lagi, ya." and a "Tetap simpan" action that resends with `confirm_outlier: true`. The local engine also shows the warning before submit, so the round trip is rare.
- **Delete:** the confirmation sheet removes the row optimistically and shows a 5-second "Urungkan" toast, which calls `/restore`.
  - **Copy deviation:** the design's sheet body ends "Tindakan ini tidak bisa dibatalkan.", which contradicts the PRD's undo toast. The spec drops that sentence. Confirm with design.
- **Formatting:** dates "12 Sep 2026"; numbers with a comma decimal ("94,8 cm"); ages "3 tahun 2 bulan" (header and form) and "3 th 2 bln" (history row). Chips and status copy are as given in the PRD.

### D7. Rollout flag
- `growth_tracking` is seeded `is_enabled = false` and is **fail-closed** in the app (it joins `FeatureFlagsNotifier.failClosed`). An app talking to a backend without the endpoints, or before the flag is fetched, never shows the tab.
- The RFC's 10% stage is not possible with boolean flags. Staging is done with the flag on in the e2e/staging environment for internal testers, then the flag on in production alongside a Play staged rollout of the app release.

### D8. Backoffice metrics are aggregate-only
- The card sits on the backoffice **Dashboard** (last 30 days). The repo's `AnalyticsPage` is not routed, so a card there would never be seen.
- `GET /admin/analytics/growth?days=30` returns:
  - `active_parents`: parents with a session in the window, the same source as DAU.
  - `activated_parents`: parents with at least one measurement created in the window, and the activation rate.
  - `habit_rate`: activated parents who logged again within 45 days of their first measurement.
  - `corrections_per_100`: edited rows (`updated_at > created_at`) plus soft-deleted rows, per 100 created in the window.
  - `outlier_confirmed_share`: flagged rows as a share of created rows.
  - `category_distribution`: counts per latest category, HFA and WFA.
- It is cached in Redis for 10 minutes like the other analytics.
- Retention lift and "saves blocked by the guard" need client events the app does not emit. The card states that they are not tracked yet.

## Risks / Trade-offs
- **Engines drift between Dart and Go.** Mitigation: the shared golden fixture and the LMS checksum test in both CIs.
- **Free-text gender values from old accounts.** These are treated as an incomplete profile, which leads to the "Lengkapi profil anak" CTA. That is a safe failure.
- **Nested navigator edge cases** (deep links, push notifications landing in Belajar). Mitigation: a single `openBelajar` entry point, and widget tests for each caller.
- **Copy and design gaps** (the undo copy conflict, no chevron because there is a single child). These are documented, not invented.

## Migration Plan
1. Backend: deploy the migration and code with the flag off. The old `/growth` routes disappear, which is safe because nothing calls them.
2. App: release with the 4-tab nav. Belajar ships for everyone, and Tumbuh stays hidden until the flag is on.
3. Turn `growth_tracking` on in staging and test internally. Then turn it on in production.
4. Rollback: turn the flag off. The Tumbuh tab and Beranda card disappear and the data stays.

## Open Questions
- Confirm with design that the delete sheet drops "Tindakan ini tidak bisa dibatalkan." (D6).
- The Belajar hub shows only Kartu AR and Dongeng until Stimulasi, Angka and Huruf ship. Confirm with design that a 2-card hub is acceptable.
