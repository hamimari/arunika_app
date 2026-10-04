## ADDED Requirements

### Requirement: Single products are bought with their Google Play product id
The AR card list and detail responses and the dongeng list and detail responses SHALL include the linked product's `play_product_id` (omitted when unmapped). The app SHALL pass it to the payment screen, so a locked card or story mapped to a Google Play product can be bought through Google Play Billing. A single item without a `play_product_id` SHALL NOT be purchasable.

#### Scenario: Mapped card is purchasable
- **WHEN** an AR card's product has `play_product_id = "sku_frog"`
- **THEN** `GET /ar/cards` SHALL return `play_product_id: "sku_frog"` for that card, and the app SHALL offer "Bayar Sekarang" for it

#### Scenario: Unmapped card is not purchasable
- **WHEN** an AR card's product has no `play_product_id`
- **THEN** the response SHALL omit the field and the payment screen SHALL show "Belum tersedia di perangkat ini" for it

### Requirement: An interrupted single-product purchase is recovered
When the app reports a Google Play purchase without an order id (it was interrupted before it could), the backend SHALL find the user's most recent PENDING order for the package, or else the single product, mapped to that product id, and settle it.

#### Scenario: Recovering a single-product purchase
- **WHEN** a user's PENDING order is for a product mapped to `sku_frog`, and `POST /payment/play/verify` is called with `product_id = "sku_frog"`, a valid purchase token and no order id
- **THEN** that order SHALL be settled and the user granted the product
