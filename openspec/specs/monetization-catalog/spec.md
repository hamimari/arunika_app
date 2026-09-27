# monetization-catalog Specification

## Purpose
TBD - created by archiving change add-monetization-entitlements. Update Purpose after archive.
## Requirements
### Requirement: Feature taxonomy identifies purchasable content types
The system SHALL have a `features` table (`id` UUID PK, `code` VARCHAR UNIQUE, `name`, `description`, `is_active`, `created_at`, `updated_at`) seeded with exactly two rows: `AR_CARD` and `DONGENG`. `features` SHALL NOT contain content-specific fields (no file URLs, no sound URLs).

#### Scenario: Feature codes seeded
- **WHEN** the catalog migrations run on a fresh database
- **THEN** `features` SHALL contain rows with `code = 'AR_CARD'` and `code = 'DONGENG'`, and no other codes

### Requirement: Products represent the purchasable unit of content
The system SHALL have a `products` table (`id` UUID PK, `feature_id` UUID FK → `features.id`, `price_idr` BIGINT, `is_active` BOOLEAN, `created_at`, `updated_at`). A product is never referenced by `resource_type`/`resource_id` polymorphism; it is linked to exactly one content row via a dedicated mapping table.

#### Scenario: Product created for a feature
- **WHEN** a product is inserted with `feature_id` referencing the `AR_CARD` feature
- **THEN** the row SHALL be persisted with a valid foreign key to `features`

#### Scenario: Invalid feature rejected
- **WHEN** a product is inserted with a `feature_id` that does not exist in `features`
- **THEN** the database SHALL reject the insert with a foreign key violation

### Requirement: Product-to-content mapping uses real foreign keys
The system SHALL have `product_ar_cards` (`product_id` UUID PK FK → `products.id` ON DELETE CASCADE, `ar_card_id` UUID UNIQUE FK → `ar_cards.id` ON DELETE RESTRICT) and `product_dongengs` (`product_id` UUID PK FK → `products.id` ON DELETE CASCADE, `dongeng_id` UUID UNIQUE FK → `dongengs.id` ON DELETE RESTRICT). Each content row maps to at most one product.

#### Scenario: AR card mapped to a product
- **WHEN** a `product_ar_cards` row is inserted linking a product to an AR card
- **THEN** the AR card SHALL be resolvable to exactly one product via that mapping

#### Scenario: Duplicate mapping rejected
- **WHEN** a second `product_ar_cards` row is inserted for an `ar_card_id` that already has a mapping
- **THEN** the database SHALL reject the insert due to the unique constraint on `ar_card_id`

#### Scenario: Deleting a content row referenced by a product is restricted
- **WHEN** a delete is attempted on an `ar_cards` or `dongengs` row that has an active `product_ar_cards`/`product_dongengs` mapping
- **THEN** the database SHALL reject the delete (`ON DELETE RESTRICT`)

### Requirement: Content without a product mapping is implicitly free
The system SHALL treat any AR card or dongeng with no corresponding row in `product_ar_cards`/`product_dongengs` as free content, requiring no entitlement to access.

#### Scenario: Unmapped AR card is free
- **WHEN** an AR card has no row in `product_ar_cards`
- **THEN** access resolution SHALL grant access to every user regardless of entitlements

