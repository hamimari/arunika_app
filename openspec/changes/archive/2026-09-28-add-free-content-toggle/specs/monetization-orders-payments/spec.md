## ADDED Requirements

### Requirement: Free content cannot be bought as a single product
The single-product order endpoints (Midtrans product checkout and Google Play product order creation) SHALL reject, with 400, a product whose linked AR card or dongeng has `is_free = true`. No order SHALL be created. Package orders are not affected.

#### Scenario: Stale client tries to buy a now-free card
- **WHEN** a client requests a Google Play product order for a product whose AR card is flagged `is_free`
- **THEN** the response SHALL be 400 with a "content is free" error, and no `orders` row SHALL be created

#### Scenario: Package containing a free item still sells
- **WHEN** a user buys a content package that includes a flagged-free item
- **THEN** the order SHALL proceed normally
