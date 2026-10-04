## ADDED Requirements

### Requirement: User entitlements record per-user ownership
The system SHALL have a `user_entitlements` table (`id` UUID PK, `user_id` UUID NOT NULL, `product_id` UUID NOT NULL FK → `products.id`, `starts_at` TIMESTAMPTZ NOT NULL, `expires_at` TIMESTAMPTZ NULL, `source_order_id` UUID NULL FK → `orders.id`, `created_at`), with a `UNIQUE (user_id, product_id)` constraint.

#### Scenario: Duplicate entitlement grant is rejected/ignored
- **WHEN** a second `user_entitlements` row is inserted for the same `(user_id, product_id)` pair
- **THEN** the database SHALL reject the insert via the unique constraint, and the granting transaction SHALL treat this as a successful no-op (`ON CONFLICT DO NOTHING`) rather than an error

### Requirement: Successful content-package payment grants entitlements transactionally
When an order referencing a `package_id` with `premium_packages.type = 'content'` transitions to `PAID`, the system SHALL, within the same database transaction, resolve `premium_package_items` for that package to their `product_id`s and insert one `user_entitlements` row per product for the ordering user, with `expires_at = NULL`.

#### Scenario: Bundle purchase grants all items
- **WHEN** an order for a content package containing 4 products transitions to `PAID`
- **THEN** the user SHALL have 4 `user_entitlements` rows, one per product in the package, each with `expires_at = NULL`

### Requirement: Successful individual-product payment grants a single entitlement
When an order referencing a `product_id` directly (not a package) transitions to `PAID`, the system SHALL insert one `user_entitlements` row for that user and product.

#### Scenario: Single product purchase grants one entitlement
- **WHEN** an order with `product_id` set transitions to `PAID`
- **THEN** exactly one `user_entitlements` row SHALL exist for that user and product

### Requirement: Successful subscription-package payment grants blanket subscription access
When an order referencing a `package_id` with `premium_packages.type = 'subscription'` transitions to `PAID`, the system SHALL upsert a `user_subscriptions` row for the user with `status = 'active'`, `start_date = now`, `end_date = now + package.duration_days days`, and `package_id` set. A user with an active, unexpired subscription is granted access to all paid AR cards and dongeng, independent of individual `user_entitlements` rows.

#### Scenario: Subscription purchase grants access without per-product rows
- **WHEN** a user purchases a `subscription`-type package and the order transitions to `PAID`
- **THEN** `user_subscriptions.status` SHALL be `active` with `end_date` equal to `start_date + package.duration_days`, and the user SHALL be granted access to every paid AR card and dongeng without individual `user_entitlements` rows being created

### Requirement: Access is resolved per request from entitlements, not a stored flag
The system SHALL compute content-access (`is_unlocked` on AR cards, `is_unlocked` on dongeng) at request time as: free (no linked product) → allowed; else allowed if the requesting user has an active `user_entitlements` row for the linked product OR an active subscription; else denied. Stored global unlock flags SHALL NOT be used for this determination.

#### Scenario: Free content always accessible
- **WHEN** a request is made for an AR card with no linked product
- **THEN** `is_unlocked` SHALL be `true` for every user, including unauthenticated requests

#### Scenario: Paid content accessible only with an entitlement
- **WHEN** a request is made for a paid AR card by a user with an active `user_entitlements` row for its product
- **THEN** `is_unlocked` SHALL be `true`

#### Scenario: Paid content inaccessible without an entitlement
- **WHEN** a request is made for a paid AR card by a user with no matching entitlement and no active subscription
- **THEN** `is_unlocked` SHALL be `false`

#### Scenario: Expired entitlement does not grant access
- **WHEN** a user's `user_entitlements` row for a product has `expires_at` in the past
- **THEN** `is_unlocked` SHALL be `false` for that product

### Requirement: Legacy stored unlock flags are removed after cutover
The `ar_cards.is_unlocked` and `animals.is_unlocked` stored columns SHALL be dropped once entitlement-based access resolution is live and verified. The `is_unlocked` field remains present in API responses as a computed value.

#### Scenario: API shape unchanged after column removal
- **WHEN** the `is_unlocked` column is dropped from `ar_cards`
- **THEN** `GET /ar/cards` responses SHALL still include an `is_unlocked` boolean field per card, now computed per-request
