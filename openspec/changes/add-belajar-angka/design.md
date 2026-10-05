## Context
The RFC says Angka reuses "the Belajar Huruf platform". In code, that platform is what `add-belajar-huruf` built on the `belajar-huruf` branches:
- `EntitlementService.HasActiveSubscription`, with access checked per item in the service (402 `PREMIUM_REQUIRED`);
- `content_assets` with the public, content-addressed `storage.Store` (R2 or local) and `POST /admin/assets`, plus external https URL slots;
- `admin_users.role`, `RequireAdminRole("publisher")`, and `admin_audit_log` with `AuditService.Record` (draft-save coalescing);
- the draft, publish, version and rollback pattern with `draft_rev` and `409 DRAFT_CONFLICT`, and `422 VALIDATION_FAILED` with field paths;
- in the app: `BelajarTab` and `BelajarDestination`, the `belajar_huruf` fail-closed flag pattern, `LearningFeedbackDialog`, `HomeContinueLearning`, and the locked-tap flow (parental gate, then `/premium`);
- in the backoffice: the "Konten Belajar" menu group, `useCanPublish()`, `AssetField` (upload or URL), `StatusTag`, `HistoryDrawer`, and the phone preview pattern.

Some RFC assumptions that the Huruf design already replaced also apply here:
- There are no `/me/entitlements`, `RequireEntitlement` middleware or signed URLs.
- Offline play is deferred.

There are also legacy `counting_questions` and `counting_progress` tables (V7, V8, `/counting/*`), and a hidden "Counting Questions" backoffice page. They are fixed questions with no levels, versions or audio, the app doesn't use them, and they are left untouched.

## Goals / Non-Goals
- **Goals:**
  - PRD FR-1 to FR-7 for the first child, and BO-1 to BO-5;
  - one free level plus free numbers 1–5;
  - access and stars decided by the server;
  - published changes reach devices within 15 minutes;
  - a deterministic question generator, identical in Go and Dart.
- **Non-Goals:**
  - offline play;
  - iOS purchases;
  - numbers above 20;
  - arithmetic;
  - the parent stars report;
  - multi-child;
  - percentage rollout;
  - removing the legacy counting tables.

## Decisions

### D1. Access: the Huruf rule, per item
- **Numbers:** `GET /learn/angka/numbers/:value` is allowed when the number's published `is_free` is true or the caller is premium.
- **Levels:**
  - `GET /learn/angka/levels/:id` and `POST …/sessions` are allowed when the level is `is_free` or the caller is premium.
  - Otherwise the server answers `402 {"error":"premium required","code":"PREMIUM_REQUIRED"}`.
- **Checks live in `AngkaService`,** not in a middleware, as in Huruf D1. They run in this order:
  1. child ownership (404);
  2. a published, visible item (404);
  3. access (402);
  4. the prerequisite (409 `LEVEL_LOCKED`).
- **Expiry mid-level (PRD):** "the current level can be finished".
  - Access is checked when a session **starts**.
  - `PATCH` and `complete` on an existing session only check that the child owns it.
  - The next session start on a premium level answers 402. Stars and progress are kept.
- **Free flags:**
  - Levels have at most one free level, enforced by a partial unique index as `letters` does. `set-free` moves it in one transaction, and `unset-free` allows zero.
  - Numbers can have any number of free numbers, set per row. The seed makes 1–5 free.

### D2. Content model
All JSON is snake_case.

- **`angka_objects`:** `id uuid`, `status text CHECK (draft|published|hidden)`, `draft jsonb`, `content jsonb NULL` (the published copy), `draft_rev int`, `updated_by`, `updated_at`.
  - The content is `{name, question_text, image_asset_id?, image_url?, question_audio_id?, question_audio_url?}`.
  - **No version table.** Objects are small, and the audit log keeps the before and after of every publish.
  - Publish copies `draft` to `content`.
- **`angka_numbers`:** `value smallint PRIMARY KEY CHECK (1..20)`, `is_free bool`, `status`, `draft jsonb`, `content jsonb NULL`, `draft_rev`, `updated_by`, `updated_at`.
  - The content is `{name, audio_asset_id?, audio_url?, object_id}`.
  - `V66` seeds 1–20 as `draft`, with the names "satu" … "dua puluh", and 1–5 free.
- **`angka_levels`:** `id`, `sort_order`, `is_free`, `status`, `draft jsonb`, `draft_rev`, `published_version_id`, `updated_by`, `updated_at`. A partial unique index allows one free level.
- **`angka_level_versions`:** `id`, `level_id`, `version`, `content`, `published_by`, `published_at`, `UNIQUE(level_id, version)`.
- **Level content** (the RFC shape, snake_case), with the prerequisite inside it so a version captures it:

```json
{ "name":"Hitung 1 sampai 10", "prerequisite_id":"…|null",
  "range":{"min":1,"max":10}, "question_count":10,
  "object_ids":["…","…"], "layout":"scatter",
  "stars":{"three":9,"two":7},
  "feedback":{"success":"Hebat! Benar!","retry":"Hampir benar!",
              "hint":"Sentuh {benda} satu per satu sambil menyebut 1, 2, 3…"} }
```

- **Status for all three** follows Huruf D2:
  - `hidden` keeps the published copy;
  - the list shows Draft, Terbit, Ada perubahan (the canonical draft differs from the published copy) or Disembunyikan.
- **Deviation from the RFC:**
  - The RFC's `angka_numbers` and `angka_objects` are edited live, with `NOT NULL` asset columns.
  - Here they get a draft and a published copy, so editors can't change live content and only publishers publish, matching the role model.
  - The seed can create numbers before any audio exists.

### D3. Question generator (`angkagen` in Go, `lib/core/angka/` in Dart)
Generation is pure and uses **only 32-bit integer arithmetic**, so Go and Dart match exactly. There is no floating point anywhere.

- **PRNG:** mulberry32 over `uint32`. `next()` returns a `uint32`, and `intn(n) = next() % n`. Dart has no `uint32`, so it uses 32-bit helpers (masking with `& 0xFFFFFFFF` and splitting multiplications into 16-bit halves, like `Math.imul`). The helpers are unit-tested against Go's output.
- **Input:** `(content.range, content.question_count, object_ids, content.layout, seed)`. The output is a list of `{count, object_id, size, points[{x,y}]}`.
- **Counts:**
  - Let `R = max − min + 1` and `n = question_count`.
  - The bag holds `n / R` full copies of `min..max`, plus the first `n % R` values of a Fisher–Yates shuffle of `min..max`.
  - The bag is then Fisher–Yates shuffled.
  - **Spread:** the bag is re-read in order. Each step takes the first remaining value that differs from the previous one, unless one value fills more than half of what remains; that value must then go next.
  - This uses no PRNG, and it leaves no equal neighbours whenever such an order exists, which is always except when `R = 1`. A plain "swap with the next different value" pass gets stuck on bags like six 6s and five 7s.
  - So every value appears when `R ≤ n`, and the counts are distinct when `R ≥ n`.
- **Objects:**
  - `idx = intn(len)`. If it equals the previous index and `len > 1`, use `idx = (idx + 1) % len`.
- **Positions:** the area is 320 × 180 units.
  - **Picture size** by count: ≤ 5 → 52, ≤ 10 → 38, ≤ 15 → 30, otherwise 26.
    - Five per row always fit.
    - Scatter succeeds in ≥ 85% of questions with up to 10 pictures, measured over 1,000 seeds per count.
    - Bigger counts fall back to rows more often, and rows are easier to count anyway.
  - **Scatter** uses dart-throwing Poisson-disc sampling:
    - each candidate centre is `x = size/2 + intn(320 − size + 1)`, with `y` the same way;
    - a candidate is accepted when the integer squared distance to every placed point is ≥ `(size + 12)²`;
    - each point gets 30 candidates. If any point fails, the whole question falls back to rows. The PRNG keeps running, so later questions stay deterministic.
  - **Rows:** `ceil(n / 5)` rows, with earlier rows taking the extra picture (7 pictures are laid out as 4 + 3). Each row is centred, the block of rows is centred vertically, and the gap is 12 units.
  - The app scales the 320 × 180 box to the picture area, and the backoffice preview does the same.
- **Order of PRNG use** is fixed: the remainder shuffle, the bag shuffle, then for each question its object followed by its positions. The golden fixture makes any drift fail the tests.
- **Parity:**
  - `angkagen/testdata/generator_golden.json` holds 500 generated cases (about 800 KB), with seeds and ranges chosen to cover every size bucket, `R = 1`, `R > n` and both layouts.
  - Each question is stored compactly as `[count, object_id, size, layout, [x1, y1, …]]`.
  - Go writes the file (`go test -run Golden -update`), and it is copied into the app's `test/fixtures/`.
  - Both languages must reproduce it exactly.
  - Property tests run 10,000 random cases in each language. They check that every value is covered, that no count or object repeats back to back, that points never overlap and stay inside the area, and that the output is deterministic.
- **Why not 10,000 golden cases (the RFC):** the file would be several MB. 500 cases plus the property tests catch the same drift.

### D4. Sessions, scoring and unlocks
- **`angka_sessions`:** `id`, `child_id → children ON DELETE CASCADE`, `level_id`, `level_version_id`, `seed bigint` (uint32 range), `object_ids uuid[]`, `answers jsonb` (`[{"q":1,"tries":[5,7]}]`), `status (in_progress|completed|abandoned)`, `stars`, `first_correct`, `started_at`, `updated_at`, `completed_at`.
- **`angka_level_progress`:** `(child_id, level_id) PRIMARY KEY`, `best_stars smallint`, `completed bool`, `current_session_id NULL`, `updated_at`.
- **Start:** `POST /children/:childId/angka/sessions {level_id, restart?}`.
  - When an in-progress session for that level exists, was touched in the last 7 days, and `restart` is not true, the server returns it. This is "Lanjut".
  - Otherwise it marks any old one `abandoned` and creates a new session pinned to the current published version.
  - The new session gets a random seed and **an object snapshot**: the level's `object_ids` filtered to objects that are currently published and not hidden. This answers the PRD's "hidden objects aren't used in new questions" without regenerating sessions in progress.
  - The response is `{session_id, seed, level_version, object_ids, answers}`.
- **Tries:** `PATCH …/sessions/:id {q, try, answer}`.
  - `q` is 1..n, and `try` counts up from 1 with no limit; a question stays open until it is answered right. `answer` is 0..99; the app strips leading zeros.
  - A repeated `(q, try)` with the same answer is a no-op (idempotent).
  - These are rejected with `422 INVALID_TRY`:
    - a different answer for a recorded try;
    - a gap in tries;
    - a try after a correct one;
    - a wrong try after 50 wrong ones on that question (only the right answer is still stored, which bounds storage without ever blocking a child);
    - a try on a completed session.
  - Correctness is computed by the server from the regenerated question, not sent by the client.
- **Complete:** `POST …/sessions/:id/complete`.
  - The server regenerates the questions from (version content, seed, object snapshot).
  - Every question must be finished, meaning it has a correct try. Otherwise the server answers `422 SESSION_INCOMPLETE`.
  - `first_correct` is the number of questions whose try 1 was right.
  - Stars are 3 when `first_correct ≥ stars.three`, 2 when `≥ stars.two`, and 1 otherwise.
  - The server then updates progress: `best_stars = GREATEST`, `completed = true` and `current_session_id = NULL`.
  - It returns `{stars, first_correct, best_stars, unlocked_level_ids}`, where `unlocked_level_ids` are the published levels whose prerequisite is this level and which weren't playable before.
  - Completing an already completed session returns the same result (idempotent).
- **Unlock:** a level is playable when it is published and visible, the caller has access (D1), and its prerequisite is completed by the child. A missing, hidden or unpublished prerequisite counts as met, so hiding a level never strands the next one.
- **Staleness:** there is no cron. A session older than 7 days is marked `abandoned` lazily, when progress is read or a session is started.
- **Header star counter:** it shows the session's first-try correct count so far. "+1 bintang" on the success pop-up appears only for a first-try correct answer and increments it.
  - The design's "★ 6" at question 3 is placeholder data; see Open Questions.

### D5. Delivery
- **`GET /learn/angka/manifest`** (auth only):
  - `numbers`: the published, non-hidden numbers, each `{value, name, is_free, locked}`;
  - `levels`: the published, non-hidden levels in order, each `{id, name, range, question_count, prerequisite_id, is_free, locked, version}`;
  - `premium`.
  - The ETag is a SHA-256 of the body without `locked`, plus the premium bit, with 304 handling, as in Huruf D3.
- **`GET /learn/angka/numbers/:value`** returns `{value, name, audio_url, object: {id, name, image_url}, count_audio: {"1": url, …, "n": url}}`.
  - `count_audio` is the published audio of every number from 1 to n, hidden ones included, so the card can count aloud. It is served under this number's access, not each number's own.
- **`GET /learn/angka/levels/:id`** returns:
  - the version content and `version`;
  - `objects`: every object the version references, published, **including hidden ones**, so a session in progress can still draw them. Each is `{id, name, question_text, image_url, question_audio_url, hidden}`;
  - `count_audio` for 1..`range.max`, which tap-to-count uses.
- **Asset resolution** reuses Huruf's `mediaURL`: an asset id wins over a URL.
- **App caching:**
  - the manifest is refetched when the screen opens and the last fetch is older than 15 minutes, on pull-to-refresh, and after `/premium`;
  - level and number JSON are cached in memory by `(id, version)`;
  - media go through the existing `MediaCache`.

### D6. Admin API and validation
All routes are under `/admin/angka`.

- **Editor (any admin):**
  - `GET /objects` and `POST /objects` (creates a draft);
  - `GET /objects/:id/draft` and `PUT /objects/:id/draft`;
  - `GET /numbers` and `PUT /numbers/:value/draft`;
  - `GET /levels` and `POST /levels` (creates a draft with defaults);
  - `GET /levels/:id/draft`, `PUT /levels/:id/draft`, `GET /levels/:id/versions`;
  - `POST /levels/:id/preview {draft, seed}`.
- **Publisher:**
  - objects: `POST /objects/:id/publish|hide|unhide` and `DELETE /objects/:id`;
  - numbers: `POST /numbers/:value/publish|hide|unhide|set-free|unset-free`;
  - levels: `POST /levels/:id/publish|hide|unhide|set-free|unset-free|rollback/:version`, `PUT /levels/order`, and `DELETE /levels/:id`.
- **Concurrency and audit:**
  - Every draft PUT takes `draft_rev` and answers `409 DRAFT_CONFLICT` when it is stale.
  - Every write records an audit entry in the same transaction. The entity types are `angka_object`, `angka_number` and `angka_level`; the actions reuse Huruf's names, plus `delete`.
- **Delete rules:**
  - A level can be deleted only when it was never published and is not any level's prerequisite. Otherwise the server answers `409 LEVEL_IN_USE`.
  - An object can be deleted only when no level draft or version references it. Otherwise it answers `409 OBJECT_IN_USE`, and the backoffice offers "Sembunyikan" instead.
- **Hiding an object** is refused with `409 OBJECT_LAST_IN_LEVEL` when a published, visible level would be left with no published, visible object.
- **Publish validation** answers `422 VALIDATION_FAILED` with field paths:
  - **Object:**
    - `name` 1–30 characters, and `question_text` 1–80;
    - an image (an asset of kind image, or an https URL). An uploaded image must be ≤ 300 KB (`TOO_LARGE`) and not `has_alpha = false` (`NOT_TRANSPARENT`);
    - a question audio. An uploaded one must be ≤ 5,000 ms (`TOO_LONG`).
    - URL slots can't be measured and pass. The backoffice warns about this.
  - **Number:**
    - `name` 1–20 characters;
    - an audio;
    - `object_id` is a published, visible object.
  - **Level:**
    - `name` 1–40 characters;
    - `1 ≤ min ≤ max ≤ 20` and `5 ≤ question_count ≤ 20`;
    - at least one object, all published and visible;
    - `layout` is `scatter` or `rows`;
    - `1 ≤ stars.two ≤ stars.three ≤ question_count`;
    - feedback titles are 1–80 characters and the hint is 1–160;
    - the prerequisite is published, isn't the level itself, and forms no cycle;
    - every number from 1 to `range.max` has a published copy with audio, which may be hidden from the grid (`range.max` → `NUMBER_AUDIO_MISSING`), so counting aloud always works.
- **Preview** runs `angkagen` on the posted draft and seed, using the objects' current draft or published media. It returns the questions with positions and object URLs.
- **The list endpoints** return the derived status and version, and:
  - for levels, the object names;
  - for objects, a "used in n levels" count (distinct levels whose draft or published version references the object).

### D7. Assets
- `V66` adds `content_assets.has_alpha boolean NULL`.
  - At upload, `inspectAsset` sets it for images: true when the decoded image has an alpha channel and at least one pixel with alpha below 255.
  - Huruf's existing rows stay `NULL`, which passes the check, so nothing is backfilled.
- The upload limits stay the generic ones: square, 256–2048 px, at most 500 KB, and audio at most 10 s. The Angka-specific limits (300 KB, transparent, 5 s) are checked at **publish**, because the same asset may serve Huruf, and an upload has no module context.
- The storage key keeps the `huruf/<sha256>.<ext>` prefix. Assets are module-agnostic and content-addressed, and renaming the prefix would move existing objects and change the local `/media/huruf/:file` route for no benefit.

### D8. Backoffice
- **Menu:** "Konten Belajar" becomes Fairy Tales, AR Cards, **Angka**, Huruf. Angka is placed above Huruf, as in the design. The routes are `/angka` (the tabs are kept in `?tab=levels|objects|numbers`) and `/angka/levels/:id`, and `/angka/*` highlights Angka.
- **Shared components:** `AssetField` (with the Unggah file / Pakai URL switch), `StatusTag`, `HistoryDrawer` (now taking `entityType` and `entityId`, and the versions loader as a prop) and `hurufUtils`' upload and URL messages move to `src/components/content/`. Huruf imports them from there, with no behaviour change.
- **Levels tab:**
  - It shows the info note "Soal dibuat otomatis dari rentang angka dan benda di tiap level. Satu level bertanda Gratis bisa dimainkan tanpa Akses Premium.";
  - the table: a drag handle, Urutan, Nama level (with the "Gratis" chip, and "Tanpa syarat" or "Setelah Level n"), Rentang, Soal, Benda, "Bintang (benar pertama)" (★★★ ≥ x, ★★ ≥ y), Status, Versi, and Edit plus a "⋯" menu (Sembunyikan or Tampilkan, Jadikan gratis, Hapus);
  - the "Pustaka benda" summary card with "Kelola pustaka", which switches tabs.
  - "Tambah level" creates a draft level with the defaults: name "Level n", range 1–5, 10 questions, stars 9 and 7, 2 tries, scatter, the default feedback, and the last level as prerequisite. It then opens the editor.
- **Level editor:** the design p.22 layout and copy.
  - "Urutan" is read-only; the order is changed by dragging on the list.
  - Below "Gratis untuk semua" it shows "Saat ini: Level n. Hanya satu level yang bisa gratis."
  - The object chips show a picture swatch and toggle with ✓. The line below reads "Satu benda per soal, dipilih acak. n benda dipilih."
  - The layout cards are "Tersebar" and "Baris".
  - The Penilaian inputs read "dari N soal", and the hint field notes "{benda} diganti otomatis dengan nama benda di soal."
  - Autosave, conflict handling and field errors work as in Huruf.
- **Pratinjau soal:**
  - It calls the preview endpoint with the unsaved draft and a seed. "Acak ulang" sends a new seed.
  - Arrows step through "Contoh soal k dari N · draft".
  - It renders the question screen in React and SVG: the header, question, pictures at the generated positions, the answer box and the number pad.
  - The number pad works. Periksa shows the draft's success or retry title and hint.
  - The footer reads: "Soal di aplikasi dibuat dengan cara yang sama, jadi pratinjau ini sesuai dengan yang dilihat anak."
- **Pustaka benda tab:**
  - The object cards show the picture on a tinted background, the name, "Dipakai di n level" and the status.
  - "+ Tambah benda" opens a drawer with: Gambar (`AssetField`, with a note "PNG/WebP latar transparan, maks. 300 KB"), Nama, Teks pertanyaan (prefilled "Ada berapa {nama}?" while it is empty), Suara pertanyaan (`AssetField`, "maks. 5 detik"), and the actions "Simpan draft", "Terbitkan", "Sembunyikan" and "Hapus".
- **Kenal Angka tab:**
  - a 20-row table: Angka, Nama, Suara (with play), Benda (a thumbnail), Gratis (a switch), Tampil di aplikasi (a switch that publishes, hides or unhides), Status and Edit;
  - Edit opens a drawer with the name, audio and object select.
- **Roles:** editors see every publisher-only control disabled, with the Huruf tooltip.

### D9. App placement and gating
- **Flag:** `FeatureFlag.belajarAngka = 'belajar_angka'` is fail-closed. When it is off, the hub card and the Angka entry in "Lanjutkan belajar" are hidden.
- **Guests** get the login prompt, and the first child is used, as in Huruf D10.
- **Navigation:** `BelajarDestination.angka` opens `AngkaScreen` in the Belajar navigator. The number card and the question screen are pushed in the same navigator, and locked taps push `/premium` behind the parental gate.
- **Kenal Angka:**
  - The tiles use the design's colours, cycling through orange, blue, teal, purple and brown.
  - The card's speaker button counts the open numbers aloud, using the count audio of the highest open number (one request), since there is no instruction audio asset; see Open Questions.
  - The number card shows the numeral, the name, and n copies of the object.
    - Nothing plays on open. Its speaker says the number, then counts aloud: object k lights up as `count_audio[k]` plays, about 700 ms per object.
    - It has the speaker, previous and next.
- **Question screen:**
  - The question audio plays only when the child taps the speaker or "Dengar soal lagi" (changed after review: autoplay was unwanted).
  - Tapping a picture marks it with the next number and plays that number's audio. The marks reset when the question changes.
  - The answer box holds at most 2 digits, and "07" is read as 7. Periksa is disabled while the box is empty, and no timers are used.
- **Pop-ups** reuse `LearningFeedbackDialog`. It gains `showStars` (off for a correct answer that wasn't first try) and `starsEarned` (the level result as 1–3 of 3 stars), and its content now scrolls rather than overflowing on short phones with large text:
  - **Success:** "Hebat! Benar!", "Ada 7 apel. Kamu pintar berhitung!", "+1 bintang" (first try only), "Soal berikutnya" and "Kembali ke menu".
  - **Retry:** "Hampir benar!", "Jawabanmu 6. Yuk, hitung apelnya sekali lagi.", the hint with `{benda}` filled in, "Coba lagi" and "Dengar soal lagi".
  - **Last wrong try:** no pop-up. The pictures number themselves one by one with the count audio, the answer box shows the right number, and the screen shows "Soal berikutnya".
- **Level end:**
  - a success pop-up with 1–3 stars, "x dari N benar di percobaan pertama", "Level berikutnya" (when it unlocked one), "Main lagi" and "Kembali ke menu";
  - plus "Buka semua level" for non-subscribers on the free level.
  - "Level berikutnya" goes to a level that `complete` unlocked, unless that level still needs Akses Premium.
  - The stars shown come from the server's `complete` result. While it is pending or fails, they are computed locally and labelled provisional (retried later).
- **Writes:**
  - Each try is PATCHed right away, with backoff retry while the screen is open; the answer check itself is local.
  - When the app is closed mid-level, the session and its recorded tries are on the server, so "Lanjut" resumes at the first unfinished question.
  - When a session reaches the end but `complete` failed, the next open of Belajar Angka calls `complete` for it before showing the list.

## Risks / Trade-offs
- **Generator drift between Go and Dart** would let the server score different questions than the child saw. *Mitigation:* integer-only arithmetic, a fixed PRNG call order, the golden fixture in both CI suites, and the server storing what it computed.
- **A client can PATCH fake answers,** but it can't change the questions or the scoring. Stars only gate the next level, which is low value to cheat.
- **URL-mode media** skip the size, transparency and duration checks. *Mitigation:* the backoffice warns, and preview shows them.
- **Count audio comes from the numbers.** A level can't publish until numbers 1..max have audio, which orders the content work (numbers first). The PRD's release plan already loads numbers first.

## Migration Plan
1. Backend migrations (the next free versions after Huruf's V65):
   - **V66:** `content_assets.has_alpha`, `angka_objects`, `angka_numbers` (seed 1–20, with 1–5 free), `angka_levels`, `angka_level_versions`, `angka_sessions` and `angka_level_progress`;
   - **V67:** the `belajar_angka` flag (off).
   Both are additive.
2. Deploy the backend and backoffice. The content team uploads the objects, publishes numbers 1–10, then creates and publishes the 3 levels (Hitung 1–5 as the free one, 1–10, and 11–20), which also needs numbers 11–20.
3. Release the app with the flag off. Enable it for internal testing, then for everyone, with or after `belajar_huruf`.

## Open Questions
- **Header star count.** Assumed: the first-try correct answers in this session. The design shows 6 at question 3, which suggests a running total across levels instead.
- **Kenal Angka speaker.** It has no instruction audio. Assumed: it plays the visible numbers in order. Alternatively, add an optional instruction audio slot.
- **Level 3 (11–20) with 10 questions** never shows 1–10. The bag rule picks 10 distinct counts from 11–20, as specified. Confirm that this is intended.
- **Numbers 11–20.** The PRD says the Kenal Angka grid shows 1–10 at launch, but Level 3 needs audio for numbers up to 20. Assumed: publish 11–20 as well, and hide them from the grid until wanted.
