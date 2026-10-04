## MODIFIED Requirements

### Requirement: premium_packages database table exists
The system SHALL have a `premium_packages` table with columns: `id` (UUID PK), `name` (VARCHAR 100), `subtitle` (VARCHAR 255), `description` (TEXT, nullable), `image_url` (TEXT, nullable), `price_idr` (INTEGER), `type` (VARCHAR 20, CHECK IN `content`, `subscription`), `badge_label` (VARCHAR 50, nullable), `is_best_value` (BOOLEAN, default FALSE), `is_active` (BOOLEAN, default TRUE), `sort_order` (INTEGER, default 0), `duration_days` (INTEGER, nullable), `created_at` (TIMESTAMPTZ), `updated_at` (TIMESTAMPTZ). Migration `V49__add_description_image_to_premium_packages.sql` SHALL add `description` and `image_url` as nullable columns to the existing table, requiring no backfill.

#### Scenario: Existing packages unaffected by the new columns
- **WHEN** migration `V49` runs against a database with existing `premium_packages` rows
- **THEN** those rows SHALL retain all existing column values and SHALL have `description = NULL` and `image_url = NULL`

#### Scenario: New package can set description and image
- **WHEN** a package is created or updated with non-null `description` and `image_url` values
- **THEN** those values SHALL be persisted and returned by subsequent reads

### Requirement: Public API returns active packages
The system SHALL expose `GET /premium/packs` returning all packages where `is_active = TRUE`, ordered by `sort_order ASC`, including each package's `description` and `image_url` (either of which MAY be `null`). An optional `?type=content|subscription` query parameter SHALL filter results to a single type. No authentication SHALL be required.

#### Scenario: Response includes description and image_url
- **WHEN** `GET /premium/packs` is called and a package has non-null `description` and `image_url`
- **THEN** the response item for that package SHALL include both fields with their stored values

#### Scenario: Null fields serialize as null, not omitted
- **WHEN** a package has `description = NULL` and/or `image_url = NULL`
- **THEN** the response item SHALL include those keys with a `null` value rather than omitting them

### Requirement: Admin API provides full CRUD for packages
The system SHALL expose authenticated admin endpoints: `GET /admin/premium/packs` (all packages including inactive), `POST /admin/premium/packs` (create), `PUT /admin/premium/packs/:id` (update), `DELETE /admin/premium/packs/:id` (delete), `PATCH /admin/premium/packs/:id/visibility` (toggle `is_active`). Create and update requests SHALL accept optional `description` and `image_url` string fields. All endpoints SHALL require a valid admin JWT.

#### Scenario: Admin creates a package with description and image
- **WHEN** `POST /admin/premium/packs` is called with `description` and `image_url` set, alongside the existing required fields
- **THEN** the package SHALL be saved with those values and returned with its generated `id`

#### Scenario: Admin creates a package without description or image
- **WHEN** `POST /admin/premium/packs` is called omitting `description` and `image_url`
- **THEN** the package SHALL be created successfully with both fields `null`

#### Scenario: Admin updates description and image on an existing package
- **WHEN** `PUT /admin/premium/packs/:id` is called with new `description`/`image_url` values
- **THEN** the package's stored values SHALL be updated accordingly
