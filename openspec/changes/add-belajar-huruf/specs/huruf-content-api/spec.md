## ADDED Requirements

### Requirement: Letter content storage
The backend SHALL store letters in a `letters` table with these columns:
- `upper`, a unique A–Z letter;
- `sort_order`;
- `is_free`;
- `status`, one of `draft`, `published` or `hidden`;
- `draft`, an editable JSON document;
- `draft_rev`;
- `published_version_id`;
- `updated_by` and `updated_at`.

It SHALL store published snapshots in `letter_versions` (`letter_id`, `version`, `content`, `published_by`, `published_at`), unique on `(letter_id, version)` and never updated after insert. At most one letter SHALL have `is_free = true`, enforced by a partial unique index.

A migration SHALL seed the 26 letters A–Z as `draft`: `sort_order` 1–26, `upper` and `lower` set, the default feedback texts, and A marked free.

#### Scenario: Seeded letters
- **WHEN** migrations run on an empty database
- **THEN** 26 letters exist with status `draft`, and only A has `is_free = true`

#### Scenario: Second free letter rejected by the database
- **WHEN** a row update sets `is_free = true` on B while A is free
- **THEN** the database rejects it

### Requirement: Huruf manifest
`GET /learn/huruf/manifest` SHALL require a valid user JWT. It SHALL return the published, non-hidden letters ordered by `sort_order`, each with:
- `id`, `upper`, `lower` and `word`;
- `image_url`;
- `is_free`;
- `version`, the published version number;
- `locked`, which is true when the letter is not free and the caller has no active Akses Premium subscription.

The response SHALL also include `premium` (the caller's status) and `tracing_thresholds` (`radius`, `coverage`, `accuracy`, `direction`, `start_tolerance`, `max_failures`), taken from server configuration with the defaults 22, 0.80, 0.85, 0.70, 30 and 3.

The response SHALL carry an `ETag` that changes whenever any published content, order, hidden state, free flag or the caller's premium status changes. A request with a matching `If-None-Match` SHALL respond 304 with no body.

#### Scenario: Non-subscriber manifest
- **WHEN** a user without a subscription requests the manifest and A is free
- **THEN** A has `locked: false`, every other letter has `locked: true`, and `premium` is false

#### Scenario: Draft and hidden letters excluded
- **WHEN** letter D has never been published and letter H is hidden
- **THEN** neither D nor H appears in the manifest

#### Scenario: Unchanged manifest
- **WHEN** the app sends the last `ETag` in `If-None-Match` and nothing has changed
- **THEN** the server responds 304

#### Scenario: Publish changes the ETag
- **WHEN** an admin publishes a new version of B
- **THEN** the next manifest response has a different `ETag` and B's `version` is incremented

### Requirement: Premium-gated letter content
`GET /learn/huruf/letters/:id` SHALL return the published `content` of a visible letter: `kenali` (word, highlight), `dengar`, `tebalkan` (grid, `lower_required`, the upper and lower strokes with order, label and path) and `feedback`. Asset ids SHALL be resolved to `image_url`, `letter_audio_url` and `word_audio_url`. The response SHALL also include `version`.

Access SHALL be checked per letter by the service. The request SHALL be allowed when the letter is free or the caller has an active Akses Premium subscription (`user_subscriptions.status = 'premium'` and `expires_at` is null or in the future). Otherwise the server SHALL respond `402 {"error": "...", "code": "PREMIUM_REQUIRED"}`. An unknown, draft-only or hidden letter SHALL respond 404. Content-only purchases SHALL NOT unlock letters.

#### Scenario: Free letter without subscription
- **WHEN** a non-subscriber requests letter A, which is free
- **THEN** the server responds 200 with A's published content and asset URLs

#### Scenario: Locked letter
- **WHEN** a non-subscriber requests letter B
- **THEN** the server responds 402 `PREMIUM_REQUIRED`

#### Scenario: Expired subscription
- **WHEN** a user whose subscription expired yesterday requests letter B
- **THEN** the server responds 402 `PREMIUM_REQUIRED`

#### Scenario: Owner of a content pack only
- **WHEN** a user who bought a Dongeng pack but has no subscription requests letter B
- **THEN** the server responds 402 `PREMIUM_REQUIRED`

### Requirement: Letter progress
The backend SHALL store progress in `letter_progress`, keyed by `(child_id, letter_id)`, with `kenali_done`, `dengar_done`, `tebalkan_done`, `best_score` (0–1, two decimals), `attempts` and `updated_at`. `child_id` SHALL be a foreign key with `ON DELETE CASCADE`.

`GET /children/:childId/huruf/progress` SHALL return all of the child's rows. `PUT /children/:childId/huruf/progress/:letterId` SHALL accept `kenali_done`, `dengar_done`, `tebalkan_done`, `score` and `attempt`, and upsert the row as follows:
- each flag is OR-merged with the stored value;
- `best_score` becomes the larger of the stored and sent scores;
- `attempts` increases by 1 when `attempt` is true.

It SHALL respond with the merged row.

Both routes SHALL respond 404 unless the child belongs to the caller and is not deleted. The PUT SHALL apply the same access rule as letter content, responding 402 for a locked letter.

#### Scenario: Stale write never clears completion
- **WHEN** a letter has `tebalkan_done: true` and a PUT arrives with `tebalkan_done: false, dengar_done: true`
- **THEN** the stored row has both `tebalkan_done` and `dengar_done` true

#### Scenario: Best score kept
- **WHEN** the stored `best_score` is 0.91 and a PUT sends `score: 0.84, attempt: true`
- **THEN** `best_score` stays 0.91 and `attempts` increases by 1

#### Scenario: Another parent's child
- **WHEN** parent A sends a PUT for parent B's child
- **THEN** the server responds 404 and stores nothing

#### Scenario: Progress on a locked letter
- **WHEN** a non-subscriber sends a PUT for letter B
- **THEN** the server responds 402 `PREMIUM_REQUIRED`

### Requirement: Huruf API contract and authorization tests
`openapi.yaml` SHALL document every new `/learn/huruf/*` and `/children/:childId/huruf/*` route, and every response including 304, 402 and 404. A table-driven Go test SHALL assert, for each premium-guarded route, that a non-subscriber gets 402 for a non-free letter and 200 for the free one. The security suite SHALL cover cross-parent progress read and write.

#### Scenario: Router-wide premium check
- **WHEN** the table-driven test calls every guarded route as a non-subscriber for letter B
- **THEN** each responds 402
