## ADDED Requirements

### Requirement: Admin can map a product to a Google Play SKU
The Products page SHALL show a "Play Billing" column (Mapped with the SKU, or Unmapped) and a "Play Product ID" field on the Add and Edit product forms. `POST /admin/products` and `PUT /admin/products/:id` SHALL accept `play_product_id`.
- On update, an absent field SHALL leave the mapping unchanged, and `null` or a blank string SHALL clear it. Surrounding whitespace SHALL be trimmed.
- A SKU already used by another product or by a package SHALL be rejected with 400, and the page SHALL show the server's message.

#### Scenario: Mapping a product
- **WHEN** the admin enters `card_frog` in "Play Product ID" and saves
- **THEN** the product SHALL show "Mapped" with `card_frog`, and the public AR card list SHALL carry `play_product_id: "card_frog"`

#### Scenario: Editing the price keeps the mapping
- **WHEN** a client updates a product's price without sending `play_product_id`
- **THEN** the product's mapping SHALL be unchanged

#### Scenario: Clearing the mapping
- **WHEN** the admin empties the "Play Product ID" field and saves
- **THEN** the mapping SHALL be cleared and the product SHALL show "Unmapped"

#### Scenario: Duplicate SKU
- **WHEN** the admin enters a SKU that another product or package already uses
- **THEN** the save SHALL be rejected and the page SHALL show "already used by another product or package"
