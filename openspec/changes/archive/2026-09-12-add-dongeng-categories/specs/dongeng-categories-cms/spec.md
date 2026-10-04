## ADDED Requirements

### Requirement: dongeng_categories database table exists
The system SHALL have a `dongeng_categories` table with columns `id` (UUID PK), `name` (VARCHAR 100 NOT NULL), `emoji` (VARCHAR 20 NOT NULL DEFAULT ''), `image_url` (TEXT NOT NULL DEFAULT ''), `parent_id` (UUID, self-referencing FK to `dongeng_categories(id)` ON DELETE SET NULL, nullable), `sort_order` (INT NOT NULL DEFAULT 0), `created_at`/`updated_at` (TIMESTAMPTZ), and `is_deleted` (BOOLEAN NOT NULL DEFAULT false). A `parent_id IS NULL` row is a top-level category; a row with `parent_id` set is a sub-category of it.

#### Scenario: Table created by migration
- **WHEN** migration `V43__create_dongeng_categories.sql` runs on a fresh database
- **THEN** the `dongeng_categories` table SHALL exist with all required columns, the self-referencing FK, and an index on `parent_id`

### Requirement: Seed data provides Fairy Tales and Islamic categories
The system SHALL seed two top-level `dongeng_categories` rows — "Fairy Tales" and "Islamic" — both with `parent_id = NULL`. The seed SHALL be idempotent (re-running it must not create duplicates).

#### Scenario: Seed runs on a fresh database
- **WHEN** `R__seed_dongeng_categories.sql` runs after the table migration
- **THEN** exactly one "Fairy Tales" row and one "Islamic" row SHALL exist, both top-level

#### Scenario: Seed re-run is a no-op
- **WHEN** the seed is applied a second time
- **THEN** no duplicate "Fairy Tales" or "Islamic" rows SHALL be created

### Requirement: dongengs link to a dongeng category
The `dongengs` table SHALL gain nullable `dongeng_category_id` and `dongeng_sub_category_id` columns, both foreign keys to `dongeng_categories(id)` with `ON DELETE SET NULL`. These are additive alongside the pre-existing `category_id` column (which continues to reference the unrelated generic `categories` table and is not modified by this change).

#### Scenario: A dongeng can be linked to a top-level category
- **WHEN** an admin sets a dongeng's `dongeng_category_id` to a top-level `dongeng_categories` row
- **THEN** the dongeng record SHALL persist that link and it SHALL be readable via the public API's `category_ref`

#### Scenario: Deleting a category unlinks dongeng rows instead of failing
- **WHEN** a `dongeng_categories` row referenced by one or more `dongengs.dongeng_category_id` values is deleted
- **THEN** the referencing `dongengs.dongeng_category_id` values SHALL be set to NULL rather than the deletion failing

### Requirement: Public API exposes dongeng categories
The system SHALL expose `GET /dongeng-categories`, returning all non-deleted top-level categories ordered by `sort_order ASC`, each with its non-deleted children (sub-categories) preloaded. No authentication SHALL be required.

#### Scenario: Returns top-level categories with children
- **WHEN** `GET /dongeng-categories` is called
- **THEN** the response SHALL list top-level categories ordered by `sort_order`, each including any child categories

#### Scenario: Deleted categories excluded
- **WHEN** a category has `is_deleted = true`
- **THEN** it SHALL NOT appear in the response, whether top-level or as a child

### Requirement: Dongeng list/detail API supports category filtering and includes category refs
`GET /fairy-tales` SHALL accept optional `dongeng_category_id` and `dongeng_sub_category_id` query parameters, filtering results to matching dongeng rows when provided. Both `GET /fairy-tales` and `GET /fairy-tales/:id` responses SHALL include a nested `category_ref` and `sub_category_ref` object (or `null`/omitted when unset) reflecting the linked `dongeng_categories` rows.

#### Scenario: Filtering by category
- **WHEN** `GET /fairy-tales?dongeng_category_id=<id>` is called
- **THEN** only dongeng rows with that `dongeng_category_id` SHALL be returned

#### Scenario: Filtering by category and sub-category
- **WHEN** both `dongeng_category_id` and `dongeng_sub_category_id` are supplied
- **THEN** only dongeng rows matching both SHALL be returned

#### Scenario: Response includes category ref
- **WHEN** a dongeng has `dongeng_category_id` set to an existing category
- **THEN** the response for that dongeng SHALL include `category_ref` with that category's `id`, `name`, and `emoji`

### Requirement: Admin API provides full CRUD for dongeng categories
The system SHALL expose authenticated admin endpoints: `GET /admin/content/dongeng-categories` (list, including hidden/soft-deleted-as-hidden), `POST /admin/content/dongeng-categories` (create), `GET /admin/content/dongeng-categories/:id` (get one), `PUT /admin/content/dongeng-categories/:id` (update), `DELETE /admin/content/dongeng-categories/:id` (soft delete), `PATCH /admin/content/dongeng-categories/:id/visibility` (toggle visibility). All endpoints SHALL require a valid admin JWT.

#### Scenario: Create a category
- **WHEN** an admin `POST`s `{"name": "Adventure", "emoji": "🗺️"}` to `/admin/content/dongeng-categories`
- **THEN** a new `dongeng_categories` row SHALL be created and returned with a generated `id`

#### Scenario: Update a category
- **WHEN** an admin `PUT`s changed fields to `/admin/content/dongeng-categories/:id`
- **THEN** the matching row SHALL be updated and the response SHALL reflect the new values

#### Scenario: Delete a category
- **WHEN** an admin `DELETE`s `/admin/content/dongeng-categories/:id`
- **THEN** the row SHALL be soft-deleted (`is_deleted = true`) and excluded from subsequent public/admin list responses

#### Scenario: Unauthenticated request rejected
- **WHEN** any `/admin/content/dongeng-categories*` endpoint is called without a valid admin JWT
- **THEN** the request SHALL be rejected with a 401/403 response
