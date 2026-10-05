All work happens on the `belajar-angka` branch in each repo, cut from `belajar-huruf`. Dependencies between sections:
- Section 1 (the generator) comes first. It has no other dependency, and its golden fixture feeds the app.
- Section 2 needs nothing else. Sections 3–4 need section 2, and section 5 needs sections 3–4.
- App section 6 needs only section 1's fixture, so it can run in parallel with sections 2–5.
- App sections 7–9 need section 4.
- Backoffice section 10 can start any time. Sections 11–12 need section 3.

## 1. Backend: question generator (`angkagen`)
- [x] 1.1 Add mulberry32 over `uint32` with `intn`.
- [x] 1.2 Add `Generate(range, count, objectIDs, layout, seed)`, following design D3:
  - counts: full copies, the remainder shuffle, the bag shuffle, and de-repeat;
  - objects with no back-to-back repeats;
  - the size buckets;
  - Poisson-disc scatter with 30 tries and the whole-question fallback to rows;
  - the rows layout.
- [x] 1.3 Golden fixture: `testdata/generator_golden.json` with at least 500 cases covering every size bucket, `R = 1`, `R > n` and both layouts, plus a `-update` flag.
- [x] 1.4 Property tests over 10,000 random cases: coverage, no repeats, no overlap, inside the area, deterministic. *(These caught that a greedy "swap with the next different value" pass leaves repeats in bags like six 6s and five 7s; the spread ordering in design D3 replaced it. Picture sizes were tuned to 52/38/30/26 so scatter mostly succeeds.)*

## 2. Backend: data model
- [x] 2.1 Migration `V66`:
  - `content_assets.has_alpha`;
  - `angka_objects`, `angka_numbers` (seed 1–20 with names, 1–5 free) and `angka_levels` (one-free partial unique index);
  - `angka_level_versions`, `angka_sessions` and `angka_level_progress` (child FKs with `ON DELETE CASCADE`).
- [x] 2.2 Migration `V67`: the `belajar_angka` flag (off).
- [x] 2.3 Add `models/angka.go`: `AngkaObject`, `AngkaNumber`, `AngkaLevel`, `AngkaLevelVersion`, `AngkaSession`, `AngkaLevelProgress`, and the typed content structs (snake_case).
- [x] 2.4 Set `has_alpha` on image upload in `asset_inspect.go` and `asset_service.go`. Test it with transparent, opaque and RGB-only PNG and WebP files.
- [x] 2.5 Migration tests: the seeded numbers, the free-level index, and the cascade on child delete.

## 3. Backend: admin API
- [x] 3.1 `AngkaAdminService`, objects:
  - list with status and the "used in" count;
  - create, draft get and save (`draft_rev`);
  - publish validation;
  - hide (`OBJECT_LAST_IN_LEVEL`), unhide, and delete (`OBJECT_IN_USE`).
- [x] 3.2 Numbers: list, draft save, publish validation, publish, hide, unhide, set-free and unset-free.
- [x] 3.3 Levels:
  - list, create with defaults, draft get and save;
  - publish validation (design D6, including the cycle check and `NUMBER_AUDIO_MISSING`);
  - publish, versions and rollback;
  - hide, unhide, set-free and unset-free (one transaction);
  - reorder (full-set check) and delete (`LEVEL_IN_USE`).
- [x] 3.4 Preview: validate the draft's shape, run `angkagen` with the seed, and resolve object media from the draft or the published copy.
- [x] 3.5 Audit entries for every write (entity types `angka_object`, `angka_number` and `angka_level`). Reuse the audit-log endpoint and its draft-save coalescing.
- [x] 3.6 Handlers and routes under `/admin/angka`. Guard publish, hide, unhide, free, order, rollback and delete with `RequireAdminRole("publisher")`.
- [x] 3.7 Tests:
  - every validation rule;
  - version numbering and rollback;
  - free-level exclusivity;
  - the conflict 409;
  - hide and delete guards;
  - preview determinism;
  - audit per action;
  - editor 403s.

## 4. Backend: public API and sessions
- [x] 4.1 `AngkaService.Manifest(userID)`: published, visible numbers and levels with `locked` and `premium`, the ETag including the premium bit, and 304.
- [x] 4.2 `GET /learn/angka/numbers/:value` and `GET /learn/angka/levels/:id`:
  - access is free or premium, otherwise 402;
  - 404 for draft-only, hidden or unknown items;
  - resolved URLs, `objects` including hidden ones, and `count_audio`.
- [x] 4.3 `AngkaSessionService.Start`: checks in the order ownership, visibility, access and prerequisite (`LEVEL_LOCKED`); resume within 7 days or `restart`; the seed, the version pin and the object snapshot.
- [x] 4.4 `PATCH` tries: idempotent per `(q, try)`, with the `INVALID_TRY` rules and an ownership-only check.
- [x] 4.5 `complete`:
  - regenerate the questions and require every question to be finished (`SESSION_INCOMPLETE`);
  - compute `first_correct` and the stars;
  - update progress with `GREATEST`, `completed` and clearing the current session;
  - return `unlocked_level_ids`, idempotently.
- [x] 4.6 `GET /children/:childId/angka/progress`, with lazy abandonment of sessions older than 7 days.
- [x] 4.7 Account deletion removes `angka_sessions` and `angka_level_progress`.
- [x] 4.8 Update `openapi.yaml` with every public and admin route and schema. Copy it to the app's and backoffice's contract test folders, and run the contract tests.
- [x] 4.9 Tests:
  - a table-driven 402 test on every guarded route (free versus locked, expired, content-pack only);
  - the 409 prerequisite, including a hidden prerequisite counting as met;
  - expiry mid-session still completing;
  - scoring boundaries and a tampered client total;
  - the ETag changing on publish, free and subscription;
  - cross-parent sessions and progress in `tests/security/authz_test.go`.
- [x] 4.10 Run `make test`, golangci-lint and the coverage baseline check.

## 5. Backend: wrap-up
- [x] 5.1 Register the services and handlers in `registry.go` and `router.go`.
- [x] 5.2 E2e seed (`docker-compose.test.yml`): three published objects with fixture assets, numbers 1–10 published, and Level 1 (free, 1–5) and Level 2 (1–10, after Level 1) published.

## 6. App: generator (needs only the section 1 fixture)
- [x] 6.1 Add `lib/core/angka/prng.dart`: mulberry32 using 32-bit-safe multiply and shift helpers, unit-tested against Go values.
- [x] 6.2 Add `lib/core/angka/question_generator.dart`, mirroring `angkagen`.
- [x] 6.3 Copy the golden fixture to `test/fixtures/angka_generator_golden.json`. Add the parity test and the 10,000-case property tests.

## 7. App: data layer and gating
- [x] 7.1 Add `FeatureFlag.belajarAngka` (fail-closed) and `belajarAngkaEnabled`.
- [x] 7.2 Add `data/api/angka_api.dart` and the models (manifest, number, level, session, progress, complete result), and `data/repositories/angka_repository.dart`:
  - the ETag and 15-minute refetch;
  - in-memory caching by `(id, version)`;
  - try writes with retry and backoff;
  - 402 mapped to locked, and 409 mapped to prerequisite-locked;
  - a pending-complete retry.
  Register them in `di/locator.dart`, and add the paths to `api_paths.dart`.
- [x] 7.3 Add `AngkaCubit`: the first child, the manifest plus progress, the derived number and level states, the continue level, retrying pending completes on load, refresh after `/premium`, and the locked-tap flow.
- [x] 7.4 Add `AngkaPlayCubit`:
  - start or resume a session;
  - generate the questions from `(content, seed, object_ids)` and skip the answered ones;
  - local answer checks, and the try flow (unlimited tries until right; the answer is never revealed);
  - the first-try counter, and complete with provisional stars.

## 8. App: screens
- [x] 8.1 Add `BelajarDestination.angka` and the Angka card on `BelajarHubScreen` (design p.6: the "123" icon, "Premium" badge, guest prompt, hidden when the flag is off).
- [x] 8.2 Add `AngkaScreen` (p.10):
  - the header;
  - the Kenal Angka card, with the speaker button that plays the visible numbers in order, coloured tiles, locks and Gratis;
  - the Hitung Benda level cards, with the range badge, stars and the Mulai, Lanjut, Main lagi, prerequisite-lock and premium-lock states;
  - pull-to-refresh, and the loading, error and incomplete-profile states.
- [x] 8.3 Add `AngkaNumberCard`: the numeral, the name, n objects lighting up with the count audio when the speaker is tapped (no autoplay), previous and next.
- [x] 8.4 Add `AngkaQuestionScreen` (p.11):
  - the header with progress and the star counter;
  - the question and speaker (plays only on tap);
  - the picture panel that scales the 320 × 180 box and numbers pictures on tap;
  - the answer box and the number pad (keys ≥ 56 px, 2 digits, leading zeros, Periksa disabled while empty).
- [x] 8.5 Wire up `LearningFeedbackDialog` (p.12–14):
  - success, with "+1 bintang" on the first try;
  - retry, with the `{benda}` hint, "Coba lagi" and "Dengar soal lagi";
  - the level-end pop-up with the stars, "Level berikutnya", "Main lagi", "Kembali ke menu", and "Buka semua level" for non-subscribers on the free level.
- [x] 8.6 Add the Angka card to the Beranda "Lanjutkan belajar" row (`home_continue_learning.dart`), next to Huruf, refreshed on pull-to-refresh.
- [x] 8.7 Add all copy to `app_strings.dart`.

## 9. App: tests and wrap-up
- [x] 9.1 Widget tests:
  - tile and level states for subscribers and non-subscribers;
  - the prerequisite lock;
  - a locked tap reaching the parental gate;
  - unlock after the paywall;
  - number pad rules;
  - the retry and then counting-animation flow;
  - "+1 bintang" only on the first try;
  - the level-end pop-up with server stars replacing provisional ones;
  - "Buka semua level" only for non-subscribers;
  - the hub card and Beranda card hidden when the flag is off;
  - resume at the first unfinished question.
- [x] 9.2 Repository tests: the ETag 304, the 402 and 409 mapping, try retry, and the pending-complete retry.
- [ ] 9.3 Integration test against the e2e backend: play Level 1 with one wrong answer, check the stars and that Level 2 unlocks, and check that a locked Level 2 opens the paywall for a non-subscriber. *(Written in `integration_test/flows/angka_flow_test.dart` and analyzed; not run, because it needs the e2e stack and a device.)*
- [x] 9.4 Run `flutter analyze`, `flutter test` and the coverage baseline check. Do the 360 dp / 140% text check on the question screen.

## 10. Backoffice: foundations
- [x] 10.1 Move `AssetField`, `StatusTag`, `HistoryDrawer` (now generic, taking the entity type and id and a versions loader) and the upload and URL messages from `src/pages/huruf/` to `src/components/content/`. Update the Huruf imports, and keep the Huruf tests green.
- [x] 10.2 Add `src/api/angka.ts` with the types and clients for objects, numbers, levels, preview, versions and reorder.
- [x] 10.3 Menu and routes: add Konten Belajar › Angka above Huruf, `/angka` (with `?tab=`) and `/angka/levels/:id`, and highlight Angka on `/angka/*`.

## 11. Backoffice: Angka pages
- [x] 11.1 Add `AngkaPage` with the tabs and counts, and the levels tab (p.21): the note, the table columns, drag reorder, the "⋯" menu, "Tambah level", and the Pustaka benda summary card.
- [x] 11.2 Add `AngkaLevelEditorPage` (p.22):
  - the header;
  - the Identitas, Soal (object chips, layout cards), Penilaian and Umpan balik sections;
  - autosave, the conflict prompt and field errors.
- [x] 11.3 Add `QuestionPreview`: the preview endpoint, "Acak ulang", stepping arrows, the question layout scaled from 320 × 180, and a working number pad showing the draft feedback.
- [x] 11.4 Add `ObjectsTab` and `ObjectDrawer`: the cards, add and edit with `AssetField` and its hints, the question-text prefill, publish, hide and delete with the `OBJECT_IN_USE` and `OBJECT_LAST_IN_LEVEL` messages.
- [x] 11.5 Add `NumbersTab` and `NumberDrawer`: the 20 rows, the play button, the Gratis and Tampil switches, and editing the name, audio and object.
- [x] 11.6 Disable publisher-only controls for editors, with the Huruf tooltip.

## 12. Backoffice: tests
- [x] 12.1 Unit tests:
  - the API clients;
  - the tab URL state;
  - the level table rendering;
  - the editor's autosave and conflict handling;
  - validation errors highlighting fields;
  - preview reseeding;
  - the object drawer's delete and hide messages;
  - the number switches;
  - editor-disabled controls.
- [ ] 12.2 Playwright e2e: *(Written in `e2e/belajar-angka.spec.ts` and type-checked; not run, because it needs the e2e stack.)*
  - an editor adds an object and a level draft;
  - a publisher publishes the object, numbers 1–5 and the level, and the version shows v1;
  - "Belajar Angka" appears on App Features.
- [x] 12.3 Run `npm run lint`, `npm test`, and the bundle and coverage baseline checks. *(Lint: 0 errors. 303 tests pass. The bundle is 7.1% over the baseline, which includes Huruf's 4.6%, within the 20% budget.)*

## 13. Rollout
- [ ] 13.1 Deploy the backend and backoffice with the flag off.
- [ ] 13.2 The content team uploads the objects, publishes numbers 1–20 (hiding 11–20 from the grid if wanted), and publishes Levels 1–3 with Level 1 free.
- [ ] 13.3 Run a usability session with 5–10 children aged 3–6 on Levels 1 and 2.
- [ ] 13.4 Release the app with the flag off. Enable `belajar_angka` for internal testing, then in production, with or after `belajar_huruf`. Watch first-try accuracy per level, the 402 and 409 rates, and paywall conversion.
