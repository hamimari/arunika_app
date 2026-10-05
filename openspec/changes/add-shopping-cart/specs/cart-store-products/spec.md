## ADDED Requirements

### Requirement: Store products exist for every possible cart total
The system SHALL have a `store_products` table (`id`, `store` IN `google`, `play_product_id` text unique, `price_idr` BIGINT, `active` boolean) with a unique `(store, price_idr)`. For Google Play there SHALL be one consumable product per whole Rp 1.000 from Rp 1.000 to Rp 500.000 (500 products), named `arunika.cart.t<rupiah>`. The server SHALL choose the product with `price_idr = total_idr` among active rows; the app SHALL never build a product id.

#### Scenario: Exact product chosen
- **WHEN** an order total is Rp 106.000
- **THEN** the product `arunika.cart.t106000` SHALL be selected and `charge_idr` SHALL be 106000

#### Scenario: Inactive product not used
- **WHEN** the product for a total is inactive
- **THEN** the order SHALL be refused with `AMOUNT_UNAVAILABLE`

### Requirement: A tool creates the store products
`cmd/storeprices` SHALL read the price grid, create missing consumable products through the Google Play Developer API, write `store_products`, and be safe to run again (existing products are skipped). Credentials SHALL come from the secret store, never from config files in the repository. It SHALL support a dry run that lists what it would create.

#### Scenario: Re-run creates nothing new
- **WHEN** the tool is run twice
- **THEN** the second run SHALL create no products

#### Scenario: Dry run
- **WHEN** the tool is run with the dry-run flag
- **THEN** it SHALL list missing products and make no changes in Google Play or the database

### Requirement: Item prices follow the Rp 1.000 step
`products.price_idr` SHALL be a whole multiple of 1000, enforced by a database `CHECK` and by the admin product API (400 with a validation message). A price of 0 (catalog placeholder rows) is allowed but such a product is never for sale in the cart. The migration SHALL list existing rows that break the rule and fail instead of rounding.

#### Scenario: Price not on the grid rejected
- **WHEN** an admin saves a price of 1500
- **THEN** the API SHALL respond 400 and the price SHALL not change

#### Scenario: Migration with bad data
- **WHEN** a product has price 1500 at migration time
- **THEN** the migration SHALL fail and name that product
