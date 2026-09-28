## ADDED Requirements

### Requirement: Content can be explicitly flagged free
`ar_cards` and `dongengs` SHALL each have an `is_free BOOLEAN NOT NULL DEFAULT false` column. Content with `is_free = true` SHALL be treated as free even when it has a product mapping. The mapping, the product and any orders or entitlements referencing it SHALL be kept unchanged.

#### Scenario: Flagged AR card with a product is free
- **WHEN** an AR card has a row in `product_ar_cards` and `is_free = true`
- **THEN** access resolution SHALL grant access to every user regardless of entitlements

#### Scenario: Existing cards keep their behaviour after migration
- **WHEN** the migration adding `ar_cards.is_free` runs
- **THEN** every existing AR card SHALL have `is_free = false`, and its access SHALL be unchanged
