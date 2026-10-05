## ADDED Requirements

### Requirement: Angka content storage
The backend SHALL store:
- `angka_objects` and `angka_numbers` (`value` 1–20), each with `status` (`draft`, `published` or `hidden`), an editable `draft`, a published `content` copy, `draft_rev`, `updated_by` and `updated_at`;
- `angka_levels`, with `sort_order`, `is_free`, `status`, `draft`, `draft_rev` and `published_version_id`;
- `angka_level_versions`, unique on `(level_id, version)` and never updated after insert.

At most one level SHALL have `is_free = true`, enforced by a partial unique index. A migration SHALL seed numbers 1–20 as `draft` with the names "satu" to "dua puluh", and numbers 1–5 free.

#### Scenario: Seeded numbers
- **WHEN** migrations run on an empty database
- **THEN** 20 numbers exist with status `draft`, and exactly 1–5 have `is_free = true`

#### Scenario: Second free level rejected by the database
- **WHEN** a row update sets `is_free = true` on a second level
- **THEN** the database rejects it

### Requirement: Angka manifest
`GET /learn/angka/manifest` SHALL require a user JWT. It SHALL return:
- `numbers`: the published, non-hidden numbers by value, each `{value, name, is_free, locked}`;
- `levels`: the published, non-hidden levels by `sort_order`, each `{id, name, range, question_count, prerequisite_id, is_free, locked, version}`;
- `premium`.

`locked` SHALL be true when the item is not free and the caller has no active Akses Premium subscription. The response SHALL carry an `ETag` that changes with any published content, order, hidden state or free flag, and with the caller's premium status. A matching `If-None-Match` SHALL get 304.

#### Scenario: Non-subscriber manifest
- **WHEN** a non-subscriber requests the manifest, Level 1 is free, and numbers 1–5 are free
- **THEN** Level 1 and numbers 1–5 have `locked: false`, and every other level and number has `locked: true`

#### Scenario: Draft and hidden items excluded
- **WHEN** Level 3 was never published and number 7 is hidden
- **THEN** neither appears in the manifest

#### Scenario: Unchanged manifest
- **WHEN** the app sends the last `ETag` and nothing changed
- **THEN** the server responds 304

### Requirement: Premium-gated number and level content
`GET /learn/angka/numbers/:value` SHALL return:
- `value`, `name` and `audio_url`;
- `object` (`id`, `name`, `image_url`);
- `count_audio`, the published audio URL of each number from 1 to `value`.

`GET /learn/angka/levels/:id` SHALL return:
- the published level content and `version`;
- `objects`: every object referenced by that version, with `name`, `question_text`, `image_url`, `question_audio_url` and `hidden`;
- `count_audio` for 1 to `range.max`.

Asset ids SHALL be resolved to public URLs, and an asset id SHALL win over an external URL.

A request SHALL be allowed when the item is free or the caller has an active Akses Premium subscription. Otherwise the server SHALL respond `402 {"code":"PREMIUM_REQUIRED"}`. An unknown, draft-only or hidden item SHALL respond 404. Content-only purchases SHALL NOT unlock Angka.

#### Scenario: Free level without subscription
- **WHEN** a non-subscriber requests Level 1, which is free
- **THEN** the server responds 200 with the content, the object media URLs, and count audio for 1–5

#### Scenario: Locked number
- **WHEN** a non-subscriber requests number 7
- **THEN** the server responds 402 `PREMIUM_REQUIRED`

#### Scenario: Expired subscription
- **WHEN** a user whose subscription expired yesterday requests Level 2
- **THEN** the server responds 402 `PREMIUM_REQUIRED`

### Requirement: Angka API contract and authorization tests
`openapi.yaml` SHALL document every new `/learn/angka/*` and `/children/:childId/angka/*` route and every response, including 304, 402, 404, 409 and 422. A table-driven Go test SHALL assert, for each premium-guarded route, that a non-subscriber gets 402 for a non-free item and 200 for a free one. The security suite SHALL cover reading and writing another parent's Angka sessions and progress.

#### Scenario: Router-wide premium check
- **WHEN** the table-driven test calls every guarded route as a non-subscriber for Level 2 and number 7
- **THEN** each responds 402
