## ADDED Requirements

### Requirement: premium_packages database table exists
The system SHALL have a `premium_packages` table with columns: `id` (UUID PK), `name` (VARCHAR 100), `subtitle` (VARCHAR 255), `price_idr` (INTEGER), `type` (VARCHAR 20, CHECK IN `content`, `subscription`), `badge_label` (VARCHAR 50, nullable), `is_best_value` (BOOLEAN, default FALSE), `is_active` (BOOLEAN, default TRUE), `sort_order` (INTEGER, default 0), `created_at` (TIMESTAMPTZ), `updated_at` (TIMESTAMPTZ). A seed migration SHALL insert the 6 existing static packages.

#### Scenario: Table created by migration
- **WHEN** the migration `001_create_premium_packages.sql` is run on a fresh database
- **THEN** the `premium_packages` table SHALL exist with all required columns and constraints

#### Scenario: Type constraint enforced
- **WHEN** a record is inserted with `type` not in `('content', 'subscription')`
- **THEN** the database SHALL reject the insert with a constraint violation error

#### Scenario: Seed migration populates default packages
- **WHEN** `002_seed_premium_packages.sql` is run after the table creation migration
- **THEN** 4 content packages and 2 subscription packages SHALL exist in the table

### Requirement: Public API returns active packages
The system SHALL expose `GET /premium/packs` returning all packages where `is_active = TRUE`, ordered by `sort_order ASC`. An optional `?type=content|subscription` query parameter SHALL filter results to a single type. No authentication SHALL be required.

#### Scenario: Returns only active packages
- **WHEN** `GET /premium/packs` is called and one package has `is_active = FALSE`
- **THEN** that package SHALL NOT appear in the response

#### Scenario: Filtered by type
- **WHEN** `GET /premium/packs?type=subscription` is called
- **THEN** only packages with `type = 'subscription'` SHALL be returned

#### Scenario: Ordered by sort_order
- **WHEN** packages have different `sort_order` values
- **THEN** the response SHALL list them in ascending `sort_order` order

#### Scenario: No auth required
- **WHEN** `GET /premium/packs` is called without an Authorization header
- **THEN** the response SHALL return 200 with the package list

### Requirement: Admin API provides full CRUD for packages
The system SHALL expose authenticated admin endpoints: `GET /admin/premium/packs` (all packages including inactive), `POST /admin/premium/packs` (create), `PUT /admin/premium/packs/:id` (update), `DELETE /admin/premium/packs/:id` (delete), `PATCH /admin/premium/packs/:id/visibility` (toggle `is_active`). All endpoints SHALL require a valid admin JWT.

#### Scenario: Admin lists all packages including inactive
- **WHEN** `GET /admin/premium/packs` is called with a valid admin JWT
- **THEN** all packages, including those with `is_active = FALSE`, SHALL be returned

#### Scenario: Admin creates a package
- **WHEN** `POST /admin/premium/packs` is called with valid fields
- **THEN** the package SHALL be saved and returned with its generated `id`

#### Scenario: Admin toggles visibility
- **WHEN** `PATCH /admin/premium/packs/:id/visibility` is called with `{ "is_active": false }`
- **THEN** the package's `is_active` SHALL be updated and the updated record returned

#### Scenario: Admin deletes a package
- **WHEN** `DELETE /admin/premium/packs/:id` is called
- **THEN** the package SHALL be removed from the database and a 204 response returned

#### Scenario: Unauthenticated admin request is rejected
- **WHEN** any `/admin/premium/packs` endpoint is called without a valid JWT
- **THEN** the response SHALL return 401 Unauthorized
