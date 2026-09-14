## MODIFIED Requirements

### Requirement: premium_packages database table exists
The system SHALL have a `premium_packages` table with columns: `id` (UUID PK), `name` (VARCHAR 100), `subtitle` (VARCHAR 255), `price_idr` (INTEGER), `type` (VARCHAR 20, CHECK IN `content`, `subscription`), `badge_label` (VARCHAR 50, nullable), `is_best_value` (BOOLEAN, default FALSE), `is_active` (BOOLEAN, default TRUE), `sort_order` (INTEGER, default 0), `duration_days` (INTEGER, nullable), `created_at` (TIMESTAMPTZ), `updated_at` (TIMESTAMPTZ). `duration_days` SHALL be required (NOT NULL) when `type = 'subscription'` and SHALL be NULL when `type = 'content'`. A seed migration SHALL insert the 6 existing static packages, with `duration_days = 30` for "Bulanan" and `duration_days = 365` for "Tahunan".

#### Scenario: Table created by migration
- **WHEN** the migration `001_create_premium_packages.sql` is run on a fresh database
- **THEN** the `premium_packages` table SHALL exist with all required columns and constraints

#### Scenario: Type constraint enforced
- **WHEN** a record is inserted with `type` not in `('content', 'subscription')`
- **THEN** the database SHALL reject the insert with a constraint violation error

#### Scenario: Seed migration populates default packages
- **WHEN** `002_seed_premium_packages.sql` is run after the table creation migration
- **THEN** 4 content packages and 2 subscription packages SHALL exist in the table, with the two subscription packages having distinct `duration_days` values

#### Scenario: Subscription package without duration_days rejected
- **WHEN** a package is inserted with `type = 'subscription'` and `duration_days = NULL`
- **THEN** the database SHALL reject the insert

### Requirement: Public API returns active packages
The system SHALL expose `GET /premium/packs` returning all packages where `is_active = TRUE`, ordered by `sort_order ASC`. An optional `?type=content|subscription` query parameter SHALL filter results to a single type; when the parameter is absent or empty, no type filter SHALL be applied and packages of all types SHALL be returned. No authentication SHALL be required.

#### Scenario: Returns only active packages
- **WHEN** `GET /premium/packs` is called and one package has `is_active = FALSE`
- **THEN** that package SHALL NOT appear in the response

#### Scenario: Filtered by type
- **WHEN** `GET /premium/packs?type=subscription` is called
- **THEN** only packages with `type = 'subscription'` SHALL be returned

#### Scenario: No type filter returns all types
- **WHEN** `GET /premium/packs` is called without a `type` query parameter
- **THEN** active packages of every type SHALL be returned, not zero results

#### Scenario: Ordered by sort_order
- **WHEN** packages have different `sort_order` values
- **THEN** the response SHALL list them in ascending `sort_order` order

#### Scenario: No auth required
- **WHEN** `GET /premium/packs` is called without an Authorization header
- **THEN** the response SHALL return 200 with the package list

## ADDED Requirements

### Requirement: Package items map packages to products
The system SHALL have a `premium_package_items` table (`package_id` UUID FK → `premium_packages.id` ON DELETE CASCADE, `product_id` UUID FK → `products.id` ON DELETE RESTRICT, `created_at`, composite PK `(package_id, product_id)`). A package's purchasable content is defined exclusively through this table — `premium_packages` SHALL NOT directly reference `ar_cards` or `dongengs`.

#### Scenario: Package item added
- **WHEN** a `premium_package_items` row is inserted linking a package to a product
- **THEN** the product SHALL be resolvable as part of that package's contents

#### Scenario: Duplicate package item rejected
- **WHEN** the same `(package_id, product_id)` pair is inserted twice
- **THEN** the database SHALL reject the second insert via the composite primary key

### Requirement: Admin API manages package items
The system SHALL expose authenticated admin endpoints: `GET /admin/premium/packs/:id/items` (list products in a package), `POST /admin/premium/packs/:id/items` (add a product to a package, body `{ "product_id": "..." }`), `DELETE /admin/premium/packs/:id/items/:product_id` (remove a product from a package). All endpoints SHALL require a valid admin JWT.

#### Scenario: Admin lists package items
- **WHEN** `GET /admin/premium/packs/:id/items` is called with a valid admin JWT
- **THEN** all products currently in the package SHALL be returned

#### Scenario: Admin adds a product to a package
- **WHEN** `POST /admin/premium/packs/:id/items` is called with a valid `product_id`
- **THEN** a `premium_package_items` row SHALL be created and the product SHALL appear in subsequent item listings for that package

#### Scenario: Admin removes a product from a package
- **WHEN** `DELETE /admin/premium/packs/:id/items/:product_id` is called
- **THEN** the corresponding `premium_package_items` row SHALL be deleted
