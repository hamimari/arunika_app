## ADDED Requirements

### Requirement: Growth measurement storage
The backend SHALL store measurements in a `growth_measurements` table. Each row SHALL hold:
- `child_id`, a foreign key to `children` with `ON DELETE CASCADE`;
- `measured_on`;
- nullable `height_cm` and `weight_kg`, each `numeric(4,1)`, at least one of them non-null and each positive when present;
- `position` (`standing` or `recumbent`);
- the derived values `age_days`, `hfa_z`, `wfa_z`, `hfa_category` and `wfa_category`;
- `flagged`;
- `who_version` (default `who2006`);
- a unique nullable `client_id`;
- `created_at`, `updated_at` and `deleted_at`.

The migration SHALL drop the unused `growth_records` table. The old `POST /growth`, `GET /growth` and `PUT /growth/:id` routes SHALL be removed.

#### Scenario: Both values missing
- **WHEN** a row is inserted with neither height nor weight
- **THEN** the database rejects it

#### Scenario: Old route removed
- **WHEN** a client calls `GET /growth?child_id=…`
- **THEN** the server responds 404

### Requirement: Child ownership on every growth endpoint
Every route under `/children/:childId/growth` SHALL require a valid JWT. It SHALL respond 404 unless the child has `parent_id` equal to the caller and is not deleted, and unless any measurement id in the path belongs to that child. An unknown id and another parent's id SHALL get identical responses.

#### Scenario: Another parent's child
- **WHEN** parent A requests `GET /children/{child of B}/growth`
- **THEN** the server responds 404 with no measurement data

#### Scenario: Measurement of a different child
- **WHEN** parent A sends `PATCH /children/{A's child}/growth/measurements/{id of B's measurement}`
- **THEN** the server responds 404 and B's row is unchanged

### Requirement: Growth summary and history
`GET /children/:childId/growth` SHALL return:
- `profile_complete`;
- the child's `name`, normalized `sex`, `birth_date`, `age_label` and `over_60_months`;
- `latest_height` and `latest_weight`, taken from the newest non-deleted measurement that has that value, each with `value`, `category`, `measured_on` and `delta_from_previous` (omitted when there is no earlier measurement with that value);
- every non-deleted measurement, newest first by `measured_on` and then `created_at`, each with raw values, `position`, `age_days`, `age_label`, categories, `flagged`, `created_at` and `updated_at`.

A child whose `gender` does not normalize to male or female SHALL be reported with `profile_complete: false`.

#### Scenario: Two measurements
- **WHEN** a child has measurements of 92.6 cm on 12 Jun 2026 and 94.8 cm on 12 Sep 2026
- **THEN** `latest_height.value` is 94.8 and `latest_height.delta_from_previous` is 2.2

#### Scenario: Only one measurement
- **WHEN** a child has a single measurement
- **THEN** `delta_from_previous` is absent from both latest values

#### Scenario: Unrecognized gender
- **WHEN** the child's stored gender is an empty string
- **THEN** the response has `profile_complete: false`

### Requirement: Create measurement
`POST /children/:childId/growth/measurements` SHALL accept `client_id`, `measured_on`, `height_cm`, `weight_kg`, `position` and `confirm_outlier`. The server SHALL compute age, z-scores and categories with the `growth-classification` engine and SHALL ignore any category sent by the client. It SHALL respond 201 with the stored row.

It SHALL respond 422, with the body `{"error": "…", "code": "…"}`, for these codes:
- `PROFILE_INCOMPLETE` when the birth date or sex is missing or unrecognized;
- `DATE_OUT_OF_RANGE` when `measured_on` is after today (Asia/Jakarta) or before the birth date;
- `VALUE_REQUIRED` when both values are missing;
- `INVALID_VALUE` when a value is ≤ 0 or ≥ 1000, and `INVALID_POSITION` for an unknown position;
- `OUTLIER_NEEDS_CONFIRM`, naming the flagged indicators, when a value is implausible and `confirm_outlier` is not true.

A confirmed outlier SHALL be stored with `flagged = true`. A request whose `client_id` already exists for the same child SHALL respond 200 with the existing row and SHALL NOT create a duplicate; one used for a different child SHALL respond 409 `CLIENT_ID_CONFLICT`.

#### Scenario: Normal measurement
- **WHEN** a boy born 2023-07-12 gets `{measured_on: 2026-09-12, height_cm: 94.8, weight_kg: 13.9, position: standing}`
- **THEN** the server responds 201 with `age_label` "3 tahun 2 bulan" and both categories `normal`

#### Scenario: Future date
- **WHEN** `measured_on` is tomorrow
- **THEN** the server responds 422 `DATE_OUT_OF_RANGE`

#### Scenario: Outlier without confirmation
- **WHEN** a 3-year-old's height is 9.5 cm and `confirm_outlier` is false
- **THEN** the server responds 422 `OUTLIER_NEEDS_CONFIRM` and stores nothing

#### Scenario: Outlier confirmed
- **WHEN** the same request is resent with `confirm_outlier: true`
- **THEN** the server responds 201 with `flagged: true`

#### Scenario: Retried create
- **WHEN** the same `client_id` is posted twice
- **THEN** the second call responds 200 with the first row and only one row exists

#### Scenario: Two measurements on the same date
- **WHEN** two measurements with different `client_id`s share a `measured_on`
- **THEN** both are stored

### Requirement: Edit measurement
`PATCH /children/:childId/growth/measurements/:id` SHALL update the provided fields among `measured_on`, `height_cm`, `weight_kg` and `position`. An explicit null SHALL clear a height or weight. The request SHALL be checked with the same validation and outlier rules as create, the server SHALL recompute age, z-scores and categories, and it SHALL set `updated_at`. A soft-deleted measurement SHALL respond 404.

#### Scenario: Correcting a typo
- **WHEN** a parent changes a height from 9.5 cm to 95.0 cm
- **THEN** the row's height-for-age category is recomputed and `flagged` becomes false

#### Scenario: Clearing the only value
- **WHEN** a PATCH clears the weight on a row that has no height
- **THEN** the server responds 422 `VALUE_REQUIRED`

### Requirement: Soft delete and restore
`DELETE /children/:childId/growth/measurements/:id` SHALL set `deleted_at` and respond 204. The row SHALL then be excluded from summaries and history. `POST …/measurements/:id/restore` SHALL clear `deleted_at` and return the row, as long as the row has not been purged. A background job SHALL run at least daily and hard-delete rows soft-deleted more than 30 days ago.

#### Scenario: Undo after delete
- **WHEN** a parent deletes a measurement and calls restore 3 seconds later
- **THEN** the measurement reappears in `GET …/growth` unchanged

#### Scenario: Purge
- **WHEN** the purge job runs and a row was soft-deleted 31 days ago
- **THEN** the row is permanently removed and restore responds 404

### Requirement: Recompute on profile change
When `PUT /user` changes a child's `date_of_birth` or `gender`, the backend SHALL recompute `age_days`, z-scores, categories and `flagged` for every measurement of that child, in the same transaction.

#### Scenario: Birth date corrected
- **WHEN** a parent changes their child's birth date from 2023-07-12 to 2023-01-12
- **THEN** every stored measurement's `age_days` grows by 181 and its categories reflect the new age

#### Scenario: Sex corrected
- **WHEN** a child's gender changes from "Laki-Laki" to "Perempuan"
- **THEN** every measurement is reclassified against the girls' tables

### Requirement: Growth data deletion and privacy
Account deletion SHALL hard-delete every growth measurement of the account's children. Growth endpoints SHALL NOT log request or response bodies.

#### Scenario: Account deleted
- **WHEN** a parent deletes their account
- **THEN** no `growth_measurements` rows remain for their children

### Requirement: Growth tracking feature flag seed
A migration SHALL insert the `app_feature_flags` row `growth_tracking`, named "Tumbuh Kembang", described "Tumbuh tab and Beranda growth card.", with `is_enabled = false`.

#### Scenario: Fresh database
- **WHEN** migrations run on an empty database
- **THEN** `GET /app/feature-flags` includes `growth_tracking: false`

### Requirement: Growth API contract and authorization tests
`openapi.yaml` SHALL document every new route, request and response, and SHALL drop the old `/growth` paths. The security test suite SHALL cover cross-parent read, create, edit, delete and restore on the new routes.

#### Scenario: Cross-parent restore
- **WHEN** parent A calls restore on parent B's deleted measurement
- **THEN** the test asserts 404 and the row stays deleted
